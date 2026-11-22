import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place_location_model.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/google_maps_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/location_autocomplete_picker_modal.dart';
import '../../../widgets/route_map_webview.dart';
import 'driver_publish_ride_calendar_screen_92.dart';

// ─── Lightweight inline card controller ───────────────────────────────────────
class _StopCard {
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController priceCtrl;
  LocationPoint? resolvedLocation;

  _StopCard({int defaultPrice = 750})
      : priceCtrl = TextEditingController(text: defaultPrice.toString());

  void dispose() {
    locationCtrl.dispose();
    priceCtrl.dispose();
  }
}
// ──────────────────────────────────────────────────────────────────────────────

class DriverPostRideScreen extends StatefulWidget {
  const DriverPostRideScreen({super.key});

  @override
  State<DriverPostRideScreen> createState() => _DriverPostRideScreenState();
}

class _DriverPostRideScreenState extends State<DriverPostRideScreen> {
  LocationPoint _pickupLocation = const LocationPoint(
    name: 'Mangalagiri Road, Vijayawada',
    formattedAddress: 'Mangalagiri Road, Vijayawada, Andhra Pradesh, India',
    latitude: 16.4357,
    longitude: 80.5694,
  );

  LocationPoint _destLocation = const LocationPoint(
    name: 'Tirupati',
    formattedAddress: 'Tirupati, Andhra Pradesh, India',
    latitude: 13.6288,
    longitude: 79.4192,
  );

  RouteResult? _routeResult;
  bool _isLoadingRoute = false;
  TimeOfDay _departureTime = const TimeOfDay(hour: 6, minute: 0);

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Inline intermediate pickup stop cards
  final List<_StopCard> _stopCards = [];

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  @override
  void dispose() {
    for (final c in _stopCards) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Route fetching ──────────────────────────────────────────────────────────
  Future<void> _fetchDirections() async {
    setState(() => _isLoadingRoute = true);

    final fromQ = _pickupLocation.formattedAddress.isNotEmpty
        ? _pickupLocation.formattedAddress
        : _pickupLocation.name;
    final toQ = _destLocation.formattedAddress.isNotEmpty
        ? _destLocation.formattedAddress
        : _destLocation.name;

    try {
      RouteResult? result;
      if (_pickupLocation.latitude != 0.0 && _destLocation.latitude != 0.0) {
        result = await GoogleMapsService.getDirections(
          originLat: _pickupLocation.latitude,
          originLng: _pickupLocation.longitude,
          destLat: _destLocation.latitude,
          destLng: _destLocation.longitude,
        );
      }
      if (result == null || result.candidateRoutes.isEmpty) {
        result = await GoogleMapsService.getDirectionsByAddress(
          origin: fromQ,
          destination: toQ,
        );
      }
      if (mounted && result != null && result.candidateRoutes.isNotEmpty) {
        setState(() {
          _isLoadingRoute = false;
          _routeResult = result;
        });
        return;
      }
    } catch (_) {}

    // Backend fallback
    try {
      final res = await RideService.calculateRoute(from: fromQ, to: toQ);
      if (mounted && res['success'] == true) {
        final dist = res['distance']?.toString() ?? '330 KM';
        final dur = res['duration']?.toString() ?? '4 hours 30 mins';
        final poly = res['polyline']?.toString() ?? '';
        final parsed = RouteResult(
          distanceText: dist,
          distanceMeters: (res['distanceValue'] as num?)?.toInt() ?? 0,
          durationText: dur,
          durationSeconds: (res['durationValue'] as num?)?.toInt() ?? 0,
          overviewPolyline: poly,
          startAddress: fromQ,
          endAddress: toQ,
          candidateRoutes: [
            CandidateRoute(
              routeIndex: 0,
              summary: 'Main Route',
              name: 'Route 1',
              distanceText: dist,
              distanceMeters: (res['distanceValue'] as num?)?.toInt() ?? 0,
              durationText: dur,
              durationSeconds: (res['durationValue'] as num?)?.toInt() ?? 0,
              overviewPolyline: poly,
              isRecommended: true,
            ),
          ],
        );
        setState(() {
          _isLoadingRoute = false;
          _routeResult = parsed;
        });
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingRoute = false);
  }

  // ── Location pickers ────────────────────────────────────────────────────────
  Future<void> _selectPickup() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Pickup Location',
      initialQuery: _pickupLocation.name,
    );
    if (picked != null && mounted) {
      setState(() => _pickupLocation = picked);
      _fetchDirections();
    }
  }

