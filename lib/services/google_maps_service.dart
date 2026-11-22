import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_env.dart';
import '../models/place_location_model.dart';

class GoogleMapsService {
  /// Google Maps Places & Directions API Key from AppEnv
  static String get apiKey => AppEnv.googleMapsApiKey;

  static const String _autocompleteBaseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _placeDetailsBaseUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// 1. Address Search Autocomplete (Live Google Places API)
  /// Endpoint: GET https://maps.googleapis.com/maps/api/place/autocomplete/json
  static Future<List<PlaceAutocompletePrediction>> getAutocompleteSuggestions(
    String query, {
    String countryCode = 'in',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_autocompleteBaseUrl?input=${Uri.encodeComponent(trimmed)}&key=$apiKey&components=country:$countryCode',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List<dynamic>? ?? [];
          return predictions
              .map((p) => PlaceAutocompletePrediction.fromJson(p as Map<String, dynamic>))
              .toList();
        } else {
          debugPrint('Google Autocomplete API: status=$status, message=${data['error_message']}');
        }
      }
    } catch (e) {
      debugPrint('Error calling Google Autocomplete API: $e');
    }
    return [];
  }

  /// 2. Place Details API (Live Google Places Details API)
  /// Endpoint: GET https://maps.googleapis.com/maps/api/place/details/json
  static Future<LocationPoint?> getPlaceDetails(String placeId) async {
    if (placeId.trim().isEmpty) return null;

    try {
      final url = Uri.parse(
        '$_placeDetailsBaseUrl?place_id=$placeId&fields=name,formatted_address,geometry&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK' && data['result'] != null) {
          return LocationPoint.fromJson(data['result'] as Map<String, dynamic>, placeId: placeId);
        } else {
          debugPrint('Google Place Details API: status=$status, message=${data['error_message']}');
        }
      }
    } catch (e) {
      debugPrint('Error calling Google Place Details API: $e');
    }
    return null;
  }

  /// 3. Google Directions API (Live Google Directions API)
  /// Endpoint: GET https://maps.googleapis.com/maps/api/directions/json
  static Future<RouteResult?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_directionsBaseUrl?origin=$originLat,$originLng&destination=$destLat,$destLng&mode=driving&alternatives=true&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK') {
          return RouteResult.fromJson(data);
        } else {
          debugPrint('Google Directions API: status=$status, message=${data['error_message']}');
        }
      }
    } catch (e) {
      debugPrint('Error calling Google Directions API: $e');
    }
    return null;
  }

  /// 3b. Google Directions API by Address / Place Name
  static Future<RouteResult?> getDirectionsByAddress({
    required String origin,
    required String destination,
  }) async {
    final origTrim = origin.trim();
    final destTrim = destination.trim();
    if (origTrim.isEmpty || destTrim.isEmpty) return null;

    try {
      final url = Uri.parse(
        '$_directionsBaseUrl?origin=${Uri.encodeComponent(origTrim)}&destination=${Uri.encodeComponent(destTrim)}&mode=driving&alternatives=true&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK') {
          return RouteResult.fromJson(data);
        } else {
          debugPrint('Google Directions (address) API: status=$status, message=${data['error_message']}');
        }
      }
    } catch (e) {
      debugPrint('Error calling Google Directions by address: $e');
    }
    return null;
  }

  /// 4. Reverse Geocoding API (Live Google Geocoding API)
  /// Endpoint: GET https://maps.googleapis.com/maps/api/geocode/json
  static Future<LocationPoint?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final formatted = first['formatted_address']?.toString() ?? '';
          final placeId = first['place_id']?.toString() ?? '';
          return LocationPoint(
            name: formatted.split(',').first,
            formattedAddress: formatted,
            latitude: lat,
            longitude: lng,
            placeId: placeId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
    return null;
  }

  /// Checks and triggers the default Android/iOS system runtime location permission dialog.
  /// Returns true if granted (while in use or always).
  static Future<bool> requestSystemLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Location permission request error: $e');
      return false;
    }
  }

  /// 5. Live Device / Current Location Resolver with True Hardware GPS
  static Future<LocationPoint?> getCurrentLocation() async {
    // 1. Check if device location services (GPS) are enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // 2. Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const PermissionDeniedException(
        'Location permission was denied. Please allow location access to use your current location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permissions are permanently denied. Please enable them in your device or browser settings.',
      );
    }

    // 3. Acquire Position
    Position? position;
    try {
      // First try high-accuracy GPS with generous 12s timeout
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      debugPrint('High accuracy GPS timed out or failed: $e. Checking last known or medium accuracy...');
      try {
        // Fast instant check for cached last known position
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // If still null, try balanced / medium accuracy
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {}
      }
    }

    if (position == null) {
      throw TimeoutException(
        'Could not acquire your GPS location. Please ensure location services are enabled and you have a clear GPS signal, or search your address manually.',
      );
    }

    // 4. Reverse geocode to exact street, landmark, area, city & pin code
    final geoPoint = await reverseGeocode(position.latitude, position.longitude);
    if (geoPoint != null && geoPoint.formattedAddress.isNotEmpty) {
      return geoPoint;
    }

    return LocationPoint(
      name: 'Current Location',
      formattedAddress: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Helper to convert location exceptions into user-friendly diagnostic messages
  static String getReadableLocationError(dynamic error) {
    if (error is LocationServiceDisabledException) {
      return 'Location services (GPS) are turned off. Please enable GPS on your device or browser.';
    } else if (error is PermissionDeniedException) {
      final msg = error.message ?? '';
      return msg.isNotEmpty
          ? msg
          : 'Location permission was denied. Please allow location access in your browser or device settings.';
    } else if (error is TimeoutException) {
      return 'GPS request timed out. Please check your signal or search your location.';
    }
    final str = error.toString().replaceAll('Exception: ', '').trim();
    return str.isNotEmpty ? str : 'Unable to acquire current location.';
  }
}


