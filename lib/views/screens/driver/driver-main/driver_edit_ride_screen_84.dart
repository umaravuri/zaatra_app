import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place_location_model.dart';
import '../../../../services/google_maps_service.dart';
import '../../../../services/driver_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/driver_cancel_ride_dialog.dart';
import '../../../widgets/location_autocomplete_picker_modal.dart';
import '../../../widgets/route_map_webview.dart';

class DriverEditRideScreen extends StatefulWidget {
  final Map<String, dynamic>? rideData;
  final String? rideId;

  const DriverEditRideScreen({
    super.key,
    this.rideData,
    this.rideId,
  });

  @override
  State<DriverEditRideScreen> createState() => _DriverEditRideScreenState();
}

class _EditStopCard {
  final TextEditingController locationCtrl;
  final TextEditingController priceCtrl;
  LocationPoint? resolvedLocation;
  String time;
  String pincode;

  _EditStopCard({
    String location = '',
    int price = 0,
    this.resolvedLocation,
    this.time = '',
    this.pincode = '',
  })  : locationCtrl = TextEditingController(text: location),
        priceCtrl = TextEditingController(text: price > 0 ? price.toString() : '');

  void dispose() {
    locationCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _EditCustomPrefItem {
  final TextEditingController controller;
  bool enabled;
  final String category; // 'customer' or 'feature'

  _EditCustomPrefItem({
    String title = '',
    this.enabled = true,
    required this.category,
  }) : controller = TextEditingController(text: title);

  void dispose() {
    controller.dispose();
  }
}

class _DriverEditRideScreenState extends State<DriverEditRideScreen> {
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  late TextEditingController _priceController;

  final List<_EditStopCard> _stopCards = [];

  late int _price;
  late int _seats;
  int _bookedSeats = 0;
  late int _luggage;

  late DateTime _departureDate;
  late TimeOfDay _departureTime;

  // Departure as loaded from the ride, so save only rejects a past time the
  // driver newly chose (an untouched, already-departed time is left alone).
  late DateTime _originalDeparture;

  // Preferences
  bool _autoApproval = true;
  bool _smokingAllowed = false;
  bool _ac = true;
  bool _usb = true;
  bool _doorstepPickupDrop = true;
  final List<_EditCustomPrefItem> _customCustomerPrefs = [];
  final List<_EditCustomPrefItem> _customFeaturePrefs = [];

  // Live Google Route & Alternatives State
  late LocationPoint _pickupLocation;
  late LocationPoint _destinationLocation;
  RouteResult? _routeResult;
  bool _isLoadingRoute = false;
  int _selectedRouteIndex = 0;
  List<String> _routes = [];

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final ride = widget.rideData ?? {};

    // Price
    final rawPrice = ride['price'] ?? ride['pricePerSeat'] ?? 0;
    _price = int.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    _priceController = TextEditingController(text: _price > 0 ? '$_price' : '');

    // Seats & Luggage
    _seats = int.tryParse((ride['seats'] ?? 1).toString()) ?? 1;
    _bookedSeats = int.tryParse((ride['booked'] ?? ride['bookedSeats'] ?? ride['seatsBooked'] ?? 0).toString()) ?? 0;
    _luggage = int.tryParse((ride['maxLuggagePerPassenger'] ?? ride['luggageCount'] ?? 0).toString()) ?? 0;

    // Route / Address controllers
    final from = (ride['from'] ?? ride['pickupLocation'] ?? '').toString();
    final to = (ride['to'] ?? ride['destinationLocation'] ?? '').toString();

    _pickupController = TextEditingController(text: from);
    _destinationController = TextEditingController(text: to);

    // Initialize existing intermediate pickups if present
    final rawPickups = ride['intermediatePickups'] ?? ride['intermediateStops'] ?? ride['stops'];
    if (rawPickups is List) {
      for (final p in rawPickups) {
        if (p is Map) {
          final loc = (p['location'] ?? p['name'] ?? p['address'] ?? '').toString();
          final priceVal = int.tryParse((p['price'] ?? p['fare'] ?? p['priceToDestination'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final timeVal = (p['time'] ?? p['calculatedTime'] ?? '').toString();
          final pinVal = (p['pincode'] ?? '').toString();
          if (loc.isNotEmpty) {
            _stopCards.add(_EditStopCard(
              location: loc,
              price: priceVal,
              time: timeVal,
              pincode: pinVal,
            ));
          }
        }
      }
    }

    // Initial LocationPoint coordinates
    double parseCoordinate(dynamic v1, dynamic v2, dynamic v3) {
      final v = v1 ?? v2 ?? v3;
      if (v is num) return v.toDouble();
      if (v != null) return double.tryParse(v.toString()) ?? 0.0;
      return 0.0;
    }

    final double pickupLat = parseCoordinate(ride['pickupLat'], ride['pickupLatitude'], ride['originLat']);
    final double pickupLng = parseCoordinate(ride['pickupLng'], ride['pickupLongitude'], ride['originLng']);
    final double destLat = parseCoordinate(ride['destLat'], ride['destinationLat'], ride['destinationLatitude']);
    final double destLng = parseCoordinate(ride['destLng'], ride['destinationLng'], ride['destinationLongitude']);

    _pickupLocation = LocationPoint(
      name: from,
      formattedAddress: from,
      latitude: pickupLat,
      longitude: pickupLng,
    );
    _destinationLocation = LocationPoint(
      name: to,
      formattedAddress: to,
      latitude: destLat,
      longitude: destLng,
    );

    // Initial route index
    _selectedRouteIndex = (ride['selectedRouteIndex'] is num)
        ? (ride['selectedRouteIndex'] as num).toInt()
        : (int.tryParse(ride['selectedRouteIndex']?.toString() ?? '') ?? 0);

    // Seed route result if available in rideData
    final initialPoly = (ride['overviewPolyline'] ?? ride['polyline'] ?? '').toString();
    final initialDur = (ride['duration'] ?? '').toString();
    final initialDist = (ride['distance'] ?? '').toString();
    final initialRouteName = (ride['routeName'] ?? 'Route').toString();

    if (initialPoly.isNotEmpty) {
      final initialCandidate = CandidateRoute(
        routeIndex: 0,
        summary: initialRouteName,
        name: initialRouteName,
        distanceText: initialDist,
        distanceMeters: 0,
        durationText: initialDur,
        durationSeconds: 0,
        overviewPolyline: initialPoly,
        isRecommended: true,
      );
      _routeResult = RouteResult(
        distanceText: initialDist,
        distanceMeters: 0,
        durationText: initialDur,
        durationSeconds: 0,
        overviewPolyline: initialPoly,
        startAddress: from,
        endAddress: to,
        candidateRoutes: [initialCandidate],
      );
      _routes = ['$initialDur - initialRouteName)'];
    }

    _fetchDirections();

    // Parse Departure Date
    _departureDate = _parseRideDateTime(ride) ?? DateTime.now().add(const Duration(days: 1));

    // Parse Departure Time
    _departureTime = _parseRideTimeOfDay(ride['departureTime']?.toString() ?? '09:00 AM');
    _originalDeparture = DateTime(
      _departureDate.year,
      _departureDate.month,
      _departureDate.day,
      _departureTime.hour,
      _departureTime.minute,
    );

    // Initial Preferences from ride data
    if (ride['preferences'] is Map) {
      final p = ride['preferences'] as Map;
      _autoApproval = p['autoApproval'] ?? p['auto_approval'] ?? _autoApproval;
      _smokingAllowed = p['smokingAllowed'] ?? p['smoking'] ?? _smokingAllowed;
      _doorstepPickupDrop = p['doorstepPickupDrop'] ?? p['doorstep_pickup_drop'] ?? _doorstepPickupDrop;
      _ac = p['ac'] ?? p['airConditioning'] ?? _ac;
      _usb = p['usbCharging'] ?? p['usb_charging'] ?? p['usb'] ?? _usb;

      if (p['customCustomerPreferences'] is List) {
        for (final item in p['customCustomerPreferences'] as List) {
          if (item is Map) {
            final title = item['title']?.toString() ?? item['label']?.toString() ?? '';
            if (title.isNotEmpty) {
              _customCustomerPrefs.add(_EditCustomPrefItem(
                title: title,
                enabled: item['enabled'] == true,
                category: 'customer',
              ));
            }
          }
        }
      }

      if (p['customRideFeatures'] is List) {
        for (final item in p['customRideFeatures'] as List) {
          if (item is Map) {
            final title = item['title']?.toString() ?? item['label']?.toString() ?? '';
            if (title.isNotEmpty) {
              _customFeaturePrefs.add(_EditCustomPrefItem(
                title: title,
                enabled: item['enabled'] == true,
                category: 'feature',
              ));
            }
          }
        }
      }

      if (p['customPreferences'] is List) {
        for (final item in p['customPreferences'] as List) {
          if (item is Map) {
            final title = item['title']?.toString() ?? item['label']?.toString() ?? '';
            final cat = item['category']?.toString().toLowerCase() ?? 'customer';
            if (title.isNotEmpty) {
              final existsInCustomer = _customCustomerPrefs.any((c) => c.controller.text == title);
              final existsInFeature = _customFeaturePrefs.any((f) => f.controller.text == title);
              if (!existsInCustomer && !existsInFeature) {
                if (cat == 'feature' || cat == 'ride_feature') {
                  _customFeaturePrefs.add(_EditCustomPrefItem(
                    title: title,
                    enabled: item['enabled'] == true,
                    category: 'feature',
                  ));
                } else {
                  _customCustomerPrefs.add(_EditCustomPrefItem(
                    title: title,
                    enabled: item['enabled'] == true,
                    category: 'customer',
                  ));
                }
              }
            }
          }
        }
      }
    }

    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('driver_pref_save_enabled') && prefs.getBool('driver_pref_save_enabled') == true) {
        if (!mounted) return;
        setState(() {
          if (widget.rideData?['preferences'] == null) {
            _autoApproval = prefs.getBool('driver_pref_auto_approval') ?? _autoApproval;
            _smokingAllowed = prefs.getBool('driver_pref_smoking_allowed') ?? _smokingAllowed;
            _doorstepPickupDrop = prefs.getBool('driver_pref_doorstep_pickup_drop') ?? _doorstepPickupDrop;
            _ac = prefs.getBool('driver_pref_ac') ?? _ac;
            _usb = prefs.getBool('driver_pref_usb_charging') ?? _usb;
          }

          // Restore saved custom customer preferences
          final custStr = prefs.getString('driver_pref_custom_customer_list') ?? prefs.getString('driver_pref_custom_driver_list');
          if (custStr != null && custStr.isNotEmpty) {
            final decoded = jsonDecode(custStr);
            if (decoded is List) {
              for (final item in decoded) {
                if (item is Map) {
                  final title = item['title']?.toString() ?? item['label']?.toString() ?? '';
                  if (title.isNotEmpty && !_customCustomerPrefs.any((c) => c.controller.text == title)) {
                    _customCustomerPrefs.add(_EditCustomPrefItem(
                      title: title,
                      enabled: item['enabled'] == true,
                      category: 'customer',
                    ));
                  }
                }
              }
            }
          }

          // Restore saved custom ride features
          final featStr = prefs.getString('driver_pref_custom_features_list');
          if (featStr != null && featStr.isNotEmpty) {
            final decoded = jsonDecode(featStr);
            if (decoded is List) {
              for (final item in decoded) {
                if (item is Map) {
                  final title = item['title']?.toString() ?? item['label']?.toString() ?? '';
                  if (title.isNotEmpty && !_customFeaturePrefs.any((f) => f.controller.text == title)) {
                    _customFeaturePrefs.add(_EditCustomPrefItem(
                      title: title,
                      enabled: item['enabled'] == true,
                      category: 'feature',
                    ));
                  }
                }
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  DateTime? _parseRideDateTime(Map<String, dynamic> ride) {
    final val = ride['departs'] ?? ride['departureDate'] ?? ride['date'] ?? ride['scheduledDate'] ?? ride['createdAt'];
    if (val == null) return null;
    if (val is DateTime) return val.toLocal();

    final str = val.toString().trim();
    if (str.isEmpty) return null;

    final isoParsed = DateTime.tryParse(str);
    if (isoParsed != null) return isoParsed.toLocal();

    final numbers = RegExp(r'(\d+)').allMatches(str).map((m) => int.tryParse(m.group(0)!)).whereType<int>().toList();
    if (numbers.length >= 3) {
      if (numbers[0] > 1000) {
        return DateTime(numbers[0], numbers[1], numbers[2]);
      }
      if (numbers[2] > 1000) {
        return DateTime(numbers[2], numbers[1], numbers[0]);
      }
    }
    return null;
  }

  TimeOfDay _parseRideTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');

      final parts = clean.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      if (parts.isNotEmpty) {
        int hour = int.tryParse(parts[0]) ?? 9;
        int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatDateDisplay(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '${dt.day.toString().padLeft(2, '0')} $monthName, ${dt.year} ( $dayName )';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    for (var card in _stopCards) {
      card.dispose();
    }
    for (var item in _customCustomerPrefs) {
      item.dispose();
    }
    for (var item in _customFeaturePrefs) {
      item.dispose();
    }
    super.dispose();
  }

  // Intermediate Stop Management
  Future<void> _addStop() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Intermediate Pickup',
    );
    if (picked != null && mounted) {
      setState(() {
        _stopCards.add(_EditStopCard(
          location: picked.name,
          resolvedLocation: picked,
          pincode: '',
        ));
      });
      _recalculatePricingAndFares();
    }
  }

  void _removeStop(int index) {
    if (index >= 0 && index < _stopCards.length) {
      setState(() {
        _stopCards[index].dispose();
        _stopCards.removeAt(index);
      });
      _recalculatePricingAndFares();
    }
  }

  Future<void> _pickLocationForStop(int index) async {
    if (index < 0 || index >= _stopCards.length) return;
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Intermediate Pickup',
      initialQuery: _stopCards[index].locationCtrl.text,
    );
    if (picked != null && mounted) {
      setState(() {
        _stopCards[index].locationCtrl.text = picked.name;
        _stopCards[index].resolvedLocation = picked;
        _stopCards[index].pincode = '';
      });
      _recalculatePricingAndFares();
    }
  }

  /// Recalculates both the main full-ride price and individual intermediate stop prices
  /// using the official backend POST /api/rides/calculate-intermediate-fares API.
  Future<void> _recalculatePricingAndFares() async {
    final fromText = _pickupController.text.trim();
    final toText = _destinationController.text.trim();
    if (fromText.isEmpty || toText.isEmpty) return;

    final activeCards = _stopCards.where((c) => c.locationCtrl.text.trim().isNotEmpty).toList();
    final stopsPayload = activeCards.map((c) => {
      'location': c.locationCtrl.text.trim(),
      'name': c.locationCtrl.text.trim(),
      'latitude': c.resolvedLocation?.latitude ?? 0.0,
      'longitude': c.resolvedLocation?.longitude ?? 0.0,
    }).toList();

    try {
      final res = await RideService.calculateIntermediateFares(
        pickupLocation: fromText,
        destinationLocation: toText,
        departureTime: _formatTimeOfDay(_departureTime),
        ratePerKm: 10,
        seats: _seats,
        intermediatePickups: stopsPayload,
      );

      if (res['success'] == true && mounted) {
        final data = res['data'] is Map ? res['data'] as Map : res;
        final rawTotal = data['totalPrice'] ?? data['price'] ?? data['fare'];
        if (rawTotal is num && rawTotal > 0) {
          setState(() {
            _price = rawTotal.toInt();
            _priceController.text = '$_price';
          });
        }

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
                final rawP = match['price'] ?? match['fare'] ?? match['recommendedFare'] ?? match['priceToDestination'];
                if (rawP != null) {
                  card.priceCtrl.text = rawP.toString();
                }
                if (match['time'] != null || match['calculatedTime'] != null) {
                  card.time = (match['calculatedTime'] ?? match['time']).toString();
                }
                if (match['pincode'] != null) {
                  card.pincode = match['pincode'].toString();
                }
              }
            }
          });
        }
      } else {
        // Fallback: ₹10/km rate
        if (_routeResult != null) {
          final distKm = _parseDistanceKm(_routeResult!.distanceText);
          if (distKm > 0) {
            final fbPrice = (distKm * 10).round();
            setState(() {
              _price = fbPrice;
              _priceController.text = '$_price';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Pricing recalculation error: $e');
      if (_routeResult != null) {
        final distKm = _parseDistanceKm(_routeResult!.distanceText);
        if (distKm > 0) {
          final fbPrice = (distKm * 10).round();
          setState(() {
            _price = fbPrice;
            _priceController.text = '$_price';
          });
        }
      }
    }
  }

  double _parseDistanceKm(String text) {
    final match = RegExp(r'([\d,.]+)').firstMatch(text);
    if (match != null) {
      final numStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(numStr) ?? 0.0;
    }
    return 0.0;
  }

  int _calculateRecommendedPrice(double distanceKm) {
    if (distanceKm <= 0) return 0;
    // Standard Zaatra rate: ₹10/km
    return (distanceKm * 10).round();
  }

  Future<void> _fetchDirections({bool updatePrice = false}) async {
    final fromText = _pickupController.text.trim();
    final toText = _destinationController.text.trim();
    if (fromText.isEmpty || toText.isEmpty) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      RouteResult? result;

      // 1. Live Google Directions API with multi-route alternatives enabled
      if (_pickupLocation.latitude != 0.0 &&
          _pickupLocation.longitude != 0.0 &&
          _destinationLocation.latitude != 0.0 &&
          _destinationLocation.longitude != 0.0) {
        result = await GoogleMapsService.getDirections(
          originLat: _pickupLocation.latitude,
          originLng: _pickupLocation.longitude,
          destLat: _destinationLocation.latitude,
          destLng: _destinationLocation.longitude,
        );
      }

      // 2. Fallback to address-based Directions API
      if (result == null || result.candidateRoutes.isEmpty) {
        result = await GoogleMapsService.getDirectionsByAddress(
          origin: fromText,
          destination: toText,
        );
      }

      if (mounted && result != null && result.candidateRoutes.isNotEmpty) {
        final candidateRoutes = result.candidateRoutes;
        final finalResult = result;
        final newRoutes = candidateRoutes.map((cr) {
          final isFastest = cr.routeIndex == 0;
          final labelTag = isFastest ? 'Fastest' : 'Alternative';
          final summaryInfo = cr.summary.isNotEmpty ? 'via ${cr.summary}' : '';
          return '${cr.durationText} - labelTag $summaryInfo)'.trim();
        }).toList();

        final double distanceKm = candidateRoutes.first.distanceMeters > 0
            ? candidateRoutes.first.distanceMeters / 1000.0
            : _parseDistanceKm(candidateRoutes.first.distanceText);
        final int newCalculatedPrice = _calculateRecommendedPrice(distanceKm);

        setState(() {
          _isLoadingRoute = false;
          _routeResult = finalResult;
          if (_selectedRouteIndex >= candidateRoutes.length) {
            _selectedRouteIndex = 0;
          }
          _routes = newRoutes;
          if (updatePrice && newCalculatedPrice > 0) {
            _price = newCalculatedPrice;
            _priceController.text = '$_price';
          }
        });
        if (updatePrice) {
          _recalculatePricingAndFares();
        }
        return;
      }
    } catch (e) {
      debugPrint('GoogleMapsService getDirections error: $e');
    }

    // 3. Fallback to backend RideService.calculateRoute
    try {
      final res = await RideService.calculateRoute(
        from: fromText,
        to: toText,
      );

      if (mounted && res['success'] == true) {
        final dist = res['distance']?.toString() ?? '';
        final dur = res['duration']?.toString() ?? '4 hours 30 mins';
        final poly = res['polyline']?.toString() ?? '';
        final optList = res['routeOptions'] as List<dynamic>?;

        final candidate = CandidateRoute(
          routeIndex: 0,
          summary: 'Main Route',
          name: 'Route 1: Main Highway Route',
          distanceText: dist,
          distanceMeters: (res['distanceValue'] as num?)?.toInt() ?? 0,
          durationText: dur,
          durationSeconds: (res['durationValue'] as num?)?.toInt() ?? 0,
          overviewPolyline: poly,
          isRecommended: true,
        );

        final parsedResult = RouteResult(
          distanceText: dist,
          distanceMeters: (res['distanceValue'] as num?)?.toInt() ?? 0,
          durationText: dur,
          durationSeconds: (res['durationValue'] as num?)?.toInt() ?? 0,
          overviewPolyline: poly,
          startAddress: fromText,
          endAddress: toText,
          candidateRoutes: [candidate],
        );

        final num? distM = res['distanceValue'] as num?;
        final double distanceKm = distM != null && distM > 0
            ? distM / 1000.0
            : _parseDistanceKm(dist);
        final int newCalculatedPrice = _calculateRecommendedPrice(distanceKm);

        setState(() {
          _isLoadingRoute = false;
          _routeResult = parsedResult;
          _selectedRouteIndex = 0;
          if (optList != null && optList.isNotEmpty) {
            _routes = optList.map((opt) => opt['name']?.toString() ?? 'Route').toList();
          } else {
            _routes = ['$dur - $dist (Fastest Route)'];
          }
          if (updatePrice && newCalculatedPrice > 0) {
            _price = newCalculatedPrice;
            _priceController.text = '$_price';
          }
        });
        if (updatePrice) {
          _recalculatePricingAndFares();
        }
        return;
      }
    } catch (e) {
      debugPrint('RideService calculateRoute fallback error: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _selectPickupLocation() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Pickup Location',
      initialQuery: _pickupController.text,
      hintText: 'Search pickup area, landmark, or street...',
    );

    if (picked != null && mounted) {
      setState(() {
        _pickupLocation = picked;
        _pickupController.text = picked.formattedAddress.isNotEmpty ? picked.formattedAddress : picked.name;
      });
      _fetchDirections(updatePrice: true);
    }
  }

  Future<void> _selectDestinationLocation() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Destination Location',
      initialQuery: _destinationController.text,
      hintText: 'Search destination city, area, or street...',
    );

    if (picked != null && mounted) {
      setState(() {
        _destinationLocation = picked;
        _destinationController.text = picked.formattedAddress.isNotEmpty ? picked.formattedAddress : picked.name;
      });
      _fetchDirections(updatePrice: true);
    }
  }

  Future<void> _selectDepartureDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 30));

    DateTime initial = _departureDate;
    if (initial.isBefore(today)) {
      initial = today;
    } else if (initial.isAfter(maxDate)) {
      initial = maxDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _departureDate = picked;
      });

      // Switching to today with a time that has already passed: move the time
      // to the next valid minute and tell the driver.
      if (_isPastTimeToday(_departureTime)) {
        final now = DateTime.now().add(const Duration(minutes: 1));
        setState(() {
          _departureTime = TimeOfDay(hour: now.hour, minute: now.minute);
        });
        _showPastTimeMessage();
      }
    }
  }

  // ── Departure-time validation (no past times on today's date) ──────────────

  bool _isDepartureDateToday() {
    final now = DateTime.now();
    return _departureDate.year == now.year &&
        _departureDate.month == now.month &&
        _departureDate.day == now.day;
  }

  /// True when the departure date is today and [t] is earlier than the current
  /// minute. The current minute itself is still allowed.
  bool _isPastTimeToday(TimeOfDay t) {
    if (!_isDepartureDateToday()) return false;
    final now = DateTime.now();
    return t.hour * 60 + t.minute < now.hour * 60 + now.minute;
  }

  void _showPastTimeMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Please select a time later than the current time.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _selectDepartureTime() async {
    // On today's date, never open the picker on a time that is already past.
    final initial = _isPastTimeToday(_departureTime)
        ? TimeOfDay.now()
        : _departureTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      if (_isPastTimeToday(picked)) {
        // Reject the past time and let the driver choose again.
        _showPastTimeMessage();
        await _selectDepartureTime();
        return;
      }
      setState(() {
        _departureTime = picked;
      });
    }
  }

