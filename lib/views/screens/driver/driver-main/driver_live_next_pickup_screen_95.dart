import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../../services/trip_card_share.dart';
import '../../../widgets/route_timeline_tile.dart';
import 'driver_live_ride_id_screen_96.dart';

class DriverLiveNextPickupScreen extends StatefulWidget {
  final String? rideId;
  final String? statusBadge;
  final List<Map<String, dynamic>>? routeTimeline;
  final List<Map<String, dynamic>>? seatsAvailable;
  final String? fuelContribution;
  final String? driverName;
  final String? driverCode;
  final String? bookingSeatZaatraId;
  final Map<String, dynamic>? nextPickup;
  final String? nextPickupLocation;
  final Map<String, dynamic>? tripData;

  const DriverLiveNextPickupScreen({
    super.key,
    this.rideId,
    this.statusBadge,
    this.routeTimeline,
    this.seatsAvailable,
    this.fuelContribution,
    this.driverName,
    this.driverCode,
    this.bookingSeatZaatraId,
    this.nextPickup,
    this.nextPickupLocation,
    this.tripData,
  });

  @override
  State<DriverLiveNextPickupScreen> createState() => _DriverLiveNextPickupScreenState();
}

class _DriverLiveNextPickupScreenState extends State<DriverLiveNextPickupScreen> {
  late String _badge;
  late String _fuel;
  late String _driver;
  late String _code;
  late String _bookingId;
  late String _pickupLoc;
  late List<Map<String, dynamic>> _timeline;
  late List<Map<String, dynamic>> _seats;
  Map<String, dynamic>? _data;
  String _vehicleModel = '';
  String _vehiclePlate = '';
  String _driverRating = '';
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _data = widget.tripData ?? {};
    _badge = widget.statusBadge ?? _data?['statusBadge'] ?? 'On Trip';
    
    final rawFuel = widget.fuelContribution ??
        _data?['tripDetails']?['fuelContributionFormatted'] ??
        _data?['fuelContribution'] ??
        _data?['fuelSaved'] ??
        _data?['price'];
    if (rawFuel != null && rawFuel.toString().isNotEmpty) {
      final s = rawFuel.toString();
      _fuel = s.startsWith('₹') ? s : '₹$s';
    } else {
      _fuel = '';
    }

    _driver = widget.driverName ??
        _data?['tripDetails']?['driverName'] ??
        _data?['driverName'] ??
        'Driver';
    _code = widget.driverCode ??
        _data?['tripDetails']?['driverCode'] ??
        _data?['driverCode'] ??
        _data?['driver']?['driverCode'] ??
        _data?['code'] ??
        '';
    _bookingId = widget.bookingSeatZaatraId ?? _data?['tripDetails']?['bookingSeatZaatraId'] ?? (widget.rideId ?? '');
    _pickupLoc = widget.nextPickupLocation ??
        widget.nextPickup?['location'] ??
        _data?['nextPickup']?['location'] ??
        '';

    _timeline = widget.routeTimeline ??
        (_data?['routeTimeline'] is List
            ? List<Map<String, dynamic>>.from(_data!['routeTimeline'])
            : _buildDynamicTimeline(_data));

    // Real seats only: nothing is shown (or shared) when the ride gave none.
    _seats = widget.seatsAvailable ??
        (_data?['seatsAvailable'] is List
            ? List<Map<String, dynamic>>.from(_data!['seatsAvailable'])
            : <Map<String, dynamic>>[]);

