import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/api_service.dart';
import '../../../../services/ride_service.dart';
import 'driver_booking_detail_screen_104.dart';

class TripPreparationDriversScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final String date;
  final String time;
  final String passengers;
  final String paidForSeat;
  final String luggage;
  final bool isDoorstepEnabled;
  final String? doorstepPickup;
  final String? doorstepDrop;

  const TripPreparationDriversScreen({
    super.key,
    this.pickup = '',
    this.destination = '',
    this.date = '',
    this.time = '',
    this.passengers = '',
    this.paidForSeat = '',
    this.luggage = '',
    this.isDoorstepEnabled = false,
    this.doorstepPickup,
    this.doorstepDrop,
  });

  @override
  State<TripPreparationDriversScreen> createState() => _TripPreparationDriversScreenState();
}

class _TripPreparationDriversScreenState extends State<TripPreparationDriversScreen> {
  List<RideDriver> _allDrivers = [];
  List<RideDriver> _drivers = [];
  final Set<String> _favoriteDriverIds = {};
  bool _isLoading = false;
  String _selectedSort = 'price'; // 'price' | 'departure_time'
  bool _filterDoorToDoor = false;
  bool _filterSharedRide = false;

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  /// Incremented per request so a slow earlier response cannot overwrite a newer one.
  int _fetchSeq = 0;

  Future<void> _fetchRides() async {
    setState(() => _isLoading = true);
    final seq = ++_fetchSeq;
    final count = int.tryParse(widget.passengers.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final filterBy = _filterDoorToDoor
        ? 'door_to_door'
        : (_filterSharedRide ? 'shared_ride' : null);

    Map<String, dynamic> res;
    try {
      res = await RideService.searchRides(
        pickupLocation: widget.pickup,
        destination: widget.destination,
        date: widget.date,
        passengers: count,
        filterBy: filterBy,
        rideType: filterBy,
        sortBy: _selectedSort == 'price' ? 'price_asc' : 'departure_asc',
        acceptDoorToDoor: _filterDoorToDoor ? true : (_filterSharedRide ? false : null),
      );
    } catch (_) {
      res = {'success': false, 'message': 'Could not load rides. Please check your connection and try again.'};
    }

    if (mounted && seq == _fetchSeq) {
      if (res['success'] == false && res['data'] is! List && res['rides'] is! List) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Could not load rides. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      final rawList = (res['data'] is List)
          ? res['data'] as List
          : ((res['rides'] is List) ? res['rides'] as List : []);

      if (rawList.isNotEmpty) {
        if (rawList.first is RideDriver) {
          _allDrivers = List<RideDriver>.from(rawList);
        } else {
          _allDrivers = rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => RideDriver.fromJson(item))
              .toList();
        }
      } else {
        _allDrivers = [];
      }

      _isLoading = false;
      _applySortAndFilter();
    }
  }

  void _applySortAndFilter() {
    List<RideDriver> list = List.from(_allDrivers);

    // Sort: Price (lowest first) vs Departure Time (earliest first)
    if (_selectedSort == 'price') {
      list.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
    } else if (_selectedSort == 'departure_time') {
      list.sort((a, b) => _parseTimeToMinutes(a.departureTime).compareTo(_parseTimeToMinutes(b.departureTime)));
    }

    setState(() {
      _drivers = list;
    });
  }

