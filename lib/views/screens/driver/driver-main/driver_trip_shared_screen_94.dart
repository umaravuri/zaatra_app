import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../../services/trip_card_share.dart';
import '../../../widgets/trip_share_card.dart';
import '../../../widgets/route_timeline_tile.dart';
import '../../../../services/trip_stage.dart';
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
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  bool _isSharing = false;
  // Unknown until the driver's profile / the API provides them: never invented,
  // because they end up on the card that is shared with other people.
  String _driverRating = '';
  String _vehicleModel = '';
  String _vehiclePlate = '';

  String get _vehicleLine =>
      [_vehicleModel, _vehiclePlate].where((e) => e.trim().isNotEmpty).join(' · ');

  /// Stage from the ride's real status when the caller did not pass one.
  static String _inferStage(Map<String, dynamic>? data) =>
      TripStage.fromData(data) ?? TripStage.beforeRide;

  @override
  void initState() {
    super.initState();
    _currentStage = widget.stage ?? _inferStage(widget.tripData);
    _data = widget.tripData ?? {};
    _rideId = (widget.rideId ?? _data?['rideId'] ?? _data?['id'] ?? '').toString();
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
      _fuel = '';
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
        '';
    _bookingId = widget.bookingSeatZaatraId ?? _data?['tripDetails']?['bookingSeatZaatraId'] ?? (_rideId ?? '');
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
      final savedRating = prefs.getString('driver_rating') ?? '';
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
            'category': 'Zaatra Go',
            'categoryTitle': 'Zaatra Go',
            'vehicleSpecs': _vehicleLine,
            'vehicleModel': _vehicleModel,
            'vehicleNumberPlate': _vehiclePlate,
            'driverName': _driver,
            'driverRole': 'Driver',
            'driverRating': double.tryParse(_driverRating) ?? 0.0,
            'driverRatingDisplay': _driverRating.isEmpty ? 'Driver' : 'Driver · ★ $_driverRating',
          };
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _buildTimelineFromData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return <Map<String, dynamic>>[];

    if (data['routeTimeline'] is List && (data['routeTimeline'] as List).isNotEmpty) {
      return List<Map<String, dynamic>>.from(data['routeTimeline']);
    }

    final origin = data['pickupLocation'] ?? data['origin'] ?? data['pickup'] ?? data['from'] ?? '';
    final dest = data['destination'] ?? data['dropLocation'] ?? data['drop'] ?? data['to'] ?? '';
    final startTime = data['time'] ?? data['departureTime'] ?? data['startTime'] ?? '';

    if (origin.toString().isNotEmpty || dest.toString().isNotEmpty) {
      final stopsList = <Map<String, dynamic>>[];
      stopsList.add({
        'index': 0,
        'time': startTime.toString().split(' ')[0],
        'timeRaw': startTime.toString(),
        'location': origin.toString(),
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
        'location': dest.toString(),
        'isDestination': true,
        'type': 'destination',
        'icon': 'destination',
      });
      return stopsList;
    }

    return <Map<String, dynamic>>[];
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
    return <Map<String, dynamic>>[];
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

  Future<void> _loadTripCard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final rId = _rideId ?? '';
      final Map<String, dynamic> res = rId.isEmpty
          ? <String, dynamic>{'success': false}
          : await RideService.getTripSharedMaster(rideId: rId, stage: _currentStage);

      if (mounted && res['success'] == true) {
        setState(() {
          // The ride's real status decides the card when the caller gave no stage.
          final apiStage = TripStage.fromData(res);
          if (widget.stage == null && apiStage != null) {
            _currentStage = apiStage;
          }
          _screenTitle = (res['screenTitle'] ?? _getStageTitle(_currentStage)).toString();
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
        if (rId.isNotEmpty) {
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
      // Only real data: nothing is invented when the ride gave us none.
      if (_timeline.isEmpty) {
        _timeline = _buildTimelineFromData(_data);
      }
      if (_seats.isEmpty) {
        _seats = _buildSeatsFromData(_data, stage);
      }
    });
  }

  Future<void> _handleShareTripAgain() async {
    final rId = _rideId ?? '';
    setState(() => _isLoading = true);
    final Map<String, dynamic> res =
        rId.isEmpty ? <String, dynamic>{} : await RideService.shareTripAgain(rideId: rId);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final shareUrl = (res['shareUrl'] ?? _shareUrl()).toString();
    final shareText = (res['shareText'] ?? _buildShareText(_buildShareCardData(), shareUrl)).toString();

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

  String _shareUrl() => TripCardShare.urlFor(_rideId);

  /// Builds the data for the purple trip card from what this screen already holds.
  /// Anything unknown is left empty so the card omits it.
  TripShareCardData _buildShareCardData() {
    var eta = (_statusCard?['estimateArrival']?['time'] ?? _data?['arrivalTime'] ?? '').toString();
    final status = TripCardShare.statusForStage(_currentStage);
    return TripCardShare.buildData(
      driverName: _driver,
      vehicleLine: _vehicleLine,
      rating: _driverRating,
      timeline: _timeline,
      seats: _seats,
      estimatedArrival: eta,
      statusLabel: status.label,
      statusColor: status.color,
    );
  }

  String _buildShareText(TripShareCardData d, String url) => TripCardShare.buildText(d, url);

  /// Shares the purple "Trip Shared" card as an image (not the on-screen page).
  Future<void> _handleCaptureAndShare() async {
    if (_isSharing) return;
    _isSharing = true;

    final data = _buildShareCardData();
    final shareUrl = _shareUrl();
    ScaffoldMessenger.of(context).showSnackBar(
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
        text: _buildShareText(data, shareUrl),
        fallbackUrl: shareUrl,
      );
    } finally {
      _isSharing = false;
    }

    if (!mounted) return;
    if (res['success'] != true || res['isWeb'] == true) {
      _handleShareTripAgain();
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

  /// Route timeline rows built from real stops only (stops without a place name
  /// are skipped). Shows a short note when the route is not known.
  List<Widget> _timelineSection() {
    final stops = _timeline
        .where((e) => (e['location'] ?? e['station'] ?? e['address'] ?? '').toString().trim().isNotEmpty)
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
          time: (stops[i]['time'] ?? stops[i]['timeRaw'] ?? '').toString(),
          station: (stops[i]['location'] ?? stops[i]['station'] ?? stops[i]['address']).toString(),
          isStart: i == 0,
          isLast: i == stops.length - 1,
        ),
    ];
  }

  String get _driverInfoText {
    final name = _driver == 'Driver' ? '' : _driver;
    final parts = <String>[
      if (name.isNotEmpty) name,
      if (_code.trim().isNotEmpty) 'driver code $_code',
    ];
    return parts.join(' - ');
  }

  /// "<date>, <time>" from the ride data, or '' when unknown.
  String get _scheduleText {
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = (_data?[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final date = pick(['departureDate', 'date', 'scheduledDate', 'departs']);
    final time = pick(['departureTime', 'time', 'startTime']);
    return [date, time].where((e) => e.isNotEmpty).join(', ');
  }

  Future<void> _callPhone(String? raw) async {
    final number = (raw ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available.')),
      );
      return;
    }
    try {
      final ok = await launchUrl(Uri(scheme: 'tel', path: number), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
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
        ..._timelineSection(),

        const SizedBox(height: 24),

        if (_seats.isNotEmpty) ...[
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

        ],

        // Trip info rows: each one only when its value is known
        if (_driverInfoText.isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            iconBg: const Color(0xFFF3EDF7),
            iconColor: AppColors.primary,
            text: _driverInfoText,
          ),
          const SizedBox(height: 16),
        ],
        if (_scheduleText.isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFF3EDF7),
            iconColor: AppColors.primary,
            text: 'Date & Time : $_scheduleText',
          ),
          const SizedBox(height: 16),
        ],
        if (_vehicleLine.isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.directions_car_outlined,
            iconBg: const Color(0xFFF3EDF7),
            iconColor: AppColors.primary,
            text: _vehicleLine,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ==========================================
  // STAGE 2: DURING RIDE (Screenshot 2)
  // ==========================================
  Widget _buildDuringRideContent() {
    // Only a real next pickup is shown; nothing is invented when there is none.
    final Map<String, dynamic> np = Map<String, dynamic>.from(
        (_nextPickup ?? _pickupProgression?['nextPickup'] ?? const <String, dynamic>{}) as Map);
    final npName = (np['passengerName'] ?? '').toString();
    final npLocation = (np['location'] ?? '').toString();
    final npSeat = (np['seatNumber'] ?? '').toString();
    final npPhone = (np['phone'] ?? np['passengerPhone'] ?? np['mobile'] ?? '').toString();
    final hasNextPickup = npName.isNotEmpty || npLocation.isNotEmpty;
    final npDetail = [
      if (npLocation.isNotEmpty) npLocation,
      if ((np['eta'] ?? '').toString().isNotEmpty) 'ETA ${np['eta']}',
      if ((np['distanceRemaining'] ?? '').toString().isNotEmpty) '(${np['distanceRemaining']})',
    ].join(' · ');
    final progText = (_pickupProgression?['progressText'] ??
            (hasNextPickup
                ? 'Next pickup: ${npName.isNotEmpty ? npName : 'passenger'}${npLocation.isNotEmpty ? ' at $npLocation' : ''}.'
                : ''))
        .toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route Timeline
        ..._timelineSection(),

        const SizedBox(height: 20),

        if (progText.isNotEmpty) ...[
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
        ],

        if (hasNextPickup) ...[
          // Next Pickup Highlight Card (the passenger's boarding PIN is intentionally not shown here)
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
                  children: [
                    if (npSeat.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9D8FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          npSeat,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'Next Pickup',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                          if (npName.isNotEmpty)
                            Text(
                              npName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          if (npDetail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              npDetail,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.phone_in_talk_rounded,
                        color: npPhone.isEmpty ? Colors.grey.shade400 : AppColors.primary,
                      ),
                      onPressed: () => _callPhone(npPhone),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (_seats.isNotEmpty) ...[
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

        ],

        // Trip Info (only when known)
        if (_driverInfoText.isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            iconBg: const Color(0xFFF3EDF7),
            iconColor: AppColors.primary,
            text: _driverInfoText,
          ),
        ],

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
                  nextPickupLocation: _nextPickup?['location']?.toString(),
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
      'category': 'Zaatra Go',
      'vehicleSpecs': _vehicleLine,
      'driverName': _driver,
      'driverRatingDisplay': _driverRating.isEmpty ? 'Driver' : 'Driver · ★ $_driverRating',
    };
    final sc = _statusCard ?? {};
    final etaTime = (sc['estimateArrival']?['time'] ?? _data?['arrivalTime'] ?? '').toString();
    final tripStatus = sc['tripStatus']?['value'] ?? (_currentStage == 'during_ride' ? 'On The Way' : (_currentStage == 'summary' ? 'Completed' : 'Seats Open'));
    final bookedCount = _seats.where((s) => s['isBooked'] == true).length;
    final coTravelers = _totalPassenger?['count'] ?? bookedCount;

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
                    hero['category'] ?? 'Zaatra Go',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hero['vehicleSpecs'] ?? _vehicleLine,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hero['driverName'] ?? _driver,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      children: [
                        const TextSpan(text: 'Driver'),
                        if (_driverRating.isNotEmpty)
                          TextSpan(text: ' · ★ $_driverRating', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
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
        ..._timelineSection(),

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
              if (etaTime.isNotEmpty)
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
    return RouteTimelineTile(time: time, station: station, isStart: isStart, isLast: isLast);
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