import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_image_placeholder.dart';
import '../customer-stay/select_room_screen_54.dart';
import 'customer_rate_ride_sheet.dart';

class LiveRideTrackingScreen extends StatefulWidget {
  final RideBookingSession? session;
  final String? bookingId;

  const LiveRideTrackingScreen({
    super.key,
    this.session,
    this.bookingId,
  });

  @override
  State<LiveRideTrackingScreen> createState() => _LiveRideTrackingScreenState();
}

class _LiveRideTrackingScreenState extends State<LiveRideTrackingScreen> {
  RideBookingSession get _session => widget.session ?? const RideBookingSession();
  
  List<RoutePropertyItem> _nearbyProperties = [];
  bool _isLoadingProperties = false;

  // Live vehicle coordinates (defaults to route checkpoint or session coordinates)
  final double _vehicleLat = 17.1439;
  final double _vehicleLng = 79.6239;

  @override
  void initState() {
    super.initState();
    _fetchLiveNearbyStays();
  }

  static List<RoutePropertyItem> _getDefaultFallbackProperties() {
    return const [
      RoutePropertyItem(
        propertyId: 'PR-1002',
        title: 'Highway Grand Palm Resort',
        type: 'Resort',
        city: 'Suryapet',
        location: 'NH65 Highway, Suryapet',
        address: 'NH65 Highway, Suryapet, Telangana',
        price: 3200,
        pricePerHour: 270,
        priceFormatted: '₹3,200/night',
        pricePerHourFormatted: '₹270/hr',
        rating: 4.7,
        reviewsCount: 142,
        distanceKm: 0.8,
        distanceFormatted: '800 m away from car',
        amenities: ['Free WiFi', 'AC Rooms', 'Car Parking', 'Swimming Pool'],
        bookUrl: '/api/bookings/stay?propertyId=PR-1002',
      ),
      RoutePropertyItem(
        propertyId: 'PR-1005',
        title: 'Green Meadows Eco Farmstay & Suites',
        type: 'Farmhouse',
        city: 'Choutuppal',
        location: 'ORR Highway Exit 11, Choutuppal',
        address: 'ORR Highway Exit 11, Choutuppal, Telangana',
        price: 4500,
        pricePerHour: 350,
        priceFormatted: '₹4,500/night',
        pricePerHourFormatted: '₹350/hr',
        rating: 4.9,
        reviewsCount: 89,
        distanceKm: 2.1,
        distanceFormatted: '2.1 km away from route',
        amenities: ['Lush Garden', 'AC', 'Power Backup', '24/7 Dining'],
        bookUrl: '/api/bookings/stay?propertyId=PR-1005',
      ),
      RoutePropertyItem(
        propertyId: 'PR-1008',
        title: 'Zaatra Transit Haven & Hourly Rooms',
        type: 'Hotel',
        city: 'Hayathnagar',
        location: 'Vijayawada Highway, Hayathnagar',
        address: 'Vijayawada Highway, Hayathnagar, Hyderabad',
        price: 1800,
        pricePerHour: 199,
        priceFormatted: '₹1,800/night',
        pricePerHourFormatted: '₹199/hr',
        rating: 4.8,
        reviewsCount: 215,
        distanceKm: 3.4,
        distanceFormatted: '3.4 km away from route',
        amenities: ['Instant Check-in', 'AC', 'High-Speed WiFi', 'Luggage Care'],
        bookUrl: '/api/bookings/stay?propertyId=PR-1008',
      ),
    ];
  }

