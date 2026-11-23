import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place_location_model.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/google_maps_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/driver_conflict_dialogs.dart';
import '../../../widgets/route_map_webview.dart';
import '../../../widgets/route_timeline_tile.dart';
import 'driver_passenger_pin_verification_screen_89.dart';
import 'driver_on_trip_seats_screen_91.dart';
import 'driver_trip_shared_screen_94.dart';
import 'trip_completed_summary_screen_35.dart';

class DriverRideStartDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? rideData;
  final String? rideId;
  final String? origin;
  final String? destination;
  final String? departureTime;
  final String? totalDistance;
  final List<Map<String, dynamic>>? initialPassengers;
  final List<Map<String, dynamic>>? initialStops;

  const DriverRideStartDetailsScreen({
    super.key,
    this.rideData,
    this.rideId,
    this.origin,
    this.destination,
    this.departureTime,
    this.totalDistance,
    this.initialPassengers,
    this.initialStops,
  });

  @override
  State<DriverRideStartDetailsScreen> createState() => _DriverRideStartDetailsScreenState();
}

class _DriverRideStartDetailsScreenState extends State<DriverRideStartDetailsScreen> {
  late String _rideId;
  late String _origin;
  late String _destination;
  late String _totalDistance;
  late List<Map<String, dynamic>> _passengers;
  late List<Map<String, dynamic>> _stops;
  final TextEditingController _broadcastMsgController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  final GlobalKey _messageCardKey = GlobalKey();
  String? _messageTargetId; // bookingId of the passenger being messaged, null = everyone
  StartRideLockStatus _startRideStatus = const StartRideLockStatus();
  bool _isRideStarted = false;
  bool _isCompleted = false;
  bool _hasArrived = false;
  bool _isDriverOnline = true;
  String _rideStatus = 'active';
  List<CandidateRoute> _candidateRoutes = [];

  bool get _isRideActive {
    if (_isRideStarted) return true;
    final s = _rideStatus.toLowerCase().trim();
    if (s == 'completed' || s == 'cancelled') {
      return false;
    }
    return _isDriverOnline;
  }

