import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/intermediate_pickup_model.dart';
import '../../../../models/place_location_model.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/location_autocomplete_picker_modal.dart';
import '../../../widgets/route_map_webview.dart';
import 'driver_route_preview_screen_32.dart';

/// Redesigned Intermediate Pickup & Drop Screen.
/// Features:
/// 1. Pickup & Destination summary card (green & red pin indicator).
/// 2. Interactive Route Map Preview (`RouteMapWebView`).
/// 3. Corridor Validation: Validates whether added stops fall on the main highway corridor
///    and alerts the driver if a point requires an unrealistic detour (e.g., Bengaluru for a Miyapur ➔ Vijayawada ride).
/// 4. Price Display & Customization: Shows calculated proportional fare per seat (e.g. ₹ 400)
///    with tap-to-edit capability for each stop.
/// 5. "Route Plan" vertical timeline with departure, intermediate stop ETAs + fares, and destination.
/// 6. Sticky "Next" button forwarding to DriverRoutePreviewScreen.
class DriverIntermediatePickupsScreen extends StatefulWidget {
  final String? rideId;
  final LocationPoint? pickup;
  final LocationPoint? destination;
  final RouteResult? route;
  final String? date;
  final DateTime? selectedDateTime;
  final String? time;
  final String? seats;
  final String? fare;
  final String? luggage;
  final double? basePricePerKm;
  final double? pricePerSeat;
  final bool? offerDoorstepPickupDrop;
  final double? detourRadiusKm;
  final double? detourRatePerKm;

  const DriverIntermediatePickupsScreen({
    super.key,
    this.rideId,
    this.pickup,
    this.destination,
    this.route,
    this.date,
    this.selectedDateTime,
    this.time,
    this.seats,
    this.fare,
    this.luggage,
    this.basePricePerKm,
    this.pricePerSeat,
    this.offerDoorstepPickupDrop,
    this.detourRadiusKm,
    this.detourRatePerKm,
  });

  @override
  State<DriverIntermediatePickupsScreen> createState() =>
      _DriverIntermediatePickupsScreenState();
}

class _SelectablePickupPoint {
  final String name;
  String? landmark;
  String? pincode;
  LocationPoint? locationPoint;
  bool isSelected;
  double? price;
  String? etaTime;
  bool isOffCorridor;

  _SelectablePickupPoint({
    required this.name,
    this.landmark,
    this.pincode,
    this.locationPoint,
    this.isSelected = true,
    this.price,
    this.etaTime,
    this.isOffCorridor = false,
  });
}

class _RoutePlanItem {
  final String time;
  final String location;
  final double? price;
  final bool isStart;
  final bool isEnd;
  final _SelectablePickupPoint? pointRef;

  const _RoutePlanItem({
    required this.time,
    required this.location,
    this.price,
    this.isStart = false,
    this.isEnd = false,
    this.pointRef,
  });
}