  Future<void> _selectDestination() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Destination',
      initialQuery: _destLocation.name,
    );
    if (picked != null && mounted) {
      setState(() => _destLocation = picked);
      _fetchDirections();
    }
  }

  // ── Intermediate stop management ────────────────────────────────────────────
  void _addStop() {
    setState(() => _stopCards.add(_StopCard()));
  }

  void _removeStop(int index) {
    setState(() {
      _stopCards[index].dispose();
      _stopCards.removeAt(index);
    });
  }

  Future<void> _pickLocationForStop(int index) async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Intermediate Pickup',
      initialQuery: _stopCards[index].locationCtrl.text,
    );
    if (picked != null && mounted) {
      setState(() {
        _stopCards[index].locationCtrl.text = picked.name;
        _stopCards[index].resolvedLocation = picked;
      });

      // Query backend for intermediate fares directly via POST /api/rides/calculate-intermediate-fares
      final activeCards = _stopCards.where((c) => c.locationCtrl.text.trim().isNotEmpty).toList();
      if (activeCards.isNotEmpty) {
        final fromText = _pickupLocation.formattedAddress.isNotEmpty
            ? _pickupLocation.formattedAddress
            : _pickupLocation.name;
        final toText = _destLocation.formattedAddress.isNotEmpty
            ? _destLocation.formattedAddress
            : _destLocation.name;

        final stopsPayload = activeCards.map((c) => {
          'location': c.locationCtrl.text.trim(),
          'name': c.locationCtrl.text.trim(),
          'latitude': c.resolvedLocation?.latitude ?? 0.0,
          'longitude': c.resolvedLocation?.longitude ?? 0.0,
        }).toList();

        try {
          final res = await RideService.calculateIntermediateFares(
            pickupLocation: fromText.isNotEmpty ? fromText : 'Origin',
            destinationLocation: toText.isNotEmpty ? toText : 'Destination',
            departureTime: _formatTimeOfDay(_departureTime),
            ratePerKm: 10,
            seats: 3,
            intermediatePickups: stopsPayload,
          );
          if (res['success'] == true && mounted) {
            final faresList = RideService.extractIntermediateFares(res);
            if (faresList.isNotEmpty) {
              setState(() {
                for (int i = 0; i < activeCards.length; i++) {
                  final card = activeCards[i];
                  Map<String, dynamic>? match;
                  final foundIdx = faresList.indexWhere((f) =>
                      (f['location'] ?? f['name'] ?? '').toString().trim().toLowerCase() ==
                      card.locationCtrl.text.trim().toLowerCase());
                  if (foundIdx >= 0) {
                    match = faresList[foundIdx];
                  } else if (i < faresList.length) {
                    match = faresList[i];
                  }
                  if (match != null) {
                    final rawP = match['price'] ?? match['fare'] ?? match['recommendedFare'] ?? match['farePerSeat'];
                    if (rawP != null) {
                      card.priceCtrl.text = rawP.toString();
                    }
                  }
                }
              });
            }
          }
        } catch (_) {}
      }
    }
  }

  // ── Route plan timeline ─────────────────────────────────────────────────────
  List<Map<String, String>> _buildRoutePlan() {
    final plan = <Map<String, String>>[];
    plan.add({'time': _formatTimeOfDay(_departureTime), 'location': _pickupLocation.name, 'type': 'start'});

    int hour = 6, minute = 45;
    for (final card in _stopCards) {
      final loc = card.locationCtrl.text.trim();
      if (loc.isEmpty) continue;
      final timeStr =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} AM';
      plan.add({'time': timeStr, 'location': loc, 'type': 'pickup'});
      minute += 45;
      if (minute >= 60) {
        hour++;
        minute -= 60;
      }
    }

    final activeCandidate = (_routeResult != null &&
            _routeResult!.candidateRoutes.isNotEmpty)
        ? _routeResult!.candidateRoutes[0]
        : null;
    final durSec =
        activeCandidate?.durationSeconds ?? _routeResult?.durationSeconds ?? (4 * 3600 + 30 * 60);
    final totalMin = (durSec / 60).round();
    final arrivalHour = (6 + (totalMin ~/ 60)) % 24;
    final arrivalMin = totalMin % 60;
    final ampm = arrivalHour >= 12 ? 'PM' : 'AM';
    final displayHour =
        arrivalHour > 12 ? (arrivalHour - 12) : (arrivalHour == 0 ? 12 : arrivalHour);
    final arrivalTime =
        '${displayHour.toString().padLeft(2, '0')}:${arrivalMin.toString().padLeft(2, '0')} $ampm';

    plan.add({'time': arrivalTime, 'location': _destLocation.name, 'type': 'destination'});
    return plan;
  }

  // ── Next button ─────────────────────────────────────────────────────────────
  void _handleNext() {
    final routePlan = _buildRoutePlan();

    final dynamicIntermediatePickups = _stopCards
        .where((c) => c.locationCtrl.text.trim().isNotEmpty)
        .map((c) => {
              'location': c.locationCtrl.text.trim(),
              'price': int.tryParse(c.priceCtrl.text.trim()) ?? 0,
              'pincode': c.resolvedLocation?.postalCode ?? '',
              'landmark': '',
              'time': '',
            })
        .toList();

    final activeCandidate = (_routeResult != null &&
            _routeResult!.candidateRoutes.isNotEmpty)
        ? _routeResult!.candidateRoutes[0]
        : null;

    final rideDetails = <String, dynamic>{
      'from': _pickupLocation.formattedAddress,
      'pickupLocation': _pickupLocation.name,
      'pickupLat': _pickupLocation.latitude,
      'pickupLng': _pickupLocation.longitude,
      'to': _destLocation.formattedAddress,
      'destinationLocation': _destLocation.name,
      'destLat': _destLocation.latitude,
      'destLng': _destLocation.longitude,
      'duration': activeCandidate?.durationText ?? _routeResult?.durationText ?? '4 hours 30 mins',
      'distance': activeCandidate?.distanceText ?? _routeResult?.distanceText ?? '330 KM',
      'polyline': activeCandidate?.overviewPolyline ?? _routeResult?.overviewPolyline ?? '',
      'routeName': activeCandidate?.name ?? 'Route',
      'selectedCities':
          _stopCards.map((c) => c.locationCtrl.text.trim()).where((s) => s.isNotEmpty).toList(),
      'intermediatePickups': dynamicIntermediatePickups,
      'routePlan': routePlan,
      'price': 850,
      'pricePerSeat': 850,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverPublishRideCalendarScreen(rideDetails: rideDetails),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final routePlan = _buildRoutePlan();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post Ride',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                  // Pickup
                  InkWell(
                    onTap: _selectPickup,
                    borderRadius: BorderRadius.circular(14),
                    child: _buildLocationBox(
                      'Pickup location',
                      _pickupLocation.formattedAddress.isNotEmpty
                          ? _pickupLocation.formattedAddress
                          : _pickupLocation.name,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Destination
                  InkWell(
                    onTap: _selectDestination,
                    borderRadius: BorderRadius.circular(14),
                    child: _buildLocationBox(
                      'Destination',
                      _destLocation.formattedAddress.isNotEmpty
                          ? _destLocation.formattedAddress
                          : _destLocation.name,
                      const Color(0xFFE53935),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Route Map (single route, no selector UI)
                  RouteMapWebView(
                    pickup: _pickupLocation.name,
                    destination: _destLocation.name,
                    pickupPoint: _pickupLocation,
                    destPoint: _destLocation,
                    candidateRoutes: _routeResult?.candidateRoutes ?? const [],
                    height: 220,
                    borderRadius: 18,
                    interactive: true,
                    selectedRouteIndex: 0,
                    onRouteSelected: null,
                  ),

                  const SizedBox(height: 20),

                  // ── Intermediate Pickup Points ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Intermediate Pickup Points',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: AppColors.textPrimary),
                      ),
                      if (_isLoadingRoute)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stop cards
                  ...List.generate(_stopCards.length, (i) => _buildStopCard(i)),

                  // Add button
                  InkWell(
                    onTap: _addStop,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '+ Add Intermediate Pickup',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Route Plan ──────────────────────────────────────────────
                  const Text(
                    'Route Plan',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),

                  ...List.generate(routePlan.length, (i) {
                    final item = routePlan[i];
                    final isEnd = i == routePlan.length - 1;
                    return Column(
                      children: [
                        _buildWaypointItem(
                          item['time'] ?? '',
                          item['location'] ?? '',
                          isStart: i == 0,
                        ),
                        if (!isEnd) _buildTimelineLine(),
                      ],
                    );
                  }),

                  const SizedBox(height: 32),

                  CustomButton(text: 'Next', onPressed: _handleNext, fontWeight: FontWeight.normal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildStopCard(int index) {
    final card = _stopCards[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Stop ${index + 1}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeStop(index),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Location row
          GestureDetector(
            onTap: () => _pickLocationForStop(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.locationCtrl.text.isNotEmpty
                          ? card.locationCtrl.text
                          : 'Search pickup location...',
                      style: TextStyle(
                        fontSize: 14,
                        color: card.locationCtrl.text.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.search_rounded,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Price row
          Row(
            children: [
              const Icon(Icons.currency_rupee_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text('Price per stop:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: card.priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBox(String label, String address, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildWaypointItem(String time, String station, {bool isStart = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(time,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 10),
        isStart
            ? const Icon(Icons.directions_car_rounded,
                color: Colors.redAccent, size: 18)
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                ),
              ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            station,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 74),
      child: Container(
        height: 16,
        width: 2,
        color: AppColors.border,
      ),
    );
  }
}