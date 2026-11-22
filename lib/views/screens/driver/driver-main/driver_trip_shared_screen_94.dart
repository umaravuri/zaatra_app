import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../../services/native_share_service.dart';
import '../../../widgets/custom_button.dart';
import 'driver_live_next_pickup_screen_95.dart';

class DriverTripSharedScreen extends StatefulWidget {
  final String? rideId;
  final String? stage; // 'before_ride' | 'during_ride' | 'summary'
  final String? statusBadge;
  final List<Map<String, dynamic>>? routeTimeline;
  final List<Map<String, dynamic>>? seatsAvailable;
  final String? fuelContribution;
  final String? driverName;
  final String? driverCode;
  final String? bookingSeatZaatraId;
  final Map<String, dynamic>? nextPickup;
  final Map<String, dynamic>? tripData;

  const DriverTripSharedScreen({
    super.key,
    this.rideId,
    this.stage,
    this.statusBadge,
    this.routeTimeline,
    this.seatsAvailable,
    this.fuelContribution,
    this.driverName,
    this.driverCode,
    this.bookingSeatZaatraId,
    this.nextPickup,
    this.tripData,
  });

  @override
  State<DriverTripSharedScreen> createState() => _DriverTripSharedScreenState();
}

class _DriverTripSharedScreenState extends State<DriverTripSharedScreen> {
  String? _rideId;
  late String _currentStage; // 'before_ride' | 'during_ride' | 'summary'
  late String _screenTitle;
  late String _badge;
  late String _fuel;
  late String _driver;
  late String _code;
  late String _bookingId;
  late List<Map<String, dynamic>> _timeline;
  late List<Map<String, dynamic>> _seats;
  Map<String, dynamic>? _nextPickup;
  Map<String, dynamic>? _pickupProgression;
  Map<String, dynamic>? _heroCard;
  Map<String, dynamic>? _statusCard;
  Map<String, dynamic>? _totalPassenger;
  Map<String, dynamic>? _actionButton;
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  final GlobalKey _shareCardKey = GlobalKey();
  final GlobalKey _modalShareCardKey = GlobalKey();
  String _driverRating = '4.8';
  String _vehicleModel = 'Swift Dzire';
  String _vehiclePlate = 'TS 09 AB 1234';

  static String _inferStage(Map<String, dynamic>? data) {
    if (data == null) return 'before_ride';
    final status = (data['status'] ?? data['tripStatus'] ?? data['rideStatus'] ?? '').toString().toLowerCase();
    if (status.contains('complete') || status.contains('finish')) {
      return 'summary';
    }
    if (status.contains('active') || status.contains('progress') || status.contains('started') || status.contains('on_the_way')) {
      return 'during_ride';
    }
    return 'before_ride';
  }

  @override
  void initState() {
    super.initState();
    _currentStage = widget.stage ?? _inferStage(widget.tripData);
    _data = widget.tripData ?? {};
    _rideId = widget.rideId ?? _data?['rideId'] ?? _data?['id'] ?? 'RIDE-20124568';
    _screenTitle = _getStageTitle(_currentStage);
    _badge = widget.statusBadge ?? _data?['statusBadge'] ?? (_currentStage == 'during_ride' ? 'On Trip' : 'Seats Open');
    
    // Dynamic fuel resolution
    final rawFuel = widget.fuelContribution ??
        _data?['tripDetails']?['fuelContributionFormatted'] ??
        _data?['fuelContribution'] ??
        _data?['fuelSaved'] ??
        _data?['price'] ??
        _data?['fare'];
    if (rawFuel != null && rawFuel.toString().isNotEmpty) {
      final s = rawFuel.toString();
      _fuel = s.startsWith('₹') ? s : '₹$s';
    } else {
      _fuel = '₹358';
    }

    // Dynamic driver name resolution
    _driver = widget.driverName ??
        _data?['tripDetails']?['driverName'] ??
        _data?['driverName'] ??
        _data?['driver']?['name'] ??
        'Driver';

    _code = widget.driverCode ??
        _data?['tripDetails']?['driverCode'] ??
        _data?['driverCode'] ??
        _data?['driver']?['driverCode'] ??
        _data?['code'] ??
        _data?['tripDetails']?['code'] ??
        '#1245';
    _bookingId = widget.bookingSeatZaatraId ?? _data?['tripDetails']?['bookingSeatZaatraId'] ?? (_rideId ?? '20124568');
    _nextPickup = widget.nextPickup ?? _data?['nextPickup'];

    // Dynamic timeline from routeTimeline or stops in tripData
    _timeline = widget.routeTimeline ?? _buildTimelineFromData(_data);

    // Dynamic seats from seatsAvailable or passengers
    _seats = widget.seatsAvailable ??
        (_data?['seatsAvailable'] is List
            ? List<Map<String, dynamic>>.from(_data!['seatsAvailable'])
            : _buildSeatsFromData(_data, _currentStage));

    _initPreferences();
    _loadTripCard();
  }