class _DriverIntermediatePickupsScreenState
    extends State<DriverIntermediatePickupsScreen> {
  // Starts empty: the driver adds their desired pickup points explicitly
  final List<_SelectablePickupPoint> _pickupPoints = [];

  // ── Corridor Validation ─────────────────────────────────────────────────────
  /// Checks whether a selected stop point lies reasonably within the main travel
  /// corridor between pickup and destination using geodesic distance bounds.
  bool _isPointOnCorridor(LocationPoint stop) {
    if (widget.pickup == null || widget.destination == null) return true;

    final oLat = widget.pickup!.latitude;
    final oLng = widget.pickup!.longitude;
    final dLat = widget.destination!.latitude;
    final dLng = widget.destination!.longitude;
    final sLat = stop.latitude;
    final sLng = stop.longitude;

    // If coordinates are missing (e.g. manual fallback entry), permit through
    if (oLat == 0.0 || dLat == 0.0 || sLat == 0.0) return true;

    // 1. Direct distance between Origin and Destination
    final directDistMeters = Geolocator.distanceBetween(oLat, oLng, dLat, dLng);
    // 2. Distance from Origin to Stop
    final originToStopMeters = Geolocator.distanceBetween(oLat, oLng, sLat, sLng);
    // 3. Distance from Stop to Destination
    final stopToDestMeters = Geolocator.distanceBetween(sLat, sLng, dLat, dLng);

    final totalViaStop = originToStopMeters + stopToDestMeters;

    // Allowable detour: up to 35% of direct route distance, capped between 25km and 65km
    final maxAllowedDetourMeters = (directDistMeters * 0.35).clamp(25000.0, 65000.0);

    return totalViaStop <= (directDistMeters + maxAllowedDetourMeters);
  }


  // ── Off-Corridor Warning Dialog ─────────────────────────────────────────────
  Future<bool> _showOffCorridorDialog(LocationPoint stop) async {
    final originName = widget.pickup?.name ?? 'Pickup';
    final destName = widget.destination?.name ?? 'Destination';

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Off Main Corridor',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${stop.name}" does not fall on the travel corridor between $originName and $destName.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Adding this point would require a major detour in the opposite or divergent direction. Please pick a town or stop along your highway route.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel & Pick Another',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Add Anyway',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Add Pickup Point Handler ────────────────────────────────────────────────
  
  // ── Calculate Intermediate Fares from Backend API (POST /api/rides/calculate-intermediate-fares) ──
  Future<void> _fetchIntermediateFaresFromApi() async {
    final activePoints = _pickupPoints.where((p) => p.isSelected).toList();
    if (activePoints.isEmpty) return;

    final fromText = widget.pickup?.formattedAddress.isNotEmpty == true
        ? widget.pickup!.formattedAddress
        : (widget.pickup?.name ?? widget.route?.startAddress ?? '');
    final toText = widget.destination?.formattedAddress.isNotEmpty == true
        ? widget.destination!.formattedAddress
        : (widget.destination?.name ?? widget.route?.endAddress ?? '');
    final depTime = widget.time ?? '07:00 PM';
    final rateKm = widget.basePricePerKm ?? 10.0;
    final seatCount = int.tryParse((widget.seats ?? '3').replaceAll(RegExp(r'[^0-9]'), '')) ?? 3;
    final totalFare = widget.pricePerSeat ??
        double.tryParse(widget.fare?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ??
        0.0;

    final stopsPayload = activePoints.map((p) {
      final loc = p.locationPoint?.formattedAddress.isNotEmpty == true
          ? p.locationPoint!.formattedAddress
          : p.name;
      return {
        'location': loc,
        'name': p.name,
        'latitude': p.locationPoint?.latitude ?? 0.0,
        'longitude': p.locationPoint?.longitude ?? 0.0,
        'time': p.etaTime ?? '',
      };
    }).toList();

    try {
      final res = await RideService.calculateIntermediateFares(
        pickupLocation: fromText,
        destinationLocation: toText,
        departureTime: depTime,
        ratePerKm: rateKm,
        seats: seatCount,
        price: totalFare > 0 ? totalFare : null,
        intermediatePickups: stopsPayload,
      );

      if (mounted && res['success'] == true) {
        final faresList = RideService.extractIntermediateFares(res);
        if (faresList.isNotEmpty) {
          setState(() {
            for (int i = 0; i < activePoints.length; i++) {
              final pt = activePoints[i];
              Map<String, dynamic>? match;
              final foundIdx = faresList.indexWhere((f) {
                final loc = (f['location'] ?? f['name'] ?? f['address'] ?? '').toString().trim().toLowerCase();
                final pName = pt.name.trim().toLowerCase();
                return loc.contains(pName) || pName.contains(loc);
              });
              if (foundIdx >= 0) {
                match = faresList[foundIdx];
              } else if (i < faresList.length) {
                match = faresList[i];
              }

              if (match != null) {
                final rawP = match['price'] ??
                    match['suggestedPrice'] ??
                    match['priceToDestination'] ??
                    match['fare'];
                if (rawP != null) {
                  final parsed = double.tryParse(rawP.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
                  if (parsed != null && parsed > 0) {
                    pt.price = parsed;
                  }
                }

                // Bind time/ETA, landmark, and pincode returned by backend
                final timeVal = match['time'] ?? match['calculatedTime'];
                if (timeVal != null && timeVal.toString().isNotEmpty) {
                  pt.etaTime = timeVal.toString();
                }
                if (match['landmark'] != null && match['landmark'].toString().isNotEmpty) {
                  pt.landmark = match['landmark'].toString();
                }
                if (match['pincode'] != null && match['pincode'].toString().isNotEmpty) {
                  pt.pincode = match['pincode'].toString();
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error calculating intermediate fares: $e');
    }
  }

  Future<void> _onAddPickupPoint() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Add Pickup Point',
      hintText: 'Search city, area, or landmark along route...',
    );

    if (picked == null || !mounted) return;

    // Validate whether the point falls on the main corridor via Backend 2.4.0
    final totalFare = widget.pricePerSeat ??
        double.tryParse(widget.fare?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ??
        0.0;

    bool isOnCorridor = true;
    double? calculatedFare;
    bool isDetour = false;

    if (widget.pickup != null && widget.destination != null) {
      final res = await RideService.validateCorridorStop(
        rideId: widget.rideId ?? 'ride_preview',
        origin: widget.pickup!,
        destination: widget.destination!,
        stop: picked,
        fullRideFare: totalFare,
      );
      if (res['success'] == true && res['data'] != null) {
        final val = CorridorValidationResult.fromJson(res);
        isOnCorridor = val.isOnCorridor;
        if (val.driverCustomFare != null && val.driverCustomFare! > 0) {
          calculatedFare = val.driverCustomFare;
        } else if (val.recommendedFarePerSeat > 0) {
          calculatedFare = val.recommendedFarePerSeat;
        }
      }
    } else {
      isOnCorridor = _isPointOnCorridor(picked);
    }

    bool shouldAdd = true;

    if (!isOnCorridor) {
      final override = await _showOffCorridorDialog(picked);
      if (!override) return;
      shouldAdd = true;
      isDetour = true;
    }

    if (shouldAdd && mounted) {

      setState(() {
        final existingIndex = _pickupPoints.indexWhere((p) =>
            p.name.trim().toLowerCase() == picked.name.trim().toLowerCase());
        if (existingIndex < 0) {
          _pickupPoints.add(
            _SelectablePickupPoint(
              name: picked.name,
              locationPoint: picked,
              isSelected: true,
              price: calculatedFare,
              isOffCorridor: isDetour,
            ),
          );
        } else {
          _pickupPoints[existingIndex].isSelected = true;
          _pickupPoints[existingIndex].isOffCorridor = isDetour;
        }
      });
      await _fetchIntermediateFaresFromApi();
    }
  }

  // ── Edit Stop Price Modal ───────────────────────────────────────────────────
  void _editStopPrice(_SelectablePickupPoint point) {
    final controller = TextEditingController(
      text: point.price != null && point.price! > 0 ? point.price!.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Set Fare for ${point.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the price per passenger seat for this intermediate stop:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                labelText: 'Fare per seat',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newP = double.tryParse(controller.text.trim());
              if (newP != null && newP > 0) {
                setState(() {
                  point.price = newP;
                });
                final rId = widget.rideId ?? '';
                if (rId.isNotEmpty) {
                  final idx = _pickupPoints.indexOf(point);
                  RideService.updateStopPrice(
                    rideId: rId,
                    stopIndex: idx >= 0 ? idx : 0,
                    price: newP,
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Fare', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Route Plan Calculation ──────────────────────────────────────────────────
  List<_RoutePlanItem> _buildRoutePlan() {
    final items = <_RoutePlanItem>[];

    // 1. Departure Start Point
    final startTimeStr = (widget.time != null && widget.time!.isNotEmpty)
        ? widget.time!
        : '9 : 00';
    final pickupName = widget.pickup?.name.isNotEmpty == true
        ? widget.pickup!.name
        : (widget.route?.startAddress.isNotEmpty == true
            ? widget.route!.startAddress
            : 'Madhapur');

    items.add(
      _RoutePlanItem(
        time: startTimeStr,
        location: pickupName,
        isStart: true,
      ),
    );

    // 2. Active Added Intermediate Stops
    final activeStops = _pickupPoints.where((p) => p.isSelected).toList();

    // Parse start time to calculate realistic progression
    int startHour = 9;
    int startMinute = 0;
    try {
      final clean = startTimeStr.replaceAll(RegExp(r'\s+'), ' ').trim();
      final parts = clean.split(' ');
      final timeParts = parts[0].split(':');
      startHour = int.parse(timeParts[0]);
      startMinute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && startHour < 12) {
        startHour += 12;
      }
    } catch (_) {}

    // Total estimated duration in minutes
    final durSec = widget.route?.durationSeconds ?? (4 * 3600 + 30 * 60);
    final totalMinutes = durSec ~/ 60;
    final int stepCount = activeStops.length + 1;
    final int intervalMinutes = (totalMinutes / stepCount).round().clamp(15, 180);

    int currentTotalMinutes = startHour * 60 + startMinute;

    for (int i = 0; i < activeStops.length; i++) {
      final stop = activeStops[i];
      String formattedTime;
      if (stop.etaTime != null && stop.etaTime!.isNotEmpty && stop.etaTime != '-- : --') {
        formattedTime = stop.etaTime!;
      } else {
        currentTotalMinutes += intervalMinutes;
        final stopH = (currentTotalMinutes ~/ 60) % 24;
        final stopM = currentTotalMinutes % 60;
        formattedTime =
            '${stopH.toString().padLeft(2, '0')} : ${stopM.toString().padLeft(2, '0')}';
        stop.etaTime = formattedTime;
      }

      items.add(
        _RoutePlanItem(
          time: formattedTime,
          location: stop.name,
          price: stop.price,
          pointRef: stop,
        ),
      );
    }

    // 3. Destination Final Point
    final finalArrivalMinutes = (startHour * 60 + startMinute) + totalMinutes;
    final finalH = (finalArrivalMinutes ~/ 60) % 24;
    final finalM = finalArrivalMinutes % 60;
    final destTimeStr =
        '${finalH.toString().padLeft(2, '0')} : ${finalM.toString().padLeft(2, '0')}';

    final destName = widget.destination?.name.isNotEmpty == true
        ? widget.destination!.name
        : (widget.route?.endAddress.isNotEmpty == true
            ? widget.route!.endAddress
            : 'Destination');

    final totalFare = widget.pricePerSeat ??
        double.tryParse(widget.fare?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ??
        0.0;

    items.add(
      _RoutePlanItem(
        time: destTimeStr,
        location: destName,
        price: totalFare,
        isEnd: true,
      ),
    );

    return items;
  }

  // ── Next Button Handler ─────────────────────────────────────────────────────
  void _handleNext() {
    final activeStops = _pickupPoints.where((p) => p.isSelected).toList();

    final intermediateList = activeStops.map((p) {
      final priceVal = p.price != null && p.price! > 0
          ? p.price!.toStringAsFixed(0)
          : '';

      return IntermediatePickupModel(
        location: p.name,
        pinCode: p.pincode ?? '',
        landmark: p.landmark ?? '',
        time: (p.etaTime != null && p.etaTime!.isNotEmpty) ? p.etaTime! : (widget.time ?? ''),
        price: priceVal,
        locationPoint: p.locationPoint,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRoutePreviewScreen(
          pickup: widget.pickup,
          destination: widget.destination,
          route: widget.route,
          date: widget.date,
          selectedDateTime: widget.selectedDateTime,
          time: widget.time,
          seats: widget.seats,
          fare: widget.fare,
          luggage: widget.luggage,
          preference: 'Standard Ride',
          basePricePerKm: widget.basePricePerKm,
          pricePerSeat: widget.pricePerSeat,
          offerDoorstepPickupDrop: widget.offerDoorstepPickupDrop,
          detourRadiusKm: widget.detourRadiusKm,
          detourRatePerKm: widget.detourRatePerKm,
          intermediatePickups: intermediateList,
        ),
      ),
    );
  }

  // ── Build UI ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pickupDisplayName = widget.pickup?.formattedAddress.isNotEmpty == true
        ? widget.pickup!.formattedAddress
        : (widget.pickup?.name.isNotEmpty == true
            ? widget.pickup!.name
            : 'Pickup Location');

    final destDisplayName = widget.destination?.formattedAddress.isNotEmpty == true
        ? widget.destination!.formattedAddress
        : (widget.destination?.name.isNotEmpty == true
            ? widget.destination!.name
            : 'Destination Location');

    final routePlan = _buildRoutePlan();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post Ride',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Pickup & Destination Summary Card ────────────────────
                    _buildPickupDestinationCard(pickupDisplayName, destDisplayName),

                    const SizedBox(height: 18),

                    // ── 2. Route Map Preview ────────────────────────────────────
                    _buildMapPreview(),

                    const SizedBox(height: 22),

                    // ── 3. Pickup Points Header & Options ───────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pickup points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_pickupPoints.isNotEmpty)
                          Text(
                            '${_pickupPoints.length} stop${_pickupPoints.length > 1 ? 's' : ''} added',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // When no stops are added yet: show clean prompt to add
                    if (_pickupPoints.isEmpty)
                      _buildEmptyPickupPrompt()
                    else ...[
                      // List of driver-added stops with price badge and remove controls
                      ..._pickupPoints.map((point) => _buildAddedPickupCard(point)),
                      const SizedBox(height: 8),
                      // Button to add more stops
                      _buildAddAnotherPointButton(),
                    ],

                    const SizedBox(height: 24),

                    // ── 4. Route Plan Timeline ──────────────────────────────────
                    const Text(
                      'Route Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildRoutePlanTimeline(routePlan),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── 5. Sticky Bottom Action Button ────────────────────────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Widget Builders ─────────────────────────────────────────────────────────

  /// 30x30 pin icon: exported Figma PNG, with a drawn fallback if missing.
  Widget _buildLocationIcon({
    required String asset,
    required IconData fallbackIcon,
    required Color color,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(fallbackIcon, color: color, size: 18),
        ),
      ),
    );
  }

  // Figma 88246851: two stacked white cards (68px, radius 10, shadow
  // 0 0 4 #EDE8FF, no gap); icon 30x30, label 12 #A1A1A1, address 12 black.
  Widget _buildLocationCard({
    required String label,
    required String address,
    required Widget icon,
  }) {
    return Container(
      width: double.infinity,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0xFFEDE8FF), blurRadius: 4)],
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 19),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1A1)),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDestinationCard(String pickupText, String destText) {
    return Column(
      children: [
        _buildLocationCard(
          label: 'Pickup location',
          address: pickupText,
          icon: _buildLocationIcon(
            asset:
                'assets/images/ChatGPT_Image_Aug_4__2026__11_34_09_AM-removebg-preview 1.png',
            fallbackIcon: Icons.my_location_rounded,
            color: const Color(0xFF4CAF50),
          ),
        ),
        _buildLocationCard(
          label: 'Destination',
          address: destText,
          icon: _buildLocationIcon(
            asset: 'assets/images/image 23.png',
            fallbackIcon: Icons.flag_rounded,
            color: const Color(0xFFE53935),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: RouteMapWebView(
          pickup: widget.pickup?.name ?? 'Pickup',
          destination: widget.destination?.name ?? 'Destination',
          pickupPoint: widget.pickup,
          destPoint: widget.destination,
          candidateRoutes: widget.route?.candidateRoutes ?? const [],
          height: 190,
          borderRadius: 16,
          interactive: true,
          selectedRouteIndex: 0,
        ),
      ),
    );
  }

  Widget _buildEmptyPickupPrompt() {
    return InkWell(
      onTap: _onAddPickupPoint,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_location_alt_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+ Add Pickup Point',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Search stops along the highway corridor (e.g. Suryapet, Kodad)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedPickupCard(_SelectablePickupPoint point) {
    final fareDisplay = point.price != null && point.price! > 0
        ? '₹ ' + point.price!.toStringAsFixed(0)
        : '₹ --';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: point.isOffCorridor ? Colors.orange.shade300 : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: point.isOffCorridor ? const Color(0xFFFFF3E0) : const Color(0xFFF3EDF7),
            ),
            child: Center(
              child: Icon(
                Icons.location_on_rounded,
                size: 18,
                color: point.isOffCorridor ? Colors.orange : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        point.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (point.isOffCorridor)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: const Text(
                          'Detour',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Estimated stop time: ${point.etaTime ?? "-- : --"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Price Badge & Edit Action ─────────────────────────────────────
          InkWell(
            onTap: () => _editStopPrice(point),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fareDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                    ],
                  ),
                  const Text(
                    'per seat',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 4),

          // ── Remove Button ─────────────────────────────────────────────────
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: Color(0xFFE53935),
            ),
            tooltip: 'Remove stop',
            onPressed: () {
              setState(() {
                _pickupPoints.remove(point);
              });
              _fetchIntermediateFaresFromApi();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddAnotherPointButton() {
    return InkWell(
      onTap: _onAddPickupPoint,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              '+ Add Another Pickup Point',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Figma 88246851 route plan: 12px grey (#D9D9D9) stop dots joined by a 1px
  // line, car glyph (20x17) on the first stop. The marker column has a fixed
  // width and the line is drawn inside it, so the line always runs through
  // the centre of every marker.
  static const Color _timelineGrey = Color(0xFFD9D9D9);
  static const double _timelineMarkerY = 10;

  Widget _buildRoutePlanTimeline(List<_RoutePlanItem> items) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time column
                SizedBox(
                  width: 64,
                  child: Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Marker column with the connector line inside it
                SizedBox(
                  width: 20,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: isFirst ? _timelineMarkerY : 0,
                        bottom: isLast ? null : 0,
                        height: isLast ? _timelineMarkerY : null,
                        child: Container(width: 1, color: _timelineGrey),
                      ),
                      Positioned(
                        top: item.isStart ? 1 : _timelineMarkerY - 6,
                        child: item.isStart
                            ? Container(
                                width: 20,
                                height: 17,
                                color: Colors.white,
                                child: Image.asset(
                                  'assets/images/glyphs-poly_car-wash.png',
                                  width: 20,
                                  height: 17,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.directions_car_filled_rounded,
                                    size: 17,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: _timelineGrey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Location name & price badge
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (item.price != null && item.price! > 0 && !item.isStart)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDFC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹ ${item.price!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: CustomButton(
        text: 'Next',
        onPressed: _handleNext,
      ),
    );
  }
}