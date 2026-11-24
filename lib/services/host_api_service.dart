import 'package:flutter/foundation.dart';
import '../data/host_static_data.dart';
import 'api_service.dart';

/// Centralized service handling the host-side backend APIs.
///
/// While [useStaticData] is true every method returns sample data from
/// [HostStaticData] and never touches the network. Set it to false when the
/// real APIs are integrated (then delete lib/data/host_static_data.dart).
///
/// In live mode a failed call returns `{'success': false, 'message': ...}` so
/// callers can show a real error; it never pretends to have succeeded.
class HostApiService {
  HostApiService._();

  /// TEMPORARY: serve sample data instead of calling the backend.
  static bool useStaticData = true;

  // Cached in-memory metadata
  static Map<String, dynamic>? _cachedMetadata;

  /// Small delay so loading states are visible while running on static data.
  static Future<void> _staticDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  static Map<String, dynamic> _failure(String api, Object? error) {
    debugPrint('HostApiService: $api failed: $error');
    return {'success': false, 'message': error?.toString() ?? 'Request failed'};
  }

  // ---------------------------------------------------------------------------
  // 1. Host Mobile Dashboard (Screen 1)
  // GET /api/hosts/dashboard?period=this_month
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getDashboard({
    String period = 'this_month',
    String? hostId,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.dashboard(period); // STATIC
    }

    try {
      final queryParams = <String, String>{
        'period': period,
        if (hostId != null && hostId.isNotEmpty) 'hostId': hostId,
      };
      final queryString = Uri(queryParameters: queryParams).query;

      final res = await ApiService.get('/hosts/dashboard?$queryString');
      if (res['success'] == true && res['dashboard'] != null) {
        return res;
      }

      // Try alternate endpoint
      final altRes = await ApiService.get('/hosts/home?$queryString');
      if (altRes['success'] == true && altRes['dashboard'] != null) {
        return altRes;
      }
      return _failure('getDashboard', res['message']);
    } catch (e) {
      return _failure('getDashboard', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Reference Metadata for Listing Wizard
  // GET /api/hosts/properties/metadata
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getPropertiesMetadata({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedMetadata != null) {
      return {'success': true, 'metadata': _cachedMetadata};
    }

    if (useStaticData) {
      await _staticDelay();
      _cachedMetadata = HostStaticData.propertiesMetadata(); // STATIC
      return {'success': true, 'metadata': _cachedMetadata};
    }

    try {
      final res = await ApiService.get('/hosts/properties/metadata');
      if (res['success'] == true && res['metadata'] != null) {
        _cachedMetadata = Map<String, dynamic>.from(res['metadata']);
        return res;
      }
      return _failure('getPropertiesMetadata', res['message']);
    } catch (e) {
      return _failure('getPropertiesMetadata', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Wizard Step Save API
  // POST /api/hosts/properties/wizard/step
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> saveWizardStep({
    required int step,
    Map<String, dynamic>? stepData,
    Map<String, dynamic>? payload,
    String? propertyId,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.wizardStep(step: step, propertyId: propertyId); // STATIC
    }

    final effectiveData = stepData ?? payload ?? <String, dynamic>{};
    final body = <String, dynamic>{
      'step': step,
      if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
      ...effectiveData,
    };

    try {
      final res = await ApiService.post('/hosts/properties/wizard/step', body);
      if (res['success'] == true) return res;
      return _failure('saveWizardStep', res['message']);
    } catch (e) {
      return _failure('saveWizardStep', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Create Custom Facility from Dialog Box (Screen 11 / 12)
  // POST /api/hosts/properties/metadata/facilities
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> createCustomFacility({
    required String name,
    required String provisionType,
    double extraCharge = 0.0,
    String? propertyId,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.customFacility( // STATIC
        name: name,
        provisionType: provisionType,
        extraCharge: extraCharge,
      );
    }

    final body = {
      'name': name,
      'provisionType': provisionType,
      'extraCharge': extraCharge,
      if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
    };

    try {
      final res = await ApiService.post('/hosts/properties/metadata/facilities', body);
      if (res['success'] == true) return res;
      return _failure('createCustomFacility', res['message']);
    } catch (e) {
      return _failure('createCustomFacility', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Add Additional Spoken Language (Screen 13)
  // POST /api/hosts/properties/metadata/languages
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> addCustomLanguage({
    required String language,
    String? propertyId,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.customLanguage(language); // STATIC
    }

    final body = {
      'language': language,
      if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
    };

    try {
      final res = await ApiService.post('/hosts/properties/metadata/languages', body);
      if (res['success'] == true) return res;
      return _failure('addCustomLanguage', res['message']);
    } catch (e) {
      return _failure('addCustomLanguage', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 6. Upload Property Photos (Screen 18)
  // POST /api/hosts/properties/upload-photos
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> uploadPropertyPhotos({
    List<dynamic>? files,
    String? propertyId,
  }) async {
    final effectiveFiles = files ?? <dynamic>[];
    if (effectiveFiles.isEmpty) {
      return {'success': true, 'count': 0, 'photos': <String>[]};
    }

    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.uploadedPhotos(effectiveFiles.length); // STATIC
    }

    try {
      final res = await ApiService.uploadMultipart(
        '/hosts/properties/upload-photos',
        fieldName: 'photos',
        files: effectiveFiles,
      );

      if (res['success'] == true && res['photos'] != null) {
        return {
          'success': true,
          'count': (res['photos'] as List).length,
          'photos': List<String>.from(res['photos']),
        };
      }
      return _failure('uploadPropertyPhotos', res['message']);
    } catch (e) {
      return _failure('uploadPropertyPhotos', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 7. Resume / Fetch Active Property Draft
  // GET /api/hosts/properties/wizard/draft
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getActiveDraft() async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.activeDraft(); // STATIC
    }

    try {
      final res = await ApiService.get('/hosts/properties/wizard/draft');
      if (res['success'] == true) return res;
      return _failure('getActiveDraft', res['message']);
    } catch (e) {
      return _failure('getActiveDraft', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 8. Final Listing Publication (Screen 24 / Completion)
  // POST /api/hosts/properties/publish
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> publishProperty({
    required String propertyId,
    required double price,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.published(propertyId: propertyId, price: price); // STATIC
    }

    final body = {
      'propertyId': propertyId,
      'price': price,
    };

    try {
      final res = await ApiService.post('/hosts/properties/publish', body);
      if (res['success'] == true) return res;
      return _failure('publishProperty', res['message']);
    } catch (e) {
      return _failure('publishProperty', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 9. Get Host's Properties List ("Property" Tab)
  // GET /api/hosts/properties
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getHostProperties() async {
    if (useStaticData) {
      await _staticDelay();
      final list = HostStaticData.properties(); // STATIC
      return {'success': true, 'count': list.length, 'properties': list};
    }

    try {
      final res = await ApiService.get('/hosts/properties');
      if (res['success'] == true && res['properties'] != null) return res;
      return _failure('getHostProperties', res['message']);
    } catch (e) {
      return _failure('getHostProperties', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 10. Bookings (list, detail, payments, OTP, review, cancel, offline booking)
  // ---------------------------------------------------------------------------

  /// GET /api/hosts/bookings?status=active|upcoming|completed|cancelled
  static Future<Map<String, dynamic>> getBookings(String status) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.bookings(status); // STATIC
    }
    try {
      final res = await ApiService.get('/hosts/bookings?status=$status');
      if (res['success'] == true && res['bookings'] != null) return res;
      return _failure('getBookings', res['message']);
    } catch (e) {
      return _failure('getBookings', e);
    }
  }

  /// GET /api/hosts/bookings/:id
  static Future<Map<String, dynamic>> getBooking(String id) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.booking(id); // STATIC
    }
    try {
      final res = await ApiService.get('/hosts/bookings/$id');
      if (res['success'] == true && res['booking'] != null) return res;
      return _failure('getBooking', res['message']);
    } catch (e) {
      return _failure('getBooking', e);
    }
  }

  /// POST /api/hosts/bookings/:id/payments   kind: 'advance' | 'balance'
  static Future<Map<String, dynamic>> collectPayment({
    required String bookingId,
    required String kind,
    required String method,
    required double amount,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.collectPayment( // STATIC
        id: bookingId,
        kind: kind,
        method: method,
        amount: amount,
      );
    }
    try {
      final res = await ApiService.post('/hosts/bookings/$bookingId/payments', {
        'kind': kind,
        'method': method,
        'amount': amount,
      });
      if (res['success'] == true) return res;
      return _failure('collectPayment', res['message']);
    } catch (e) {
      return _failure('collectPayment', e);
    }
  }

  /// POST /api/hosts/bookings/:id/otp   otpNumber: 1 (check-in) or 2 (completion)
  static Future<Map<String, dynamic>> verifyBookingOtp({
    required String bookingId,
    required int otpNumber,
    required String otp,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.verifyOtp(id: bookingId, otpNumber: otpNumber, otp: otp); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/bookings/$bookingId/otp', {
        'otpNumber': otpNumber,
        'otp': otp,
      });
      if (res['success'] == true) return res;
      return _failure('verifyBookingOtp', res['message']);
    } catch (e) {
      return _failure('verifyBookingOtp', e);
    }
  }

  /// POST /api/hosts/bookings/:id/review
  static Future<Map<String, dynamic>> submitCustomerReview({
    required String bookingId,
    required Map<String, int> ratings,
    String comment = '',
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.submitReview(id: bookingId, ratings: ratings, comment: comment); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/bookings/$bookingId/review', {
        'ratings': ratings,
        'comment': comment,
      });
      if (res['success'] == true) return res;
      return _failure('submitCustomerReview', res['message']);
    } catch (e) {
      return _failure('submitCustomerReview', e);
    }
  }

  /// POST /api/hosts/bookings/:id/cancel
  static Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.cancelBooking(id: bookingId, reason: reason); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/bookings/$bookingId/cancel', {'reason': reason});
      if (res['success'] == true) return res;
      return _failure('cancelBooking', res['message']);
    } catch (e) {
      return _failure('cancelBooking', e);
    }
  }

  /// POST /api/hosts/bookings/offline
  static Future<Map<String, dynamic>> createOfflineBooking(Map<String, dynamic> data) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.createOfflineBooking(data); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/bookings/offline', data);
      if (res['success'] == true) return res;
      return _failure('createOfflineBooking', res['message']);
    } catch (e) {
      return _failure('createOfflineBooking', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 11. Availability calendar, block dates, slot timings, venue rates
  // ---------------------------------------------------------------------------

  /// GET /api/hosts/availability?hall=&year=&month=
  static Future<Map<String, dynamic>> getAvailability({
    required String hall,
    required int year,
    required int month,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.availability(hall: hall, year: year, month: month); // STATIC
    }
    try {
      final q = Uri(queryParameters: {'hall': hall, 'year': 'month'}).query;
      final res = await ApiService.get('/hosts/availability?$q');
      if (res['success'] == true && res['days'] != null) return res;
      return _failure('getAvailability', res['message']);
    } catch (e) {
      return _failure('getAvailability', e);
    }
  }

  /// POST /api/hosts/availability/block   dates: 'YYYY-MM-DD', slots: 1 and/or 2
  static Future<Map<String, dynamic>> blockDates({
    required String hall,
    required List<String> dates,
    required List<int> slots,
    required String reason,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.blockDates(hall: hall, dates: dates, slots: slots, reason: reason); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/availability/block', {
        'hall': hall,
        'dates': dates,
        'slots': slots,
        'reason': reason,
      });
      if (res['success'] == true) return res;
      return _failure('blockDates', res['message']);
    } catch (e) {
      return _failure('blockDates', e);
    }
  }

  /// POST /api/hosts/availability/unblock
  static Future<Map<String, dynamic>> unblockDates({
    required String hall,
    required List<String> dates,
    required List<int> slots,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.unblockDates(hall: hall, dates: dates, slots: slots); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/availability/unblock', {
        'hall': hall,
        'dates': dates,
        'slots': slots,
      });
      if (res['success'] == true) return res;
      return _failure('unblockDates', res['message']);
    } catch (e) {
      return _failure('unblockDates', e);
    }
  }

  /// PUT /api/hosts/availability/timings
  static Future<Map<String, dynamic>> setSlotTimings({
    required String slot1,
    required String slot2,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.setSlotTimings(slot1: slot1, slot2: slot2); // STATIC
    }
    try {
      final res = await ApiService.put('/hosts/availability/timings', {
        'slot1': slot1,
        'slot2': slot2,
      });
      if (res['success'] == true) return res;
      return _failure('setSlotTimings', res['message']);
    } catch (e) {
      return _failure('setSlotTimings', e);
    }
  }

  /// GET /api/hosts/rates?hall=&year=&month=
  static Future<Map<String, dynamic>> getRates({
    required String hall,
    required int year,
    required int month,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.rates(hall: hall, year: year, month: month); // STATIC
    }
    try {
      final q = Uri(queryParameters: {'hall': hall, 'year': 'month'}).query;
      final res = await ApiService.get('/hosts/rates?$q');
      if (res['success'] == true && res['days'] != null) return res;
      return _failure('getRates', res['message']);
    } catch (e) {
      return _failure('getRates', e);
    }
  }

  /// PUT /api/hosts/rates   from/to: 'YYYY-MM-DD' inclusive
  static Future<Map<String, dynamic>> updateRates({
    required String hall,
    required String from,
    required String to,
    required int slot1,
    required int slot2,
    int? stayRate,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.updateRates( // STATIC
        hall: hall,
        from: from,
        to: to,
        slot1: slot1,
        slot2: slot2,
        stayRate: stayRate,
      );
    }
    try {
      final res = await ApiService.put('/hosts/rates', {
        'hall': hall,
        'from': from,
        'to': to,
        'slot1': slot1,
        'slot2': slot2,
        if (stayRate != null) 'stayRate': stayRate,
      });
      if (res['success'] == true) return res;
      return _failure('updateRates', res['message']);
    } catch (e) {
      return _failure('updateRates', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 12. Messages and booking requests
  // ---------------------------------------------------------------------------

  /// GET /api/hosts/messages?filter=all|requests
  static Future<Map<String, dynamic>> getConversations(String filter) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.conversations(filter); // STATIC
    }
    try {
      final res = await ApiService.get('/hosts/messages?filter=$filter');
      if (res['success'] == true && res['conversations'] != null) return res;
      return _failure('getConversations', res['message']);
    } catch (e) {
      return _failure('getConversations', e);
    }
  }

  /// GET /api/hosts/messages/:id
  static Future<Map<String, dynamic>> getConversation(String id) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.conversation(id); // STATIC
    }
    try {
      final res = await ApiService.get('/hosts/messages/$id');
      if (res['success'] == true && res['conversation'] != null) return res;
      return _failure('getConversation', res['message']);
    } catch (e) {
      return _failure('getConversation', e);
    }
  }

  /// POST /api/hosts/messages/:id
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.sendMessage(id: conversationId, text: text); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/messages/$conversationId', {'text': text});
      if (res['success'] == true) return res;
      return _failure('sendMessage', res['message']);
    } catch (e) {
      return _failure('sendMessage', e);
    }
  }

  /// POST /api/hosts/messages/:id/respond   action: 'accept' | 'decline'
  static Future<Map<String, dynamic>> respondToRequest({
    required String conversationId,
    required String action,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.respondToRequest(id: conversationId, action: action); // STATIC
    }
    try {
      final res = await ApiService.post('/hosts/messages/$conversationId/respond', {'action': action});
      if (res['success'] == true) return res;
      return _failure('respondToRequest', res['message']);
    } catch (e) {
      return _failure('respondToRequest', e);
    }
  }

  /// POST /api/hosts/messages/:id/counter-offer
  static Future<Map<String, dynamic>> sendCounterOffer({
    required String conversationId,
    required Map<String, dynamic> details,
    required num price,
    required num taxes,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.sendCounterOffer( // STATIC
        id: conversationId,
        details: details,
        price: price,
        taxes: taxes,
      );
    }
    try {
      final res = await ApiService.post('/hosts/messages/$conversationId/counter-offer', {
        'details': details,
        'price': price,
        'taxes': taxes,
      });
      if (res['success'] == true) return res;
      return _failure('sendCounterOffer', res['message']);
    } catch (e) {
      return _failure('sendCounterOffer', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 13. Host profile and notification preferences
  // ---------------------------------------------------------------------------

  /// GET /api/hosts/profile
  static Future<Map<String, dynamic>> getHostProfile() async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.profile(); // STATIC
    }
    try {
      final res = await ApiService.get('/hosts/profile');
      if (res['success'] == true && res['profile'] != null) return res;
      return _failure('getHostProfile', res['message']);
    } catch (e) {
      return _failure('getHostProfile', e);
    }
  }

  /// PUT /api/hosts/profile
  static Future<Map<String, dynamic>> updateHostProfile({
    required String name,
    required String email,
  }) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.updateProfile(name: name, email: email); // STATIC
    }
    try {
      final res = await ApiService.put('/hosts/profile', {'name': name, 'email': email});
      if (res['success'] == true) return res;
      return _failure('updateHostProfile', res['message']);
    } catch (e) {
      return _failure('updateHostProfile', e);
    }
  }

  /// GET /api/hosts/notification-preferences
  static Future<Map<String, dynamic>> getNotificationPreferences() async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.notificationPrefs(); // STATIC
    }
    try {
      final res = await ApiService.get('/hosts/notification-preferences');
      if (res['success'] == true && res['preferences'] != null) return res;
      return _failure('getNotificationPreferences', res['message']);
    } catch (e) {
      return _failure('getNotificationPreferences', e);
    }
  }

  /// PUT /api/hosts/notification-preferences
  static Future<Map<String, dynamic>> setNotificationPreferences(Map<String, bool> prefs) async {
    if (useStaticData) {
      await _staticDelay();
      return HostStaticData.setNotificationPrefs(prefs); // STATIC
    }
    try {
      final res = await ApiService.put('/hosts/notification-preferences', {'preferences': prefs});
      if (res['success'] == true) return res;
      return _failure('setNotificationPreferences', res['message']);
    } catch (e) {
      return _failure('setNotificationPreferences', e);
    }
  }
}