  int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 999999;
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final timeParts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      if (timeParts.isNotEmpty) {
        int hour = int.tryParse(timeParts[0]) ?? 0;
        int min = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        return hour * 60 + min;
      }
    } catch (_) {}
    return 999999;
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trip Preparation',
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route Info Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.pickup.isNotEmpty ? widget.pickup : 'Pickup',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.destination.isNotEmpty ? widget.destination : 'Destination',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.time.isNotEmpty ? " - ${widget.time}" : ""}'.trim(),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sort / Filter / Map Chips Row
                        Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: _buildChip(
                                Icons.swap_vert_rounded,
                                _selectedSort == 'price' ? 'Sort: Price' : 'Sort: Time',
                                onTap: _showSortBottomSheet,
                                isSelected: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 8,
                              child: _buildChip(
                                Icons.filter_list_rounded,
                                _filterDoorToDoor
                                    ? 'Door-to-door'
                                    : (_filterSharedRide ? 'Shared ride' : 'Filter'),
                                onTap: _showFilterBottomSheet,
                                isSelected: _filterDoorToDoor || _filterSharedRide,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: _buildChip(
                                Icons.map_outlined,
                                'Map',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Map view coming soon')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available drivers',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            if (widget.date.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.date,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Driver Cards List
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        else if (_drivers.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9FB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined, size: 50, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No drivers available',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'There are no active drivers scheduled for this route and date. Please try different dates or search again.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _drivers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final driver = _drivers[index];

                              final isDoorToDoor = driver.rideType == 'door_to_door' || driver.isWholeCarOnly;
                              final count = int.tryParse(widget.passengers.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                              final effectiveSeats = isDoorToDoor ? (driver.totalSeats > 0 ? driver.totalSeats : 4) : (count > 0 ? count : 1);
                              final seatsFare = isDoorToDoor
                                  ? (driver.wholeCarPrice > 0 ? driver.wholeCarPrice : driver.pricePerSeat)
                                  : (driver.pricePerSeat * effectiveSeats);

                              final priceLabel = isDoorToDoor
                                  ? (driver.wholeCarPrice > 0
                                      ? 'Cost Per Ride ₹ ${driver.wholeCarPrice.toStringAsFixed(0)}'
                                      : (driver.pricePerSeat > 0
                                          ? 'Cost Per Ride ₹ ${driver.pricePerSeat.toStringAsFixed(0)}'
                                          : 'Cost Per Ride'))
                                  : 'Cost Per Seat ₹ ${driver.pricePerSeat.toStringAsFixed(0)}';

                              void navigateToDetails() {
                                final session = RideBookingSession(
                                  driver: driver,
                                  pickup: widget.pickup,
                                  destination: widget.destination,
                                  date: widget.date,
                                  time: widget.time,
                                  seatsCount: effectiveSeats,
                                  totalAmount: seatsFare,
                                  luggage: widget.luggage,
                                  isDoorstepPickup: isDoorToDoor,
                                  detourCharge: 0.0,
                                  detourDistanceKm: 0.0,
                                  perKmDetourRate: driver.detourRatePerKm,
                                  customerPickupAddress: widget.pickup,
                                  customerDropAddress: widget.destination,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverBookingDetailScreen(session: session),
                                  ),
                                );
                              }

                              final summaryParts = <String>[];
                              if (driver.carModel.isNotEmpty) summaryParts.add(driver.carModel);
                              if (driver.tripsText.isNotEmpty) {
                                summaryParts.add(driver.tripsText);
                              } else if (driver.reviewCount > 0) {
                                summaryParts.add('${driver.reviewCount} trips');
                              }
                              if (driver.vehicleNumber.isNotEmpty) summaryParts.add(driver.vehicleNumber);
                              final vehicleSummaryText = summaryParts.join(', ');

                              final originPoint = driver.pickupPoint.isNotEmpty ? driver.pickupPoint : (widget.pickup.isNotEmpty ? widget.pickup : 'Pickup');
                              final destPoint = driver.destinationPoint.isNotEmpty ? driver.destinationPoint : (widget.destination.isNotEmpty ? widget.destination : 'Destination');
                              final originTime = driver.departureTime.isNotEmpty ? driver.departureTime : widget.time;
                              final originSubText = '${widget.date.isNotEmpty ? "${widget.date}, " : ""}$originTime'.trim();

                              return Container(
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
                                    // Top Row: Avatar + Info + Action Icons
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                final avatarProvider = _getAvatarProvider(driver.avatarImage);
                                                return CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor: const Color(0xFFF3EDF7),
                                                  backgroundImage: avatarProvider,
                                                  onBackgroundImageError: avatarProvider != null ? (_, __) {} : null,
                                                  child: avatarProvider == null
                                                      ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                                                      : null,
                                                );
                                              },
                                            ),
                                            if (driver.isVerifiedByAdmin)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Image.asset(
                                                  'assets/images/Vector.png',
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (vehicleSummaryText.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Text(
                                                  vehicleSummaryText,
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                              if (driver.rating > 0) ...[
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFF4EC),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.star_rounded, color: Color(0xFFFF7A00), size: 14),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${driver.rating}',
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Share and Favorite Action Icons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF6750A4)),
                                              padding: const EdgeInsets.all(6),
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Feature coming soon'),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            IconButton(
                                              icon: Icon(
                                                _favoriteDriverIds.contains(driver.id) ? Icons.favorite : Icons.favorite_border,
                                                size: 22,
                                                color: const Color(0xFF6750A4),
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  if (_favoriteDriverIds.contains(driver.id)) {
                                                    _favoriteDriverIds.remove(driver.id);
                                                  } else {
                                                    _favoriteDriverIds.add(driver.id);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),

                                      ],
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                    const SizedBox(height: 14),

                                    // Timeline Row: Origin -> Destination
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Origin
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      originPoint,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (originSubText.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  originSubText,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Dotted Arrow Line
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(width: 24, height: 1.5, color: const Color(0xFFCCCCCC)),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCCCCCC)),
                                            ],
                                          ),
                                        ),
                                        // Destination
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF2E7D32),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      destPoint,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (widget.date.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  widget.date,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

                                    // Dynamic seat indicator & Instant Approval Badge (Protected against overflow)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: isDoorToDoor
                                              ? Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFE8F5E9),
                                                        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Icon(Icons.event_seat_rounded, size: 15, color: Color(0xFF2E7D32)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        '${driver.seatsAvailable > 0 ? driver.seatsAvailable : (driver.totalSeats > 0 ? driver.totalSeats : 4)} seats available',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF2E7D32),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Builder(
                                                  builder: (context) {
                                                    final total = driver.totalSeats > 0 ? driver.totalSeats : 4;
                                                    final avail = driver.seatsAvailable.clamp(0, total);
                                                    final booked = (total - avail).clamp(0, total);

                                                    final seatBoxes = <Widget>[];
                                                    // Booked seats: Gray box with person icon
                                                    for (int i = 0; i < booked; i++) {
                                                      seatBoxes.add(
                                                        Container(
                                                          width: 28,
                                                          height: 28,
                                                          margin: const EdgeInsets.only(right: 5),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF1F3F5),
                                                            borderRadius: BorderRadius.circular(7),
                                                            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(Icons.person, size: 16, color: Color(0xFF757575)),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    // Available seats: Green outlined box with green person icon
                                                    for (int i = 0; i < avail; i++) {
                                                      seatBoxes.add(
                                                        Container(
                                                          width: 28,
                                                          height: 28,
                                                          margin: const EdgeInsets.only(right: 5),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFE8F5E9),
                                                            borderRadius: BorderRadius.circular(7),
                                                            border: Border.all(color: const Color(0xFF4CAF50), width: 1.2),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(Icons.person_outline, size: 16, color: Color(0xFF2E7D32)),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    return SingleChildScrollView(
                                                      scrollDirection: Axis.horizontal,
                                                      physics: const BouncingScrollPhysics(),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: seatBoxes,
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: driver.preferences.autoApproval
                                                ? const Color(0xFFE8F5E9)
                                                : const Color(0xFFFFF8E1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: driver.preferences.autoApproval
                                                  ? const Color(0xFF81C784)
                                                  : const Color(0xFFFFD54F),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                driver.preferences.autoApproval
                                                    ? Icons.bolt_rounded
                                                    : Icons.hourglass_top_rounded,
                                                size: 13,
                                                color: driver.preferences.autoApproval
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFFF57F17),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                driver.preferences.autoApproval
                                                    ? 'Instant'
                                                    : 'Approval req.',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: driver.preferences.autoApproval
                                                      ? const Color(0xFF2E7D32)
                                                      : const Color(0xFFF57F17),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),



                                    const SizedBox(height: 16),

                                    // View Details Action Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: navigateToDetails,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: const Text(
                                          'View Details',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ),

                                    // Intermediate Route Note (if stops exist)
                                    if (driver.viaLocations.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '$originPoint to $destPoint via ${driver.viaLocations.join(", ")}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE7F6) : const Color(0xFFF3EDF7),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    const SizedBox(height: 18),
                    const Text(
                      'Sort by',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    _buildSortOption(
                      title: 'Price',
                      subtitle: 'Lowest fare first',
                      icon: Icons.currency_rupee_rounded,
                      isSelected: _selectedSort == 'price',
                      onTap: () {
                        setState(() {
                          _selectedSort = 'price';
                          _applySortAndFilter();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildSortOption(
                      title: 'Departure time',
                      subtitle: 'Earliest departure first',
                      icon: Icons.access_time_rounded,
                      isSelected: _selectedSort == 'departure_time',
                      onTap: () {
                        setState(() {
                          _selectedSort = 'departure_time';
                          _applySortAndFilter();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3EDF7) : const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: AppColors.primary,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    bool tempDoorToDoor = _filterDoorToDoor;
    bool tempSharedRide = _filterSharedRide;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter by',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        if (tempDoorToDoor || tempSharedRide)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempDoorToDoor = false;
                                tempSharedRide = false;
                              });
                            },
                            child: const Text('Reset', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFilterOption(
                      title: 'Door-to-door',
                      subtitle: 'Direct pickup & dropoff at your exact location',
                      icon: Icons.door_front_door_outlined,
                      isChecked: tempDoorToDoor,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            tempDoorToDoor = true;
                            tempSharedRide = false;
                          } else {
                            tempDoorToDoor = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFilterOption(
                      title: 'Shared ride',
                      subtitle: 'Affordable carpool with other verified passengers',
                      icon: Icons.group_outlined,
                      isChecked: tempSharedRide,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            tempSharedRide = true;
                            tempDoorToDoor = false;
                          } else {
                            tempSharedRide = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterDoorToDoor = tempDoorToDoor;
                            _filterSharedRide = tempSharedRide;
                          });
                          Navigator.pop(context);
                          _fetchRides();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFFF3EDF7) : const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isChecked ? AppColors.primary : const Color(0xFFEEEEEE),
            width: isChecked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isChecked ? AppColors.primary.withValues(alpha: 0.12) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: isChecked ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isChecked ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isChecked ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
                color: isChecked ? AppColors.primary : Colors.transparent,
              ),
              child: isChecked
                  ? const Center(
                      child: Icon(Icons.circle, size: 10, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') || lower.contains('air condition') || lower.contains('climate')) return Icons.ac_unit_rounded;
    if (lower.contains('usb') || lower.contains('charg') || lower.contains('power')) return Icons.power_rounded;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('music') || lower.contains('audio') || lower.contains('spotify') || lower.contains('sound')) return Icons.music_note_rounded;
    if (lower.contains('sunroof') || lower.contains('moonroof')) return Icons.wb_sunny_outlined;
    if (lower.contains('snack') || lower.contains('refresh') || lower.contains('food') || lower.contains('water') || lower.contains('drink')) return Icons.fastfood_outlined;
    if (lower.contains('child') || lower.contains('booster') || lower.contains('baby')) return Icons.child_care_rounded;
    if (lower.contains('legroom') || lower.contains('comfort') || lower.contains('seat')) return Icons.airline_seat_legroom_extra_rounded;
    return Icons.check_circle_outline_rounded;
  }

  IconData _getCustomerPrefIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('no smoking') || lower.contains('smoke-free')) return Icons.smoke_free_rounded;
    if (lower.contains('smoking')) return Icons.smoking_rooms_rounded;
    if (lower.contains('pet') || lower.contains('dog') || lower.contains('cat')) return Icons.pets_rounded;
    if (lower.contains('quiet') || lower.contains('silence')) return Icons.volume_off_rounded;
    if (lower.contains('chat') || lower.contains('talk')) return Icons.chat_bubble_outline_rounded;
    if (lower.contains('luggage') || lower.contains('bag')) return Icons.luggage_outlined;
    return Icons.rule_rounded;
  }

  IconData _getDriverRuleIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('instant') || lower.contains('auto approval')) return Icons.bolt_rounded;
    if (lower.contains('verif')) return Icons.verified_user_rounded;
    if (lower.contains('women') || lower.contains('ladies') || lower.contains('female')) return Icons.female_rounded;
    if (lower.contains('back') || lower.contains('max') || lower.contains('passenger')) return Icons.group_outlined;
    return Icons.info_outline_rounded;
  }

  Widget _buildCardPill(
    IconData icon,
    String label, {
    Color bgColor = const Color(0xFFF5F5F7),
    Color borderColor = const Color(0xFFE0E0E0),
    Color iconColor = AppColors.textSecondary,
    Color textColor = AppColors.textPrimary,
  }) {
    String cleanLabel = label.trim();
    if (cleanLabel.startsWith('{')) {
      if (cleanLabel.contains('label:')) {
        final match = RegExp(r'label:\s*([^,}]+)').firstMatch(cleanLabel);
        if (match != null && match.group(1) != null) {
          cleanLabel = match.group(1)!.trim();
        }
      } else if (cleanLabel.contains('"label":')) {
        final match = RegExp(r'"label":\s*"([^"]+)"').firstMatch(cleanLabel);
        if (match != null && match.group(1) != null) {
          cleanLabel = match.group(1)!.trim();
        }
      }
    }

    if (cleanLabel.isEmpty || cleanLabel.startsWith('{')) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              cleanLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}