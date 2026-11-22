import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/intermediate_pickup_model.dart';
import '../models/place_location_model.dart';
import '../models/ride_booking_model.dart';
import '../models/ride_preference_template_model.dart';

class RideService {
  /// Ride Search API: GET /api/rides/search or POST /api/rides/search (Backend 2.4.0)
  /// Supports geospatial coordinates, database sorting (price_asc, departure_asc), filters & pagination
  static Future<Map<String, dynamic>> searchRides({
    required String pickupLocation,
    required String destination,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
    String? date,
    int? passengers,
    String? sortBy,
    int? page,
    int? limit,
    String? rideType,
    String? filterBy,
    bool? acceptDoorToDoor,
    bool? isWholeCar,
    String? bookingMode,
    String? smoking,
    bool? ac,
  }) async {
    try {
      final seatCount = (passengers != null && passengers > 0) ? passengers : 1;
      final queryParams = <String>[
        'pickup=${Uri.encodeComponent(pickupLocation)}',
        'pickupLocation=${Uri.encodeComponent(pickupLocation)}',
        'destination=${Uri.encodeComponent(destination)}',
        if (pickupLat != null && pickupLat != 0.0) 'pickupLat=$pickupLat',
        if (pickupLng != null && pickupLng != 0.0) 'pickupLng=$pickupLng',
        if (destLat != null && destLat != 0.0) 'destLat=$destLat',
        if (destLng != null && destLng != 0.0) 'destLng=$destLng',
        if (date != null && date.isNotEmpty) 'date=${Uri.encodeComponent(date)}',
        'passengers=$seatCount',
        'seats=$seatCount',
        'capacity=$seatCount',
        if (filterBy != null && filterBy.isNotEmpty) 'filterBy=${Uri.encodeComponent(filterBy)}',
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy=${Uri.encodeComponent(sortBy)}',
        if (page != null && page > 0) 'page=$page',
        if (limit != null && limit > 0) 'limit=$limit',
        if (rideType != null && rideType.isNotEmpty) 'rideType=${Uri.encodeComponent(rideType)}',
        if (acceptDoorToDoor != null) 'acceptDoorToDoor=$acceptDoorToDoor',
        if (isWholeCar != null) 'isWholeCar=$isWholeCar',
        if (bookingMode != null && bookingMode.isNotEmpty) 'bookingMode=${Uri.encodeComponent(bookingMode)}',
        if (smoking != null && smoking.isNotEmpty) 'smoking=${Uri.encodeComponent(smoking)}',
        if (ac != null) 'ac=$ac',
      ];

      // Prefer GET with geospatial query params per Backend 2.4.0 specification
      final getRes = await ApiService.get('/rides/search?${queryParams.join('&')}');
      if (getRes['success'] == true) return getRes;

      // Fallback: POST /api/rides/search
      final body = <String, dynamic>{
        'pickup': pickupLocation,
        'pickupLocation': pickupLocation,
        'destination': destination,
        if (pickupLat != null && pickupLat != 0.0) 'pickupLat': pickupLat,
        if (pickupLng != null && pickupLng != 0.0) 'pickupLng': pickupLng,
        if (destLat != null && destLat != 0.0) 'destLat': destLat,
        if (destLng != null && destLng != 0.0) 'destLng': destLng,
        if (date != null && date.isNotEmpty) 'date': date,
        'seats': seatCount,
        'passengers': seatCount,
        'capacity': seatCount,
        if (filterBy != null && filterBy.isNotEmpty) 'filterBy': filterBy,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (rideType != null && rideType.isNotEmpty) 'rideType': rideType,
        if (acceptDoorToDoor != null) 'acceptDoorToDoor': acceptDoorToDoor,
        if (isWholeCar != null) 'isWholeCar': isWholeCar,
        if (bookingMode != null && bookingMode.isNotEmpty) 'bookingMode': bookingMode,
        if (smoking != null && smoking.isNotEmpty) 'smoking': smoking,
        if (ac != null) 'ac': ac,
      };

      return await ApiService.post('/rides/search', body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to search rides: $e',
        'rides': [],
      };
    }
  }

  /// Module 1: Validate Highway Corridor Stop (POST /api/rides/validate-corridor-stop)
  static Future<Map<String, dynamic>> validateCorridorStop({
    required String rideId,
    required LocationPoint origin,
    required LocationPoint destination,
    required LocationPoint stop,
    required double fullRideFare,
  }) async {
    try {
      final payload = <String, dynamic>{
        'rideId': rideId,
        'origin': {
          'name': origin.name,
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
        'destination': {
          'name': destination.name,
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'stop': {
          'name': stop.name,
          'latitude': stop.latitude,
          'longitude': stop.longitude,
        },
        'fullRideFare': fullRideFare,
      };

      final res = await ApiService.post('/rides/validate-corridor-stop', payload);
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to validate corridor stop: $e'};
    }
  }

  /// Module 1: Driver Custom Pickup Price Update (PUT /api/rides/:rideId/stops/price)
  static Future<Map<String, dynamic>> updateStopPrice({
    required String rideId,
    required int stopIndex,
    required double price,
  }) async {
    try {
      final payload = <String, dynamic>{
        'stopIndex': stopIndex,
        'price': price,
      };
      final res = await ApiService.put('/rides/$rideId/stops/price', payload);
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to update stop price: $e'};
    }
  }

  /// Module 2: Dynamic Fare Quote Engine (POST /api/rides/quote-fare)
  /// Calculates itemized fare, doorstep detour, promo discounts, issues 15-min quoteId
  static Future<Map<String, dynamic>> quoteFare({
    required String rideId,
    required String pickupName,
    double? pickupLat,
    double? pickupLng,
    bool isDoorstepPickup = false,
    required String dropoffName,
    double? dropoffLat,
    double? dropoffLng,
    bool isDoorstepDrop = false,
    required int seatsCount,
    String? promoCode,
  }) async {
    try {
      final payload = <String, dynamic>{
        'rideId': rideId,
        'pickup': {
          'name': pickupName,
          if (pickupLat != null && pickupLat != 0.0) 'latitude': pickupLat,
          if (pickupLng != null && pickupLng != 0.0) 'longitude': pickupLng,
          'isDoorstep': isDoorstepPickup,
        },
        'dropoff': {
          'name': dropoffName,
          if (dropoffLat != null && dropoffLat != 0.0) 'latitude': dropoffLat,
          if (dropoffLng != null && dropoffLng != 0.0) 'longitude': dropoffLng,
          'isDoorstep': isDoorstepDrop,
        },
        'seatsCount': seatsCount,
        if (promoCode != null && promoCode.trim().isNotEmpty) 'promoCode': promoCode.trim().toUpperCase(),
      };

      final res = await ApiService.post('/rides/quote-fare', payload);
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to quote fare: $e'};
    }
  }

  /// Driver Details & Timeline API: GET /api/rides/:id (or /api/rides/:id/details)
  /// Supports optional segment query parameters (pickup, destination) for dynamic segment fare calculation.
  static Future<Map<String, dynamic>> getRideDetails(
    String rideId, {
    String? pickup,
    String? destination,
  }) async {
    final queryParams = <String>[];
    if (pickup != null && pickup.trim().isNotEmpty) {
      queryParams.add('pickup=${Uri.encodeComponent(pickup.trim())}');
      queryParams.add('pickupLocation=${Uri.encodeComponent(pickup.trim())}');
    }
    if (destination != null && destination.trim().isNotEmpty) {
      queryParams.add('destination=${Uri.encodeComponent(destination.trim())}');
    }
    final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    try {
      final response = await ApiService.get('/rides/$rideId$qs');
      if (response['success'] == true) return response;
      return await ApiService.get('/rides/$rideId/details$qs');
    } catch (e) {
      try {
        return await ApiService.get('/rides/$rideId/details$qs');
      } catch (_) {
        return {
          'success': false,
          'message': 'Failed to get ride details: $e',
        };
      }
    }
  }

  /// Select Boarding Point API: GET /api/rides/:id/boarding-points
  static Future<Map<String, dynamic>> getBoardingPoints(String rideId) async {
    try {
      final response = await ApiService.get('/rides/$rideId/boarding-points');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get boarding points: $e',
        'boardingPoints': [],
      };
    }
  }

  /// Search Configuration & Placeholders API: GET /api/rides/search-config (or /api/rides/search-metadata)
  static Future<Map<String, dynamic>> getSearchConfig() async {
    try {
      final res = await ApiService.get('/rides/search-config');
      if (res['success'] == true) return res;
      return await ApiService.get('/rides/search-metadata');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get search config: $e',
      };
    }
  }