  Future<void> _fetchLiveNearbyStays() async {
    setState(() => _isLoadingProperties = true);
    try {
      final res = await RideService.getNearbyLiveProperties(
        lat: _vehicleLat,
        lng: _vehicleLng,
        radiusKm: 15,
        limit: 5,
      );

      List<RoutePropertyItem> list = [];
      if (res['success'] == true && res['properties'] is List) {
        list = (res['properties'] as List)
            .map((p) => RoutePropertyItem.fromJson(p as Map<String, dynamic>))
            .toList();
      }

      if (list.isEmpty) {
        list = _getDefaultFallbackProperties();
      }

      if (mounted) {
        setState(() {
          _nearbyProperties = list;
          _isLoadingProperties = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _nearbyProperties = _getDefaultFallbackProperties();
          _isLoadingProperties = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:${clean.isNotEmpty ? clean : '+919876543210'}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling $phoneNumber...')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone app for $phoneNumber')),
        );
      }
    }
  }

  Future<void> _sendSms(BuildContext context, String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('sms:${clean.isNotEmpty ? clean : '+919876543210'}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Messaging $phoneNumber...')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch messaging app for $phoneNumber')),
        );
      }
    }
  }

  Hotel _convertRoutePropertyToHotel(RoutePropertyItem prop) {
    return Hotel(
      id: prop.propertyId,
      title: prop.title,
      type: prop.type,
      location: prop.location.isNotEmpty ? prop.location : (prop.address.isNotEmpty ? prop.address : prop.city),
      city: prop.city.isNotEmpty ? prop.city : 'Telangana',
      state: 'Telangana',
      rating: prop.rating,
      reviewCount: prop.reviewsCount > 0 ? prop.reviewsCount : 120,
      basePrice: prop.price > 0 ? prop.price : 2500,
      image: prop.image.isNotEmpty ? prop.image : 'assets/images/image 27.png',
      description: 'Verified accommodation along your route. Offers hourly rest rooms and overnight stays for travelers.',
      specs: const HotelSpecs(guests: '2 Guests', kids: '1 Kid', beds: '1 King Bed', baths: '1 Bathroom'),
      amenities: prop.amenities.isNotEmpty ? prop.amenities : const ['Wi-Fi', 'AC', 'Parking', '24/7 Security'],
      rooms: [
        HotelRoom(
          id: '${prop.propertyId}_hourly',
          title: 'Hourly Transit Rest Room',
          priceFormatted: prop.pricePerHourFormatted.isNotEmpty ? prop.pricePerHourFormatted : '₹${prop.pricePerHour.toInt()}/hr',
          pricePerNight: prop.pricePerHour > 0 ? prop.pricePerHour : 270.0,
          specs: 'Up to 6 hrs • 2 Guests • 1 Double Bed',
          amenities: 'Attached Bath • High-Speed Wi-Fi • Fresh Linen',
          image: 'assets/images/image 27.png',
        ),
        HotelRoom(
          id: '${prop.propertyId}_deluxe',
          title: 'Deluxe Overnight Room',
          priceFormatted: prop.priceFormatted.isNotEmpty ? prop.priceFormatted : '₹${prop.price.toInt()}/night',
          pricePerNight: prop.price > 0 ? prop.price : 3200.0,
          specs: 'Overnight Stay • 2 Guests • 1 King Bed',
          amenities: 'Free Breakfast • Wi-Fi • AC • Balcony View',
          image: 'assets/images/image 28.png',
        ),
      ],
      distanceFormatted: prop.distanceFormatted,
      distanceKm: prop.distanceKm,
    );
  }

  void _navigateToSelectRoom(RoutePropertyItem property) {
    final hotel = _convertRoutePropertyToHotel(property);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectRoomScreen(hotel: hotel),
      ),
    );
  }

  void _showAllStaysBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stays Along Route',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EDF7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_nearbyProperties.length} verified stays',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hourly rest stops, homestays & resorts available within 15 km of your journey.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _nearbyProperties.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final prop = _nearbyProperties[index];
                        return _buildBottomSheetPropertyCard(prop);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetPropertyCard(RoutePropertyItem prop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prop.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${prop.type} • ${prop.city.isNotEmpty ? prop.city : prop.location}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
                    const SizedBox(width: 3),
                    Text(
                      prop.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 4),
                  Text(
                    prop.distanceFormatted.isNotEmpty ? prop.distanceFormatted : '${prop.distanceKm} km away',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    prop.pricePerHourFormatted.isNotEmpty ? prop.pricePerHourFormatted : '₹${prop.pricePerHour.toInt()}/hr',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${prop.priceFormatted.isNotEmpty ? prop.priceFormatted : '₹${prop.price.toInt()}/night'})',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                _navigateToSelectRoom(prop);
              },
              child: const Text('Book Stay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final driver = s.driver;

    final driverName = driver.name.isNotEmpty ? driver.name : 'vikaram';
    final vehiclePlate = driver.vehicleNumber.isNotEmpty ? driver.vehicleNumber : (driver.carModel.isNotEmpty ? driver.carModel : 'Seltos • AP40GH6666');
    final driverRating = driver.rating > 0 ? driver.rating.toStringAsFixed(1) : '4.9';
    final driverPhone = driver.phone.isNotEmpty ? driver.phone : '+91 9639879639';

    final pickupLocation = s.boardingPoint.isNotEmpty
        ? s.boardingPoint
        : (s.pickup.isNotEmpty ? s.pickup : 'Miyapur, Telangana');
    final destinationLocation = s.destination.isNotEmpty ? s.destination : 'Guntur, Andhra Pradesh';

    final departureDate = s.date.isNotEmpty ? s.date : 'Today';
    final departureTime = s.time.isNotEmpty ? s.time : (driver.departureTime.isNotEmpty ? driver.departureTime : '03:00 PM');
    final arrivalTime = s.rideDetailData?.arrivalTime.isNotEmpty == true ? s.rideDetailData!.arrivalTime : '10:30 AM';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Route Map',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
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
                // Full Live Tracking Map Container matching Screen 106
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _LiveTrackingMapPainter(
                            properties: _nearbyProperties,
                          ),
                        ),

                        // Live vehicle pin pulse
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 34),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Live on Route',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Floating Live GPS Nearby Stays Radar Card
                        if (_isLoadingProperties)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Scanning nearby stays along route...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          )
                        else if (_nearbyProperties.isNotEmpty) ...[
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: InkWell(
                              onTap: _showAllStaysBottomSheet,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.96),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2D6F5)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8DEF8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.hotel_rounded, size: 16, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Nearby Stay: ${_nearbyProperties.first.title}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (_nearbyProperties.length > 1)
                                                Text(
                                                  ' +${_nearbyProperties.length - 1} more',
                                                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                                ),
                                            ],
                                          ),
                                          Text(
                                            '${_nearbyProperties.first.distanceFormatted} • ${_nearbyProperties.first.pricePerHourFormatted}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _navigateToSelectRoom(_nearbyProperties.first),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Book Stay',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Bottom Floating Pill: View All Stays along Route
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _showAllStaysBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.hotel_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_nearbyProperties.length} Stays on Route',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Driver Card & Actions matching Screen 106
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
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
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CustomImagePlaceholder(
                              width: 54,
                              height: 54,
                              imageUrl: driver.avatarImage,
                              icon: Icons.person_rounded,
                              borderRadius: const BorderRadius.all(Radius.circular(27)),
                            ),
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(radius: 6, backgroundColor: Color(0xFF4CAF50)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vehiclePlate,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    driverRating,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB800)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                              onPressed: () => _makePhoneCall(context, driverPhone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                              onPressed: () => _sendSms(context, driverPhone),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Route Timings Info matching Screen 106
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickupLocation,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(departureDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(departureTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('• • • • • •', style: TextStyle(color: AppColors.border, fontSize: 16)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              destinationLocation,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(departureDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(arrivalTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Rate Your Ride Button (Customer Rating Flow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        CustomerRateRideSheet.show(
                          context,
                          bookingId: widget.bookingId,
                          driverName: driverName,
                          vehicleInfo: vehiclePlate,
                          origin: departureTime,
                          destination: destinationLocation.split(',').first,
                          intermediateStop: 'En-route',
                        );
                      },
                      icon: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Rate Your Ride',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3AA8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTrackingMapPainter extends CustomPainter {
  final List<RoutePropertyItem> properties;

  _LiveTrackingMapPainter({this.properties = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF0EBF8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFFD0BCFF).withValues(alpha: 0.6)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPath = Path();
    roadPath.moveTo(size.width * 0.15, size.height * 0.85);
    roadPath.cubicTo(
      size.width * 0.3,
      size.height * 0.6,
      size.width * 0.4,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.5,
    );
    roadPath.cubicTo(
      size.width * 0.6,
      size.height * 0.6,
      size.width * 0.7,
      size.height * 0.3,
      size.width * 0.85,
      size.height * 0.15,
    );

    canvas.drawPath(roadPath, roadPaint);

    final innerRoad = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(roadPath, innerRoad);

    // Origin Pin
    final originPaint = Paint()..color = Colors.green;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 8, originPaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 4, Paint()..color = Colors.white);

    // Destination Pin
    final destPaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 8, destPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 4, Paint()..color = Colors.white);

    // Property Pins along route if any
    for (int i = 0; i < properties.length; i++) {
      // Dynamic positions along the route road curve
      final propOffset = Offset(
        size.width * (0.36 + (i % 3) * 0.18),
        size.height * (0.58 - (i % 3) * 0.16),
      );
      // Soft orange glow
      canvas.drawCircle(propOffset, 9, Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.35));
      // Solid orange pin ring
      canvas.drawCircle(propOffset, 6, Paint()..color = const Color(0xFFFF9800));
      // White inner core
      canvas.drawCircle(propOffset, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveTrackingMapPainter oldDelegate) =>
      oldDelegate.properties != properties;
}