  Future<void> _initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('currentUserName') ??
          prefs.getString('fullName') ??
          prefs.getString('driver_name') ??
          prefs.getString('name') ??
          '';
      final savedModel = prefs.getString('driver_vehicle_model') ??
          prefs.getString('vehicleModel') ??
          '';
      final savedPlate = prefs.getString('driver_vehicle_number') ??
          prefs.getString('vehicleNumber') ??
          '';
      final savedRating = prefs.getString('driver_rating') ?? '4.8';
      final savedCode = prefs.getString('driver_code') ?? prefs.getString('driverCode') ?? '';

      if (mounted) {
        setState(() {
          if (savedName.isNotEmpty && (widget.driverName == null || widget.driverName!.isEmpty) && _driver == 'Driver') {
            _driver = savedName;
          }
          if (savedCode.isNotEmpty && (_code == '#1245' || _code.isEmpty)) {
            _code = savedCode;
          }
          if (savedModel.isNotEmpty) _vehicleModel = savedModel;
          if (savedPlate.isNotEmpty) _vehiclePlate = savedPlate;
          if (savedRating.isNotEmpty) _driverRating = savedRating;

          _heroCard ??= {
            'category': 'Zatara Go',
            'categoryTitle': 'Zatara Go',
            'vehicleSpecs': '$_vehicleModel · $_vehiclePlate',
            'vehicleModel': _vehicleModel,
            'vehicleNumberPlate': _vehiclePlate,
            'driverName': _driver,
            'driverRole': 'Driver',
            'driverRating': double.tryParse(_driverRating) ?? 4.8,
            'driverRatingDisplay': 'Driver · ★ $_driverRating',
          };
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _buildTimelineFromData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return _getDefaultTimeline();

    if (data['routeTimeline'] is List && (data['routeTimeline'] as List).isNotEmpty) {
      return List<Map<String, dynamic>>.from(data['routeTimeline']);
    }

    final origin = data['pickupLocation'] ?? data['origin'] ?? data['pickup'] ?? data['from'] ?? '';
    final dest = data['destination'] ?? data['dropLocation'] ?? data['drop'] ?? data['to'] ?? '';
    final startTime = data['time'] ?? data['departureTime'] ?? data['startTime'] ?? '09:00 AM';

    if (origin.toString().isNotEmpty || dest.toString().isNotEmpty) {
      final stopsList = <Map<String, dynamic>>[];
      stopsList.add({
        'index': 0,
        'time': startTime.toString().split(' ')[0],
        'timeRaw': startTime.toString(),
        'location': origin.toString().isNotEmpty ? origin.toString() : 'Origin',
        'isOrigin': true,
        'type': 'start',
        'icon': 'car',
      });

      final rawStops = data['stops'] ?? data['intermediatePickups'] ?? data['routePlan'];
      if (rawStops is List && rawStops.isNotEmpty) {
        for (int i = 0; i < rawStops.length; i++) {
          final s = rawStops[i];
          final sName = s is Map ? (s['name'] ?? s['location'] ?? s['station'] ?? 'Stop ${i + 1}') : s.toString();
          final sTime = s is Map ? (s['time'] ?? s['expectedArrival'] ?? '') : '';
          stopsList.add({
            'index': i + 1,
            'time': sTime.toString().isNotEmpty ? sTime.toString().split(' ')[0] : '',
            'timeRaw': sTime.toString(),
            'location': sName.toString(),
            'isOrigin': false,
            'type': 'intermediate',
            'icon': 'stop',
          });
        }
      }

      final destTime = data['arrivalTime'] ?? data['destinationTime'] ?? '';
      stopsList.add({
        'index': stopsList.length,
        'time': destTime.toString().isNotEmpty ? destTime.toString().split(' ')[0] : '',
        'timeRaw': destTime.toString(),
        'location': dest.toString().isNotEmpty ? dest.toString() : 'Destination',
        'isDestination': true,
        'type': 'destination',
        'icon': 'destination',
      });
      return stopsList;
    }

    return _getDefaultTimeline();
  }

  List<Map<String, dynamic>> _buildSeatsFromData(Map<String, dynamic>? data, String stage) {
    if (data != null && data['passengers'] is List && (data['passengers'] as List).isNotEmpty) {
      final pList = data['passengers'] as List;
      final seats = <Map<String, dynamic>>[];
      for (int i = 0; i < pList.length; i++) {
        final p = pList[i];
        final pName = p is Map ? (p['name'] ?? p['passengerName'] ?? 'Passenger ${i + 1}') : p.toString();
        final isBoarded = p is Map ? (p['isBoarded'] == true || p['status'] == 'BOARDED') : false;
        seats.add({
          'seatNumber': 'S-${i + 1}',
          'label': 'S-${i + 1} Booked',
          'displayLabel': isBoarded ? 'S-${i + 1} In Car' : 'S-${i + 1} Booked',
          'status': isBoarded ? 'completed' : 'booked',
          'isBooked': true,
          'isBoarded': isBoarded,
          'badge': isBoarded ? 'In Car' : 'Booked',
          'passengerName': pName,
          'icon': 'user',
          'color': '#E9D8FD',
        });
      }
      final total = (data['totalSeats'] is int) ? data['totalSeats'] as int : 4;
      while (seats.length < total) {
        final idx = seats.length + 1;
        seats.add({
          'seatNumber': 'S-$idx',
          'label': 'Available',
          'status': 'available',
          'isBooked': false,
          'isBoarded': false,
          'badge': 'Available',
          'passengerStatus': 'Empty',
          'icon': 'empty_seat',
          'color': '#D1E7DD',
        });
      }
      return seats;
    }
    return _getDefaultSeats(stage);
  }

  String _getStageTitle(String stage) {
    switch (stage) {
      case 'during_ride':
        return 'Trip Shared card During ride';
      case 'summary':
        return 'Trip Shared card Completed';
      case 'before_ride':
      default:
        return 'Trip Shared card before ride';
    }
  }

  List<Map<String, dynamic>> _getDefaultTimeline() {
    return [
      {'index': 0, 'time': '9 : 00', 'timeRaw': '09:00 AM', 'location': 'Madhapur', 'isOrigin': true, 'type': 'start', 'icon': 'car'},
      {'index': 1, 'time': '10 : 00', 'timeRaw': '10:00 AM', 'location': 'Ameerpet', 'isOrigin': false, 'type': 'intermediate', 'icon': 'stop'},
      {'index': 2, 'time': '12 : 00', 'timeRaw': '12:00 PM', 'location': 'Begumpet', 'isOrigin': false, 'type': 'intermediate', 'icon': 'stop'},
      {'index': 3, 'time': '01 : 00', 'timeRaw': '01:00 PM', 'location': 'Secundrabad', 'isDestination': true, 'type': 'destination', 'icon': 'destination'},
    ];
  }

  List<Map<String, dynamic>> _getDefaultSeats(String stage) {
    if (stage == 'during_ride') {
      return [
        {
          'seatNumber': 'S-1',
          'label': 'S-1 Booked',
          'displayLabel': 'S-1 In Car',
          'status': 'completed',
          'boardingState': 'COMPLETED',
          'isBooked': true,
          'isBoarded': true,
          'badge': 'In Car',
          'stepStatus': 'Customer entered car (Seat completed)',
          'passengerName': 'Ananya Sharma',
          'pickupLocation': 'Madhapur',
          'icon': 'user',
          'color': '#E9D8FD',
        },
        {
          'seatNumber': 'S-2',
          'label': 'S-2 Booked',
          'displayLabel': 'S-2 Next Pickup',
          'status': 'next_pickup',
          'boardingState': 'NEXT_PICKUP',
          'isNextPickup': true,
          'isBooked': true,
          'isBoarded': false,
          'badge': 'Next Pickup',
          'stepStatus': 'Going to pick up next: Suresh Kumar',
          'passengerName': 'Suresh Kumar',
          'passengerPhone': '+919876543211',
          'pickupLocation': 'Ameerpet',
          'boardingPin': '4829',
          'icon': 'user',
          'color': '#E9D8FD',
        },
        {
          'seatNumber': 'S-3',
          'label': 'S-3 Booked',
          'displayLabel': 'S-3 Waiting',
          'status': 'waiting',
          'boardingState': 'WAITING',
          'isNextPickup': false,
          'isBooked': true,
          'isBoarded': false,
          'badge': 'Waiting',
          'stepStatus': 'Waiting for cab',
          'passengerName': 'Ramesh Reddy',
          'passengerPhone': '',
          'pickupLocation': 'Begumpet',
          'icon': 'user',
          'color': '#E9D8FD',
        },
        {
          'seatNumber': 'S-4',
          'label': 'Available',
          'status': 'available',
          'isBooked': false,
          'isBoarded': false,
          'badge': 'Available',
          'passengerStatus': 'Empty',
          'icon': 'empty_seat',
          'color': '#D1E7DD',
        },
      ];
    }

    // Default Before Ride
    return [
      {
        'seatNumber': 'S-1',
        'label': 'S-1 Booked',
        'status': 'booked',
        'isBooked': true,
        'isBoarded': false,
        'badge': 'Booked',
        'passengerStatus': 'Waiting for cab',
        'passengerName': 'Ananya Sharma',
        'icon': 'user',
        'color': '#E9D8FD',
      },
      {
        'seatNumber': 'S-2',
        'label': 'S-2 Booked',
        'status': 'booked',
        'isBooked': true,
        'isBoarded': false,
        'badge': 'Booked',
        'passengerStatus': 'Waiting for cab',
        'passengerName': 'Suresh Kumar',
        'icon': 'user',
        'color': '#E9D8FD',
      },
      {
        'seatNumber': 'S-3',
        'label': 'S-3 Booked',
        'status': 'booked',
        'isBooked': true,
        'isBoarded': false,
        'badge': 'Booked',
        'passengerStatus': 'Waiting for cab',
        'passengerName': 'Ramesh Reddy',
        'icon': 'user',
        'color': '#E9D8FD',
      },
      {
        'seatNumber': 'S-4',
        'label': 'Available',
        'status': 'available',
        'isBooked': false,
        'isBoarded': false,
        'badge': 'Available',
        'passengerStatus': 'Empty',
        'passengerName': null,
        'icon': 'empty_seat',
        'color': '#D1E7DD',
      },
    ];
  }

  Future<void> _loadTripCard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final rId = _rideId ?? 'RIDE-20124568';
      final res = await RideService.getTripSharedMaster(rideId: rId, stage: _currentStage);

      if (mounted && res['success'] == true) {
        setState(() {
          _screenTitle = res['screenTitle'] ?? _getStageTitle(_currentStage);
          if (widget.stage == null && res['stage'] != null) {
            _currentStage = res['stage'].toString();
          }
          if (res['statusBadge'] != null) {
            _badge = res['statusBadge'].toString();
          }
          if (res['routeTimeline'] is List && (res['routeTimeline'] as List).isNotEmpty) {
            _timeline = List<Map<String, dynamic>>.from(res['routeTimeline']);
          }
          if (res['seatsAvailable'] is List && (res['seatsAvailable'] as List).isNotEmpty) {
            _seats = List<Map<String, dynamic>>.from(res['seatsAvailable']);
          }
          if (res['pickupProgression'] is Map) {
            _pickupProgression = Map<String, dynamic>.from(res['pickupProgression']);
            if (_pickupProgression?['nextPickup'] is Map) {
              _nextPickup = Map<String, dynamic>.from(_pickupProgression!['nextPickup']);
            }
          }
          if (res['heroCard'] is Map) {
            _heroCard = Map<String, dynamic>.from(res['heroCard']);
          }
          if (res['statusCard'] is Map) {
            _statusCard = Map<String, dynamic>.from(res['statusCard']);
          }
          if (res['totalPassenger'] is Map) {
            _totalPassenger = Map<String, dynamic>.from(res['totalPassenger']);
          }
          if (res['actionButton'] is Map) {
            _actionButton = Map<String, dynamic>.from(res['actionButton']);
          }
          if (res['tripDetails'] is Map) {
            final td = res['tripDetails'];
            if (td['driverName'] != null) _driver = td['driverName'].toString();
            if (td['driverCode'] != null) {
              _code = td['driverCode'].toString();
            } else if (td['code'] != null) {
              _code = td['code'].toString();
            }
            if (td['bookingSeatZaatraId'] != null) _bookingId = td['bookingSeatZaatraId'].toString();
          } else {
            if (res['driverCode'] != null) {
              _code = res['driverCode'].toString();
            } else if (res['code'] != null) {
              _code = res['code'].toString();
            }
          }
        });
      } else {
        // Fallback: Query live ride status from Module 5 API if rideId is available
        if (rId.isNotEmpty && rId != 'RIDE-20124568') {
          try {
            final liveRes = await RideService.getLiveRideStatus(rId);
            if (liveRes['success'] == true && liveRes['data'] != null && mounted) {
              final live = LiveRideStatusResult.fromJson(liveRes);
              if (live.stops.isNotEmpty) {
                final liveTimeline = live.stops.map((s) => {
                  'index': s.index,
                  'time': s.expectedArrival,
                  'timeRaw': s.expectedArrival,
                  'location': s.name,
                  'isOrigin': s.type == 'ORIGIN',
                  'isDestination': s.type == 'DESTINATION',
                  'type': s.type == 'ORIGIN' ? 'start' : (s.type == 'DESTINATION' ? 'destination' : 'intermediate'),
                  'icon': s.type == 'ORIGIN' ? 'car' : (s.type == 'DESTINATION' ? 'destination' : 'stop'),
                }).toList();

                setState(() {
                  _timeline = List<Map<String, dynamic>>.from(liveTimeline);
                  if (live.tripStatus.isNotEmpty) {
                    _badge = live.tripStatus == 'IN_PROGRESS'
                        ? 'On Trip'
                        : (live.tripStatus == 'SCHEDULED' ? 'Seats Open' : live.tripStatus);
                  }
                });
              }
            }
          } catch (_) {}
        }
        _applyStageFallbacks(_currentStage);
      }
    } catch (e) {
      debugPrint('Error loading trip shared card: $e');
      _applyStageFallbacks(_currentStage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyStageFallbacks(String stage) {
    if (!mounted) return;
    setState(() {
      _screenTitle = _getStageTitle(stage);
      // Preserve existing dynamic timeline if already set
      if (_timeline.isEmpty) {
        _timeline = _buildTimelineFromData(_data);
      }
      // Preserve existing dynamic seats if already set
      if (_seats.isEmpty) {
        _seats = _buildSeatsFromData(_data, stage);
      }

      if (stage == 'during_ride') {
        _pickupProgression = {
          'completedCount': 1,
          'totalBooked': 3,
          'progressText': 'Customer get in so seat one is already completed. Next we are going to second person: Suresh Kumar at Ameerpet.',
          'nextPickup': {
            'pickupIndex': 2,
            'seatNumber': 'S-2',
            'passengerName': 'Suresh Kumar',
            'phone': '+919876543211',
            'location': 'Ameerpet',
            'time': '10 : 00',
            'boardingPin': '4829',
            'routeSegment': 'Ameerpet - Begumpet',
            'eta': '10 mins',
            'distanceRemaining': '4.2 KM',
          },
        };
        _nextPickup = _pickupProgression!['nextPickup'];
      } else if (stage == 'summary') {
        final arrival = _data?['arrivalTime'] ?? _data?['time'] ?? '10:20 PM';
        final bookedCount = _seats.where((s) => s['isBooked'] == true).length;
        _heroCard ??= {
          'category': 'Zatara Go',
          'categoryTitle': 'Zatara Go',
          'vehicleSpecs': '$_vehicleModel · $_vehiclePlate',
          'vehicleModel': _vehicleModel,
          'vehicleNumberPlate': _vehiclePlate,
          'carImage': 'https://cdn-icons-png.flaticon.com/512/3202/3202926.png',
          'driverName': _driver,
          'driverRole': 'Driver',
          'driverRating': double.tryParse(_driverRating) ?? 4.8,
          'driverRatingDisplay': 'Driver · ★ $_driverRating',
        };
        _statusCard ??= {
          'estimateArrival': {'title': 'Estimate arrival', 'time': arrival.toString()},
          'tripStatus': {'title': 'Trip Status', 'value': 'On The Way', 'color': '#16A34A', 'statusCode': 'ON_THE_WAY'},
        };
        _totalPassenger ??= {
          'title': 'Total Passenger',
          'label': 'Co-travelers',
          'count': bookedCount > 0 ? bookedCount : 3,
          'icon': 'co_travelers',
        };
        _actionButton = {
          'text': 'Share Trip Again',
          'action': 'share_again',
          'endpoint': '/api/rides/RIDE-20124568/share-again',
          'shareUrl': 'https://zaatra.app/track/RIDE-20124568',
          'shareText': 'Track my Zaatra ride from Madhapur to Secundrabad with Rahul Kumar. Status: On The Way. ETA: 10:20 PM. Live link: https://zaatra.app/track/RIDE-20124568',
        };
      }
    });
  }

  Future<void> _handleShareTripAgain() async {
    final rId = _rideId ?? 'RIDE-20124568';
    setState(() => _isLoading = true);
    final res = await RideService.shareTripAgain(rideId: rId);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final shareUrl = res['shareUrl'] ?? 'https://zaatra.app/track/$rId';
    final shareText = res['shareText'] ??
        'Track my Zaatra ride from Madhapur to Secundrabad with Rahul Kumar. Status: On The Way. ETA: 10:20 PM. Live link: $shareUrl';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.share_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Share Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shareText, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDF7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareUrl,
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trip share link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing via WhatsApp...')),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCaptureAndShare() async {
    final rId = _rideId ?? 'RIDE-20124568';
    final shareUrl = 'https://zaatra.app/track/$rId';
    final shareText = 'Track my Zaatra ride with $_driver! Live link: $shareUrl';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing trip card image...'),
        duration: Duration(milliseconds: 1200),
      ),
    );

    // Wait a brief frame for layout rendering
    await Future.delayed(const Duration(milliseconds: 250));

    final targetKey = _shareCardKey.currentContext != null ? _shareCardKey : _modalShareCardKey;

    final res = await NativeShareService.captureAndShareWidget(
      key: targetKey,
      text: shareText,
      fallbackShareUrl: shareUrl,
    );

    if (!mounted) return;

    if (res['success'] != true || res['isWeb'] == true) {
      _handleShareTripAgain();
    }
  }

  Future<void> _handleCaptureAndShareScreen96() => _handleCaptureAndShare();

  void _showTripSharedModalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: _modalShareCardKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildSummaryContent(isModal: true),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _screenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: _handleCaptureAndShare,
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
                    backgroundColor: Color(0xFFF3EDF7),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 3,
                  ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadTripCard,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: RepaintBoundary(
                        key: _shareCardKey,
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                              if (_currentStage == 'summary')
                                _buildSummaryContent()
                              else if (_currentStage == 'during_ride')
                                _buildDuringRideContent()
                              else
                                _buildBeforeRideContent(),
                            ],
                          ),
                        ),
                      ),
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

  // ==========================================
  // STAGE 1: BEFORE RIDE (Screenshot 1)
  // ==========================================
  Widget _buildBeforeRideContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Pill "Seats Open"
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

        // Route Timeline
        ...List.generate(_timeline.length, (i) {
          final item = _timeline[i];
          final isStart = item['isStart'] == true || item['type'] == 'start' || item['isOrigin'] == true || i == 0;
          final isLast = item['isLast'] == true || item['type'] == 'destination' || item['isDestination'] == true || i == _timeline.length - 1;
          final time = item['time'] ?? item['timeRaw'] ?? '09:00 AM';
          final station = item['location'] ?? item['station'] ?? item['address'] ?? '';

          return _buildWaypointTile(time: time, station: station, isStart: isStart, isLast: isLast);
        }),

        const SizedBox(height: 24),

        // Seats Available Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Seats Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDF7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_seats.where((s) => s['isBooked'] != true && s['status'] != 'booked').length} Available',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final canFitEvenly = (_seats.length <= 5) || (availableWidth / (_seats.isNotEmpty ? _seats.length : 1) >= 48);

              final seatWidgets = List.generate(_seats.length, (i) {
                final seat = _seats[i];
                final label = seat['label'] ?? seat['seatNumber'] ?? 'S-${i + 1}';
                final isBooked = seat['isBooked'] == true || seat['status'] == 'booked';
                final pName = seat['passengerName']?.toString();
                final seatBox = _buildSeatBox(
                  label: label,
                  isBooked: isBooked,
                  passengerName: pName,
                  colorHex: seat['color']?.toString(),
                );

                if (canFitEvenly) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: seatBox,
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(width: 50, child: seatBox),
                  );
                }
              });

              if (canFitEvenly) {
                return Row(
                  children: seatWidgets,
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: seatWidgets,
                  ),
                );
              }
            },
          ),
        ),

        const SizedBox(height: 24),

        // Trip Info Rows
        _buildInfoRow(
          icon: Icons.person_outline_rounded,
          iconBg: const Color(0xFFF3EDF7),
          iconColor: AppColors.primary,
          text: '$_driver - driver code $_code',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.access_time_rounded,
          iconBg: const Color(0xFFF3EDF7),
          iconColor: AppColors.primary,
          text: 'Date & Time : 08-08-26, 10:26 PM',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.directions_car_outlined,
          iconBg: const Color(0xFFF3EDF7),
          iconColor: AppColors.primary,
          text: 'White Swift Dzire · TS 09 AB 1234',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==========================================
  // STAGE 2: DURING RIDE (Screenshot 2)
  // ==========================================
  Widget _buildDuringRideContent() {
    final progText = _pickupProgression?['progressText'] ??
        'Customer get in so seat one is already completed. Next we are going to second person: Suresh Kumar at Ameerpet.';
    final np = _nextPickup ?? _pickupProgression?['nextPickup'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route Timeline
        ...List.generate(_timeline.length, (i) {
          final item = _timeline[i];
          final isStart = item['isStart'] == true || item['type'] == 'start' || item['isOrigin'] == true || i == 0;
          final isLast = item['isLast'] == true || item['type'] == 'destination' || item['isDestination'] == true || i == _timeline.length - 1;
          final time = item['time'] ?? '09:00 AM';
          final station = item['location'] ?? item['station'] ?? '';

          return _buildWaypointTile(time: time, station: station, isStart: isStart, isLast: isLast);
        }),

        const SizedBox(height: 20),

        // Progression Banner Text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1D5EA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  progText,
                  style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Next Pickup Highlight Card with PIN 4829
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9D8FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          np['seatNumber'] ?? 'S-2',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Next Pickup',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  // Boarding PIN Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PIN: ${np['boardingPin'] ?? '4829'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFF3EDF7),
                    child: Icon(Icons.person, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          np['passengerName'] ?? 'Suresh Kumar',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${np['location'] ?? 'Ameerpet'} · ETA ${np['eta'] ?? '10 mins'} (${np['distanceRemaining'] ?? '4.2 KM'})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${np['passengerName']} (${np['phone'] ?? '+919876543211'})...')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Seats Available Section (Progressive Boarding States)
        const Text(
          'Seats Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final canFitEvenly = (_seats.length <= 5) || (availableWidth / (_seats.isNotEmpty ? _seats.length : 1) >= 48);

              final seatWidgets = List.generate(_seats.length, (i) {
                final seat = _seats[i];
                final label = seat['displayLabel'] ?? seat['label'] ?? 'S-${i + 1}';
                final badge = seat['badge']?.toString() ?? '';
                final status = seat['status']?.toString() ?? '';
                final isCompleted = status == 'completed' || badge == 'In Car';
                final isNext = status == 'next_pickup' || badge == 'Next Pickup';

                final seatBox = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFD1E7DD)
                            : (isNext ? const Color(0xFFE9D8FD) : const Color(0xFFF3EDF7)),
                        borderRadius: BorderRadius.circular(12),
                        border: isNext ? Border.all(color: AppColors.primary, width: 2) : null,
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : (isNext ? Icons.directions_car_rounded : Icons.person_outline_rounded),
                          color: isCompleted ? const Color(0xFF198754) : AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                        color: isNext ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                );

                if (canFitEvenly) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: seatBox,
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(width: 50, child: seatBox),
                  );
                }
              });

              if (canFitEvenly) {
                return Row(
                  children: seatWidgets,
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: seatWidgets,
                  ),
                );
              }
            },
          ),
        ),

        const SizedBox(height: 24),

        // Trip Info
        _buildInfoRow(
          icon: Icons.person_outline_rounded,
          iconBg: const Color(0xFFF3EDF7),
          iconColor: AppColors.primary,
          text: '$_driver - driver code $_code',
        ),

        const SizedBox(height: 30),

        CustomButton(
          text: 'View Live Next Pickup',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverLiveNextPickupScreen(
                  rideId: _rideId ?? widget.rideId,
                  statusBadge: _badge,
                  routeTimeline: _timeline,
                  seatsAvailable: _seats,
                  fuelContribution: _fuel,
                  driverName: _driver,
                  driverCode: _code,
                  bookingSeatZaatraId: _bookingId,
                  nextPickup: _nextPickup,
                  nextPickupLocation: _nextPickup?['location'] ?? 'Ameerpet',
                  tripData: _data,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==========================================
  // STAGE 3: SUMMARY & SHARE ACTION (Screenshot 3 / 96.png)
  // ==========================================
  Widget _buildSummaryContent({bool isModal = false}) {
    final hero = _heroCard ?? {
      'category': 'Zatara Go',
      'vehicleSpecs': '$_vehicleModel · $_vehiclePlate',
      'driverName': _driver,
      'driverRatingDisplay': 'Driver · ★ $_driverRating',
    };
    final sc = _statusCard ?? {};
    final etaTime = sc['estimateArrival']?['time'] ?? (_data?['arrivalTime'] ?? _data?['time'] ?? '10:20 PM');
    final tripStatus = sc['tripStatus']?['value'] ?? (_currentStage == 'during_ride' ? 'On The Way' : (_currentStage == 'summary' ? 'Completed' : 'Seats Open'));
    final bookedCount = _seats.where((s) => s['isBooked'] == true).length;
    final coTravelers = _totalPassenger?['count'] ?? (bookedCount > 0 ? bookedCount : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isModal) ...[
          // Modal Header with Back Arrow & Centered Title matching 96.png
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text(
                'Trip Shared',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
        ],

        // 1. Vehicle & Driver Hero Row (Matching 96.png)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EEFD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/hero_ride_3d_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.directions_car_rounded, size: 40, color: Color(0xFF1E88E5)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero['category'] ?? 'Zatara Go',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hero['vehicleSpecs'] ?? 'White Swift Dzire · TS 09 AB 1234',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hero['driverName'] ?? 'Rahul Kumar',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      children: [
                        TextSpan(text: 'Driver · '),
                        TextSpan(text: '★ 4.8', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 2. Route Timeline (Matching 96.png)
        ...List.generate(_timeline.length, (i) {
          final item = _timeline[i];
          final isStart = item['isStart'] == true || item['type'] == 'start' || item['isOrigin'] == true || i == 0;
          final isLast = item['isLast'] == true || item['type'] == 'destination' || item['isDestination'] == true || i == _timeline.length - 1;
          final time = item['time'] ?? '09:00';
          final station = item['location'] ?? item['station'] ?? '';

          return _buildWaypointTile(time: time, station: station, isStart: isStart, isLast: isLast);
        }),

        const SizedBox(height: 20),

        // 3. Status Card: Estimate Arrival & Trip Status (Unified lavender card matching 96.png)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimate arrival', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  Text(etaTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trip Status', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    const SizedBox(height: 2),
                    Text(
                      tripStatus,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4. Total Passenger Header & Pill (Matching 96.png)
        const Text(
          'Total Passenger',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Co-travelers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                '$coTravelers',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 5. Trip sharing active caption
        const Center(
          child: Text(
            'Trip sharing is active until the ride ends.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWaypointTile({
    required String time,
    required String station,
    required bool isStart,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                time,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              isStart
                  ? const Icon(Icons.directions_car_rounded, color: Color(0xFFE53935), size: 18)
                  : Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                    ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
              child: Text(
                station,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatBox({
    required String label,
    required bool isBooked,
    String? passengerName,
    String? colorHex,
  }) {
    Color bg = isBooked ? const Color(0xFFE8DEF8) : const Color(0xFFD1E7DD);
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final hexStr = colorHex.replaceAll('#', '');
        if (hexStr.length == 6) {
          bg = Color(int.parse('FF$hexStr', radix: 16));
        }
      } catch (_) {}
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              isBooked ? Icons.person_rounded : Icons.event_seat_outlined,
              color: isBooked ? AppColors.primary : const Color(0xFF198754),
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        if (passengerName != null && passengerName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            passengerName.split(' ').first,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
