import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/api_service.dart';
import '../../../../services/google_maps_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/location_autocomplete_picker_modal.dart';
import '../../../widgets/route_timeline_tile.dart';
import 'passenger_details_screen_107.dart';
import 'ride_chat_screen.dart';
import 'select_boarding_point_screen_105.dart';

class DriverBookingDetailScreen extends StatefulWidget {
  final RideBookingSession? session;

  const DriverBookingDetailScreen({
    super.key,
    this.session,
  });

  @override
  State<DriverBookingDetailScreen> createState() => _DriverBookingDetailScreenState();
}

class _DriverBookingDetailScreenState extends State<DriverBookingDetailScreen> {
  late RideBookingSession _session;
  RideDetailData? _detailData;
  bool _isLoading = false;

  /// True while the fare quote for "Next" is in flight (prevents double taps).
  bool _isQuoting = false;

  // Doorstep Pickup & Drop options state
  bool _isDoorstepSelected = false;
  String _customPickup = '';
  String _customDrop = '';
  double _detourDistanceKm = 0.0;
  double _detourCharge = 0.0;
  bool _isCalculatingDetour = false;
  bool _isFetchingGps = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? const RideBookingSession();
    _isDoorstepSelected = _session.isDoorstepPickup;
    _customPickup = _session.customerPickupAddress.isNotEmpty ? _session.customerPickupAddress : _session.pickup;
    _customDrop = _session.customerDropAddress.isNotEmpty ? _session.customerDropAddress : _session.destination;
    _detourDistanceKm = _session.detourDistanceKm;
    _detourCharge = _session.detourCharge;
    _loadRideDetails();
  }

  Future<void> _loadRideDetails() async {
    final rideId = _session.rideId.isNotEmpty ? _session.rideId : _session.driver.id;
    if (rideId.isEmpty) return;

    setState(() => _isLoading = true);
    Map<String, dynamic> res;
    try {
      res = await RideService.getRideDetails(
        rideId,
        pickup: _session.pickup,
        destination: _session.destination,
      );
    } catch (_) {
      res = {'success': false, 'message': 'Could not load ride details. Please check your connection and try again.'};
    }

    if (mounted) {
      if (res['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Could not load ride details. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _detailData = RideDetailData.fromJson(
            res,
            pickup: _session.pickup,
            destination: _session.destination,
            fallbackPrice: _session.driver.pricePerSeat,
          );
          final effectivePrice = _detailData!.pricePerSeat > 0
              ? _detailData!.pricePerSeat
              : (_session.driver.pricePerSeat > 0 ? _session.driver.pricePerSeat : 0.0);
          final hasAutoApproval = _detailData!.driver.preferences.autoApproval || _session.driver.preferences.autoApproval;
          final updatedPrefs = _detailData!.driver.preferences.copyWith(
            autoApproval: hasAutoApproval,
            autoApprovalBadge: hasAutoApproval ? 'Instant Booking (Auto Approval)' : _detailData!.driver.preferences.autoApprovalBadge,
          );
          final updatedDriver = _detailData!.driver.copyWith(
            pricePerSeat: effectivePrice,
            isDoorstepAllowed: _detailData!.driver.isDoorstepAllowed || _session.driver.isDoorstepAllowed,
            maxDetourRadiusKm: _detailData!.driver.maxDetourRadiusKm > 0 ? _detailData!.driver.maxDetourRadiusKm : _session.driver.maxDetourRadiusKm,
            detourRatePerKm: _detailData!.driver.detourRatePerKm > 0 ? _detailData!.driver.detourRatePerKm : _session.driver.detourRatePerKm,
            preferences: updatedPrefs,
          );
          final isDoorToDoor = _session.isDoorstepPickup ||
              updatedDriver.rideType == 'door_to_door' ||
              updatedDriver.isWholeCarOnly;
          final vehicleSeats = updatedDriver.totalSeats > 0 ? updatedDriver.totalSeats : 4;
          final flatCarPrice = (updatedDriver.wholeCarPrice > (effectivePrice * 1.5))
              ? updatedDriver.wholeCarPrice
              : (effectivePrice * vehicleSeats);
          final calculatedAmount = isDoorToDoor ? flatCarPrice : (effectivePrice * _session.seatsCount);

          _session = _session.copyWith(
            rideId: _detailData!.rideId,
            driver: updatedDriver,
            totalAmount: calculatedAmount + _detourCharge,
            rideDetailData: _detailData,
          );
        }
      });
    }
  }

  Future<void> _calculateDetourFare(RideDriver driver) async {
    final customPickup = _customPickup.trim();
    final customDrop = _customDrop.trim();

    if (customPickup.isEmpty && customDrop.isEmpty) {
      if (mounted) {
        setState(() {
          _detourDistanceKm = 0.0;
          _detourCharge = 0.0;
        });
      }
      return;
    }

    setState(() => _isCalculatingDetour = true);

    try {
      double totalDetourKm = 0.0;

      // Detour for pickup
      if (customPickup.isNotEmpty) {
        final origin = _session.pickup.isNotEmpty ? _session.pickup : driver.pickupPoint;
        if (origin.isNotEmpty && !customPickup.toLowerCase().contains(origin.toLowerCase())) {
          final res = await GoogleMapsService.getDirectionsByAddress(
            origin: origin,
            destination: customPickup,
          );
          if (res != null && res.distanceMeters > 0) {
            totalDetourKm += (res.distanceMeters / 1000.0);
          } else {
            totalDetourKm += 3.0;
          }
        } else {
          totalDetourKm += 2.0;
        }
      }

      // Detour for drop
      if (customDrop.isNotEmpty) {
        final dest = _session.destination.isNotEmpty ? _session.destination : driver.destinationPoint;
        if (dest.isNotEmpty && !customDrop.toLowerCase().contains(dest.toLowerCase())) {
          final res = await GoogleMapsService.getDirectionsByAddress(
            origin: dest,
            destination: customDrop,
          );
          if (res != null && res.distanceMeters > 0) {
            totalDetourKm += (res.distanceMeters / 1000.0);
          } else {
            totalDetourKm += 3.0;
          }
        } else {
          totalDetourKm += 2.0;
        }
      }

      if (totalDetourKm < 1.0) totalDetourKm = 2.0;

      final rate = driver.detourRatePerKm > 0 ? driver.detourRatePerKm : 15.0;
      final charge = (totalDetourKm * rate).roundToDouble();

      if (mounted) {
        setState(() {
          _detourDistanceKm = totalDetourKm;
          _detourCharge = charge;
          _isCalculatingDetour = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final rate = driver.detourRatePerKm > 0 ? driver.detourRatePerKm : 15.0;
        setState(() {
          _detourDistanceKm = 4.0;
          _detourCharge = (4.0 * rate).roundToDouble();
          _isCalculatingDetour = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocationForPickup(RideDriver driver) async {
    setState(() => _isFetchingGps = true);
    try {
      final loc = await GoogleMapsService.getCurrentLocation();
      if (!mounted) return;
      if (loc != null) {
        final address = loc.formattedAddress.isNotEmpty ? loc.formattedAddress : loc.name;
        setState(() {
          _customPickup = address;
        });
        _calculateDetourFare(driver);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = GoogleMapsService.getReadableLocationError(e);
      final isServiceDisabled = e is LocationServiceDisabledException;
      final isPermission = e is PermissionDeniedException;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          action: (isServiceDisabled || isPermission)
              ? SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () {
                    if (isServiceDisabled) {
                      Geolocator.openLocationSettings();
                    } else if (isPermission) {
                      Geolocator.openAppSettings();
                    }
                  },
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  Future<void> _selectCustomPickup(RideDriver driver) async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Doorstep Pickup Location',
      initialQuery: _customPickup.isNotEmpty ? _customPickup : _session.pickup,
      hintText: 'Search home address, street, or landmark...',
    );

    if (picked != null && mounted) {
      final address = picked.formattedAddress.isNotEmpty ? picked.formattedAddress : picked.name;
      setState(() {
        _customPickup = address;
      });
      _calculateDetourFare(driver);
    }
  }

  Future<void> _selectCustomDrop(RideDriver driver) async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Doorstep Drop Location',
      initialQuery: _customDrop.isNotEmpty ? _customDrop : _session.destination,
      hintText: 'Search drop address, street, or landmark...',
    );

    if (picked != null && mounted) {
      final address = picked.formattedAddress.isNotEmpty ? picked.formattedAddress : picked.name;
      setState(() {
        _customDrop = address;
      });
      _calculateDetourFare(driver);
    }
  }

  ImageProvider? _getAvatarProvider(String avatar) {
    if (avatar.isEmpty) return null;
    if (avatar.startsWith('assets/')) return AssetImage(avatar);
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) return NetworkImage(avatar);
    if (avatar.startsWith('/')) {
      final base = ApiService.serverBaseUrl;
      return NetworkImage('avatar');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final active = _session;
    final baseDriver = _detailData?.driver ?? active.driver;
    final driver = baseDriver.copyWith(
      isDoorstepAllowed: baseDriver.isDoorstepAllowed || active.driver.isDoorstepAllowed,
      maxDetourRadiusKm: baseDriver.maxDetourRadiusKm > 0 ? baseDriver.maxDetourRadiusKm : active.driver.maxDetourRadiusKm,
      detourRatePerKm: baseDriver.detourRatePerKm > 0 ? baseDriver.detourRatePerKm : active.driver.detourRatePerKm,
    );
    final vehicleSummary = _detailData?.vehicleSummary ?? '${driver.carModel} , ${driver.vehicleNumber}'.trim();
    final tripsText = driver.tripsText.isNotEmpty ? driver.tripsText : (driver.reviewCount > 0 ? '${driver.reviewCount} trips' : '');
    final timelineStops = _detailData?.routeTimeline ?? [];
    final avatarProvider = _getAvatarProvider(driver.avatarImage);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Driver Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom Background Graphic
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/image 31.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Column(
              children: [
                if (_isLoading)
                  const LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: Color(0xFFF3EDF7),
                    minHeight: 3,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver Profile Card matching 104.png
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: const Color(0xFFF3EDF7),
                                        backgroundImage: avatarProvider,
                                        onBackgroundImageError: avatarProvider != null ? (_, __) {} : null,
                                        child: avatarProvider == null
                                            ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                                            : null,
                                      ),
                                      if (driver.isVerifiedByAdmin)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Image.asset(
                                            'assets/images/codicon_verified-filled.png',
                                            width: 18,
                                            height: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driver.name.isNotEmpty ? driver.name : 'Driver',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        if (vehicleSummary.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            vehicleSummary,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // 3 Badges row: Rating, Trips, About
                              Row(
                                children: [
                                  if (driver.rating > 0) ...[
                                    _buildBadge(
                                      Icons.star_rounded,
                                      driver.ratingBadge.isNotEmpty
                                          ? driver.ratingBadge.replaceAll('★ ', '')
                                          : '(${driver.ratingCount > 0 ? driver.ratingCount : 126})',
                                      const Color(0xFFFFB800),
                                      const Color(0xFFFFF7EC),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (tripsText.isNotEmpty) ...[
                                    _buildBadge(Icons.directions_car_rounded, tripsText, AppColors.primary, const Color(0xFFF3EDF7)),
                                    const SizedBox(width: 8),
                                  ],
                                  _buildBadge(
                                    Icons.info_outline_rounded,
                                    'About',
                                    AppColors.textSecondary,
                                    const Color(0xFFF5F5F5),
                                    onTap: () => _showDriverAboutModal(context, driver),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Ride Info Header
                        const Text(
                          'Ride Info',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),

                        const SizedBox(height: 12),

                        // Ride Info Vertical Timeline (Unboxed Figma 104 Style)
                        Builder(
                          builder: (context) {
                            final selectedPickup = active.boardingPoint.isNotEmpty
                                ? active.boardingPoint
                                : (active.pickup.isNotEmpty ? active.pickup : driver.pickupPoint);
                            final selectedDestination = active.destination.isNotEmpty
                                ? active.destination
                                : driver.destinationPoint;

                            if (timelineStops.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < timelineStops.length; i++)
                                    _buildTimelineRow(
                                      stop: timelineStops[i],
                                      isFirst: i == 0,
                                      isLast: i == timelineStops.length - 1,
                                    ),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimelineRow(
                                  stop: RouteTimelineStop(
                                    time: active.time.isNotEmpty ? active.time : (_detailData?.departureTime ?? ''),
                                    location: selectedPickup.isNotEmpty ? selectedPickup : (_detailData?.from ?? 'Pickup'),
                                    type: 'start',
                                  ),
                                  isFirst: true,
                                  isLast: false,
                                ),
                                _buildTimelineRow(
                                  stop: RouteTimelineStop(
                                    time: _detailData?.arrivalTime ?? '',
                                    location: selectedDestination.isNotEmpty ? selectedDestination : (_detailData?.to ?? 'Destination'),
                                    type: 'destination',
                                  ),
                                  isFirst: false,
                                  isLast: true,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Ride Amenities & Driver Preferences Card
                        _buildPreferencesSection(driver.preferences, driverAmenities: driver.amenities),

// Doorstep/detour checkbox completely removed

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Bottom Next Full-Width Button
                Builder(
                  builder: (context) {
                    final isDoorToDoorRide = driver.rideType == 'door_to_door' ||
                        driver.isWholeCarOnly ||
                        _session.driver.rideType == 'door_to_door' ||
                        _session.driver.isWholeCarOnly;
                    final seatPrice = driver.pricePerSeat > 0 ? driver.pricePerSeat : _session.driver.pricePerSeat;
                    final wholeCarSeats = driver.totalSeats > 0 ? driver.totalSeats : 4;
                    final rawWholeCarPrice = driver.wholeCarPrice > 0 ? driver.wholeCarPrice : _session.driver.wholeCarPrice;
                    final wholeCarFare = (rawWholeCarPrice > (seatPrice * 1.5))
                        ? rawWholeCarPrice
                        : (seatPrice * wholeCarSeats);
                    final baseSeatsFare = isDoorToDoorRide ? wholeCarFare : (seatPrice * (_session.seatsCount > 0 ? _session.seatsCount : 1));
                    final finalTotal = isDoorToDoorRide ? wholeCarFare : baseSeatsFare;

                    return Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 3 Action Buttons: Contact Driver | Message Driver | Share Ride
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    final phone = driver.phone.trim();
                                    if (phone.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Driver phone number is not available yet.')),
                                      );
                                      return;
                                    }
                                    final uri = Uri(scheme: 'tel', path: phone);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBackground,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text(
                                            'Contact Driver',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RideChatScreen(
                                          bookingId: _session.bookingId,
                                          driverName: driver.name.isNotEmpty ? driver.name : 'Driver',
                                          vehicleInfo: driver.carModel,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text(
                                            'Message Driver',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Share link copied! Ready to share this ride.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.share_outlined, size: 14, color: AppColors.textPrimary),
                                          SizedBox(width: 4),
                                          Text(
                                            'Share Ride',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            text: 'Continue',
                            onPressed: () {
                              final effectivePickup = _session.boardingPoint.isNotEmpty
                                  ? _session.boardingPoint
                                  : (_session.pickup.isNotEmpty ? _session.pickup : driver.pickupPoint);
                              final effectiveDrop = _session.destination.isNotEmpty
                                  ? _session.destination
                                  : driver.destinationPoint;

                              final nextSession = _session.copyWith(
                                driver: driver,
                                boardingPoint: effectivePickup,
                                pickup: effectivePickup,
                                destination: effectiveDrop,
                                isDoorstepPickup: isDoorToDoorRide,
                                seatsCount: isDoorToDoorRide ? wholeCarSeats : _session.seatsCount,
                                totalAmount: finalTotal,
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SelectBoardingPointScreen105(
                                    session: nextSession,
                                    driver: driver,
                                    initialFare: finalTotal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverAboutModal(BuildContext context, RideDriver driver) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFF3EDF7),
                          backgroundImage: _getAvatarProvider(driver.avatarImage),
                          child: driver.avatarImage.isEmpty
                              ? const Icon(Icons.person, color: AppColors.primary, size: 26)
                              : null,
                        ),
                        if (driver.isVerifiedByAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Image.asset(
                              'assets/images/codicon_verified-filled.png',
                              width: 16,
                              height: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name.isNotEmpty ? driver.name : 'Driver',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Zaatra Driver',
                                style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'About Driver',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  driver.about.isNotEmpty
                      ? driver.about
                      : 'Verified commercial driver on Zaatra platform with extensive driving experience and high safety ratings.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                if (driver.phone.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        driver.phone,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isLocationMatch(String stopLoc, String targetLoc) {
    if (stopLoc.trim().isEmpty || targetLoc.trim().isEmpty) return false;
    final cleanStop = stopLoc.toLowerCase().trim();
    final cleanTarget = targetLoc.toLowerCase().trim();
    if (cleanStop == cleanTarget) return true;

    final tokenStop = cleanStop.split(RegExp(r'[, -]')).first.trim();
    final tokenTarget = cleanTarget.split(RegExp(r'[, -]')).first.trim();
    if (tokenStop.isNotEmpty && tokenTarget.isNotEmpty && tokenStop == tokenTarget) return true;

    return cleanStop.contains(cleanTarget) || cleanTarget.contains(cleanStop);
  }

  Widget _buildTimelineRow({
    required RouteTimelineStop stop,
    required bool isFirst,
    required bool isLast,
  }) {
    const double slot = 18.0;
    const Color greyLine = Color(0xFFE0E0E0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time column right-aligned next to car / circle dot
          SizedBox(
            width: 64,
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                height: slot,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    stop.time,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Vertical Timeline Marker Column (little red car on start, grey dot on stops)
          SizedBox(
            width: 22,
            child: Column(
              children: [
                SizedBox(
                  height: slot,
                  child: Center(
                    child: isFirst
                        ? Image.asset(
                            RouteTimelineTile.carAsset,
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          )
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: greyLine,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  SizedBox(
                    height: stop.landmark.isNotEmpty ? 42 : 28,
                    child: Image.asset(
                      'assets/images/Line 50.png',
                      width: 2,
                      height: double.infinity,
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => Container(
                        width: 2,
                        color: greyLine,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Station Name + Landmark + Pick N Avatar Pill
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: slot),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              stop.location,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        if (stop.landmark.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            stop.landmark,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (stop.pickCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5DDF6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stop.passengerLabel.isNotEmpty
                                ? stop.passengerLabel
                                : 'Pick ${stop.pickCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          for (int i = 0; i < stop.pickCount; i++) ...[
                            if (i > 0) const SizedBox(width: 3),
                            const CircleAvatar(
                              radius: 9,
                              backgroundColor: Color(0xFFF3EDF7),
                              child: Icon(
                                Icons.person_rounded,
                                size: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color iconColor, Color bgColor, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }
    return content;
  }

  Widget _buildPreferencesSection(RidePreferences prefs, {List<String>? driverAmenities}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Ride Amenities & Policies',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Booking Approval Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: prefs.autoApproval ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: prefs.autoApproval ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  prefs.autoApproval ? Icons.bolt_rounded : Icons.hourglass_top_rounded,
                  color: prefs.autoApproval ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prefs.autoApprovalBadge.isNotEmpty
                            ? prefs.autoApprovalBadge
                            : (prefs.autoApproval ? 'Instant Confirmation' : 'Driver Approval Required'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: prefs.autoApproval ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prefs.autoApproval
                            ? 'Your booking is immediately confirmed upon requesting.'
                            : 'Driver will review and accept your booking request.',
                        style: TextStyle(
                          fontSize: 11,
                          color: prefs.autoApproval ? const Color(0xFF388E3C) : const Color(0xFFBF360C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Luggage Allowance Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.luggage_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Luggage Allowance',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prefs.luggageSummaryText.isNotEmpty
                            ? prefs.luggageSummaryText
                            : 'Max ${prefs.luggageCount} Large Bag and ${prefs.mediumBagCount} Medium Bag per passenger',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Amenities Grid / Chips (API 5 projection: featuresList)
          const Text(
            'Included Amenities',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          Builder(
            builder: (context) {
              final activeFeatures = <String>[];
              if (prefs.featuresList.isNotEmpty) {
                activeFeatures.addAll(prefs.featuresList);
              } else {
                if (prefs.ac) activeFeatures.add('AC');
                if (prefs.usbCharging) activeFeatures.add('USB Charging');
                if (prefs.wifi) activeFeatures.add('Free WiFi');
                activeFeatures.addAll(prefs.rideFeatures);
              }
              if (driverAmenities != null && driverAmenities.isNotEmpty) {
                for (final am in driverAmenities) {
                  if (!activeFeatures.any((f) => f.toLowerCase().trim() == am.toLowerCase().trim())) {
                    activeFeatures.add(am);
                  }
                }
              }

              if (activeFeatures.isEmpty) {
                return const Text('Standard vehicle features included', style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in activeFeatures)
                    _buildAmenityChip(
                      f.toLowerCase().contains('wifi')
                          ? Icons.wifi_rounded
                          : (f.toLowerCase().contains('usb') || f.toLowerCase().contains('charg')
                              ? Icons.power_rounded
                              : (f.toLowerCase().contains('ac') || f.toLowerCase().contains('air condition') || f.toLowerCase().contains('climate')
                                  ? Icons.ac_unit_rounded
                                  : (f.toLowerCase().contains('music') || f.toLowerCase().contains('audio') || f.toLowerCase().contains('sound')
                                      ? Icons.music_note_rounded
                                      : (f.toLowerCase().contains('sunroof')
                                          ? Icons.wb_sunny_outlined
                                          : (f.toLowerCase().contains('snack') || f.toLowerCase().contains('refresh') || f.toLowerCase().contains('food') || f.toLowerCase().contains('water')
                                              ? Icons.fastfood_outlined
                                              : (f.toLowerCase().contains('child') || f.toLowerCase().contains('booster')
                                                  ? Icons.child_care_rounded
                                                  : (f.toLowerCase().contains('legroom') || f.toLowerCase().contains('comfort')
                                                      ? Icons.airline_seat_legroom_extra_rounded
                                                      : Icons.check_circle_rounded))))))),
                      f,
                      true,
                    ),
                ],
              );
            },
          ),

          // Customer Rules & Guidelines
          if (prefs.customerPreferences.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Customer Rules & Guidelines',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pref in prefs.customerPreferences)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: pref.toLowerCase().contains('smoking allowed')
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: pref.toLowerCase().contains('smoking allowed')
                            ? const Color(0xFFFFCC80)
                            : const Color(0xFFFFE082),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pref.toLowerCase().contains('no smoking')
                              ? Icons.smoke_free_rounded
                              : (pref.toLowerCase().contains('smoking')
                                  ? Icons.smoking_rooms_rounded
                                  : (pref.toLowerCase().contains('pet')
                                      ? Icons.pets_rounded
                                      : (pref.toLowerCase().contains('quiet')
                                          ? Icons.volume_off_rounded
                                          : (pref.toLowerCase().contains('chat')
                                              ? Icons.chat_bubble_outline_rounded
                                              : (pref.toLowerCase().contains('luggage') || pref.toLowerCase().contains('bag')
                                                  ? Icons.luggage_outlined
                                                  : Icons.rule_rounded))))),
                          size: 14,
                          color: pref.toLowerCase().contains('smoking allowed')
                              ? const Color(0xFFE65100)
                              : const Color(0xFFF57F17),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pref,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pref.toLowerCase().contains('smoking allowed')
                                ? const Color(0xFFBF360C)
                                : const Color(0xFF4E342E),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          if (prefs.driverPreferences.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Driver Rules & Preferences',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pref in prefs.driverPreferences)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          pref,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAvailable ? const Color(0xFFA5D6A7) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAvailable ? const Color(0xFF1B5E20) : const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoorstepPickupSection(RideDriver driver) {
    final isDoorToDoorRide = driver.rideType == 'door_to_door' ||
        driver.isWholeCarOnly ||
        _session.driver.rideType == 'door_to_door' ||
        _session.driver.isWholeCarOnly;
    final wholeCarSeats = driver.totalSeats > 0 ? driver.totalSeats : 4;
    final seatPrice = driver.pricePerSeat > 0 ? driver.pricePerSeat : _session.driver.pricePerSeat;
    final rawWholeCarPrice = driver.wholeCarPrice > 0 ? driver.wholeCarPrice : _session.driver.wholeCarPrice;
    final wholeCarFare = (rawWholeCarPrice > (seatPrice * 1.5))
        ? rawWholeCarPrice
        : (seatPrice * wholeCarSeats);

    return Container(
      decoration: BoxDecoration(
        color: _isDoorstepSelected ? const Color(0xFFF7F5FE) : const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDoorstepSelected ? AppColors.primary : const Color(0xFFE2E0EC),
          width: _isDoorstepSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Checkbox row
          InkWell(
            onTap: () {
              setState(() {
                _isDoorstepSelected = !_isDoorstepSelected;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Checkbox(
                    value: _isDoorstepSelected,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        _isDoorstepSelected = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Door to Door (Book Whole Car)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Private Ride',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Book all $wholeCarSeats seats privately along the driver\'s scheduled route. No other passengers will join.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Whole car details card (shown when selected)
          if (_isDoorstepSelected) ...[
            const Divider(height: 1, color: Color(0xFFE6E4F0)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E0EC)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDoorToDoorRide
                              ? 'Whole Car Flat Price (${wholeCarSeats} seats)'
                              : 'Whole Car Price (${seatPrice.toInt()})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '₹${wholeCarFare.toInt()}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ride Type',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Private / Not Shared',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Route Stops',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Expanded(
                          child: Text(
                            '${driver.pickupPoint.split(',').first} → ${driver.destinationPoint.split(',').first}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFEEEEEE)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Whole Car Fare',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '₹${wholeCarFare.toInt()}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}