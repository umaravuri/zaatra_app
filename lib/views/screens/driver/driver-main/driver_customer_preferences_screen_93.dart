import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../models/ride_preference_template_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/driver_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/driver_conflict_dialogs.dart';
import 'driver_ride_management_screen_98.dart';
import 'driver_ride_start_details_screen_88.dart';

class DriverCustomerPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic>? rideDetails;

  const DriverCustomerPreferencesScreen({
    super.key,
    this.rideDetails,
  });

  @override
  State<DriverCustomerPreferencesScreen> createState() => _DriverCustomerPreferencesScreenState();
}

class _DriverCustomerPreferencesScreenState extends State<DriverCustomerPreferencesScreen> {
  // Server-driven dynamic template state
  RidePreferenceTemplate _template = () {
    final t = RidePreferenceTemplate.defaultTemplate();
    t.driverPreferences.items.removeWhere(
      (item) => item.key == 'autoApproval' || item.id == 'dp-auto-approval' || item.label.toLowerCase().contains('auto approval'),
    );
    return t;
  }();
  bool _isLoadingTemplate = true;

  // New Driver Preferences Toggles (replacing Auto approval of passenger)
  bool _isInstantBooking = true; // Instant booking vs Review every request
  bool _isDoorToDoor = false;    // Shared Ride vs Accept Door to Door request

