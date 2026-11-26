import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_maps_service.dart';
import 'ride_service.dart';

/// Manages customer active ride pre-pickup window (30-min threshold)
/// and coordinates live location sharing with the assigned driver.
class CustomerLocationTrackingService with ChangeNotifier {
  static final CustomerLocationTrackingService instance =
      CustomerLocationTrackingService._internal();

  CustomerLocationTrackingService._internal() {
    _initFromStorage();
  }

  static const String _keyBookingId = 'customer_active_booking_id';
  static const String _keyPickupTime = 'customer_active_booking_pickup_time';
  static const String _keyDriverName = 'customer_active_booking_driver_name';
  static const String _keyPickupAddress = 'customer_active_booking_pickup_address';

  String? _activeBookingId;
  DateTime? _activePickupTime;
  String? _driverName;
  String? _pickupAddress;

  Timer? _syncTimer;
  Timer? _windowCheckTimer;
  bool _isTracking = false;

  String? get activeBookingId => _activeBookingId;
  DateTime? get activePickupTime => _activePickupTime;
  String? get driverName => _driverName;
  String? get pickupAddress => _pickupAddress;
  bool get isTracking => _isTracking;

  /// Loads persisted booking state on startup
  Future<void> _initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeBookingId = prefs.getString(_keyBookingId);
      final rawTime = prefs.getString(_keyPickupTime);
      if (rawTime != null && rawTime.isNotEmpty) {
        _activePickupTime = DateTime.tryParse(rawTime);
      }
      _driverName = prefs.getString(_keyDriverName);
      _pickupAddress = prefs.getString(_keyPickupAddress);

      // Start window monitor timer to refresh UI state when entering/exiting the 30-min window
      _startWindowCheckTimer();
      notifyListeners();