  Future<void> _loadDriverOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? prefs.getString('driverPhone') ?? '';
      final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');
      bool online = true;
      if (cleanDigits.isNotEmpty && prefs.containsKey('driver_online_state_$cleanDigits')) {
        online = prefs.getBool('driver_online_state_$cleanDigits') ?? true;
      } else if (prefs.containsKey('driver_online_state')) {
        online = prefs.getBool('driver_online_state') ?? true;
      }
      if (mounted) {
        setState(() {
          _isDriverOnline = online;
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final data = widget.rideData ?? {};

    final initialStatus = (data['status']?.toString().toLowerCase()) ??
        (data['rideStatus']?.toString().toLowerCase()) ??
        (data['tab']?.toString().toLowerCase()) ??
        '';
    _rideStatus = initialStatus.isNotEmpty ? initialStatus : _rideStatus;
    _isCompleted = _rideStatus == 'completed';
    _isRideStarted = _rideStatus == 'in_progress' || _rideStatus == 'started';
    _hasArrived = _rideStatus == 'arrived' || _isRideStarted || _isCompleted;

    _rideId = widget.rideId ?? (data['_id'] ?? data['rideId'] ?? data['id'] ?? '').toString();
    final rawOrigin = widget.origin ?? data['from'] ?? data['pickupLocation'];
    _origin = (rawOrigin != null && rawOrigin.toString().isNotEmpty && rawOrigin != 'Origin')
        ? rawOrigin.toString()
        : '';
    final rawDest = widget.destination ?? data['to'] ?? data['destinationLocation'];
    _destination = (rawDest != null && rawDest.toString().isNotEmpty && rawDest != 'Destination')
        ? rawDest.toString()
        : '';
    _totalDistance = widget.totalDistance ?? data['distance'] ?? '';

    // Initialize stops dynamically from rideData without hardcoded fallbacks
    if (widget.initialStops != null && widget.initialStops!.isNotEmpty) {
      _stops = List<Map<String, dynamic>>.from(widget.initialStops!);
    } else if (data['routePlan'] is List && (data['routePlan'] as List).isNotEmpty) {
      _stops = (data['routePlan'] as List).map<Map<String, dynamic>>((item) {
        final loc = (item['location'] ?? item['station'] ?? '').toString();
        return {
          'time': item['time'] ?? '--',
          'station': loc.split(',').first,
          'isStart': item['type'] == 'start' || item['isStart'] == true,
          'type': item['type'] ?? 'pickup',
          'status': item['status'] ?? 'upcoming',
        };
      }).toList();
    } else if (data['selectedCities'] is List && (data['selectedCities'] as List).isNotEmpty) {
      final list = <Map<String, dynamic>>[];
      list.add({'time': data['departureTime'] ?? '--', 'station': _origin.split(',').first, 'isStart': true});
      for (final city in data['selectedCities']) {
        list.add({'time': '--:--', 'station': city.toString().split(',').first, 'isStart': false});
      }
      list.add({'time': data['arrivalTime'] ?? '--', 'station': _destination.split(',').first, 'isStart': false});
      _stops = list;
    } else {
      _stops = [
        {'time': data['departureTime'] ?? '--', 'station': _origin.split(',').first, 'isStart': true},
        {'time': data['arrivalTime'] ?? '--', 'station': _destination.split(',').first, 'isStart': false},
      ];
    }

    // Initialize passengers purely from dynamic data, excluding denied or cancelled
    final rawInitPassengers = widget.initialPassengers ?? (data['passengers'] is List ? List<Map<String, dynamic>>.from(data['passengers']) : null);
    if (rawInitPassengers != null && rawInitPassengers.isNotEmpty) {
      _passengers = rawInitPassengers.where((p) {
        final s = (p['status'] ?? '').toString().toLowerCase();
        return s != 'denied' && s != 'declined' && s != 'rejected' && s != 'cancelled';
      }).toList();
    } else {
      _passengers = [];
    }

    _loadDriverOnlineStatus();
    _evaluateOneHourLockStatus(data);
    _loadRideData();
    _loadDirections();
  }

  Future<void> _loadDirections() async {
    try {
      final res = await GoogleMapsService.getDirectionsByAddress(
        origin: _origin,
        destination: _destination,
      );
      if (res != null && res.candidateRoutes.isNotEmpty && mounted) {
        setState(() {
          _candidateRoutes = res.candidateRoutes;
        });
      }
    } catch (e) {
      debugPrint('Notice: Error loading directions in ride start details: $e');
    }
  }

  Future<void> _loadRideData() async {
    try {
      _loadDriverOnlineStatus();
      final List<Map<String, dynamic>> loadedPassengers = [];
      final prefs = await SharedPreferences.getInstance();
      final declinedBookingIds = prefs.getStringList('driver_declined_booking_ids') ?? [];

      final res = await RideService.getRideStartDetails(rideId: _rideId);
      if (res['success'] == true && mounted) {
        if (res['rideId'] != null) _rideId = res['rideId'].toString();
        if (res['distance'] != null && _totalDistance.isEmpty) _totalDistance = res['distance'].toString();

        // Map API timeline if present
        if (res['timeline'] is List && (res['timeline'] as List).isNotEmpty) {
          _stops = (res['timeline'] as List).map<Map<String, dynamic>>((item) {
            return {
              'time': item['time'] ?? '--',
              'station': item['location'] ?? item['station'] ?? '',
              'isStart': item['isStart'] == true || item['type'] == 'start',
              'type': item['type'],
              'status': item['status'],
            };
          }).toList();
        }

        // Map API passengers if present from backend
        final passInfo = res['passengerInfo'];
        if (passInfo != null && passInfo['passengers'] is List && (passInfo['passengers'] as List).isNotEmpty) {
          for (final p in passInfo['passengers'] as List) {
            final pStatus = (p['status'] ?? '').toString().toLowerCase();
            final pBookingId = (p['bookingId'] ?? p['passengerId'] ?? p['id'] ?? '').toString();

            // Exclude denied, declined, rejected, or cancelled passengers
            if (pStatus == 'denied' || pStatus == 'declined' || pStatus == 'rejected' || pStatus == 'cancelled' || declinedBookingIds.contains(pBookingId)) {
              continue;
            }

            int sNum = 1;
            if (p['seatNumber'] != null) {
              final sStr = p['seatNumber'].toString().replaceAll(RegExp(r'[^0-9]'), '');
              sNum = int.tryParse(sStr) ?? 1;
            }
            loadedPassengers.add({
              'id': p['passengerId'] ?? 'p${p['passengerIndex'] ?? (loadedPassengers.length + 1)}',
              'bookingId': p['bookingId'] ?? 'BK-${loadedPassengers.length + 1}',
              'name': p['name'] ?? 'Passenger',
              'phone': _extractPhone(p),
              'userId': (p['userId'] ?? p['customerId'] ?? p['passengerUserId'] ?? '').toString(),
              'title': 'Passenger ${p['passengerIndex'] ?? (loadedPassengers.length + 1)}',
              'route': p['segment'] ?? p['route'] ?? '',
              'time': p['timeWindow'] ?? '',
              'pickup': p['from'] ?? _origin,
              'dropoff': p['to'] ?? _destination,
              'seatNumber': sNum,
              'isBoarded': p['isBoarded'] == true,
            });
          }
        }

        // Map Start Ride Lock Status if provided by backend
        if (res['startRideStatus'] is Map) {
          _startRideStatus = StartRideLockStatus.fromJson(Map<String, dynamic>.from(res['startRideStatus'] as Map));
        } else if (res['actions'] is Map) {
          _startRideStatus = StartRideLockStatus.fromJson(Map<String, dynamic>.from(res['actions'] as Map));
        }
        _evaluateOneHourLockStatus(res);

        final rStatus = (res['status'] ?? res['rideStatus'] ?? res['ride']?['status'] ?? '').toString().toLowerCase();
        if (rStatus.isNotEmpty) {
          _rideStatus = rStatus;
        }
        if (rStatus == 'completed') {
          _isCompleted = true;
          _isRideStarted = false;
          _hasArrived = true;
        } else if (rStatus == 'in_progress' || rStatus == 'started' || rStatus == 'active') {
          _isRideStarted = true;
          _hasArrived = true;
        } else if (rStatus == 'arrived') {
          _hasArrived = true;
        }
      }

      // 🚀 Also query live backend bookings for this ride (GET /api/bookings)
      try {
        final bookingsRes = await ApiService.get('/bookings');
        if (bookingsRes['success'] == true && bookingsRes['bookings'] is List) {
          final allBookings = List<Map<String, dynamic>>.from(bookingsRes['bookings']);
          final matchingBookings = allBookings.where((b) {
            final bRideId = (b['rideId'] ?? b['ride']?['_id'] ?? b['ride']?['id'] ?? b['ride'] ?? '').toString();
            return bRideId.isNotEmpty && (bRideId == _rideId);
          }).toList();

          for (int i = 0; i < matchingBookings.length; i++) {
            final b = matchingBookings[i];
            final bId = (b['bookingId'] ?? b['_id'] ?? 'BK-${i + 1}').toString();
            final status = (b['status']?.toString().toLowerCase()) ?? 'confirmed';

            // Filter out denied, declined, rejected, and cancelled bookings
            if (status == 'denied' || status == 'declined' || status == 'rejected' || status == 'cancelled' || declinedBookingIds.contains(bId)) {
              continue;
            }

            final alreadyExists = loadedPassengers.any((p) => p['bookingId'] == bId);
            if (!alreadyExists) {
              loadedPassengers.add({
                'id': bId,
                'bookingId': bId,
                'name': b['userName'] ?? b['passengerName'] ?? b['customerName'] ?? 'Passenger ${i + 1}',
                'phone': _extractPhone(b),
                'userId': (b['userId'] ?? b['customerId'] ?? (b['user'] is Map ? b['user']['_id'] ?? b['user']['id'] : null) ?? '').toString(),
                'title': 'Passenger ${loadedPassengers.length + 1}',
                'route': '${(b['pickupLocation'] ?? b['from'] ?? _origin).toString().split(',').first} - ${(b['destinationLocation'] ?? b['to'] ?? _destination).toString().split(',').first}',
                'time': b['departureTime'] ?? '',
                'pickup': b['pickupLocation'] ?? b['from'] ?? _origin,
                'dropoff': b['destinationLocation'] ?? b['to'] ?? _destination,
                'seatNumber': b['seatsBooked'] ?? b['seats'] ?? (i + 1),
                'isBoarded': status == 'boarded' || status == 'completed',
              });
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _passengers = loadedPassengers.where((p) {
            final s = (p['status'] ?? '').toString().toLowerCase();
            final bId = (p['bookingId'] ?? p['id'] ?? '').toString();
            return s != 'denied' && s != 'declined' && s != 'rejected' && s != 'cancelled' && !declinedBookingIds.contains(bId);
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _broadcastMsgController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  /// Pulls a phone number out of whatever shape the backend sent for a passenger
  /// or booking (flat keys, or nested customer / passenger / user maps).
  static String _extractPhone(Map<dynamic, dynamic> p) {
    const keys = [
      'phone', 'phoneNumber', 'mobile', 'mobileNumber',
      'customerPhone', 'passengerPhone', 'userPhone', 'contact',
    ];
    String pick(Map<dynamic, dynamic> m) {
      for (final k in keys) {
        final v = m[k]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final direct = pick(p);
    if (direct.isNotEmpty) return direct;
    for (final nest in ['customer', 'passenger', 'user']) {
      final n = p[nest];
      if (n is Map) {
        final v = pick(n);
        if (v.isNotEmpty) return v;
      }
    }
    return '';
  }

  Future<void> _callPassenger(Map<String, dynamic> passenger) async {
    final raw = (passenger['phone'] ?? _extractPhone(passenger)).toString();
    final number = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number is not available for ${passenger['name'] ?? 'this passenger'}.')),
      );
      return;
    }
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: number), mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone app.'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone app.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyPassengerPin(int index) async {
    if (!_isRideStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please start the ride first before verifying passenger PIN.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final passenger = _passengers[index];
    final bookedSeatsList = _passengers
        .map<int>((p) => p['seatNumber'] is int ? p['seatNumber'] as int : int.tryParse(p['seatNumber'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 1)
        .toList();
    final passengerSeat = passenger['seatNumber'] is int
        ? passenger['seatNumber'] as int
        : int.tryParse(passenger['seatNumber'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? (index + 1);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DriverPassengerPinVerificationScreen(
          passengerName: (passenger['name'] != null && passenger['name'].toString().isNotEmpty && passenger['name'] != 'Passenger')
              ? passenger['name'].toString()
              : 'Passenger',
          pickupLocation: passenger['pickup'] ?? _origin,
          dropoffLocation: passenger['dropoff'] ?? _destination,
          boardingSeat: passengerSeat,
          totalSeats: 4,
          bookedSeats: bookedSeatsList.isNotEmpty ? bookedSeatsList : [passengerSeat],
          rideId: _rideId,
          bookingId: passenger['bookingId'],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _passengers[index]['isBoarded'] = true;
      });
    }
  }

  /// The passenger currently selected for a direct message (null = message everyone).
  Map<String, dynamic>? get _messageTarget {
    final id = _messageTargetId;
    if (id == null) return null;
    for (final p in _passengers) {
      if ((p['bookingId'] ?? p['id'] ?? '').toString() == id) return p;
    }
    return null; // passenger no longer on the ride
  }

  String _passengerLabel(Map<String, dynamic> p) {
    final n = (p['name'] ?? '').toString().trim();
    return n.isEmpty ? 'passenger' : n;
  }

  void _selectMessageTarget(Map<String, dynamic> passenger) {
    setState(() => _messageTargetId = (passenger['bookingId'] ?? passenger['id'] ?? '').toString());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _messageCardKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.3,
        );
      }
      _messageFocus.requestFocus();
    });
  }

  Future<void> _sendPassengerMessage(Map<String, dynamic> target) async {
    final text = _broadcastMsgController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a message before sending.')),
      );
      return;
    }
    final name = _passengerLabel(target);
    final res = await RideService.sendPassengerMessage(
      rideId: _rideId,
      bookingId: (target['bookingId'] ?? '').toString(),
      passengerId: (target['userId'] ?? target['id'] ?? '').toString(),
      message: text,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      _broadcastMsgController.clear();
      FocusScope.of(context).unfocus();
      setState(() => _messageTargetId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Message sent to $name.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      // Keep the typed text so nothing is lost when the send fails.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Could not send the message to $name.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendBroadcastMessage() async {
    final target = _messageTarget;
    if (target != null) {
      await _sendPassengerMessage(target);
      return;
    }
    final text = _broadcastMsgController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a message before sending.')),
      );
      return;
    }

    _broadcastMsgController.clear();
    FocusScope.of(context).unfocus();

    final res = await RideService.sendBroadcastMessage(
      rideId: _rideId,
      message: text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Message sent to all passengers.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

    TimeOfDay? _parseTimeString(String s) {
    try {
      final clean = s.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final match = RegExp(r'(\d+):(\d+)').firstMatch(clean);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        if (isPM && h < 12) h += 12;
        if (isAM && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return null;
  }

  void _evaluateOneHourLockStatus(Map<String, dynamic> data) {
    if (_isRideStarted) return;
    try {
      final dateStr = (data['departureDate'] ?? data['date'] ?? '').toString();
      final timeStr = (widget.departureTime ?? data['departureTime'] ?? data['time'] ?? '').toString();
      if (timeStr.isNotEmpty) {
        DateTime? scheduled;
        if (dateStr.isNotEmpty) {
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            final timeParts = _parseTimeString(timeStr);
            if (timeParts != null) {
              scheduled = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, timeParts.hour, timeParts.minute);
            }
          }
        }
        if (scheduled == null) {
          final now = DateTime.now();
          final timeParts = _parseTimeString(timeStr);
          if (timeParts != null) {
            scheduled = DateTime(now.year, now.month, now.day, timeParts.hour, timeParts.minute);
          }
        }

        if (scheduled != null) {
          final now = DateTime.now();
          final diffMinutes = scheduled.difference(now).inMinutes;
          if (diffMinutes > 60) {
            final unlockTime = scheduled.subtract(const Duration(hours: 1));
            final unlockFormatted = '${unlockTime.hour % 12 == 0 ? 12 : unlockTime.hour % 12}:${unlockTime.minute.toString().padLeft(2, '0')} ${unlockTime.hour >= 12 ? 'PM' : 'AM'}';
            _startRideStatus = StartRideLockStatus(
              canStartRide: false,
              isLocked: true,
              departureDateTime: scheduled.toIso8601String(),
              startRideAllowedFromFormatted: unlockFormatted,
              minutesRemainingUntilStart: diffMinutes - 60,
              hoursRemainingUntilStart: (diffMinutes - 60) / 60.0,
              lockReason: 'Ride cannot be started in advance. Starting will be enabled 1 hour before scheduled departure at $unlockFormatted.',
              buttonText: 'Ride Locked (Starts 1h before)',
            );
            return;
          } else if (!_startRideStatus.hasActiveRideConflict) {
            // Within 1 hour before scheduled departure or past departure -> unlock ride!
            _startRideStatus = StartRideLockStatus(
              canStartRide: true,
              isLocked: false,
              departureDateTime: scheduled.toIso8601String(),
              departureFormatted: _startRideStatus.departureFormatted,
              startRideAllowedFrom: _startRideStatus.startRideAllowedFrom,
              startRideAllowedFromFormatted: _startRideStatus.startRideAllowedFromFormatted,
              hoursRemainingUntilStart: 0,
              minutesRemainingUntilStart: 0,
              lockReason: '',
              buttonText: 'Start Ride 🚀',
              preTripAlertSent: _startRideStatus.preTripAlertSent,
              hasActiveRideConflict: false,
              conflictingRide: null,
            );
            return;
          }
        }
      }

      if (_startRideStatus.lockReason.contains('5 hour') ||
          _startRideStatus.lockReason.contains('5-hour') ||
          _startRideStatus.lockReason.contains('5h')) {
        _startRideStatus = StartRideLockStatus(
          canStartRide: _startRideStatus.canStartRide,
          isLocked: _startRideStatus.isLocked,
          departureDateTime: _startRideStatus.departureDateTime,
          departureFormatted: _startRideStatus.departureFormatted,
          startRideAllowedFrom: _startRideStatus.startRideAllowedFrom,
          startRideAllowedFromFormatted: _startRideStatus.startRideAllowedFromFormatted,
          hoursRemainingUntilStart: _startRideStatus.hoursRemainingUntilStart,
          minutesRemainingUntilStart: _startRideStatus.minutesRemainingUntilStart,
          lockReason: _startRideStatus.lockReason.replaceAll('5 hours', '1 hour').replaceAll('5-hour', '1-hour').replaceAll('5h', '1h'),
          buttonText: _startRideStatus.buttonText.replaceAll('5-Hour', '1-Hour').replaceAll('5h', '1h'),
          preTripAlertSent: _startRideStatus.preTripAlertSent,
          hasActiveRideConflict: _startRideStatus.hasActiveRideConflict,
          conflictingRide: _startRideStatus.conflictingRide,
        );
      }
    } catch (_) {}
  }

  void _showStartLockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Ride Start Locked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _startRideStatus.lockReason.isNotEmpty
                  ? _startRideStatus.lockReason
                  : 'Ride cannot be started in advance. Starting will be enabled 1 hour before scheduled departure.',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_startRideStatus.startRideAllowedFromFormatted.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Unlocks at: ${_startRideStatus.startRideAllowedFromFormatted}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startRide() async {
    if (!_isDriverOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please turn your status 'On' from the dashboard to start the ride.",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_isCompleted || _rideStatus == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This ride is already completed or cancelled.",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_startRideStatus.isLocked) {
      if (_startRideStatus.hasActiveRideConflict && _startRideStatus.conflictingRide != null) {
        await DriverConflictDialogs.showActiveRideAlreadyRunningModal(
          context,
          conflict: _startRideStatus.conflictingRide!,
          onSwitchToActiveTrip: () => _switchToActiveTrip(_startRideStatus.conflictingRide!.rideId),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You can only start the ride 1 hour before the scheduled ride time.",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      _showStartLockDialog();
      return;
    }
    await _launchNavigationDirectly();
  }

  void _switchToActiveTrip(String activeRideId) {
    if (activeRideId.isEmpty || activeRideId == _rideId) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRideStartDetailsScreen(
          rideId: activeRideId,
        ),
      ),
    );
  }

  Future<void> _launchNavigationDirectly() async {
    // 1. Call start-ride API
    Map<String, dynamic> apiRes = {};
    try {
      apiRes = await RideService.startRide(rideId: _rideId);
    } catch (e) {
      apiRes = {'success': false, 'message': e.toString()};
    }

    if (!mounted) return;

    // Check for API 4 Conflict (ACTIVE_RIDE_ALREADY_RUNNING)
    if (apiRes['statusCode'] == 409 ||
        apiRes['hasActiveRideConflict'] == true ||
        apiRes['error'] == 'ACTIVE_RIDE_ALREADY_RUNNING') {
      final conflict = apiRes['conflict'] is RideConflictResponse
          ? apiRes['conflict'] as RideConflictResponse
          : RideConflictResponse.fromJson(apiRes);

      setState(() {
        _startRideStatus = StartRideLockStatus.fromJson(apiRes);
      });

      await DriverConflictDialogs.showActiveRideAlreadyRunningModal(
        context,
        conflict: conflict.conflictingRide ?? const ConflictingRide(),
        onSwitchToActiveTrip: conflict.conflictingRide != null && conflict.conflictingRide!.rideId.isNotEmpty
            ? () => _switchToActiveTrip(conflict.conflictingRide!.rideId)
            : null,
      );
      return; // Guardrail: Do NOT start navigation or mark ride as started
    }

    // Check if locked due to 5-hour departure rule
    if (apiRes['isLocked'] == true) {
      setState(() {
        _startRideStatus = StartRideLockStatus.fromJson(apiRes);
      });
      _showStartLockDialog();
      return;
    }

    setState(() {
      _isRideStarted = true;
      _hasArrived = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride started successfully! 🚀'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );

    // 2. Navigate to Screen 91 (On Trip Seats & Navigation Screen)
    _navigateToOnTripSeatsScreen();
  }

  void _navigateToOnTripSeatsScreen() {
    final depTime = _stops.isNotEmpty ? _stops.first['time']?.toString() ?? '--' : '--';
    final arrTime = _stops.isNotEmpty ? _stops.last['time']?.toString() ?? '--' : '--';
    final dur = _candidateRoutes.isNotEmpty ? _candidateRoutes.first.duration : '02h 45 Mins';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverOnTripSeatsScreen(
          rideId: _rideId,
          origin: _origin.isNotEmpty ? _origin.split(',').first : 'Origin',
          destination: _destination.isNotEmpty ? _destination.split(',').first : 'Destination',
          departureTime: depTime,
          arrivalTime: arrTime,
          duration: dur,
          totalSeats: 4,
          bookedSeats: _passengers.length,
          passengerList: _passengers,
          routeTimeline: _stops,
        ),
      ),
    );
  }

  Future<void> _startGoogleMapsNavigation({bool force = false}) async {
    // Check if ride start is locked
    if (!force && _startRideStatus.isLocked) {
      _showStartLockDialog();
      return;
    }

    // 1. Call start-navigation API
    final apiRes = await RideService.startNavigation(
      rideId: _rideId,
      origin: _origin,
      destination: _destination,
    );

    if (!force && apiRes['isLocked'] == true) {
      if (mounted) {
        setState(() {
          _startRideStatus = StartRideLockStatus.fromJson(apiRes);
        });
        _showStartLockDialog();
      }
      return;
    }

    final navData = apiRes['navigation'] ?? {};
    final navIntentUrl = navData['googleMapsNavigationUrl'] ?? 'google.navigation:q=${Uri.encodeComponent(_destination)}&mode=d';
    final webUrl = navData['googleMapsWebUrl'] ?? 'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(_origin)}&destination=${Uri.encodeComponent(_destination)}&travelmode=driving';

    // 2. Launch Google Maps navigation
    try {
      final nativeUri = Uri.parse(navIntentUrl);
      final webUri = Uri.parse(webUrl);

      bool launched = false;
      try {
        launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening Google Maps navigation to $_destination...'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  String _formatRideDateDisplay({bool includeDistance = true}) {
    final data = widget.rideData ?? {};
    DateTime? rideDate;

    if (data['departs'] != null) {
      rideDate = DateTime.tryParse(data['departs'].toString());
    }
    if (rideDate == null && data['departureDate'] != null) {
      final parts = data['departureDate'].toString().split(RegExp(r'[\s\-/]+'));
      if (parts.length >= 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          rideDate = DateTime(y, m, d);
        }
      }
    }
    if (rideDate == null && data['date'] != null) {
      rideDate = DateTime.tryParse(data['date'].toString());
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = rideDate != null ? DateTime(rideDate.year, rideDate.month, rideDate.day) : today;

    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final weekdayName = weekdays[targetDate.weekday - 1];
    final monthName = months[targetDate.month - 1];
    final dayNum = targetDate.day;

    String dateLabel;
    if (targetDate.isAtSameMomentAs(today)) {
      dateLabel = '$weekdayName $dayNum $monthName (today)';
    } else if (targetDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dateLabel = '$weekdayName $dayNum $monthName (tomorrow)';
    } else {
      dateLabel = '$weekdayName $dayNum $monthName';
    }

    if (includeDistance && _totalDistance.isNotEmpty) {
      return '$dateLabel - $_totalDistance';
    }
    return dateLabel;
  }

  Future<void> _completeRide() async {
    if (!_isRideStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot complete this ride before starting it. Please tap "Start Ride" first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final res = await RideService.completeRide(rideId: _rideId);
    if (!mounted) return;
    setState(() {
      _isRideStarted = false;
      _isCompleted = true;
    });

    final summary = res['summary'] ?? {};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripCompletedSummaryScreen(
          rideId: _rideId,
          origin: _origin.split(',').first,
          destination: _destination.split(',').first,
          dateDisplay: _formatRideDateDisplay(includeDistance: false),
          fuelSaved: summary['formattedFuelShare'] ?? '--',
          paymentMode: summary['paymentMode']?.toString() ?? '--',
          coTravelers: '${summary['totalPassengersBoarded'] ?? _passengers.length}',
          summaryData: summary,
        ),
      ),
    );
  }

  Future<void> _notifyDriverArrived() async {
    try {
      final res = await RideService.driverArrivedAtPickup(rideId: _rideId);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _hasArrived = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Arrival notification sent to all passengers! 📍'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Failed to signal driver arrival.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }


  void _openShareTrip() {
    const totalSeats = 4;
    final List<Map<String, dynamic>> seatsList = [];
    for (int i = 0; i < totalSeats; i++) {
      final isBooked = i < _passengers.length;
      seatsList.add({
        'label': isBooked ? 'S-${i + 1} Booked' : 'Available',
        'isBooked': isBooked,
      });
    }

    final driverName = widget.rideData?['driver']?['name'] ??
        widget.rideData?['driverName'] ??
        'Driver';
    final driverCode = widget.rideData?['driver']?['driverCode'] ??
        '#${_rideId.length > 4 ? _rideId.substring(_rideId.length - 4) : _rideId}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverTripSharedScreen(
          // The card follows the ride: not started -> before ride, started -> during, done -> completed.
          stage: _isCompleted ? 'summary' : (_isRideStarted ? 'during_ride' : 'before_ride'),
          rideId: _rideId,
          routeTimeline: _stops,
          seatsAvailable: seatsList,
          fuelContribution: widget.rideData?['price'] != null ? '₹${widget.rideData!['price']}' : null,
          driverName: driverName,
          driverCode: driverCode,
          bookingSeatZaatraId: _rideId,
          nextPickup: {
            'location': _stops.length > 1 ? _stops[1]['station'] : _origin,
          },
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
        title: const Text(
          'Ride start',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 22),
            tooltip: 'Share Trip',
            onPressed: _openShareTrip,
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
                  // Date Header Pill matching 88.png
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _formatRideDateDisplay(includeDistance: true),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Waypoint Timeline matching 88.png
                  ...List.generate(_stops.length, (i) {
                    final stop = _stops[i];
                    final isStart = stop['isStart'] == true || stop['type'] == 'start' || i == 0;
                    final isLast = i == _stops.length - 1;

                    return _buildWaypointTile(
                      time: stop['time'] ?? '--',
                      station: stop['station'] ?? stop['location'] ?? '',
                      isStart: isStart,
                      isLast: isLast,
                    );
                  }),

                  const SizedBox(height: 24),

                  // Passenger Info Section matching 88.png
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Passenger info',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        _passengers.isEmpty
                            ? '0 Boarded'
                            : '${_passengers.where((p) => p['isBoarded'] == true).length}/${_passengers.length} Boarded',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_passengers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.people_outline_rounded, color: AppColors.textMuted, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'No passengers yet',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Booked passenger details will appear here once passengers join your ride.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: List.generate(_passengers.length, (index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: index < _passengers.length - 1 ? 14.0 : 0),
                            child: _buildPassengerCard(index),
                          );
                        }),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Message Input Box matching 88.png (compact: purple card + grey field only)
                  Container(
                    key: _messageCardKey,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_messageTarget != null) ...[
                          Container(
                            padding: const EdgeInsets.only(left: 10, right: 4, top: 2, bottom: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'To: ${_passengerLabel(_messageTarget!)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _messageTargetId = null),
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextField(
                          controller: _broadcastMsgController,
                          focusNode: _messageFocus,
                          minLines: 2,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Type here...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            filled: true,
                            fillColor: const Color(0xFFEFECF6),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                            ),
                            onPressed: _sendBroadcastMessage,
                            child: Text(
                              _messageTarget != null
                                  ? 'Message ${_passengerLabel(_messageTarget!)}'
                                  : 'Message all passengers',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Live Route Map Preview with Navigation overlay matching 88.png
                  RouteMapWebView(
                    pickup: _origin,
                    destination: _destination,
                    rideId: _rideId,
                    candidateRoutes: _candidateRoutes,
                    height: 220,
                    borderRadius: 18,
                    showNavigationOverlay: true,
                    onTap: _startGoogleMapsNavigation,
                  ),

                  const SizedBox(height: 20),

                  // 5-Hour Start Ride Lock Status Banner (if locked)
                  if (_startRideStatus.isLocked) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_clock_rounded, color: Colors.orange, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ride Start Locked (1-Hour Window)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _startRideStatus.startRideAllowedFromFormatted.isNotEmpty
                                      ? 'Unlocks: ${_startRideStatus.startRideAllowedFromFormatted}'
                                      : 'Available 1 hour prior to scheduled departure',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6D4C41)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 2. Share Trip Card Button
                  CustomButton(
                    text: 'Share Trip Card',
                    isOutlined: true,
                    backgroundColor: const Color(0xFFF3EDF7),
                    textColor: AppColors.primary,
                    onPressed: _openShareTrip,
                  ),

                  const SizedBox(height: 12),

                  if (_isCompleted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Ride Completed',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'View Trip Summary 📄',
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TripCompletedSummaryScreen(
                              rideId: _rideId,
                              origin: _origin.split(',').first,
                              destination: _destination.split(',').first,
                              dateDisplay: _formatRideDateDisplay(includeDistance: false),
                              fuelSaved: '--',
                              paymentMode: '--',
                              coTravelers: '',
                              summaryData: const {},
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // 3. Dynamic Start Ride / Resume Navigation Button
                    CustomButton(
                      text: _isRideStarted
                          ? 'Resume Navigation 🗺️'
                          : (!_isDriverOnline
                              ? 'Driver Offline (Turn ON Status)'
                              : (_startRideStatus.isLocked
                                  ? (_startRideStatus.buttonText.isNotEmpty
                                      ? _startRideStatus.buttonText
                                      : 'Ride Locked (Starts 1h before)')
                                  : 'Start Ride 🚀')),
                      backgroundColor: _isRideStarted
                          ? const Color(0xFF0288D1)
                          : (!_isDriverOnline || _startRideStatus.isLocked
                              ? const Color(0xFF9E9E9E)
                              : AppColors.primary),
                      textColor: Colors.white,
                      onPressed: _isRideStarted
                          ? _navigateToOnTripSeatsScreen
                          : _startRide,
                    ),

                    // 6. Complete Ride Button - Only shown when ride has been started!
                    if (_isRideStarted) ...[
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Complete Ride',
                        isOutlined: true,
                        backgroundColor: Colors.white,
                        textColor: AppColors.primary,
                        onPressed: _completeRide,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointTile({
    required String time,
    required String station,
    required bool isStart,
    required bool isLast,
  }) {
    return RouteTimelineTile(time: time, station: station, isStart: isStart, isLast: isLast);
  }

  Widget _buildPassengerCard(int index) {
    final passenger = _passengers[index];
    final isBoarded = passenger['isBoarded'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isBoarded ? Border.all(color: const Color(0xFF81C784), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                passenger['title'] ?? 'Passenger ${index + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              if (isBoarded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text(
                        'Boarded',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isBoarded ? const Color(0xFFE8F5E9) : const Color(0xFFF3EDF7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: isBoarded ? const Color(0xFF2E7D32) : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger['name'] ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passenger['route'] ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    Text(
                      passenger['time'] ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSmallButton(
                  'Message',
                  Icons.chat_bubble_outline_rounded,
                  const Color(0xFFFFF8E1),
                  const Color(0xFF8D6E63),
                  () => _selectMessageTarget(passenger),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSmallButton(
                  'Call',
                  Icons.phone_outlined,
                  (passenger['phone'] ?? '').toString().trim().isEmpty ? Colors.grey.shade100 : const Color(0xFFFFF8E1),
                  (passenger['phone'] ?? '').toString().trim().isEmpty ? Colors.grey.shade500 : const Color(0xFF8D6E63),
                  () => _callPassenger(passenger),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: isBoarded
                    ? _buildSmallButton(
                        'Verified ✓',
                        Icons.check_circle_rounded,
                        const Color(0xFFE8F5E9),
                        const Color(0xFF2E7D32),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${passenger['name']} is already verified and boarded.')),
                          );
                        },
                      )
                    : _buildSmallButton(
                        'Verify PIN',
                        _isRideStarted ? Icons.pin_rounded : Icons.lock_outline_rounded,
                        _isRideStarted ? const Color(0xFFFFF8E1) : Colors.grey.shade100,
                        _isRideStarted ? const Color(0xFF8D6E63) : Colors.grey.shade600,
                        () => _verifyPassengerPin(index),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(
    String label,
    IconData icon,
    Color bg,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}