  // General state
  bool _saveForFuture = true;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndTemplate();
  }

  Future<void> _loadPreferencesAndTemplate() async {
    try {
      // 1. Fetch template from API 1 (or default template fallback)
      final rideId = widget.rideDetails?['rideId']?.toString();
      final template = await RideService.getPreferenceTemplate(rideId: rideId);
      template.driverPreferences.items.removeWhere(
        (item) => item.key == 'autoApproval' || item.id == 'dp-auto-approval' || item.label.toLowerCase().contains('auto approval'),
      );

      // 2. Load saved preferences from local storage if enabled
      final prefs = await SharedPreferences.getInstance();
      final hasSaved = prefs.containsKey('driver_pref_save_enabled') && prefs.getBool('driver_pref_save_enabled') == true;

      if (hasSaved) {
        _isInstantBooking = prefs.getBool('driver_pref_instant_booking') ??
            prefs.getBool('driver_pref_auto_approval') ??
            (template.bookingMode == 'instant_booking');
        _isDoorToDoor = prefs.getBool('driver_pref_door_to_door') ?? template.acceptDoorToDoor;

        for (final item in template.customerPreferences.items) {
          if (item.key == 'smokingAllowed' || item.key == 'smoking' || item.id == 'cp-smoking') {
            item.enabled = prefs.getBool('driver_pref_smoking_allowed') ?? item.enabled;
          }
        }

        for (final item in template.rideFeatures.items) {
          if (item.key == 'ac' || item.key == 'airConditioning' || item.id == 'rf-ac') {
            item.enabled = prefs.getBool('driver_pref_ac') ?? item.enabled;
          } else if (item.key == 'usbCharging') {
            item.enabled = prefs.getBool('driver_pref_usb_charging') ?? item.enabled;
          }
        }

        // Restore custom driver preferences
        final customDriverStr = prefs.getString('driver_pref_custom_driver_list');
        if (customDriverStr != null && customDriverStr.isNotEmpty) {
          final decoded = jsonDecode(customDriverStr);
          if (decoded is List) {
            for (final entry in decoded) {
              if (entry is Map<String, dynamic>) {
                template.driverPreferences.items.add(PreferenceItem.fromJson(entry, isCustom: true));
              }
            }
          }
        }

        // Restore custom customer preferences
        final customCustomerStr = prefs.getString('driver_pref_custom_customer_list');
        if (customCustomerStr != null && customCustomerStr.isNotEmpty) {
          final decoded = jsonDecode(customCustomerStr);
          if (decoded is List) {
            for (final entry in decoded) {
              if (entry is Map<String, dynamic>) {
                template.customerPreferences.items.add(PreferenceItem.fromJson(entry, isCustom: true));
              }
            }
          }
        }

        // Restore custom ride features
        final customFeaturesStr = prefs.getString('driver_pref_custom_features_list');
        if (customFeaturesStr != null && customFeaturesStr.isNotEmpty) {
          final decoded = jsonDecode(customFeaturesStr);
          if (decoded is List) {
            for (final entry in decoded) {
              if (entry is Map<String, dynamic>) {
                template.rideFeatures.items.add(PreferenceItem.fromJson(entry, isCustom: true));
              }
            }
          }
        }
      } else {
        _isInstantBooking = template.bookingMode == 'instant_booking';
        _isDoorToDoor = template.acceptDoorToDoor;
      }

      if (mounted) {
        setState(() {
          _template = template;
          _isLoadingTemplate = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTemplate = false);
      }
    }
  }

  void _showAddCustomDialog({
    required String title,
    required String hint,
    required String category, // 'driver', 'customer', 'feature'
    required Function(PreferenceItem) onAdd,
  }) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final keyboardPadding = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: keyboardPadding + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                      fillColor: const Color(0xFFFAFAFA),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final val = textController.text.trim();
                            if (val.isNotEmpty) {
                              final newItem = PreferenceItem(
                                id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                                key: val.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
                                label: val,
                                type: PreferenceItemType.checkbox,
                                enabled: true,
                                count: 0,
                                isCustom: true,
                              );
                              onAdd(newItem);
                              Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _publishRide() async {
    setState(() => _isPublishing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final user = await AuthService.getCurrentUser();
      final phone = prefs.getString('currentPhone') ?? user?['phone']?.toString() ?? '';
      final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');

      // Resolve driverId
      final driverId = await DriverService.resolveCurrentDriverId();

      String driverName = prefs.getString('user_name_$cleanDigits') ??
          prefs.getString('currentUserName') ??
          user?['name']?.toString() ??
          'Driver';

      // Dynamically fetch driver vehicle info
      String vehicle = prefs.getString('driver_vehicle_$cleanDigits') ??
          prefs.getString('driver_vehicle_name_$cleanDigits') ??
          widget.rideDetails?['vehicle'] ??
          '';
      String vehicleMake = prefs.getString('driver_vehicle_make_$cleanDigits') ?? widget.rideDetails?['vehicleMake'] ?? '';
      String vehicleModel = prefs.getString('driver_vehicle_model_$cleanDigits') ?? widget.rideDetails?['vehicleModel'] ?? '';
      String vehicleType = prefs.getString('driver_vehicle_type_$cleanDigits') ?? widget.rideDetails?['vehicleType'] ?? '';
      String vehiclePlate = prefs.getString('driver_vehicle_plate_$cleanDigits') ?? widget.rideDetails?['vehicleNumberPlate'] ?? '';
      String fuelType = prefs.getString('driver_vehicle_fuel_$cleanDigits') ?? widget.rideDetails?['fuelType'] ?? '';

      // 1. Try fetching vehicle info directly from Driver Vehicle API
      if (phone.isNotEmpty) {
        try {
          final vehRes = await DriverService.getVehicleInfo(phone: phone);
          if (vehRes['success'] == true) {
            final v = vehRes['vehicleInformation'] ?? vehRes['data'] ?? vehRes;
            if (v is Map) {
              if (v['vehicleName'] != null && v['vehicleName'].toString().isNotEmpty) {
                vehicle = v['vehicleName'].toString();
              }
              if (v['vehicleMake'] != null && v['vehicleMake'].toString().isNotEmpty) {
                vehicleMake = v['vehicleMake'].toString();
              }
              if (v['vehicleModel'] != null && v['vehicleModel'].toString().isNotEmpty) {
                vehicleModel = v['vehicleModel'].toString();
              }
              if (v['vehicleType'] != null && v['vehicleType'].toString().isNotEmpty) {
                vehicleType = v['vehicleType'].toString();
              }
              if (v['vehicleNumberPlate'] != null && v['vehicleNumberPlate'].toString().isNotEmpty) {
                vehiclePlate = v['vehicleNumberPlate'].toString();
              }
              if (v['fuelType'] != null && v['fuelType'].toString().isNotEmpty) {
                fuelType = v['fuelType'].toString();
              }
            }
          }
        } catch (_) {}

        // 2. Try fetching driver approval status
        try {
          final driverStatus = await DriverService.getDriverApprovalStatus(phone: phone);
          if (driverStatus['success'] == true && driverStatus['driver'] != null) {
            final d = driverStatus['driver'];
            if (d['name'] != null && d['name'].toString().isNotEmpty) {
              driverName = d['name'];
            }
            if (d['vehicle'] != null && d['vehicle'].toString().isNotEmpty && vehicle.isEmpty) {
              vehicle = d['vehicle'].toString();
            }
            if (d['vehicleMake'] != null && d['vehicleMake'].toString().isNotEmpty && vehicleMake.isEmpty) {
              vehicleMake = d['vehicleMake'].toString();
            }
            if (d['vehicleModel'] != null && d['vehicleModel'].toString().isNotEmpty && vehicleModel.isEmpty) {
              vehicleModel = d['vehicleModel'].toString();
            }
            if (d['vehicleType'] != null && d['vehicleType'].toString().isNotEmpty && vehicleType.isEmpty) {
              vehicleType = d['vehicleType'].toString();
            }
            if (d['vehicleNumberPlate'] != null && d['vehicleNumberPlate'].toString().isNotEmpty && vehiclePlate.isEmpty) {
              vehiclePlate = d['vehicleNumberPlate'].toString();
            }
            if ((d['fuelType'] != null || d['vehicleFuelType'] != null) && fuelType.isEmpty) {
              fuelType = (d['fuelType'] ?? d['vehicleFuelType']).toString();
            }
          }
        } catch (_) {}
      }

      if (vehicle.isEmpty && vehicleMake.isNotEmpty) {
        vehicle = '$vehicleMake $vehicleModel'.trim();
      }

      // Normalize fuelType to match backend Ride model enum ["Diesel", "Petrol", "Electric", "CNG", "Hybrid"]
      String normalizedFuelType = 'Diesel';
      final lowerFuel = fuelType.trim().toLowerCase();
      if (lowerFuel.contains('petrol')) {
        normalizedFuelType = 'Petrol';
      } else if (lowerFuel.contains('diesel')) {
        normalizedFuelType = 'Diesel';
      } else if (lowerFuel.contains('cng')) {
        normalizedFuelType = 'CNG';
      } else if (lowerFuel.contains('elec') || lowerFuel.contains('ev')) {
        normalizedFuelType = 'Electric';
      } else if (lowerFuel.contains('hyb')) {
        normalizedFuelType = 'Hybrid';
      }

      // Extract template values for API 2
      bool autoApproval = _isInstantBooking;

      bool smokingAllowed = false;
      for (final item in _template.customerPreferences.items) {
        if (item.key == 'smokingAllowed' || item.key == 'smoking' || item.id == 'cp-smoking') {
          smokingAllowed = item.enabled;
        }
      }

      bool ac = false;
      bool usbCharging = false;
      bool wifi = false;
      for (final item in _template.rideFeatures.items) {
        if (item.key == 'ac' || item.key == 'airConditioning' || item.id == 'rf-ac') {
          ac = item.enabled;
        }
        if (item.key == 'usbCharging' || item.id == 'rf-usb-charging') usbCharging = item.enabled;
        if (item.key == 'wifi' || item.id == 'rf-wifi') wifi = item.enabled;
      }

      // Extract active custom items
      final customDriverItems = _template.driverPreferences.items.where((i) => i.isCustom && i.enabled).toList();
      final customCustomerItems = _template.customerPreferences.items.where((i) => i.isCustom && (i.enabled || i.count > 0)).toList();
      final customFeatureItems = _template.rideFeatures.items.where((i) => i.isCustom && i.enabled).toList();

      final activeDriverPrefTitles = customDriverItems.map((i) => i.label).toList();
      final activeCustomerPrefTitles = customCustomerItems.map((i) => i.label).toList();
      final activeFeatureTitles = customFeatureItems.map((i) => i.label).toList();

      final combinedCustomPrefs = [...activeDriverPrefTitles, ...activeCustomerPrefTitles];

      // Persist preferences if saveForFuture is enabled
      if (_saveForFuture) {
        try {
          await prefs.setBool('driver_pref_save_enabled', true);
          await prefs.setBool('driver_pref_instant_booking', _isInstantBooking);
          await prefs.setBool('driver_pref_auto_approval', _isInstantBooking);
          await prefs.setBool('driver_pref_door_to_door', _isDoorToDoor);
          await prefs.setBool('driver_pref_smoking_allowed', smokingAllowed);
          await prefs.setBool('driver_pref_ac', ac);
          await prefs.setBool('driver_pref_usb_charging', usbCharging);

          final customDriverList = customDriverItems.map((i) => i.toJson()).toList();
          final customCustomerList = customCustomerItems.map((i) => i.toJson()).toList();
          final customFeaturesList = customFeatureItems.map((i) => i.toJson()).toList();

          await prefs.setString('driver_pref_custom_driver_list', jsonEncode(customDriverList));
          await prefs.setString('driver_pref_custom_customer_list', jsonEncode(customCustomerList));
          await prefs.setString('driver_pref_custom_features_list', jsonEncode(customFeaturesList));
        } catch (_) {}
      }

      final fromLocation = widget.rideDetails?['from'] ?? widget.rideDetails?['pickupLocation'] ?? '';
      final toLocation = widget.rideDetails?['to'] ?? widget.rideDetails?['destinationLocation'] ?? '';

      // Seats and price must come from what the driver entered; never publish invented values.
      final rawSeats = widget.rideDetails?['seats'];
      final seatsCount = rawSeats is num ? rawSeats.toInt() : (int.tryParse(rawSeats?.toString() ?? '') ?? 0);
      final rawPrice = widget.rideDetails?['price'];
      final seatPrice = rawPrice is num ? rawPrice.toDouble() : (double.tryParse(rawPrice?.toString() ?? '') ?? 0.0);
      if (seatsCount <= 0 || seatPrice <= 0) {
        if (mounted) {
          setState(() => _isPublishing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seats and price per seat are required. Please go back and enter them before publishing.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      final wholeCarPrice = (widget.rideDetails?['wholeCarPrice'] is num)
          ? widget.rideDetails!['wholeCarPrice']
          : (seatPrice * seatsCount).round();

      // API 2 & 3: Post a Ride with Preferences matching specification
      final ridePayload = <String, dynamic>{
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': phone,
        'vehicle': vehicle,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'vehicleType': vehicleType,
        'fuelType': normalizedFuelType,
        'vehicleNumberPlate': vehiclePlate,
        'from': fromLocation,
        'pickupLocation': widget.rideDetails?['pickupLocation'] ?? fromLocation,
        'pickupPincode': widget.rideDetails?['pickupPincode'] ?? '',
        'pickupLandmark': widget.rideDetails?['pickupLandmark'] ?? '',
        'to': toLocation,
        'destinationLocation': widget.rideDetails?['destinationLocation'] ?? toLocation,
        'destinationPincode': widget.rideDetails?['destinationPincode'] ?? '',
        'destinationLandmark': widget.rideDetails?['destinationLandmark'] ?? '',
        'duration': widget.rideDetails?['duration'] ?? '',
        'distance': widget.rideDetails?['distance'] ?? '',
        'seats': seatsCount,
        'booked': 0,
        'price': seatPrice,
        'pricePerSeat': seatPrice,
        'ratePerKm': widget.rideDetails?['ratePerKm'] ?? widget.rideDetails?['basePricePerKm'] ?? 10,
        // Specification fields (API 1 Scenarios 1, 2, 3, 4):
        'bookingMode': _isInstantBooking ? 'instant_booking' : 'review_request',
        'rideType': _isDoorToDoor ? 'door_to_door' : 'shared_ride',
        'instantBooking': _isInstantBooking,
        'reviewEveryRequest': !_isInstantBooking,
        'shareRide': !_isDoorToDoor,
        'acceptDoorToDoorRequest': _isDoorToDoor,
        'acceptDoorToDoor': _isDoorToDoor,
        'wholeCarPrice': wholeCarPrice,
        'smoking': smokingAllowed ? 'allowed' : 'not_allowed',
        'ac': ac,
        'usbCharging': usbCharging,
        'wifi': wifi,
        // Fallback / compatibility fields:
        'isDoorstepAllowed': _isDoorToDoor,
        'bookingType': _isInstantBooking ? 'instant' : 'review',
        'maxDetourRadiusKm': _isDoorToDoor ? 15 : 0,
        'detourRatePerKm': _isDoorToDoor ? 12 : 0,
        'maxLuggagePerPassenger': 1,
        'departs': widget.rideDetails?['departs'] ?? widget.rideDetails?['date'] ?? DateTime.now().toIso8601String(),
        'date': widget.rideDetails?['date'] ?? widget.rideDetails?['departs'] ?? DateTime.now().toIso8601String(),
        'departureDate': widget.rideDetails?['departureDate'] ?? '',
        'departureTime': widget.rideDetails?['departureTime'] ?? '',
        'arrivalTime': widget.rideDetails?['arrivalTime'] ?? '',
        'autoApproval': _isInstantBooking,
        'autoApprovalOfPassenger': _isInstantBooking,
        'smokingAllowed': smokingAllowed,
        'airConditioning': ac,

        // API 2 Structured Objects:
        'driverPreferences': {
          'bookingMode': _isInstantBooking ? 'instant_booking' : 'review_request',
          'rideType': _isDoorToDoor ? 'door_to_door' : 'shared_ride',
          'acceptDoorToDoor': _isDoorToDoor,
          'wholeCarPrice': wholeCarPrice,
          'instantBooking': _isInstantBooking,
          'autoApproval': _isInstantBooking,
          'bookingType': _isInstantBooking ? 'instant' : 'review',
          'isDoorstepAllowed': _isDoorToDoor,
        },
        'customerPreferences': {
          'smoking': smokingAllowed ? 'allowed' : 'not_allowed',
          'smokingAllowed': smokingAllowed,
        },
        'rideFeatures': {
          'ac': ac,
          'airConditioning': ac,
          'usbCharging': usbCharging,
          'wifi': wifi,
        },

        // Legacy compatibility objects
        'preferences': {
          'instantBooking': _isInstantBooking,
          'autoApproval': _isInstantBooking,
          'isDoorstepAllowed': _isDoorToDoor,
          'acceptDoorToDoor': _isDoorToDoor,
          'smokingAllowed': smokingAllowed,
          'smoking': smokingAllowed,
          'ac': ac,
          'airConditioning': ac,
          'usbCharging': usbCharging,
          'saveForFuture': _saveForFuture,
          'driverPreferences': [
            _isInstantBooking ? 'Instant booking' : 'Review every request',
            _isDoorToDoor ? 'Accept Door to Door request' : 'Shared Ride',
            ...activeDriverPrefTitles,
          ],
          'customerPreferences': [
            smokingAllowed ? 'Smoking allowed' : 'No smoking',
            ...activeCustomerPrefTitles,
          ],
          'customPreferences': combinedCustomPrefs,
          'customFeatures': activeFeatureTitles,
          'rideFeatures': [
            if (ac) 'AC',
            if (usbCharging) 'USB charging',
            ...activeFeatureTitles,
          ],
        },
        'customPreferences': combinedCustomPrefs,
        'customFeatures': activeFeatureTitles,
        'intermediatePickups': widget.rideDetails?['intermediatePickups'] ?? [],
        'routePlan': widget.rideDetails?['routePlan'] ?? [],
        'polyline': widget.rideDetails?['polyline'] ?? '',
        'routeOption': widget.rideDetails?['routeName'] ?? '',
      };

      final response = await RideService.createRide(ridePayload);

      if (!mounted) return;
      setState(() => _isPublishing = false);

      if (response['success'] == true) {
        // Dispatch APIs 3 & 4: Register Custom Preferences / Features to the created ride ID
        final createdRideId = response['rideId'] ??
            response['id'] ??
            (response['data'] is Map
                ? (response['data']['rideId'] ?? response['data']['id'] ?? response['data']['_id'])
                : null);

        if (createdRideId != null && createdRideId.toString().isNotEmpty) {
          final rideIdStr = createdRideId.toString();

          // Sync preferences via Endpoint 2: PUT /api/rides/:rideId/preferences
          RideService.saveRidePreferences(
            rideId: rideIdStr,
            preferences: {
              'bookingMode': _isInstantBooking ? 'instant_booking' : 'review_request',
              'rideType': _isDoorToDoor ? 'door_to_door' : 'shared_ride',
              'acceptDoorToDoor': _isDoorToDoor,
              'wholeCarPrice': wholeCarPrice,
              'smoking': smokingAllowed ? 'allowed' : 'not_allowed',
              'ac': ac,
              'usbCharging': usbCharging,
              'wifi': wifi,
            },
          );

          // Dispatch Custom Features (API 3)
          for (final f in customFeatureItems) {
            RideService.addCustomPreference(
              rideId: rideIdStr,
              category: 'feature',
              label: f.label,
              type: 'checkbox',
              enabled: f.enabled,
              icon: f.icon ?? (f.label.toLowerCase().contains('ac') ? 'ac' : null),
            );
          }

          // Dispatch Custom Baggage / Customer Preferences (API 4)
          for (final c in customCustomerItems) {
            RideService.addCustomPreference(
              rideId: rideIdStr,
              category: 'customer',
              label: c.label,
              type: c.type == PreferenceItemType.counter ? 'counter' : 'checkbox',
              count: c.count > 0 ? c.count : 1,
              enabled: true,
            );
          }

          // Dispatch Custom Driver Preferences
          for (final d in customDriverItems) {
            RideService.addCustomPreference(
              rideId: rideIdStr,
              category: 'driver',
              label: d.label,
              type: 'checkbox',
              enabled: d.enabled,
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride Published Successfully! 🎉'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DriverRideManagementScreen(initialTabIndex: 1)),
          (route) => route.isFirst,
        );
      } else {
        // Check for 409 conflict (API 2 & API 3)
        final conflict = response['conflict'] is RideConflictResponse
            ? response['conflict'] as RideConflictResponse
            : RideConflictResponse.fromJson(response);

        if (conflict.hasConflict) {
          if (conflict.isScheduleOverlap) {
            // API 2: Post Ride Schedule Overlap Rejection
            await DriverConflictDialogs.showScheduleOverlapDialog(
              context,
              conflict: conflict.conflictingRide ?? const ConflictingRide(),
              onPickDifferentTime: () {
                // Navigate driver back to change time or date on calendar/post-ride screen
                Navigator.pop(context, {'action': 'change_date'});
              },
              onViewExistingTrip: conflict.conflictingRide != null && conflict.conflictingRide!.rideId.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverRideStartDetailsScreen(
                            rideId: conflict.conflictingRide!.rideId,
                            origin: conflict.conflictingRide!.from,
                            destination: conflict.conflictingRide!.to,
                          ),
                        ),
                      );
                    }
                  : null,
            );
            return;
          } else if (conflict.isActiveRideInProgress) {
            // API 3: Post Ride Rejection While Traveling
            DriverConflictDialogs.showActiveRideInProgressToast(
              context,
              conflict: conflict.conflictingRide ?? const ConflictingRide(),
              onGoToLiveTrip: conflict.conflictingRide != null && conflict.conflictingRide!.rideId.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverRideStartDetailsScreen(
                            rideId: conflict.conflictingRide!.rideId,
                            origin: conflict.conflictingRide!.from,
                            destination: conflict.conflictingRide!.to,
                          ),
                        ),
                      );
                    }
                  : null,
            );
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']?.toString() ?? 'Failed to publish ride. Please try again.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while publishing ride: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
          _template.screenTitle.isNotEmpty ? _template.screenTitle : 'Preference',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
            if (_isLoadingTemplate)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================== SECTION 1: DRIVER PREFERENCES ====================
                    _buildSectionHeader(_template.driverPreferences.title),
                    const SizedBox(height: 12),

                    // Toggle 1: Instant booking vs Review every request
                    _buildToggleCard(
                      option1Label: 'Instant booking',
                      option1Selected: _isInstantBooking,
                      onOption1Tap: () => setState(() => _isInstantBooking = true),
                      option2Label: 'Review every request',
                      option2Selected: !_isInstantBooking,
                      onOption2Tap: () => setState(() => _isInstantBooking = false),
                    ),
                    const SizedBox(height: 12),

                    // Toggle 2: Shared Ride vs Accept Door to Door request
                    _buildToggleCard(
                      option1Label: 'Shared Ride',
                      option1Selected: !_isDoorToDoor,
                      onOption1Tap: () => setState(() => _isDoorToDoor = false),
                      option2Label: 'Accept Door to Door request',
                      option2Selected: _isDoorToDoor,
                      onOption2Tap: () => setState(() => _isDoorToDoor = true),
                    ),
                    const SizedBox(height: 12),

                    ..._buildSectionItems(_template.driverPreferences),

                    const SizedBox(height: 24),

                    // ==================== SECTION 2: CUSTOMER PREFERENCES ====================
                    _buildSectionHeader(_template.customerPreferences.title),
                    const SizedBox(height: 12),
                    ..._buildSectionItems(_template.customerPreferences),
                    const SizedBox(height: 10),
                    _buildAddButton(
                      label: _template.customerPreferences.addButtonTitle,
                      onTap: () {
                        _showAddCustomDialog(
                          title: 'Add Custom Preference',
                          hint: 'e.g. Pet Friendly, Silent Ride, Child Seat',
                          category: 'customer',
                          onAdd: (item) {
                            setState(() => _template.customerPreferences.items.add(item));
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ==================== SECTION 3: RIDE FEATURES ====================
                    _buildSectionHeader(_template.rideFeatures.title),
                    const SizedBox(height: 12),
                    ..._buildSectionItems(_template.rideFeatures),
                    const SizedBox(height: 10),
                    _buildAddButton(
                      label: _template.rideFeatures.addButtonTitle,
                      onTap: () {
                        _showAddCustomDialog(
                          title: 'Add Ride Feature',
                          hint: 'e.g. Dashcam, Sunroof, Heated Seats',
                          category: 'feature',
                          onAdd: (item) {
                            setState(() => _template.rideFeatures.items.add(item));
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Save for future ride option
                    Row(
                      children: [
                        Checkbox(
                          value: _saveForFuture,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _saveForFuture = val ?? false);
                          },
                        ),
                        const Text(
                          'Save for future ride',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Publish Ride CTA Button
                    CustomButton(
                      text: _isPublishing ? 'Publishing Ride...' : 'Publish Ride',
                      isLoading: _isPublishing,
                      onPressed: _isPublishing ? null : _publishRide,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  List<Widget> _buildSectionItems(PreferenceSection section) {
    final widgets = <Widget>[];
    for (int i = 0; i < section.items.length; i++) {
      final item = section.items[i];
      // Auto approval is replaced with dedicated instant booking & door-to-door toggles
      if (item.key == 'autoApproval' ||
          item.id == 'dp-auto-approval' ||
          item.label.toLowerCase().contains('auto approval')) {
        continue;
      }

      if (item.key == 'smokingAllowed' || item.key == 'smoking' || item.id == 'cp-smoking') {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSmokingCard(
            item: item,
            onChanged: (allowed) => setState(() => item.enabled = allowed),
          ),
        ));
      } else if (item.type == PreferenceItemType.counter && !item.isCustom) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCounterCard(
            label: item.label,
            count: item.count,
            isCustom: item.isCustom,
            onChanged: (newCount) => setState(() => item.count = newCount),
            onDelete: item.isCustom ? () => setState(() => section.items.removeAt(i)) : null,
          ),
        ));
      } else {
        IconData? itemIcon;
        if (item.key == 'autoApproval') {
          itemIcon = Icons.bolt_rounded;
        } else if (item.key == 'ac' || item.label.toLowerCase() == 'ac' || item.label.toLowerCase().contains('air condition')) {
          itemIcon = Icons.ac_unit_rounded;
        } else if (item.key == 'usbCharging' || item.label.toLowerCase().contains('usb')) {
          itemIcon = Icons.power_rounded;
        }

        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCheckboxCard(
            label: item.label,
            value: item.enabled,
            icon: itemIcon,
            isCustom: item.isCustom,
            onChanged: (val) => setState(() => item.enabled = val ?? false),
            onDelete: item.isCustom ? () => setState(() => section.items.removeAt(i)) : null,
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _buildSmokingCard({
    required PreferenceItem item,
    required ValueChanged<bool> onChanged,
  }) {
    final isAllowed = item.enabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDF7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAllowed ? Icons.smoking_rooms_rounded : Icons.smoke_free_rounded,
                size: 20,
                color: isAllowed ? const Color(0xFFE65100) : AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Smoking allowed or not allowed',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(false),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !isAllowed ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isAllowed ? AppColors.primary : const Color(0xFFD0BCFF),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smoke_free_rounded,
                          size: 16,
                          color: !isAllowed ? Colors.white : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Not Allowed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: !isAllowed ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(true),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isAllowed ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAllowed ? AppColors.primary : const Color(0xFFD0BCFF),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smoking_rooms_rounded,
                          size: 16,
                          color: isAllowed ? Colors.white : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Allowed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: isAllowed ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
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

  Widget _buildAddButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxCard({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    IconData? icon,
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDF7),
        borderRadius: BorderRadius.circular(14),
        border: isCustom ? Border.all(color: AppColors.primary.withAlpha(40)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCustom && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                ),
              Checkbox(
                value: value,
                activeColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard({
    required String label,
    required int count,
    required ValueChanged<int> onChanged,
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDF7),
        borderRadius: BorderRadius.circular(14),
        border: isCustom ? Border.all(color: AppColors.primary.withAlpha(40)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCustom && onDelete != null) ...[
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],
              Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => onChanged(count + 1),
                    child: const Icon(Icons.arrow_drop_up_rounded, size: 18, color: AppColors.textPrimary),
                  ),
                  InkWell(
                    onTap: () => onChanged(count > 0 ? count - 1 : 0),
                    child: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Driver Preference Toggle Cards (Instant booking & Ride type) ───────────

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDF7),
        borderRadius: BorderRadius.circular(16),
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
              width: 22,
              height: 22,
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
                        size: 14,
                        color: Color(0xFF1D1B20),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}