      // Check if location is already active and we are in window
      if (isWithinPrePickupWindow()) {
        final available = await GoogleMapsService.isLocationAvailable();
        if (available) {
          startPeriodicLocationSync();
        }
      }
    } catch (e) {
      debugPrint('Error loading active customer booking: $e');
    }
  }

  /// Helper to set active booking from string date/time representations
  Future<void> setActiveBookingFromStrings({
    required String bookingId,
    required String? dateStr,
    required String? timeStr,
    String? driverName,
    String? pickupAddress,
  }) async {
    final pickupDateTime = parsePickupDateTime(dateStr, timeStr);
    if (pickupDateTime != null && bookingId.isNotEmpty) {
      await setActiveBooking(
        bookingId: bookingId,
        pickupDateTime: pickupDateTime,
        driverName: driverName,
        pickupAddress: pickupAddress,
      );
    }
  }

  /// Parses various date and time formats into a DateTime
  static DateTime? parsePickupDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      DateTime? baseDate = DateTime.tryParse(dateStr.trim());
      if (baseDate == null) {
        final match = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(dateStr);
        if (match != null) {
          baseDate = DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        } else {
          final parts = dateStr.replaceAll(',', '').replaceAll('.', '').split(' ');
          final months = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
          };
          int? day, month, year;
          for (final part in parts) {
            final p = part.trim().toLowerCase();
            if (months.containsKey(p)) {
              month = months[p];
            } else if (int.tryParse(p) != null) {
              final val = int.parse(p);
              if (val > 1000) {
                year = val;
              } else if (day == null && val <= 31) {
                day = val;
              }
            }
          }
          if (year != null && month != null && day != null) {
            baseDate = DateTime(year, month, day);
          }
        }
      }
      baseDate ??= DateTime.now();

      int hour = 0;
      int minute = 0;
      if (timeStr != null && timeStr.trim().isNotEmpty) {
        final clean = timeStr.trim().toUpperCase();
        final isPm = clean.contains('PM');
        final isAm = clean.contains('AM');
        final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(clean);
        if (timeMatch != null) {
          hour = int.parse(timeMatch.group(1)!);
          minute = int.parse(timeMatch.group(2)!);
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour == 12) hour = 0;
        }
      }
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Sets or updates the current active confirmed booking
  Future<void> setActiveBooking({
    required String bookingId,
    required DateTime pickupDateTime,
    String? driverName,
    String? pickupAddress,
  }) async {
    _activeBookingId = bookingId;
    _activePickupTime = pickupDateTime;
    _driverName = driverName;
    _pickupAddress = pickupAddress;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBookingId, bookingId);
      await prefs.setString(_keyPickupTime, pickupDateTime.toIso8601String());
      if (driverName != null) {
        await prefs.setString(_keyDriverName, driverName);
      }
      if (pickupAddress != null) {
        await prefs.setString(_keyPickupAddress, pickupAddress);
      }
    } catch (e) {
      debugPrint('Error saving active customer booking: $e');
    }

    _startWindowCheckTimer();
    notifyListeners();

    // If already in window and location is available, start sync
    if (isWithinPrePickupWindow()) {
      final available = await GoogleMapsService.isLocationAvailable();
      if (available) {
        startPeriodicLocationSync();
      }
    }
  }

  /// Clears active booking upon trip completion or cancellation
  Future<void> clearActiveBooking() async {
    _activeBookingId = null;
    _activePickupTime = null;
    _driverName = null;
    _pickupAddress = null;
    stopPeriodicLocationSync();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBookingId);
      await prefs.remove(_keyPickupTime);
      await prefs.remove(_keyDriverName);
      await prefs.remove(_keyPickupAddress);
    } catch (e) {
      debugPrint('Error clearing active booking: $e');
    }

    notifyListeners();
  }

  /// Checks if current time is within 30 minutes prior to pickup time
  /// Window: [PickupTime - 30 minutes, PickupTime]
  bool isWithinPrePickupWindow() {
    if (_activeBookingId == null || _activePickupTime == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = _activePickupTime!.difference(now);

    // difference > 0 means pickup is in future
    // inMinutes <= 30 means within 30 minutes before pickup
    return difference.inSeconds > 0 && difference.inMinutes <= 30;
  }

  /// Determines if the orange alert banner should be shown.
  /// Only returns true if in the 30-min window AND location is not available.
  Future<bool> shouldShowLocationBanner() async {
    if (!isWithinPrePickupWindow()) {
      return false;
    }
    final isAvailable = await GoogleMapsService.isLocationAvailable();
    return !isAvailable;
  }

  /// Tries to request system permissions and starts location sharing if granted.
  /// Returns true if location is successfully enabled and sharing started.
  Future<bool> enableLocationAndStartSharing() async {
    final granted = await GoogleMapsService.requestSystemLocationPermission();
    if (granted) {
      startPeriodicLocationSync();
      notifyListeners();
      return true;
    } else {
      // Check if blocked and open settings if needed
      await GoogleMapsService.openSettingsIfNeeded();
      final recheck = await GoogleMapsService.isLocationAvailable();
      if (recheck) {
        startPeriodicLocationSync();
        notifyListeners();
        return true;
      }
    }
    notifyListeners();
    return false;
  }

  /// Starts periodic sync (every 45s) to push customer location to backend
  void startPeriodicLocationSync() {
    if (_isTracking && _syncTimer != null && _syncTimer!.isActive) {
      return;
    }
    _isTracking = true;
    // Trigger immediate sync
    _sendLocationUpdate();

    // Start 45-second periodic timer
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!isWithinPrePickupWindow()) {
        stopPeriodicLocationSync();
        return;
      }
      _sendLocationUpdate();
    });
  }

  /// Sends customer current location to driver via backend
  Future<void> _sendLocationUpdate() async {
    if (_activeBookingId == null) return;
    try {
      final point = await GoogleMapsService.getCurrentLocation();
      if (point != null) {
        await RideService.updateCustomerLocation(
          bookingId: _activeBookingId!,
          latitude: point.latitude,
          longitude: point.longitude,
          address: point.formattedAddress,
        );
        debugPrint('Synced customer location with driver: ${point.latitude}, ${point.longitude}');
      }
    } catch (e) {
      debugPrint('Error syncing customer location to driver: $e');
    }
  }

  /// Stops periodic location sync
  void stopPeriodicLocationSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  /// Checks the window every 30 seconds to trigger banner appearance or dismissal
  void _startWindowCheckTimer() {
    _windowCheckTimer?.cancel();
    _windowCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      notifyListeners();
      if (!isWithinPrePickupWindow() && _isTracking) {
        stopPeriodicLocationSync();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _windowCheckTimer?.cancel();
    super.dispose();
  }
}