    _loadDriverProfile();
    _loadNextPickup();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('currentUserName') ??
          prefs.getString('fullName') ??
          prefs.getString('driver_name') ??
          '';
      final model = prefs.getString('driver_vehicle_model') ?? prefs.getString('vehicleModel') ?? '';
      final plate = prefs.getString('driver_vehicle_number') ?? prefs.getString('vehicleNumber') ?? '';
      final rating = prefs.getString('driver_rating') ?? '';
      if (!mounted) return;
      setState(() {
        if (savedName.isNotEmpty && (widget.driverName == null || widget.driverName!.isEmpty) && _driver == 'Driver') {
          _driver = savedName;
        }
        _vehicleModel = model;
        _vehiclePlate = plate;
        _driverRating = rating;
      });
    } catch (_) {}
  }

  List<Map<String, dynamic>> _buildDynamicTimeline(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return <Map<String, dynamic>>[];
    final origin = (data['pickupLocation'] ?? data['origin'] ?? data['pickup'] ?? '').toString();
    final dest = (data['destination'] ?? data['dropLocation'] ?? data['drop'] ?? '').toString();
    final startTime = (data['time'] ?? data['departureTime'] ?? '').toString();
    if (origin.isEmpty && dest.isEmpty) return <Map<String, dynamic>>[];

    final list = <Map<String, dynamic>>[];
    if (origin.isNotEmpty) {
      list.add({
        'time': startTime.isNotEmpty ? startTime.split(' ')[0] : '',
        'location': origin,
        'isStart': true,
      });
    }
    final rawStops = data['stops'] ?? data['intermediatePickups'];
    if (rawStops is List && rawStops.isNotEmpty) {
      for (final s in rawStops) {
        final sName = s is Map ? (s['name'] ?? s['location'] ?? '') : s.toString();
        final sTime = s is Map ? (s['time'] ?? s['expectedArrival'] ?? '') : '';
        if (sName.toString().isEmpty) continue;
        list.add({
          'time': sTime.toString().isNotEmpty ? sTime.toString().split(' ')[0] : '',
          'location': sName.toString(),
          'isStart': false,
        });
      }
    }
    if (dest.isNotEmpty) {
      list.add({
        'time': (data['arrivalTime'] ?? '').toString(),
        'location': dest,
        'isStart': false,
      });
    }
    return list;
  }

  Future<void> _loadNextPickup() async {
    try {
      final rId = widget.rideId ?? '';
      if (rId.isNotEmpty) {
        final liveRes = await RideService.getLiveRideStatus(rId);
        if (liveRes['success'] == true && liveRes['data'] != null && mounted) {
          final live = LiveRideStatusResult.fromJson(liveRes);
          final pendingStop = live.stops.firstWhere(
            (s) => s.status == 'PENDING' || s.status == 'ARRIVED',
            orElse: () => live.stops.isNotEmpty ? live.stops.last : LiveRideStop(),
          );

          setState(() {
            if (pendingStop.name.isNotEmpty) {
              _pickupLoc = pendingStop.name;
            }
            if (live.tripStatus.isNotEmpty) {
              _badge = live.tripStatus == 'IN_PROGRESS'
                  ? 'On Trip'
                  : (live.tripStatus == 'SCHEDULED' ? 'Seats Open' : live.tripStatus);
            }
            if (live.stops.isNotEmpty) {
              _timeline = live.stops.map((s) => {
                'time': s.expectedArrival,
                'location': s.name,
                'isStart': s.type == 'ORIGIN',
              }).toList();
            }
          });
          return;
        }
      }

      if (widget.nextPickupLocation != null && widget.nextPickupLocation!.isNotEmpty) {
        return;
      }
      final res = await RideService.getNextPickupDetails();
      if (res['success'] == true && mounted) {
        final np = res['nextPickup'];
        if (np != null && np['location'] != null) {
          setState(() {
            _pickupLoc = np['location'];
          });
        }
      }
    } catch (_) {}
  }

  /// Shares the same purple "Trip Shared" card as the Trip Shared screens.
  Future<void> _shareTripCard() async {
    if (_isSharing) return;
    _isSharing = true;

    final vehicleLine =
        [_vehicleModel, _vehiclePlate].where((e) => e.trim().isNotEmpty).join(' · ');
    final status = TripCardShare.statusForStage('during_ride');
    final data = TripCardShare.buildData(
      driverName: _driver,
      vehicleLine: vehicleLine,
      rating: _driverRating,
      timeline: _timeline,
      seats: _seats,
      estimatedArrival: (_data?['arrivalTime'] ?? '').toString(),
      statusLabel: status.label,
      statusColor: status.color,
    );
    final url = TripCardShare.urlFor(widget.rideId);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Preparing trip card image...'),
        duration: Duration(milliseconds: 1200),
      ),
    );

    Map<String, dynamic> res;
    try {
      res = await TripCardShare.captureAndShare(
        context,
        data: data,
        text: TripCardShare.buildText(data, url),
        fallbackUrl: url,
      );
    } finally {
      _isSharing = false;
    }

    if (!mounted) return;
    if (res['success'] != true || res['isWeb'] == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['isWeb'] == true
              ? 'Sharing the trip card is not supported in the browser.'
              : (res['message']?.toString() ?? 'Could not share the trip card.')),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Live',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: _shareTripCard,
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Header Pill "Seats Open" matching 95.png
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _badge,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Waypoint Timeline matching 95.png
                  ..._timelineSection(),

                  const SizedBox(height: 24),

                  if (_seats.isNotEmpty) ...[
                  // Seats Available Section matching 95.png
                  const Text(
                    'Seats Available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_seats.length, (i) {
                        final seat = _seats[i];
                        final label = seat['label'] ?? seat['seatNumber'] ?? 'S-${i + 1}';
                        final isBooked = seat['isBooked'] == true || seat['status'] == 'booked' || seat['status'] == 'boarding';
                        return _buildSeatBox(label, isBooked: isBooked);
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ],

                  if (_fuel.isNotEmpty) ...[
                    _buildInfoRow(Icons.local_gas_station_outlined, 'Fuel Contribution $_fuel'),
                    const SizedBox(height: 16),
                  ],
                  if (_driverInfoText.isNotEmpty) _buildInfoRow(Icons.directions_car_outlined, _driverInfoText),

                  const SizedBox(height: 28),

                  if (_pickupLoc.isNotEmpty) ...[
                  // Dynamic Next Pickup Banner Section matching 95.png
                  const Text(
                    'Next Pickup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverLiveRideIdScreen(
                            rideId: widget.rideId ?? '',
                            routeTimeline: _timeline,
                            seatsAvailable: _seats,
                            tripData: _data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFFE65100), size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Next Pick up available : $_pickupLoc',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _driverInfoText {
    final name = _driver == 'Driver' ? '' : _driver;
    final parts = <String>[
      if (name.isNotEmpty) name,
      if (_code.trim().isNotEmpty) 'driver code $_code',
    ];
    return parts.join(' - ');
  }

  /// Route rows from real stops only; a short note when the route is unknown.
  List<Widget> _timelineSection() {
    final stops = _timeline
        .where((e) => (e['location'] ?? e['station'] ?? '').toString().trim().isNotEmpty)
        .toList();
    if (stops.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Route details are not available yet.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ];
    }
    return [
      for (var i = 0; i < stops.length; i++)
        _buildWaypointTile(
          time: (stops[i]['time'] ?? '').toString(),
          station: (stops[i]['location'] ?? stops[i]['station']).toString(),
          isStart: i == 0,
          isLast: i == stops.length - 1,
        ),
    ];
  }

  Widget _buildWaypointTile({
    required String time,
    required String station,
    required bool isStart,
    required bool isLast,
  }) {
    return RouteTimelineTile(time: time, station: station, isStart: isStart, isLast: isLast);
  }

  Widget _buildSeatBox(String label, {required bool isBooked}) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isBooked ? const Color(0xFFE8DEF8) : const Color(0xFFC4D5C5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              isBooked ? Icons.person_rounded : Icons.check_box_outline_blank_rounded,
              color: isBooked ? AppColors.primary : Colors.transparent,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFF3EDF7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}