  /// Step 1: Submit Passenger Details API: POST /api/rides/:rideId/bookings or /api/rides/book
  /// Backend 2.4.0: Supports quoteId for tamper-proof fare locking.
  static Future<Map<String, dynamic>> createBooking({
    required String rideId,
    required String fullName,
    required String lastName,
    required String phoneNumber,
    required String emailID,
    required int numberOfSeats,
    required String boardingPoint,
    required String destination,
    String? quoteId,
    List<Map<String, dynamic>>? passengerDetailsList,
    String? pickup,
    String? customerPickupAddress,
    String? customerDropAddress,
    String? customerPickupPincode,
    String? customerPickupLandmark,
    String? custPickupLandmark,
    String? customerDropLandmark,
    String? paymentMethod,
    bool? doorstepPickupRequested,
    bool? isWholeCar,
    num? extraPickupCharge,
    num? pricePerSeat,
    num? totalAmount,
    String? luggage,
    String? status,
  }) async {
    try {
      final cleanRideId = rideId.trim();

      // Backend 2.4.0 Quote-driven secure booking
      if (quoteId != null && quoteId.isNotEmpty) {
        final passList = (passengerDetailsList != null && passengerDetailsList.isNotEmpty)
            ? passengerDetailsList
            : [
                {
                  'name': '$fullName $lastName'.trim(),
                  'phone': phoneNumber,
                  'email': emailID,
                }
              ];

        final securePayload = <String, dynamic>{
          'quoteId': quoteId,
          'passengerDetails': passList,
          'contactPhone': phoneNumber,
          'paymentMethod': paymentMethod ?? 'PAY_TO_DRIVER',
        };

        // Try POST /rides/:rideId/bookings
        if (cleanRideId.isNotEmpty) {
          final res = await ApiService.post('/rides/$cleanRideId/bookings', securePayload);
          if (res['success'] == true) return res;
        }

        // Fallback endpoint: POST /bookings/ride
        final altRes = await ApiService.post('/bookings/ride', securePayload);
        if (altRes['success'] == true) return altRes;
      }

      final landmark = customerPickupLandmark ?? custPickupLandmark ?? "";
      final desiredStatus = status ?? "pending";
      final effectiveDropAddress = (customerDropAddress != null && customerDropAddress.isNotEmpty)
          ? customerDropAddress
          : destination;
      final effectivePickupAddress = (customerPickupAddress != null && customerPickupAddress.isNotEmpty)
          ? customerPickupAddress
          : boardingPoint;

      final payload = <String, dynamic>{
        "rideId": cleanRideId.isNotEmpty ? cleanRideId : rideId,
        if (quoteId != null && quoteId.isNotEmpty) "quoteId": quoteId,
        "fullName": fullName,
        "lastName": lastName,
        "phoneNumber": phoneNumber,
        "emailID": emailID,
        "numberOfSeats": numberOfSeats,
        "seats": numberOfSeats,
        "boardingPoint": boardingPoint,
        "destination": destination,
        "pickup": (pickup != null && pickup.isNotEmpty) ? pickup : boardingPoint,
        "customerPickupAddress": effectivePickupAddress,
        "customerDropAddress": effectiveDropAddress,
        "customerPickupPincode": customerPickupPincode ?? "",
        "customerPickupLandmark": landmark,
        "custPickupLandmark": landmark,
        if (customerDropLandmark != null && customerDropLandmark.isNotEmpty) "customerDropLandmark": customerDropLandmark,
        "paymentMethod": paymentMethod ?? "PAY_TO_DRIVER",
        "doorstepPickupRequested": doorstepPickupRequested ?? (isWholeCar == true),
        "isWholeCar": isWholeCar ?? false,
        "extraPickupCharge": extraPickupCharge ?? 0,
        "pricePerSeat": pricePerSeat ?? 0,
        "totalAmount": totalAmount ?? 0,
        "luggage": luggage ?? "1 Medium Bag",
        "status": desiredStatus,
      };

      Map<String, dynamic> response = {};
      final rId = cleanRideId.isNotEmpty ? cleanRideId : rideId;

      // API 3 Smart Dual-Endpoint strategy
      if (isWholeCar == true && rId.isNotEmpty) {
        // Try dedicated whole-car booking endpoint first
        response = await ApiService.post('/rides/$rId/book-whole-car', payload);
        if (response['success'] != true) {
          response = await ApiService.post('/rides/$rId/book', payload);
        }
      } else if (rId.isNotEmpty) {
        // Try ride-scoped booking endpoint
        response = await ApiService.post('/rides/$rId/book', payload);
      }

      if (response['success'] != true) {
        // Fallback endpoint: POST /rides/book
        response = await ApiService.post('/rides/book', payload);
      }

      // Auto-recover if backend rejects with invalid or expired fare quote
      final errLower = (response['message'] ?? '').toString().toLowerCase();
      if (response['success'] != true && (errLower.contains('quote') || errLower.contains('expired'))) {
        try {
          // 1. Attempt to generate a fresh quote automatically
          final freshQuoteRes = await quoteFare(
            rideId: cleanRideId.isNotEmpty ? cleanRideId : rideId,
            pickupName: effectivePickupAddress,
            dropoffName: effectiveDropAddress,
            seatsCount: numberOfSeats,
            isDoorstepPickup: doorstepPickupRequested ?? false,
            isDoorstepDrop: doorstepPickupRequested ?? false,
          );

          if (freshQuoteRes['success'] == true && freshQuoteRes['data'] != null) {
            final newQuoteId = (freshQuoteRes['data']['quoteId'] ?? freshQuoteRes['quoteId'])?.toString();
            if (newQuoteId != null && newQuoteId.isNotEmpty) {
              payload['quoteId'] = newQuoteId;
              if (rId.isNotEmpty) {
                response = await ApiService.post('/rides/$rId/book', payload);
              }
              if (response['success'] != true) {
                response = await ApiService.post('/rides/book', payload);
              }
            }
          }
        } catch (_) {}

        // 2. If quote retry still failed, fallback to booking without the stale quoteId
        if (response['success'] != true) {
          payload.remove('quoteId');
          if (rId.isNotEmpty) {
            response = await ApiService.post('/rides/$rId/book', payload);
          }
          if (response['success'] != true) {
            response = await ApiService.post('/rides/book', payload);
          }
        }
      }

      if (response['success'] == true) {
        final createdBookingId = response['bookingId']?.toString() ??
            response['id']?.toString() ??
            (response['data'] is Map
                ? (response['data']['bookingId'] ?? response['data']['id'] ?? response['data']['_id'])?.toString()
                : null);

        if (createdBookingId != null && createdBookingId.isNotEmpty && desiredStatus == "pending") {
          await ApiService.patch('/bookings/$createdBookingId/status', {'status': 'pending'});
        }
      }
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create booking: $e',
      };
    }
  }

  /// Step 2: Payment Verification & Confirmation API: POST /api/payments/verify
  static Future<Map<String, dynamic>> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String method,
  }) async {
    try {
      final payload = {
        "bookingId": bookingId,
        "razorpayOrderId": razorpayOrderId,
        "razorpayPaymentId": razorpayPaymentId,
        "razorpaySignature": razorpaySignature,
        "method": method,
      };

      final response = await ApiService.post('/payments/verify', payload);
      debugPrint('🔍 [Payment Verify Response] $response');
      return response;
    } catch (e) {
      debugPrint('❌ [Payment Verify Error] $e');
      return {
        'success': false,
        'message': 'Payment verification failed: $e',
      };
    }
  }

  /// API 1: Get Ride Confirmation Screen Payload: GET /api/rides/bookings/:id/confirmation (or /api/bookings/:id/confirmation)
  static Future<Map<String, dynamic>> getRideConfirmation(String bookingId) async {
    try {
      final cleanId = bookingId.trim().replaceAll('#', '');
      var res = await ApiService.get('/rides/bookings/$cleanId/confirmation');
      if (res['success'] == true) return res;

      res = await ApiService.get('/bookings/$cleanId/confirmation');
      if (res['success'] == true) return res;

      return await ApiService.get('/bookings/$cleanId');
    } catch (e) {
      try {
        final cleanId = bookingId.trim().replaceAll('#', '');
        return await ApiService.get('/bookings/$cleanId/confirmation');
      } catch (_) {
        return {
          'success': false,
          'message': 'Failed to fetch ride confirmation: $e',
        };
      }
    }
  }

  /// API 2: Get View Trip Details & Digital Pass: GET /api/bookings/:id/pass (or /api/bookings/:id/confirmation)
  static Future<Map<String, dynamic>> getTripPassDetails(String bookingId) async {
    try {
      final cleanId = bookingId.trim().replaceAll('#', '');
      // 1. Primary endpoint per updated contract: /api/bookings/:id/pass
      var res = await ApiService.get('/bookings/$cleanId/pass');
      if (res['success'] == true) return res;

      // 2. Primary fallback per updated contract: /api/bookings/:id/confirmation
      res = await ApiService.get('/bookings/$cleanId/confirmation');
      if (res['success'] == true) return res;

      // 3. Backward-compatible alias routes
      res = await ApiService.get('/rides/bookings/$cleanId/pass');
      if (res['success'] == true) return res;

      res = await ApiService.get('/bookings/$cleanId/trip-details');
      if (res['success'] == true) return res;

      return await ApiService.get('/rides/bookings/$cleanId/trip-details');
    } catch (e) {
      try {
        final cleanId = bookingId.trim().replaceAll('#', '');
        var res = await ApiService.get('/bookings/$cleanId/pass');
        if (res['success'] == true) return res;
        return await ApiService.get('/bookings/$cleanId/confirmation');
      } catch (_) {
        return {
          'success': false,
          'message': 'Failed to fetch trip pass details: $e',
        };
      }
    }
  }

  /// API 3: Cancel Booking: POST /api/bookings/:id/cancel
  static Future<Map<String, dynamic>> cancelBooking(
    String bookingId, {
    String? reason,
    String? reasonCategory,
  }) async {
    try {
      final cleanId = bookingId.trim().replaceAll('#', '');
      final body = <String, dynamic>{
        'reasonCategory': reasonCategory ?? 'OTHER',
        'reasonDescription': reason ?? 'Cancelled by passenger',
        'reason': reason ?? 'Cancelled by passenger',
      };
      var res = await ApiService.post('/bookings/$cleanId/cancel', body);
      if (res['success'] == true) return res;

      res = await ApiService.post('/rides/bookings/$cleanId/cancel', body);
      if (res['success'] == true) return res;

      return await ApiService.delete('/bookings/$cleanId');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel booking: $e',
      };
    }
  }

  /// Scenario 1: Pre-Trip / Scheduled Route Stays: GET /api/properties/along-route?from=...&to=...&limit=10
  static Future<Map<String, dynamic>> getPropertiesAlongRoute({
    required String from,
    required String to,
    int limit = 10,
  }) async {
    try {
      final queryParams = [
        'from=${Uri.encodeComponent(from)}',
        'to=${Uri.encodeComponent(to)}',
        'limit=$limit',
      ];
      final res = await ApiService.get('/properties/along-route?${queryParams.join('&')}');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch properties along route: $e',
        'properties': [],
      };
    }
  }

  /// Scenario 2: Live In-Trip Real-Time GPS Tracking: GET /api/properties/nearby-live?lat=...&lng=...&radiusKm=15
  static Future<Map<String, dynamic>> getNearbyLiveProperties({
    required double lat,
    required double lng,
    double radiusKm = 15,
    int limit = 5,
  }) async {
    try {
      final queryParams = [
        'lat=$lat',
        'lng=$lng',
        'radiusKm=$radiusKm',
        'limit=$limit',
      ];
      final res = await ApiService.get('/properties/nearby-live?${queryParams.join('&')}');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch live nearby properties: $e',
        'properties': [],
        'propertyMarkers': [],
      };
    }
  }

  /// Helper for session-based booking
  static Future<Map<String, dynamic>> bookRide(RideBookingSession session) async {
    final requiresDriverApproval = !session.driver.preferences.autoApproval;
    final isWholeCar = session.driver.isWholeCarOnly ||
        session.driver.rideType == 'door_to_door' ||
        session.isDoorstepPickup;

    return createBooking(
      rideId: session.rideId,
      fullName: session.passengerName,
      lastName: session.passengerName.split(' ').length > 1 ? session.passengerName.split(' ').sublist(1).join(' ') : '',
      phoneNumber: session.passengerPhone,
      emailID: session.passengerEmail,
      numberOfSeats: session.seatsCount,
      boardingPoint: session.boardingPoint.isNotEmpty ? session.boardingPoint : session.pickup,
      destination: session.destination,
      pickup: session.pickup,
      customerPickupAddress: session.customerPickupAddress,
      customerDropAddress: session.customerDropAddress,
      customerPickupPincode: session.customerPickupPincode,
      customerPickupLandmark: session.customerPickupLandmark,
      custPickupLandmark: session.customerPickupLandmark,
      doorstepPickupRequested: session.isDoorstepPickup,
      isWholeCar: isWholeCar,
      extraPickupCharge: session.detourCharge,
      pricePerSeat: session.driver.pricePerSeat,
      totalAmount: session.totalAmount,
      luggage: session.luggage,
      status: requiresDriverApproval ? "pending" : "confirmed",
    );
  }

  /// API 1: Fetch Preference Screen Template or Ride Preferences:
  /// GET /api/rides/:rideId/preferences (or /api/rides/preferences/template)
  static Future<RidePreferenceTemplate> getPreferenceTemplate({String? rideId}) async {
    try {
      final endpoint = (rideId != null && rideId.isNotEmpty)
          ? '/rides/$rideId/preferences'
          : '/rides/preferences/template';
      final res = await ApiService.get(endpoint);
      if (res['success'] == true) {
        return RidePreferenceTemplate.fromJson(res);
      }
    } catch (e) {
      debugPrint('⚠️ [PreferenceTemplate] API unavailable, using fallback: $e');
    }
    return RidePreferenceTemplate.defaultTemplate();
  }

  /// API 2: Save Driver Preferences: PUT /api/rides/:rideId/preferences (fallback PATCH)
  static Future<Map<String, dynamic>> saveRidePreferences({
    required String rideId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final cleanId = rideId.trim().replaceAll('#', '');
      final res = await ApiService.put('/rides/$cleanId/preferences', preferences);
      if (res['success'] == true) return res;
      // Fallback to PATCH if PUT is not handled
      return await ApiService.patch('/rides/$cleanId/preferences', preferences);
    } catch (e) {
      try {
        final cleanId = rideId.trim().replaceAll('#', '');
        return await ApiService.patch('/rides/$cleanId/preferences', preferences);
      } catch (e2) {
        return {
          'success': false,
          'message': 'Failed to save ride preferences: $e2',
        };
      }
    }
  }

  /// API 5: Customer Booking: Whole Car Door-to-Door Trip
  /// POST /api/rides/book-door-to-door (fallback /api/rides/:rideId/book-door-to-door or /api/rides/book)
  static Future<Map<String, dynamic>> bookDoorToDoorTrip(Map<String, dynamic> bookingData) async {
    try {
      final rideId = bookingData['rideId']?.toString() ?? '';
      final payload = <String, dynamic>{
        ...bookingData,
        'isWholeCar': true,
        'bookingType': 'whole_car',
        'rideType': 'door_to_door',
      };

      // 1. Try POST /api/rides/book-door-to-door
      final res1 = await ApiService.post('/rides/book-door-to-door', payload);
      if (res1['success'] == true) return res1;

      // 2. Try POST /api/rides/:rideId/book-door-to-door
      if (rideId.isNotEmpty) {
        final res2 = await ApiService.post('/rides/$rideId/book-door-to-door', payload);
        if (res2['success'] == true) return res2;
      }

      // 3. Fallback to standard /rides/book with isWholeCar: true
      return await ApiService.post('/rides/book', payload);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to book door-to-door trip: $e',
      };
    }
  }

  /// API 6: Driver Review: View Pending Passenger Requests
  /// GET /api/rides/booking-requests (or /api/rides/:rideId/booking-requests)
  static Future<Map<String, dynamic>> getBookingRequests({String? rideId}) async {
    try {
      final endpoint = (rideId != null && rideId.isNotEmpty)
          ? '/rides/$rideId/booking-requests'
          : '/rides/booking-requests';
      final res = await ApiService.get(endpoint);
      if (res['success'] == true) return res;

      // Fallback to /drivers/booking-requests if driver-specific endpoint exists
      return await ApiService.get('/drivers/booking-requests');
    } catch (e) {
      try {
        return await ApiService.get('/drivers/booking-requests');
      } catch (_) {
        return {
          'success': false,
          'message': 'Failed to load booking requests: $e',
          'requests': [],
        };
      }
    }
  }

  /// API 7: Driver Review: Accept or Decline Passenger Request
  /// POST /api/rides/booking-requests/:bookingId/respond
  static Future<Map<String, dynamic>> respondToBookingRequest({
    required String bookingId,
    required String action, // "accept" or "decline"
    String? reason,
  }) async {
    try {
      final cleanId = bookingId.trim().replaceAll('#', '');
      final payload = <String, dynamic>{
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      // 1. Primary: POST /api/rides/booking-requests/:bookingId/respond
      final res1 = await ApiService.post('/rides/booking-requests/$cleanId/respond', payload);
      if (res1['success'] == true) return res1;

      // 2. Fallbacks: /api/rides/booking-requests/:bookingId/accept or /decline
      final subAction = action.toLowerCase() == 'accept' ? 'accept' : 'decline';
      final res2 = await ApiService.post('/rides/booking-requests/$cleanId/$subAction', payload);
      if (res2['success'] == true) return res2;

      // 3. Driver controller fallback: /drivers/booking-requests/:bookingId/:action
      return await ApiService.post('/drivers/booking-requests/$cleanId/$subAction', payload);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to respond to booking request: $e',
      };
    }
  }

  /// API 3 & 4: Add Custom Feature / Baggage / Preference: POST /api/rides/:id/preferences/custom
  static Future<Map<String, dynamic>> addCustomPreference({
    required String rideId,
    required String category, // 'feature', 'customer', or 'driver'
    required String label,
    required String type, // 'checkbox' or 'counter'
    bool enabled = true,
    int count = 1,
    String? icon,
  }) async {
    try {
      final cleanId = rideId.trim().replaceAll('#', '');
      final payload = <String, dynamic>{
        'category': category,
        'label': label,
        'type': type,
        'enabled': enabled,
        if (type == 'counter') 'count': count,
        if (icon != null && icon.isNotEmpty) 'icon': icon,
      };
      final res = await ApiService.post('/rides/$cleanId/preferences/custom', payload);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add custom preference: $e',
      };
    }
  }

  /// Calls POST /api/rides to publish a new intercity shared ride
  static Future<Map<String, dynamic>> createRide(Map<String, dynamic> rideData) async {
    try {
      final response = await ApiService.post('/rides', rideData);
      final data = response['data'] is Map ? response['data'] as Map<String, dynamic> : response;

      if (response['statusCode'] == 409 ||
          data['error'] == 'DRIVER_SCHEDULE_CONFLICT' ||
          data['error'] == 'DRIVER_TRIP_CONFLICT' ||
          data['conflictType'] != null) {
        final conflict = RideConflictResponse.fromJson(data);
        return {
          ...response,
          'success': false,
          'hasConflict': true,
          'conflict': conflict,
          'message': conflict.message.isNotEmpty
              ? conflict.message
              : (response['message'] ?? 'Schedule conflict detected.'),
        };
      }
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create ride: $e',
      };
    }
  }

  /// Calls PUT /api/rides/:rideId to update ride details (price, pickup, seats, etc.)
  static Future<Map<String, dynamic>> updateRide({
    required String rideId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final response = await ApiService.put('/rides/$rideId', updateData);
      if (response['success'] == true) return response;
      // Fallback to PATCH if PUT is not defined
      final patchResponse = await ApiService.patch('/rides/$rideId', updateData);
      return patchResponse;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update ride: $e',
      };
    }
  }

  /// Unified API: GET /api/rides with query filtering (?status=, ?driverId=, ?search=)
  static Future<Map<String, dynamic>> getRides({
    String? status,
    String? driverId,
    String? from,
    String? to,
    String? search,
  }) async {
    try {
      final queryParams = <String>[];
      if (status != null && status.isNotEmpty) queryParams.add('status=${Uri.encodeComponent(status)}');
      if (driverId != null && driverId.isNotEmpty) queryParams.add('driverId=${Uri.encodeComponent(driverId)}');
      if (from != null && from.isNotEmpty) queryParams.add('from=${Uri.encodeComponent(from)}');
      if (to != null && to.isNotEmpty) queryParams.add('to=${Uri.encodeComponent(to)}');
      if (search != null && search.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(search)}');

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final res = await ApiService.get('/rides$queryString');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch rides: $e',
        'rides': [],
      };
    }
  }

  /// API 1 & 2: GET /api/rides/active/start-details or /api/rides/{rideId}/start-details
  static Future<Map<String, dynamic>> getRideStartDetails({String? rideId}) async {
    final endpoint = (rideId != null && rideId.isNotEmpty && rideId != 'active')
        ? '/rides/$rideId/start-details'
        : '/rides/active/start-details';

    try {
      final res = await ApiService.get(endpoint);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get ride start details: $e',
      };
    }
  }

  /// API 3: POST /api/rides/{rideId}/send-message-all
  static Future<Map<String, dynamic>> sendBroadcastMessage({
    required String rideId,
    required String message,
  }) async {
    try {
      final res = await ApiService.post('/rides/$rideId/send-message-all', {'message': message});
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send broadcast message: $e',
      };
    }
  }

  /// Price per Seat Calculation: computes formula: distanceKm * basePricePerKm
  static Future<Map<String, dynamic>> calculatePricePerSeat({
    required double distanceKm,
    required double basePricePerKm,
    int? seats,
    String? from,
    String? to,
  }) async {
    final calculated = (distanceKm * basePricePerKm).roundToDouble();
    return {
      'success': true,
      'pricePerSeat': calculated,
      'totalDistanceKm': distanceKm,
      'basePricePerKm': basePricePerKm,
    };
  }

  /// Calculate Route, Distance & Polyline: POST /api/rides/calculate-route
  static Future<Map<String, dynamic>> calculateRoute({
    required String from,
    required String to,
    List<Map<String, dynamic>>? intermediatePickups,
  }) async {
    try {
      final payload = {
        'from': from,
        'to': to,
        if (intermediatePickups != null && intermediatePickups.isNotEmpty)
          'intermediatePickups': intermediatePickups,
      };
      final res = await ApiService.post('/rides/calculate-route', payload);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to calculate route: $e',
      };
    }
  }

  /// Auto-Suggest Intermediate Stop Fares API: POST /api/rides/calculate-intermediate-fares
  static Future<Map<String, dynamic>> calculateIntermediateFares({
    String? from,
    String? to,
    String? pickupLocation,
    String? destinationLocation,
    String? departureTime,
    num ratePerKm = 10,
    int seats = 3,
    num? price,
    required List<Map<String, dynamic>> intermediatePickups,
  }) async {
    try {
      final pickup = (pickupLocation != null && pickupLocation.isNotEmpty)
          ? pickupLocation
          : (from ?? '');
      final dest = (destinationLocation != null && destinationLocation.isNotEmpty)
          ? destinationLocation
          : (to ?? '');

      final formattedStops = intermediatePickups.map((p) {
        final loc = (p['location'] ?? p['name'] ?? '').toString();
        return {
          'location': loc,
          if (p['latitude'] != null) 'latitude': p['latitude'],
          if (p['longitude'] != null) 'longitude': p['longitude'],
          if (p['time'] != null && p['time'].toString().isNotEmpty) 'time': p['time'],
        };
      }).toList();

      final payload = <String, dynamic>{
        'pickupLocation': pickup,
        'destinationLocation': dest,
        'departureTime': departureTime ?? '07:00 PM',
        'ratePerKm': ratePerKm,
        'seats': seats,
        'intermediatePickups': formattedStops,
        // Backward compatibility keys
        'from': pickup,
        'to': dest,
        'origin': pickup,
        'destination': dest,
        if (price != null) 'price': price,
        if (price != null) 'fullRideFare': price,
        'stops': formattedStops,
      };
      final res = await ApiService.post('/rides/calculate-intermediate-fares', payload);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to calculate intermediate fares: $e',
      };
    }
  }

  /// Helper to extract list of stop fares from calculate-intermediate-fares response
  static List<Map<String, dynamic>> extractIntermediateFares(Map<String, dynamic> res) {
    if (res['success'] != true) return [];
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
    dynamic list = data['intermediatePickups'] ??
        data['intermediateStops'] ??
        res['intermediatePickups'] ??
        res['intermediateStops'] ??
        data['stops'] ??
        res['stops'];
    if (list is List) {
      return List<Map<String, dynamic>>.from(
        list.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    }
    dynamic fares = data['fares'] ?? res['fares'];
    if (fares is List) {
      return List<Map<String, dynamic>>.from(
        fares.map((f) => {'price': f}),
      );
    }
    return [];
  }

  /// Dedicated Highway Corridor Suggestions API: POST /api/rides/corridor-stops
  /// or GET /api/rides/corridor-stops
  /// Retrieves verified corridor highway stops, estimated arrival times, and proportional pricing.
  /// Also validates whether a search query stop is on-corridor or in the opposite direction.
  static Future<CorridorStopsResult> getCorridorStops({
    required String pickup,
    required String destination,
    String? departureTime,
    num? price,
    int? seats,
    String? query,
  }) async {
    final payload = <String, dynamic>{
      'pickup': pickup,
      'destination': destination,
      if (departureTime != null && departureTime.isNotEmpty) 'departureTime': departureTime,
      if (price != null && price > 0) 'price': price,
      if (seats != null && seats > 0) 'seats': seats,
      if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
    };

    try {
      final res = await ApiService.post('/rides/corridor-stops', payload);
      if (res['data'] is Map || res['success'] == true || res['allowed'] == false) {
        return CorridorStopsResult.fromJson(res);
      }

      // Fallback to GET query params if POST was not handled
      final qp = <String>[
        'pickup=${Uri.encodeComponent(pickup)}',
        'destination=${Uri.encodeComponent(destination)}',
        if (departureTime != null && departureTime.isNotEmpty)
          'departureTime=${Uri.encodeComponent(departureTime)}',
        if (price != null && price > 0) 'price=$price',
        if (seats != null && seats > 0) 'seats=$seats',
        if (query != null && query.trim().isNotEmpty)
          'q=${Uri.encodeComponent(query.trim())}',
      ];
      final getRes = await ApiService.get('/rides/corridor-stops?${qp.join('&')}');
      return CorridorStopsResult.fromJson(getRes);
    } catch (e) {
      return CorridorStopsResult.error(
        code: 'NETWORK_ERROR',
        message: 'Could not fetch highway corridor stops: $e',
      );
    }
  }

  /// Driver Detour Decision: POST /api/rides/detour-response
  /// Driver accepts or declines customer's doorstep detour request (> 10 km)
  static Future<Map<String, dynamic>> respondToDetourRequest({
    required String requestId,
    required String rideId,
    String? action,
    String? decision,
    double? extraFare,
    String? reason,
    String? customerName,
    String? customerPhone,
    String? pickupAddress,
    String? destinationAddress,
    num? detourDistanceKm,
    int? seats,
  }) async {
    try {
      final effectiveAction = action ?? decision ?? 'accept';
      final payload = <String, dynamic>{
        'requestId': requestId,
        'rideId': rideId,
        'action': effectiveAction,
        'decision': effectiveAction,
        if (extraFare != null) 'extraFare': extraFare,
        if (reason != null) 'reason': reason,
        if (customerName != null) 'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (pickupAddress != null) 'pickupAddress': pickupAddress,
        if (destinationAddress != null) 'destinationAddress': destinationAddress,
        if (detourDistanceKm != null) 'detourDistanceKm': detourDistanceKm,
        if (seats != null) 'seats': seats,
      };

      final response = await ApiService.post('/rides/detour-response', payload);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit detour decision: $e',
      };
    }
  }

  /// Contactless QR Code Pass Boarding: POST /api/rides/verify-qr-pass
  /// Driver scans passenger's live QR pass token for instant boarding and payment validation
  static Future<Map<String, dynamic>> verifyQrPass({
    required String token,
    String? bookingId,
    String? rideId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'token': token,
        'qrPassToken': token,
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        if (rideId != null && rideId.isNotEmpty) 'rideId': rideId,
      };

      final response = await ApiService.post('/rides/verify-qr-pass', payload);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify QR Code Pass: $e',
      };
    }
  }

  /// Driver Arrival Notification: POST /api/rides/:id/driver-arrived
  /// Driver signals arrival at passenger's pickup location
  static Future<Map<String, dynamic>> driverArrivedAtPickup({
    required String rideId,
  }) async {
    try {
      final response = await ApiService.post('/rides/$rideId/driver-arrived', {});
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to signal driver arrival: $e',
      };
    }
  }

  /// Module 3: Passenger Verification & Boarding Details: GET /api/rides/:id/passengers/:bookingId/boarding-details
  /// Backend 2.4.0: PIN is completely redacted from the driver-facing view for anti-tamper security.
  static Future<Map<String, dynamic>> getPassengerVerifyDetails({
    String? rideId,
    required String bookingId,
    String? passengerName,
  }) async {
    try {
      final cleanBId = bookingId.trim().replaceAll('#', '');
      if (rideId != null && rideId.trim().isNotEmpty) {
        final cleanRideId = rideId.trim();
        // 1. Try Backend 2.4.0 boarding-details
        final res = await ApiService.get('/rides/$cleanRideId/passengers/$cleanBId/boarding-details');
        if (res['success'] == true) return res;

        // 2. Fallback verify-details
        final res2 = await ApiService.get('/rides/$cleanRideId/passengers/$cleanBId/verify-details');
        if (res2['success'] == true) return res2;
      }

      final fallbackRes = await ApiService.get('/rides/passengers/$cleanBId/boarding-details');
      if (fallbackRes['success'] == true) return fallbackRes;

      return await ApiService.get('/rides/passengers/$cleanBId/verify-details');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get passenger verification details: $e',
      };
    }
  }

  /// Module 3: Verify Boarding PIN (POST /api/rides/:rideId/bookings/:bookingId/verify-boarding-pin)
  /// Backend 2.4.0: Server verifies hashed PIN. Unlimited attempts with zero lockout.
  static Future<Map<String, dynamic>> verifyPassengerPin({
    required String rideId,
    String? bookingId,
    required String pin,
    String? seatNumber,
    String? passengerName,
    double? latitude,
    double? longitude,
    String? expectedPin, // Deprecated: Kept for backwards compatibility
  }) async {
    try {
      final cleanPin = pin.trim();
      final cleanRideId = rideId.trim();
      final cleanBId = (bookingId != null && bookingId.isNotEmpty)
          ? bookingId.trim().replaceAll('#', '')
          : '';

      // 1. Primary: Backend 2.4.0 verify-boarding-pin endpoint
      if (cleanRideId.isNotEmpty && cleanBId.isNotEmpty) {
        final payload = <String, dynamic>{
          'pin': cleanPin,
          if (latitude != null) 'driverLatitude': latitude,
          if (longitude != null) 'driverLongitude': longitude,
          if (seatNumber != null && seatNumber.isNotEmpty) 'seatNumber': seatNumber,
          if (passengerName != null && passengerName.isNotEmpty) 'passengerName': passengerName,
        };

        final response = await ApiService.post('/rides/$cleanRideId/bookings/$cleanBId/verify-boarding-pin', payload);
        if (response['success'] == true || response['error'] == 'INVALID_PIN') {
          return response;
        }
      }

      // 2. Fallback: POST /api/rides/{rideId}/verify-pin
      final legacyPayload = {
        if (cleanBId.isNotEmpty) 'bookingId': cleanBId,
        'pin': cleanPin,
        if (seatNumber != null && seatNumber.isNotEmpty) 'seatNumber': seatNumber,
        if (passengerName != null && passengerName.isNotEmpty) 'passengerName': passengerName,
      };
      final fallbackResponse = await ApiService.post('/rides/$cleanRideId/verify-pin', legacyPayload);
      return fallbackResponse;
    } catch (e) {
      return {
        'success': false,
        'error': 'NETWORK_ERROR',
        'message': 'Failed to verify PIN: $e',
      };
    }
  }

  /// Module 5: Live Ride State Machine & Stop Progression (GET /api/rides/:rideId/live-status)
  static Future<Map<String, dynamic>> getLiveRideStatus(String rideId) async {
    try {
      final cleanId = rideId.trim();
      final res = await ApiService.get('/rides/$cleanId/live-status');
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch live ride status: $e'};
    }
  }

  /// Module 6: Cancellation Policy & Refund Preview (GET /api/bookings/:bookingId/cancellation-preview)
  static Future<Map<String, dynamic>> getCancellationPreview(String bookingId) async {
    try {
      final cleanId = bookingId.trim().replaceAll('#', '');
      final res = await ApiService.get('/bookings/$cleanId/cancellation-preview');
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch cancellation preview: $e'};
    }
  }

  /// API 6: POST /api/rides/{rideId}/start-ride or /api/rides/{rideId}/start-navigation
  static Future<Map<String, dynamic>> startNavigation({
    required String rideId,
    String? origin,
    String? destination,
  }) async {
    try {
      var res = await ApiService.post('/rides/$rideId/start-ride', {});
      if (res['statusCode'] == 404) {
        res = await ApiService.post('/rides/$rideId/start-navigation', {});
      }
      
      final data = res['data'] is Map ? res['data'] as Map<String, dynamic> : res;
      final isConflict = res['statusCode'] == 409 ||
          data['error'] == 'ACTIVE_RIDE_ALREADY_RUNNING' ||
          data['statusCode'] == 409;

      RideConflictResponse? conflict;
      if (isConflict) {
        conflict = RideConflictResponse.fromJson(data);
      }

      final isLocked = isConflict || data['isLocked'] == true || res['isLocked'] == true;
      
      return {
        ...res,
        ...data,
        'success': !isConflict && (res['success'] == true),
        'isLocked': isLocked,
        'hasActiveRideConflict': isConflict,
        if (conflict != null) 'conflict': conflict,
        'lockReason': data['lockReason'] ?? data['message'] ?? res['message'] ?? '',
        'startRideAllowedFrom': data['startRideAllowedFrom'] ?? '',
        'startRideAllowedFromFormatted': data['startRideAllowedFromFormatted'] ?? '',
        'hoursRemainingUntilStart': data['hoursRemainingUntilStart'],
        'minutesRemainingUntilStart': data['minutesRemainingUntilStart'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to start navigation: $e',
      };
    }
  }

  /// Alias for startNavigation: POST /api/rides/{rideId}/start-ride
  static Future<Map<String, dynamic>> startRide({required String rideId}) async {
    return await startNavigation(rideId: rideId);
  }

  /// Automated 5-Hour Pre-Trip Alarm Dispatch: POST /api/rides/{rideId}/send-pre-trip-alert
  static Future<Map<String, dynamic>> sendPreTripAlert({required String rideId}) async {
    try {
      final res = await ApiService.post('/rides/$rideId/send-pre-trip-alert', {});
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send pre-trip alert: $e',
      };
    }
  }

  /// Batch/Cron Pre-Trip Alarm Dispatch Scanner: GET /api/rides/check-pre-trip-alerts
  static Future<Map<String, dynamic>> checkPreTripAlerts() async {
    try {
      final res = await ApiService.get('/rides/check-pre-trip-alerts');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to check pre-trip alerts: $e',
      };
    }
  }

  /// API 7: POST /api/rides/{rideId}/complete-ride
  static Future<Map<String, dynamic>> completeRide({
    required String rideId,
  }) async {
    try {
      final res = await ApiService.post('/rides/$rideId/complete-ride', {});
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to complete ride: $e',
      };
    }
  }

  /// API 8 & 9: GET /api/rides/trip-shared or /api/rides/{rideId}/trip-card
  static Future<Map<String, dynamic>> getTripSharedCard({String? rideId}) async {
    final endpoint = (rideId != null && rideId.isNotEmpty && rideId != 'active')
        ? '/rides/$rideId/trip-card'
        : '/rides/trip-shared';

    try {
      final res = await ApiService.get(endpoint);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get trip card: $e',
      };
    }
  }

  /// 1. Master Auto-Switching Endpoint: GET /api/rides/:id/trip-shared
  /// Automatically returns the active stage based on ride.status (scheduled -> before_ride, in_progress/boarding -> during_ride, completed -> summary)
  static Future<Map<String, dynamic>> getTripSharedMaster({
    String? rideId,
    String? stage,
  }) async {
    final rId = (rideId != null && rideId.isNotEmpty && rideId != 'active') ? rideId : 'active';
    final query = (stage != null && stage.isNotEmpty) ? '?stage=$stage' : '';
    try {
      final res = await ApiService.get('/rides/$rId/trip-shared$query');
      if (res['success'] == true) return res;
      return await ApiService.get('/rides/trip-shared$query');
    } catch (_) {
      try {
        return await ApiService.get('/rides/trip-shared$query');
      } catch (e) {
        return {'success': false, 'message': 'Failed to get trip shared master: $e'};
      }
    }
  }

  /// 2. Screenshot 1: Trip Shared Card Before Ride (Pre-Ride State)
  /// GET /api/rides/:id/trip-shared/before-ride?booked=0
  static Future<Map<String, dynamic>> getTripSharedBeforeRide({
    String? rideId,
    int? booked,
  }) async {
    final rId = (rideId != null && rideId.isNotEmpty && rideId != 'active') ? rideId : 'active';
    final query = booked != null ? '?booked=$booked' : '';
    try {
      final res = await ApiService.get('/rides/$rId/trip-shared/before-ride$query');
      if (res['success'] == true) return res;
      return await ApiService.get('/rides/trip-shared/before-ride$query');
    } catch (_) {
      try {
        return await ApiService.get('/rides/trip-shared/before-ride$query');
      } catch (e) {
        return {'success': false, 'message': 'Failed to get before-ride trip card: $e'};
      }
    }
  }

  /// 3. Screenshot 2: Trip Shared Card During Ride (One-by-One Pickup Flow)
  /// GET /api/rides/:id/trip-shared/during-ride
  static Future<Map<String, dynamic>> getTripSharedDuringRide({
    String? rideId,
  }) async {
    final rId = (rideId != null && rideId.isNotEmpty && rideId != 'active') ? rideId : 'active';
    try {
      final res = await ApiService.get('/rides/$rId/trip-shared/during-ride');
      if (res['success'] == true) return res;
      return await ApiService.get('/rides/trip-shared/during-ride');
    } catch (_) {
      try {
        return await ApiService.get('/rides/trip-shared/during-ride');
      } catch (e) {
        return {'success': false, 'message': 'Failed to get during-ride trip card: $e'};
      }
    }
  }

  /// 4. Screenshot 3: Trip Shared Summary
  /// GET /api/rides/:id/trip-shared/summary
  static Future<Map<String, dynamic>> getTripSharedSummary({
    String? rideId,
  }) async {
    final rId = (rideId != null && rideId.isNotEmpty && rideId != 'active') ? rideId : 'active';
    try {
      final res = await ApiService.get('/rides/$rId/trip-shared/summary');
      if (res['success'] == true) return res;
      return await ApiService.get('/rides/trip-shared/summary');
    } catch (_) {
      try {
        return await ApiService.get('/rides/trip-shared/summary');
      } catch (e) {
        return {'success': false, 'message': 'Failed to get trip shared summary: $e'};
      }
    }
  }

  /// 5. Share Trip Again Button Action API
  /// POST /api/rides/:id/share-again
  static Future<Map<String, dynamic>> shareTripAgain({
    required String rideId,
    String? recipientPhone,
    String shareChannel = 'whatsapp',
  }) async {
    final body = {
      if (recipientPhone != null && recipientPhone.isNotEmpty) 'recipientPhone': recipientPhone,
      'shareChannel': shareChannel,
    };
    try {
      final res = await ApiService.post('/rides/$rideId/share-again', body);
      if (res['success'] == true) return res;
      return await ApiService.post('/rides/share-again', body);
    } catch (_) {
      try {
        return await ApiService.post('/rides/share-again', body);
      } catch (e) {
        return {'success': false, 'message': 'Failed to share trip again: $e'};
      }
    }
  }

  /// API 10: GET /api/rides/next-pickup
  static Future<Map<String, dynamic>> getNextPickupDetails() async {
    try {
      final res = await ApiService.get('/rides/next-pickup');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get next pickup details: $e',
      };
    }
  }

  /// API 11: DELETE /api/rides/:id (Delete/Cancel Ride)
  static Future<Map<String, dynamic>> deleteRide(String rideId, {String? reason}) async {
    try {
      if (rideId.isEmpty) {
        return {'success': false, 'message': 'Invalid ride ID.'};
      }

      var res = await ApiService.delete('/rides/$rideId');
      if (res['success'] == true) return res;

      res = await ApiService.delete('/drivers/rides/$rideId');
      if (res['success'] == true) return res;

      res = await ApiService.post('/rides/$rideId/cancel', {
        'reason': reason ?? 'Driver deleted upcoming ride',
        'status': 'cancelled',
      });
      if (res['success'] == true) return res;

      res = await ApiService.patch('/rides/$rideId', {
        'status': 'cancelled',
      });
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete ride: $e',
      };
    }
  }

  /// Group A API 1: GET /api/rides/:id/rate-screen-details (Customer Rate Screen Pre-fill)
  static Future<Map<String, dynamic>> getRateScreenDetails(String rideId) async {
    try {
      final cleanId = rideId.trim();
      var res = await ApiService.get('/rides/$cleanId/rate-screen-details');
      if (res['success'] == true) return res;

      res = await ApiService.get('/reviews/rate-screen-details?rideId=$cleanId');
      if (res['success'] == true) return res;

      res = await ApiService.get('/bookings/$cleanId/rate-screen-details');
      if (res['success'] == true) return res;

      return {
        'success': false,
        'message': 'No rate screen details found for ride $cleanId',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch rate screen details: $e',
      };
    }
  }

  /// Group A API 2: POST /api/reviews/rate-ride (Submit Completed Ride Rating)
  static Future<Map<String, dynamic>> submitRateRide(Map<String, dynamic> payload) async {
    try {
      // 1. Primary endpoint: POST /api/reviews/rate-ride
      var res = await ApiService.post('/reviews/rate-ride', payload);
      if (res['success'] == true) return res;

      // 2. Fallback aliases
      final rideId = payload['rideId']?.toString() ?? '';
      if (rideId.isNotEmpty) {
        res = await ApiService.post('/rides/$rideId/rate', payload);
        if (res['success'] == true) return res;
      }

      final bookingId = payload['bookingId']?.toString() ?? '';
      if (bookingId.isNotEmpty) {
        res = await ApiService.post('/bookings/$bookingId/rate', payload);
        if (res['success'] == true) return res;
      }

      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit review: $e',
      };
    }
  }
}