  void _updatePrice(int newPrice) {
    if (newPrice < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The minimum price is ₹50.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _price = newPrice;
      _priceController.text = '$_price';
    });
  }

  Future<void> _saveChanges() async {
    if (_seats < _bookedSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_bookedSeats seats are already booked, so you cannot offer fewer.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_price < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a price of at least ₹50.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Block a newly chosen departure that is in the past. An unchanged
    // departure (e.g. editing only the price of an earlier ride) is allowed.
    final chosenDeparture = DateTime(
      _departureDate.year,
      _departureDate.month,
      _departureDate.day,
      _departureTime.hour,
      _departureTime.minute,
    );
    final departureChanged = !chosenDeparture.isAtSameMomentAs(_originalDeparture);
    final nowMinute = DateTime.now();
    final currentMinute = DateTime(
        nowMinute.year, nowMinute.month, nowMinute.day, nowMinute.hour, nowMinute.minute);
    if (departureChanged && chosenDeparture.isBefore(currentMinute)) {
      _showPastTimeMessage();
      return;
    }

    setState(() => _isSaving = true);

    final effectiveRideId = widget.rideId ?? widget.rideData?['rideId'] ?? widget.rideData?['id'] ?? '';
    final departureTimeFormatted = _formatTimeOfDay(_departureTime);
    final departureDateIso = _departureDate.toIso8601String();
    final dateDisplayFormatted = _formatDateDisplay(_departureDate);

    final activeCandidate = (_routeResult != null &&
            _routeResult!.candidateRoutes.isNotEmpty &&
            _selectedRouteIndex < _routeResult!.candidateRoutes.length)
        ? _routeResult!.candidateRoutes[_selectedRouteIndex]
        : null;

    final activeDuration = activeCandidate?.durationText ?? _routeResult?.durationText ?? (widget.rideData?['duration']?.toString() ?? '--');
    final activeDistance = activeCandidate?.distanceText ?? _routeResult?.distanceText ?? (widget.rideData?['distance']?.toString() ?? '--');
    final activePolyline = activeCandidate?.overviewPolyline ?? _routeResult?.overviewPolyline ?? (widget.rideData?['polyline'] ?? widget.rideData?['overviewPolyline'] ?? '').toString();
    final activeRouteName = activeCandidate?.name ?? (activeCandidate?.summary.isNotEmpty == true ? 'via ${activeCandidate!.summary}' : (widget.rideData?['routeName']?.toString() ?? 'Selected Route'));

    final dynamicIntermediatePickups = _stopCards
        .where((c) => c.locationCtrl.text.trim().isNotEmpty)
        .map((c) => {
              'location': c.locationCtrl.text.trim(),
              'price': int.tryParse(c.priceCtrl.text.trim()) ?? 0,
              'pincode': c.pincode,
              'landmark': '',
              'time': c.time,
            })
        .toList();

    final List<Map<String, dynamic>> routePlan = [];
    routePlan.add({
      'location': _pickupController.text.trim(),
      'time': departureTimeFormatted,
      'type': 'start',
      'pincode': '',
      'landmark': '',
    });

    for (final c in _stopCards) {
      if (c.locationCtrl.text.trim().isNotEmpty) {
        routePlan.add({
          'location': c.locationCtrl.text.trim(),
          'time': c.time.isNotEmpty ? c.time : departureTimeFormatted,
          'type': 'pickup',
          'pincode': c.pincode,
          'landmark': '',
          'price': int.tryParse(c.priceCtrl.text.trim()) ?? 0,
        });
      }
    }

    routePlan.add({
      'location': _destinationController.text.trim(),
      'time': 'Arrival',
      'type': 'destination',
      'pincode': '',
      'landmark': '',
    });

    final customCust = _customCustomerPrefs
        .where((c) => c.controller.text.trim().isNotEmpty)
        .map((c) => {
              'title': c.controller.text.trim(),
              'enabled': c.enabled,
              'category': 'customer',
            })
        .toList();

    final customFeat = _customFeaturePrefs
        .where((c) => c.controller.text.trim().isNotEmpty)
        .map((c) => {
              'title': c.controller.text.trim(),
              'enabled': c.enabled,
              'category': 'feature',
            })
        .toList();

    final combinedCustom = [...customCust, ...customFeat];

    final updatePayload = <String, dynamic>{
      'price': _price,
      'pricePerSeat': _price,
      'from': _pickupController.text.trim(),
      'pickupLocation': _pickupController.text.trim(),
      'pickupLat': _pickupLocation.latitude,
      'pickupLng': _pickupLocation.longitude,
      'to': _destinationController.text.trim(),
      'destinationLocation': _destinationController.text.trim(),
      'destLat': _destinationLocation.latitude,
      'destLng': _destinationLocation.longitude,
      'duration': activeDuration,
      'distance': activeDistance,
      'polyline': activePolyline,
      'overviewPolyline': activePolyline,
      'routeName': activeRouteName,
      'selectedRouteIndex': _selectedRouteIndex,
      'departureTime': departureTimeFormatted,
      'departureDate': departureDateIso,
      'date': dateDisplayFormatted,
      'dateDisplay': dateDisplayFormatted,
      'scheduledDate': departureDateIso,
      'seats': _seats,
      'maxLuggagePerPassenger': _luggage,
      'autoApproval': _autoApproval,
      'autoApprovalOfPassenger': _autoApproval,
      'smokingAllowed': _smokingAllowed,
      'smoking': _smokingAllowed,
      'ac': _ac,
      'airConditioning': _ac,
      'usbCharging': _usb,
      'driverPreferences': {
        'autoApproval': _autoApproval,
        'bookingMode': _autoApproval ? 'instant_booking' : 'review_request',
        'rideType': _doorstepPickupDrop ? 'door_to_door' : 'shared',
        'acceptDoorToDoor': _doorstepPickupDrop,
      },
      'customerPreferences': {
        'smokingAllowed': _smokingAllowed,
        'smoking': _smokingAllowed,
        'customPreferences': customCust,
      },
      'rideFeatures': {
        'ac': _ac,
        'airConditioning': _ac,
        'usbCharging': _usb,
        'customFeatures': customFeat,
      },
      'preferences': {
        'autoApproval': _autoApproval,
        'doorstepPickupDrop': _doorstepPickupDrop,
        'ac': _ac,
        'airConditioning': _ac,
        'smokingAllowed': _smokingAllowed,
        'smoking': _smokingAllowed,
        'usbCharging': _usb,
        'luggageCount': _luggage,
        'customPreferences': combinedCustom,
        'customCustomerPreferences': customCust,
        'customRideFeatures': customFeat,
      },
      'intermediatePickups': dynamicIntermediatePickups,
      'routePlan': routePlan,
    };

    try {
      if (effectiveRideId.isNotEmpty) {
        await RideService.updateRide(
          rideId: effectiveRideId.toString(),
          updateData: updatePayload,
        );
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('driver_pref_save_enabled') == true) {
        await prefs.setBool('driver_pref_instant_booking', _autoApproval);
        await prefs.setBool('driver_pref_auto_approval', _autoApproval);
        await prefs.setBool('driver_pref_door_to_door', _doorstepPickupDrop);
        await prefs.setBool('driver_pref_doorstep_pickup_drop', _doorstepPickupDrop);
        await prefs.setBool('driver_pref_smoking_allowed', _smokingAllowed);
        await prefs.setBool('driver_pref_ac', _ac);
        await prefs.setBool('driver_pref_usb_charging', _usb);
        await prefs.setString('driver_pref_custom_customer_list', jsonEncode(customCust));
        await prefs.setString('driver_pref_custom_features_list', jsonEncode(customFeat));
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride details updated successfully! 🎉'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, {
      'edited': true,
      'rideId': effectiveRideId,
      'updatedPayload': updatePayload,
    });
  }

  Future<void> _confirmCancelRide() async {
    final effectiveRideId = widget.rideId ?? widget.rideData?['rideId'] ?? widget.rideData?['id'] ?? '';
    final from = _pickupController.text.trim().isNotEmpty ? _pickupController.text.trim() : (widget.rideData?['from'] ?? 'Origin').toString();
    final to = _destinationController.text.trim().isNotEmpty ? _destinationController.text.trim() : (widget.rideData?['to'] ?? 'Destination').toString();
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${_departureDate.day} ${monthNames[_departureDate.month - 1]}, ${_departureDate.year}';
    final timeStr = _departureTime.format(context);

    final reason = await DriverCancelRideDialog.show(
      context,
      origin: from,
      destination: to,
      date: dateStr,
      time: timeStr,
      rideId: effectiveRideId.toString(),
    );

    if (reason == null || !mounted) return;

    setState(() => _isDeleting = true);

    Map<String, dynamic> cancelRes = {'success': false, 'message': 'This ride has no ID and cannot be cancelled.'};
    try {
      if (effectiveRideId.toString().isNotEmpty) {
        cancelRes = await DriverService.cancelRide(rideId: effectiveRideId.toString(), reason: reason);
      }
    } catch (_) {
      cancelRes = {'success': false, 'message': 'Could not cancel the ride. Please check your connection and try again.'};
    }

    if (!mounted) return;
    setState(() => _isDeleting = false);

    // Only report success (and leave the screen) when the server actually cancelled the ride.
    if (cancelRes['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cancelRes['message']?.toString() ?? 'Could not cancel the ride. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upcoming ride cancelled successfully. Reason: $reason'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    Navigator.pop(context, {
      'deleted': true,
      'cancelled': true,
      'rideId': effectiveRideId,
      'reason': reason,
    });
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.rideData ?? {};
    final fromName = _pickupController.text.isNotEmpty ? _pickupController.text.split(',').first : 'Origin';
    final toName = _destinationController.text.isNotEmpty ? _destinationController.text.split(',').first : 'Destination';

    final activeCandidate = (_routeResult != null &&
            _routeResult!.candidateRoutes.isNotEmpty &&
            _selectedRouteIndex < _routeResult!.candidateRoutes.length)
        ? _routeResult!.candidateRoutes[_selectedRouteIndex]
        : null;

    final durationStr = activeCandidate?.durationText ?? _routeResult?.durationText ?? (ride['duration'] ?? '--').toString();
    final distanceStr = activeCandidate?.distanceText ?? _routeResult?.distanceText ?? (ride['distance'] ?? '--').toString();
    final arrivalTime = (ride['arrivalTime'] ?? '--').toString();

    final dateDisplay = _formatDateDisplay(_departureDate);
    final departureTimeFormatted = _formatTimeOfDay(_departureTime);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Edit Ride',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Main Details Container
                  Container(
                    transform: Matrix4.translationValues(0, -12, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Route Overview Card
                        const Text(
                          'Route Overview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5FE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withAlpha(30)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dateDisplay,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      departureTimeFormatted,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      fromName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(distanceStr.isNotEmpty ? '$durationStr • $distanceStr' : durationStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                  ),
                                  Expanded(
                                    child: Text(
                                      toName,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(departureTimeFormatted, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  const Text('• • • • • • •', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  Text(arrivalTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section 2: Edit Ride Date & Time
                        const Text(
                          'Ride Schedule (Date & Time)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            // Date Picker Card
                            Expanded(
                              child: InkWell(
                                onTap: _selectDepartureDate,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F5FE),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primary.withAlpha(20)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_departureDate.day} ${_getMonthAbbr(_departureDate.month)}, ${_departureDate.year}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Time Picker Card
                            Expanded(
                              child: InkWell(
                                onTap: _selectDepartureTime,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F5FE),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primary.withAlpha(20)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            Text(
                                              departureTimeFormatted,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Section 3: Price Editing
                        const Text('Price per Seat (₹)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5FE),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => _updatePrice(_price - 20),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove, color: AppColors.primary, size: 20),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('₹ ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  SizedBox(
                                    width: 90,
                                    child: TextField(
                                      controller: _priceController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val);
                                        if (parsed != null && parsed > 0) {
                                          _price = parsed;
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => _updatePrice(_price + 20),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section 4: Location & Landmark Editing (Google Places Autocomplete Integrated)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pickup & Drop Locations',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Google Maps',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        _buildLocationInputField(
                          label: 'Pickup Address',
                          controller: _pickupController,
                          icon: Icons.my_location_rounded,
                          hint: 'Search or enter pickup address',
                          onTapSearch: _selectPickupLocation,
                        ),
                        const SizedBox(height: 10),

                        _buildLocationInputField(
                          label: 'Destination Address',
                          controller: _destinationController,
                          icon: Icons.location_on_rounded,
                          hint: 'Search or enter destination address',
                          onTapSearch: _selectDestinationLocation,
                        ),
                        const SizedBox(height: 18),

                        // Intermediate Pickups Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Intermediate Pickups',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                if (_stopCards.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_stopCards.length}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _addStop,
                              icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                              label: const Text(
                                'Add Stop',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_stopCards.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F8FD),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No intermediate stops added. Tap "Add Stop" to offer pickups along the corridor.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _stopCards.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _buildStopCard(index),
                          ),

                        const SizedBox(height: 20),

                        // Section 5: Choose Route (Live Map & Route Selection)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Choose Route',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            if (_isLoadingRoute)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Calculating...',
                                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )
                            else
                              GestureDetector(
                                onTap: () => _fetchDirections(updatePrice: true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Recalculate',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Interactive Route Map
                        RouteMapWebView(
                          pickup: _pickupController.text.trim(),
                          destination: _destinationController.text.trim(),
                          pickupPoint: _pickupLocation,
                          destPoint: _destinationLocation,
                          candidateRoutes: _routeResult?.candidateRoutes ?? const [],
                          height: 220,
                          borderRadius: 16,
                          interactive: true,
                          selectedRouteIndex: _selectedRouteIndex,
                          onRouteSelected: (index) {
                            setState(() {
                              _selectedRouteIndex = index;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Route Cards
                        if (_routes.isNotEmpty)
                          ...List.generate(_routes.length, (index) {
                            final isSelected = _selectedRouteIndex == index;
                            final candidate = (_routeResult != null &&
                                    _routeResult!.candidateRoutes.isNotEmpty &&
                                    index < _routeResult!.candidateRoutes.length)
                                ? _routeResult!.candidateRoutes[index]
                                : null;
                            final isRecommended = candidate?.isRecommended ?? (index == 0);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRouteIndex = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Center(
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  candidate?.summary.isNotEmpty == true
                                                      ? 'via ${candidate!.summary}'
                                                      : 'Route ${index + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (isRecommended)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDCFCE7),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'Recommended',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF15803D),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            candidate != null
                                                ? '${candidate.durationText} • ${candidate.distanceText}'
                                                : _routes[index],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                        else if (_isLoadingRoute)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5FE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                SizedBox(width: 10),
                                Text(
                                  'Calculating alternative routes...',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Section 6: Seats & Luggage
                        const Text('Available Seats & Luggage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _buildCounterTile(
                                label: 'Seats',
                                value: _seats,
                                icon: Icons.event_seat_rounded,
                                onIncrement: () => setState(() => _seats++),
                                onDecrement: () {
                                  if (_seats <= 1) return;
                                  if (_seats - 1 < _bookedSeats) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$_bookedSeats seat${_bookedSeats == 1 ? ' is' : 's are'} already booked, so you cannot offer fewer.',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => _seats--);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCounterTile(
                                label: 'Luggage/pax',
                                value: _luggage,
                                icon: Icons.luggage_rounded,
                                onIncrement: () => setState(() => _luggage++),
                                onDecrement: () => setState(() {
                                  if (_luggage > 0) _luggage--;
                                }),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Section 7: Driver Preferences (Toggles)
                        const Text(
                          'Driver Preferences',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),

                        // Toggle 1: Instant booking vs Review every request
                        _buildToggleCard(
                          option1Label: 'Instant booking',
                          option1Selected: _autoApproval,
                          onOption1Tap: () => setState(() => _autoApproval = true),
                          option2Label: 'Review every request',
                          option2Selected: !_autoApproval,
                          onOption2Tap: () => setState(() => _autoApproval = false),
                        ),
                        const SizedBox(height: 10),

                        // Toggle 2: Shared Ride vs Accept Door to Door request
                        _buildToggleCard(
                          option1Label: 'Shared Ride',
                          option1Selected: !_doorstepPickupDrop,
                          onOption1Tap: () => setState(() => _doorstepPickupDrop = false),
                          option2Label: 'Accept Door to Door request',
                          option2Selected: _doorstepPickupDrop,
                          onOption2Tap: () => setState(() => _doorstepPickupDrop = true),
                        ),

                        const SizedBox(height: 24),

                        // Section 8: Customer Preferences
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Customer Preferences',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _customCustomerPrefs.add(_EditCustomPrefItem(category: 'customer'));
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                              label: const Text(
                                'Add Custom',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5FE),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCheckboxRow('Smoking Allowed', _smokingAllowed, (val) => setState(() => _smokingAllowed = val ?? false)),
                              if (_customCustomerPrefs.isNotEmpty) ...[
                                const Divider(height: 16, color: Color(0xFFEADBFF)),
                                ..._customCustomerPrefs.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  return _buildInlineCustomPrefRow(
                                    item: item,
                                    hint: 'e.g. Pet Friendly, Silent Ride',
                                    onDelete: () {
                                      setState(() {
                                        _customCustomerPrefs.removeAt(idx).dispose();
                                      });
                                    },
                                    onEnabledChanged: (val) {
                                      setState(() {
                                        item.enabled = val ?? false;
                                      });
                                    },
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section 9: Ride Features
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ride Features',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _customFeaturePrefs.add(_EditCustomPrefItem(category: 'feature'));
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                              label: const Text(
                                'Add Custom',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5FE),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCheckboxRow('AC (Air Conditioning)', _ac, (val) => setState(() => _ac = val ?? false)),
                              const Divider(height: 16, color: Color(0xFFEADBFF)),
                              _buildCheckboxRow('USB Charging Port', _usb, (val) => setState(() => _usb = val ?? false)),
                              if (_customFeaturePrefs.isNotEmpty) ...[
                                const Divider(height: 16, color: Color(0xFFEADBFF)),
                                ..._customFeaturePrefs.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  return _buildInlineCustomPrefRow(
                                    item: item,
                                    hint: 'e.g. Dashcam, Sunroof, Heated Seats',
                                    onDelete: () {
                                      setState(() {
                                        _customFeaturePrefs.removeAt(idx).dispose();
                                      });
                                    },
                                    onEnabledChanged: (val) {
                                      setState(() {
                                        item.enabled = val ?? false;
                                      });
                                    },
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Save Changes Primary CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: _isSaving || _isDeleting ? null : _saveChanges,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Cancel/Delete Ride Secondary Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFBFA),
                              side: const BorderSide(color: Color(0xFFFFCDD2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isSaving || _isDeleting ? null : _confirmCancelRide,
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                                  )
                                : const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                            label: Text(
                              _isDeleting ? 'Cancelling Ride...' : 'Cancel Ride',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Widget _buildStopCard(int index) {
    final card = _stopCards[index];
    final stopNumber = index + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stopNumber',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Stop #$stopNumber',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (card.time.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '• ${card.time}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () => _removeStop(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location selector field
          GestureDetector(
            onTap: () => _pickLocationForStop(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      card.locationCtrl.text.isNotEmpty ? card.locationCtrl.text : 'Tap to select intermediate pickup location',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: card.locationCtrl.text.isNotEmpty ? AppColors.textPrimary : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Price per stop field
          Row(
            children: [
              const Icon(Icons.currency_rupee_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              const Text(
                'Price per stop:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                height: 38,
                child: TextField(
                  controller: card.priceCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required VoidCallback onTapSearch,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        onTap: onTapSearch,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
            tooltip: 'Search with Google Maps',
            onPressed: onTapSearch,
          ),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEditableInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCounterTile({
    required String label,
    required int value,
    required IconData icon,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onDecrement,
                child: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.textSecondary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              InkWell(
                onTap: onIncrement,
                child: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String option1Label,
    required bool option1Selected,
    required VoidCallback onOption1Tap,
    required String option2Label,
    required bool option2Selected,
    required VoidCallback onOption2Tap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCheckRadioOption(
              label: option1Label,
              selected: option1Selected,
              onTap: onOption1Tap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCheckRadioOption(
              label: option2Label,
              selected: option2Selected,
              onTap: onOption2Tap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRadioOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1D1B20),
                  width: 1.8,
                ),
              ),
              child: selected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 13,
                        color: Color(0xFF1D1B20),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineCustomPrefRow({
    required _EditCustomPrefItem item,
    required String hint,
    required VoidCallback onDelete,
    required ValueChanged<bool?> onEnabledChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: item.enabled,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onEnabledChanged,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: item.controller,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD0BCFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD0BCFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            tooltip: 'Remove',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        Checkbox(
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}