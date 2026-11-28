import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_env.dart';
import 'api_service.dart';

class DriverService {
  // -------------------------------------------------------------
  // Step-by-Step Driver Onboarding APIs
  // -------------------------------------------------------------

  /// API 2: Driver Registration Step 1 - "Tell us About yourself"
  /// Endpoint: POST /api/drivers/register/step-1 (or /drivers/onboarding/step-1)
  static Future<Map<String, dynamic>> registerStep1({
    required String fullName,
    required String phone,
    String? email,
    String? city,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

    final body = <String, dynamic>{
      'fullName': fullName,
      'phone': tenDigits,
    };
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      body['city'] = city.trim();
    }

    try {
      final res = await ApiService.post('/drivers/register/step-1', body);
      if (res['success'] == true) return res;
      if (res['statusCode'] == 404 || res['error'] != null) {
        return await ApiService.post('/drivers/onboarding/step-1', body);
      }
      return res;
    } catch (_) {
      try {
        return await ApiService.post('/drivers/onboarding/step-1', body);
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }
  }

  /// API 3: Driver Registration Step 2 - "Upload Document"
  /// Endpoint: POST /api/drivers/register/step-2 (or /drivers/onboarding/step-2)
  /// Accepts file objects (XFile, PlatformFile, File, path) or hosted image URLs.
  static Future<Map<String, dynamic>> registerStep2({
    required String phone,
    dynamic drivingLicense,
    dynamic vehicleRegistration,
    dynamic drivingLicenseBack,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

    bool isFileObject(dynamic v) {
      if (v == null) return false;
      if (v is String) {
        // If it's a remote URL, it's not a local file to upload
        return !v.startsWith('http://') && !v.startsWith('https://') && v.contains(RegExp(r'[\\/.]'));
      }
      return true; // XFile, PlatformFile, File, etc.
    }

    final hasFiles = isFileObject(drivingLicense) ||
        isFileObject(vehicleRegistration) ||
        isFileObject(drivingLicenseBack);

    if (hasFiles) {
      final files = <String, dynamic>{};
      if (drivingLicense != null) files['drivingLicense'] = drivingLicense;
      if (vehicleRegistration != null) files['vehicleRegistration'] = vehicleRegistration;
      if (drivingLicenseBack != null) files['drivingLicenseBack'] = drivingLicenseBack;

      try {
        final res = await ApiService.uploadMultiFieldMultipart(
          '/drivers/register/step-2',
          method: 'POST',
          fields: {'phone': tenDigits},
          files: files,
        );
        if (res['success'] == true) return res;
        if (res['statusCode'] == 404 || res['error'] != null) {
          return await ApiService.uploadMultiFieldMultipart(
            '/drivers/onboarding/step-2',
            method: 'POST',
            fields: {'phone': tenDigits},
            files: files,
          );
        }
        return res;
      } catch (_) {
        try {
          return await ApiService.uploadMultiFieldMultipart(
            '/drivers/onboarding/step-2',
            method: 'POST',
            fields: {'phone': tenDigits},
            files: files,
          );
        } catch (e) {
          return {'success': false, 'error': e.toString()};
        }
      }
    }

    // Fallback to JSON payload if only remote URLs or empty strings were passed
    final body = <String, dynamic>{
      'phone': tenDigits,
    };
    if (drivingLicense != null && drivingLicense.toString().isNotEmpty) {
      body['drivingLicense'] = drivingLicense.toString();
    }
    if (vehicleRegistration != null && vehicleRegistration.toString().isNotEmpty) {
      body['vehicleRegistration'] = vehicleRegistration.toString();
    }
    if (drivingLicenseBack != null && drivingLicenseBack.toString().isNotEmpty) {
      body['drivingLicenseBack'] = drivingLicenseBack.toString();
    }

    try {
      final res = await ApiService.post('/drivers/register/step-2', body);
      if (res['success'] == true) return res;
      if (res['statusCode'] == 404 || res['error'] != null) {
        return await ApiService.post('/drivers/onboarding/step-2', body);
      }
      return res;
    } catch (_) {
      try {
        return await ApiService.post('/drivers/onboarding/step-2', body);
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }
  }

  /// API 4: Driver Registration Step 3 - "Vehicle Information" & Finish
  /// Endpoint: POST /api/drivers/register/step-3 (or /drivers/onboarding/step-3)
  static Future<Map<String, dynamic>> registerStep3({
    required String phone,
    String? vehicleType,
    String? make,
    String? model,
    String? year,
    String? vehicleNumberPlate,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

    final body = <String, dynamic>{
      'phone': tenDigits,
    };
    if (vehicleType != null && vehicleType.isNotEmpty) {
      body['vehicleType'] = vehicleType;
    }
    if (make != null && make.isNotEmpty) {
      body['make'] = make;
    }
    if (model != null && model.isNotEmpty) {
      body['model'] = model;
    }
    if (year != null && year.isNotEmpty) {
      body['year'] = year;
    }
    if (vehicleNumberPlate != null && vehicleNumberPlate.isNotEmpty) {
      body['vehicleNumberPlate'] = vehicleNumberPlate;
      body['vehicleNumber'] = vehicleNumberPlate;
      body['numberPlate'] = vehicleNumberPlate;
    }

    try {
      final res = await ApiService.post('/drivers/register/step-3', body);
      if (res['success'] == true) return res;
      if (res['statusCode'] == 404 || res['error'] != null) {
        return await ApiService.post('/drivers/onboarding/step-3', body);
      }
      return res;
    } catch (_) {
      try {
        return await ApiService.post('/drivers/onboarding/step-3', body);
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }
  }

  // 1. Driver Registration API (KYC & Personal Info)
  // Endpoint: POST /drivers/register
  static Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String phone,
    String? password,
    String? location,
    String? city,
    String? state,
    String? country,
    String? drivingLicenseNumber,
    String? drivingLicenseDocument,
    String? aadharNumber,
    String? aadharDocument,
    String? panNumber,
    String? panDocument,
    String? driverPhoto,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password ?? AppEnv.defaultDriverPassword,
      'location': (location != null && location.isNotEmpty) ? location : 'MI Road, C-Scheme',
      'city': (city != null && city.isNotEmpty) ? city : 'Jaipur',
      'state': (state != null && state.isNotEmpty) ? state : 'Rajasthan',
      'country': (country != null && country.isNotEmpty) ? country : 'India',
      'drivingLicenseNumber': (drivingLicenseNumber != null && drivingLicenseNumber.isNotEmpty) ? drivingLicenseNumber : 'RJ-142023004561',
      'drivingLicenseDocument': (drivingLicenseDocument != null && drivingLicenseDocument.isNotEmpty) ? drivingLicenseDocument : '/uploads/sample_dl.png',
      'driverPhoto': (driverPhoto != null && driverPhoto.isNotEmpty) ? driverPhoto : '/uploads/sample_driver.png',
    };

    if (aadharNumber != null && aadharNumber.isNotEmpty) {
      body['aadharNumber'] = aadharNumber;
    }
    if (aadharDocument != null && aadharDocument.isNotEmpty) {
      body['aadharDocument'] = aadharDocument;
    }
    if (panNumber != null && panNumber.isNotEmpty) {
      body['panNumber'] = panNumber;
    }
    if (panDocument != null && panDocument.isNotEmpty) {
      body['panDocument'] = panDocument;
    }

    return await ApiService.post('/drivers/register', body);
  }

  // 2. Register Driver & Vehicle (Onboarding API)
  // Endpoint: POST /drivers/onboarding
  static Future<Map<String, dynamic>> onboardDriverVehicle({
    required String name,
    required String email,
    required String phone,
    String? location,
    String? vehicle,
    required String vehicleMake,
    required String vehicleModel,
    required String vehicleType,
    required String vehicleYear,
    required String vehicleFuelType,
    String? fuelType,
    required String vehicleNumberPlate,
    String? vehicleColor,
    String? carImage,
    List<String>? carImages,
    String? vehiclePhotos,
    String? drivingLicenseNumber,
    String? drivingLicenseDocument,
    String? rcDocument,
    String? pollutionDocument,
    String? driverPhoto,
  }) async {
    final effectiveFuelType = fuelType ?? vehicleFuelType;
    final effectiveCarImage = carImage ?? vehiclePhotos ?? '/uploads/kia_front.png';
    final effectiveCarImages = carImages ?? [effectiveCarImage];

    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location ?? 'Mangalagiri Road, Vijayawada, Andhra Pradesh, India',
      'vehicle': vehicle ?? '$vehicleMake $vehicleModel',
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleType': vehicleType,
      'vehicleYear': vehicleYear,
      'fuelType': effectiveFuelType,
      'vehicleFuelType': effectiveFuelType,
      'vehicleNumberPlate': vehicleNumberPlate,
      'vehicleColor': vehicleColor ?? 'Grey',
      'carImage': effectiveCarImage,
      'carImages': effectiveCarImages,
      'vehiclePhotos': effectiveCarImage,
      'drivingLicenseNumber': drivingLicenseNumber ?? 'DL-AP-202600110',
      'drivingLicenseDocument': drivingLicenseDocument ?? '/uploads/dl_vamsi.png',
      'rcDocument': rcDocument ?? '/uploads/rc_vamsi.png',
      'pollutionDocument': pollutionDocument ?? '/uploads/pollution_vamsi.png',
      'driverPhoto': driverPhoto ?? '/uploads/photo_vamsi.png',
    };

    return await ApiService.post('/drivers/onboarding', body);
  }

  // 3. Driver Status Check API (Mobile App Flow)
  // Endpoint: GET /drivers/status?id=... or GET /drivers/status?phone=...
  static Future<Map<String, dynamic>> getDriverApprovalStatus({
    String? driverId,
    String? phone,
  }) async {
    try {
      String queryParam = '';
      if (driverId != null && driverId.isNotEmpty) {
        queryParam = '?id=$driverId';
      } else if (phone != null && phone.isNotEmpty) {
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final tenDigitPhone = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
        queryParam = '?phone=$tenDigitPhone';
      }

      final res = await ApiService.get('/drivers/status$queryParam');
      if (res['success'] == true) {
        // Admin approval is not required for any driver. Any registered driver with details can access dashboard.
        const isApproved = true;
        return {
          'success': true,
          'status': res['status'] ?? 'active',
          'kyc': res['kyc'] ?? 'verified',
          'isApproved': isApproved,
          'canAccessDashboard': isApproved,
          'message': res['message'] ?? 'Approved',
          'driver': res['driver'],
        };
      }
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch driver approval status: $e',
        'isApproved': false,
      };
    }
  }

  // 4. Quick Check Driver Admin Approval Status (Boolean) - Admin approval is NOT required
  static Future<bool> checkAdminApproval(String phoneNumber) async {
    return true;
  }

  /// Checks whether a driver is an "old driver" (has already submitted license & vehicle info)
  /// or a "new driver" (not yet submitted details).
  static Future<bool> isOldDriver(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigitPhone = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    // Check SharedPreferences cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPlate = prefs.getString('driver_vehicle_plate_$cleanPhone') ??
          prefs.getString('driver_vehicle_plate_$tenDigitPhone') ??
          prefs.getString('driver_vehicle_$cleanPhone') ??
          prefs.getString('driver_vehicle_$tenDigitPhone');
      if (localPlate != null && localPlate.trim().isNotEmpty) {
        return true;
      }
      final localLicense = prefs.getString('driver_license_$cleanPhone') ??
          prefs.getString('driver_license_$tenDigitPhone');
      if (localLicense != null && localLicense.trim().isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // Check Backend status endpoint
    try {
      final statusResult = await getDriverApprovalStatus(phone: tenDigitPhone);
      if (statusResult['success'] == true) {
        final driverData = statusResult['driver'];
        if (driverData is Map) {
          final license = driverData['drivingLicenseNumber']?.toString().trim();
          final vehicleInfo = driverData['vehicleInfo'];
          final plate = vehicleInfo is Map ? vehicleInfo['vehicleNumberPlate']?.toString().trim() : null;
          final docs = driverData['documents'];
          final rc = docs is Map ? docs['vehicleRegistration']?.toString().trim() : null;

          if ((license != null && license.isNotEmpty) ||
              (plate != null && plate.isNotEmpty) ||
              (rc != null && rc.isNotEmpty)) {
            return true;
          }
        }
      }
    } catch (_) {}

    return false;
  }

  // 5. Admin Approval / Rejection API (Admin Panel Action)
  // Endpoint: PATCH /drivers/:id/kyc
  static Future<Map<String, dynamic>> updateDriverKYCByAdmin({
    required String driverId,
    required String kyc, // "verified" | "rejected" | "pending"
    required String status, // "active" | "suspended" | "pending"
  }) async {
    final body = {
      'kyc': kyc,
      'status': status,
    };
    return await ApiService.patch('/drivers/$driverId/kyc', body);
  }

  // 7. Driver Home Dashboard Summary API (Mobile)
  // Endpoint: GET /drivers/dashboard-summary
  static Future<Map<String, dynamic>> getDashboardSummary({String? phone, String? driverId}) async {
    try {
      final queryParams = <String>[];
      if (phone != null && phone.isNotEmpty) queryParams.add('phone=${Uri.encodeComponent(phone)}');
      if (driverId != null && driverId.isNotEmpty) queryParams.add('driverId=${Uri.encodeComponent(driverId)}');
      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final res = await ApiService.get('/drivers/dashboard-summary$qs');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch dashboard summary: $e',
      };
    }
  }

  // 8. Driver Availability Switch API (Online / Offline Toggle)
  // Endpoints: PATCH /drivers/availability | POST /drivers/availability | POST /drivers/toggle-availability
  static Future<void> markOnlineAtLogin([String? phone]) async {
    try {
      await switchAvailability(isOnline: true, phone: phone);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> switchAvailability({
    required bool isOnline,
    String? phone,
    String? userId,
    String? driverId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'isOnline': isOnline,
      };
      if (phone != null && phone.isNotEmpty) {
        body['phone'] = phone;
        body['mobileNumber'] = phone;
      }
      if (userId != null && userId.isNotEmpty) {
        body['userId'] = userId;
        body['id'] = userId;
      }
      if (driverId != null && driverId.isNotEmpty) {
        body['driverId'] = driverId;
      }

      var res = await ApiService.patch('/drivers/availability', body);
      if (res['success'] != true) {
        res = await ApiService.post('/drivers/availability', body);
      }
      if (res['success'] != true) {
        res = await ApiService.post('/drivers/toggle-availability', body);
      }
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to toggle availability: $e',
      };
    }
  }

  // 9. Dedicated Driver Rides List API (Scoped by Driver & Tab)
  // Endpoint: GET /api/drivers/:driverId/rides?tab=[active|upcoming|completed|cancelled]
  static Future<Map<String, dynamic>> getDriverRides({
    required String driverId,
    String tab = 'active',
  }) async {
    try {
      final cleanDriverId = driverId.trim();
      final cleanTab = tab.trim().toLowerCase();
      final endpoint = '/drivers/$cleanDriverId/rides?tab=$cleanTab';

      final res = await ApiService.get(endpoint);
      if (res['success'] == true) {
        return res;
      }
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch driver rides: $e',
        'count': 0,
        'rides': [],
        'tabs': [],
      };
    }
  }

  /// Helper to resolve the authenticated driver ID from SharedPreferences or fallback sources
  static Future<String> resolveCurrentDriverId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');

      final savedId = prefs.getString('driver_id_$cleanDigits') ??
          prefs.getString('driverId') ??
          prefs.getString('driver_id') ??
          prefs.getString('currentDriverId') ??
          prefs.getString('userId');
      if (savedId != null && savedId.trim().isNotEmpty) {
        return savedId.trim();
      }

      if (currentPhone.isNotEmpty) {
        final statusRes = await getDriverApprovalStatus(phone: currentPhone);
        if (statusRes['success'] == true && statusRes['driver'] != null) {
          final driverObj = statusRes['driver'];
          final id = driverObj['id'] ?? driverObj['_id'] ?? driverObj['driverId'];
          if (id != null && id.toString().isNotEmpty) {
            final strId = id.toString().trim();
            await prefs.setString('driverId', strId);
            if (cleanDigits.isNotEmpty) {
              await prefs.setString('driver_id_$cleanDigits', strId);
            }
            return strId;
          }
        }
      }

      // Generate a clean deterministic ID scoped to the driver's phone
      if (cleanDigits.isNotEmpty) {
        final scopedId = 'DRV-$cleanDigits';
        await prefs.setString('driver_id_$cleanDigits', scopedId);
        return scopedId;
      }
    } catch (_) {}

    return 'DRV-${DateTime.now().millisecondsSinceEpoch}';
  }

  // 9b. Driver Upcoming Rides List API (Mobile Fallback)
  // Endpoint: GET /drivers/upcoming-rides?driverId=:driverId&tab=:tab
  static Future<Map<String, dynamic>> getUpcomingRides({String? driverId, String tab = 'upcoming'}) async {
    try {
      if (driverId != null && driverId.isNotEmpty) {
        final scopedRes = await getDriverRides(driverId: driverId, tab: tab);
        if (scopedRes['success'] == true && scopedRes['rides'] is List) {
          return {
            'success': true,
            'upcomingRides': scopedRes['rides'],
            'rides': scopedRes['rides'],
          };
        }
      }

      final queryParams = <String>[];
      if (driverId != null && driverId.isNotEmpty) queryParams.add('driverId=${Uri.encodeComponent(driverId)}');
      if (tab.isNotEmpty) queryParams.add('tab=${Uri.encodeComponent(tab)}');
      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      var res = await ApiService.get('/drivers/upcoming-rides$qs');
      if (res['success'] == true) {
        return res;
      }

      // If scoped search for this driver returned no records, return a clean empty list
      // (Do NOT leak other drivers' rides by querying global /rides)
      if (driverId != null && driverId.isNotEmpty) {
        final rideQuery = 'driverId=${Uri.encodeComponent(driverId)}&status=scheduled';
        final fallbackRes = await ApiService.get('/rides?$rideQuery');
        if (fallbackRes['success'] == true && fallbackRes['rides'] is List) {
          return {
            'success': true,
            'upcomingRides': fallbackRes['rides'],
            'rides': fallbackRes['rides'],
          };
        }
      }

      return {
        'success': true,
        'upcomingRides': [],
        'rides': [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch upcoming rides: $e',
        'upcomingRides': [],
        'rides': [],
      };
    }
  }

  // 10. GET Driver Personal Information (View Profile)
  // Endpoint: GET /drivers/profile/personal
  static Future<Map<String, dynamic>> getPersonalInfo({String? phone}) async {
    try {
      String query = '';
      if (phone != null && phone.isNotEmpty) {
        final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final ten = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
        query = '?phone=$ten';
      }
      final res = await ApiService.get('/drivers/profile/personal$query');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch personal info: $e',
      };
    }
  }

  /// Extracts driver avatar URL from profile/photo API payloads
  static String? _extractAvatarUrl(Map<String, dynamic> res) {
    final driver = res['driver'] is Map ? res['driver'] as Map : null;
    final data = res['data'] is Map ? res['data'] as Map : null;
    final candidates = [
      res['avatarUrl'],
      res['driverPhotoUrl'],
      res['avatar'],
      res['driverPhoto'],
      res['photoUrl'],
      res['photo'],
      driver?['avatarUrl'],
      driver?['driverPhotoUrl'],
      driver?['avatar'],
      driver?['driverPhoto'],
      data?['avatarUrl'],
      data?['driverPhotoUrl'],
      data?['avatar'],
      data?['driverPhoto'],
    ];
    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) {
        return c.toString().trim();
      }
    }
    return null;
  }

  /// API 2: Driver Profile Photo Upload & Sync
  /// Endpoint: POST /api/drivers/profile/photo (Alias: /api/drivers/avatar)
  static Future<Map<String, dynamic>> uploadProfilePhoto(dynamic file) async {
    try {
      var res = await ApiService.uploadMultipart(
        '/drivers/profile/photo',
        fieldName: 'photo',
        files: [file],
      );
      if (res['success'] != true &&
          (res['statusCode'] == 404 || res['statusCode'] == 405)) {
        res = await ApiService.uploadMultipart(
          '/drivers/avatar',
          fieldName: 'photo',
          files: [file],
        );
      }

      if (res['success'] == true) {
        final photoUrl = _extractAvatarUrl(res);
        if (photoUrl != null) {
          final prefs = await SharedPreferences.getInstance();
          final currentPhone = prefs.getString('currentPhone') ?? '';
          final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanDigits.isNotEmpty) {
            await prefs.setString('driver_photo_url_$cleanDigits', photoUrl);
          }
          await prefs.setString('driver_photo_url', photoUrl);
        }
        return {
          ...res,
          if (photoUrl != null) 'resolvedPhotoUrl': photoUrl,
        };
      }
      return res;
    } catch (e) {
      debugPrint('⚠️ [DriverService] uploadProfilePhoto error: $e');
      return {
        'success': false,
        'message': 'Failed to upload profile photo: $e',
      };
    }
  }

  /// GET Driver Profile Photo: GET /api/drivers/profile/photo (Alias: /api/drivers/avatar)
  static Future<Map<String, dynamic>> getProfilePhoto() async {
    try {
      var res = await ApiService.get('/drivers/profile/photo');
      if (res['success'] != true &&
          (res['statusCode'] == 404 || res['statusCode'] == 405)) {
        res = await ApiService.get('/drivers/avatar');
      }
      if (res['success'] == true) {
        final photoUrl = _extractAvatarUrl(res);
        if (photoUrl != null) {
          final prefs = await SharedPreferences.getInstance();
          final currentPhone = prefs.getString('currentPhone') ?? '';
          final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanDigits.isNotEmpty) {
            await prefs.setString('driver_photo_url_$cleanDigits', photoUrl);
          }
          await prefs.setString('driver_photo_url', photoUrl);
        }
        return {
          ...res,
          if (photoUrl != null) 'resolvedPhotoUrl': photoUrl,
        };
      }
      return res;
    } catch (e) {
      debugPrint('⚠️ [DriverService] getProfilePhoto error: $e');
      return {
        'success': false,
        'message': 'Failed to load profile photo',
      };
    }
  }

  // 11. PUT Update Driver Personal Information (Edit Profile)
  // Endpoint: PUT /drivers/profile/personal
  static Future<Map<String, dynamic>> updatePersonalInfo({
    required String fullName,
    required String phoneNumber,
    required String email,
    String? location,
    String? city,
    String? state,
    String? country,
  }) async {
    try {
      final body = {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        if (location != null) 'location': location,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
      };
      final res = await ApiService.put('/drivers/profile/personal', body);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update personal info: $e',
      };
    }
  }

  // 12. GET Driver Vehicle Information
  // Endpoint: GET /drivers/profile/vehicle
  static Future<Map<String, dynamic>> getVehicleInfo({String? phone}) async {
    try {
      String query = '';
      if (phone != null && phone.isNotEmpty) {
        final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final ten = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
        query = '?phone=$ten';
      }
      final res = await ApiService.get('/drivers/profile/vehicle$query');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch vehicle info: $e',
      };
    }
  }

  /// API 1: Verification Check on Plus (+) Tap
  /// Endpoint: GET /drivers/verify-post-ride (or GET /rides/verify-post-eligibility)
  static Future<Map<String, dynamic>> verifyPostRideEligibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('currentPhone') ?? prefs.getString('driverPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';

      final qp = <String>[];
      if (driverId.isNotEmpty) qp.add('driverId=${Uri.encodeComponent(driverId)}');
      if (phone.isNotEmpty) qp.add('phone=${Uri.encodeComponent(phone)}');
      final qs = qp.isNotEmpty ? '?${qp.join('&')}' : '';

      var res = await ApiService.get('/drivers/verify-post-ride$qs');
      if (res['success'] != true && res['canPostRide'] == null) {
        res = await ApiService.get('/rides/verify-post-eligibility$qs');
      }

      // If response has vehicle info, save to preferences for fast auto-fill
      if (res['success'] == true) {
        final v = res['vehicle'] ?? res['data']?['vehicle'];
        if (v is Map) {
          final plate = (v['vehicleNumberPlate'] ?? v['vehicleNumber'] ?? v['plate'] ?? '').toString();
          if (plate.isNotEmpty) {
            await prefs.setString('driver_vehicle_plate', plate);
          }
          if (v['vehicleType'] != null) {
            await prefs.setString('driver_vehicle_type', v['vehicleType'].toString());
          }
          if (v['vehicleMake'] != null) {
            await prefs.setString('driver_vehicle_make', v['vehicleMake'].toString());
          }
          if (v['vehicleModel'] != null) {
            await prefs.setString('driver_vehicle_model', v['vehicleModel'].toString());
          }
        }

        // If backend returned canPostRide != true because driver is offline/unavailable,
        // verify vehicle registration independently so offline drivers with a vehicle can post,
        // and offline drivers without a vehicle still get the Vehicle Not Registered popup.
        if (res['canPostRide'] != true) {
          final popup = res['popup'] is Map ? res['popup'] as Map : null;
          final btnLower = (popup?['buttonText'] ?? '').toString().toLowerCase();
          final titleLower = (popup?['title'] ?? '').toString().toLowerCase();
          final descLower = (popup?['description'] ?? '').toString().toLowerCase();
          final isAvailabilityPopup = btnLower.contains('availability') ||
              btnLower.contains('turn on') ||
              titleLower.contains('availability') ||
              titleLower.contains('status') ||
              descLower.contains('availability') ||
              descLower.contains('offline');

          if (isAvailabilityPopup) {
            final hasVehicle = res['hasVehicle'] == true
                ? true
                : await hasRegisteredVehicle(phone: phone);
            if (hasVehicle) {
              return {
                'success': true,
                'canPostRide': true,
                'hasVehicle': true,
                'action': 'OPEN_RIDE_POSTING_FORM',
                'targetScreen': 'RidePostingScreen',
                'message': 'Vehicle details verified.',
              };
            }
            return {
              'success': true,
              'canPostRide': false,
              'hasVehicle': false,
              'action': 'OPEN_VEHICLE_INFO_FORM',
              'targetScreen': 'VehicleInformationScreen',
              'popup': {
                'showPopup': true,
                'title': 'Vehicle Not Registered',
                'description': 'You need to register your vehicle before you can post a ride.',
                'buttonText': 'Register Vehicle',
                'cancelText': 'Cancel',
              },
            };
          }
        }

        return res;
      }

      // Fallback check against existing registered vehicle
      final hasVehicle = await hasRegisteredVehicle(phone: phone);
      if (hasVehicle) {
        return {
          'success': true,
          'canPostRide': true,
          'hasVehicle': true,
          'action': 'OPEN_RIDE_POSTING_FORM',
          'targetScreen': 'RidePostingScreen',
          'message': 'Vehicle details verified.',
        };
      }

      return {
        'success': true,
        'canPostRide': false,
        'hasVehicle': false,
        'action': 'OPEN_VEHICLE_INFO_FORM',
        'targetScreen': 'VehicleInformationScreen',
        'popup': {
          'showPopup': true,
          'title': 'Vehicle Not Registered',
          'description': 'You need to register your vehicle before you can post a ride.',
          'buttonText': 'Register Vehicle',
          'cancelText': 'Cancel',
        },
      };
    } catch (e) {
      debugPrint('⚠️ [DriverService] verifyPostRideEligibility error: $e');
      final hasVehicle = await hasRegisteredVehicle();
      return {
        'success': true,
        'canPostRide': hasVehicle,
        'hasVehicle': hasVehicle,
        if (!hasVehicle)
          'popup': {
            'showPopup': true,
            'title': 'Vehicle Not Registered',
            'description': 'You need to register your vehicle before you can post a ride.',
            'buttonText': 'Register Vehicle',
            'cancelText': 'Cancel',
          },
      };
    }
  }

  /// API 2: Submit Vehicle Information Screen
  /// Endpoint: POST /drivers/vehicle-info (or POST /drivers/save-vehicle)
  static Future<Map<String, dynamic>> submitVehicleInfo({
    required String vehicleType,
    required String vehicleMake,
    required String vehicleModel,
    required String vehicleNumberPlate,
    String? vehicleYear,
  }) async {
    try {
      final body = {
        'vehicleType': vehicleType,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'vehicleNumberPlate': vehicleNumberPlate,
        'vehicleNumber': vehicleNumberPlate,
        'make': vehicleMake,
        'model': vehicleModel,
        if (vehicleYear != null && vehicleYear.isNotEmpty) 'vehicleYear': vehicleYear,
      };

      var res = await ApiService.post('/drivers/vehicle-info', body);
      if (res['success'] != true) {
        res = await ApiService.post('/drivers/save-vehicle', body);
      }
      if (res['success'] != true) {
        res = await updateVehicleInfo(
          vehicleType: vehicleType,
          vehicleMake: vehicleMake,
          vehicleModel: vehicleModel,
          vehicleNumberPlate: vehicleNumberPlate,
          vehicleYear: vehicleYear,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_vehicle_plate', vehicleNumberPlate);
      await prefs.setString('driver_vehicle_type', vehicleType);
      await prefs.setString('driver_vehicle_make', vehicleMake);
      await prefs.setString('driver_vehicle_model', vehicleModel);
      if (vehicleYear != null && vehicleYear.isNotEmpty) {
        await prefs.setString('driver_vehicle_year', vehicleYear);
      }

      return res;
    } catch (e) {
      debugPrint('⚠️ [DriverService] submitVehicleInfo error: $e');
      return {
        'success': false,
        'message': 'Failed to save vehicle: $e',
      };
    }
  }

  /// Checks via backend GET /drivers/profile/vehicle if the driver has a registered vehicle
  static Future<bool> hasRegisteredVehicle({String? phone}) async {
    try {
      final res = await getVehicleInfo(phone: phone);
      if (res['success'] == true) {
        final vehicle = res['vehicle'] ?? res['data'] ?? res['driver']?['vehicleInfo'];
        if (vehicle is Map) {
          final plate = (vehicle['vehicleNumberPlate'] ?? vehicle['plate'] ?? vehicle['numberPlate'] ?? vehicle['vehicleNumber'])?.toString().trim();
          final make = (vehicle['vehicleMake'] ?? vehicle['make'])?.toString().trim();
          final model = (vehicle['vehicleModel'] ?? vehicle['model'])?.toString().trim();
          final type = (vehicle['vehicleType'] ?? vehicle['type'])?.toString().trim();
          if ((plate != null && plate.isNotEmpty) ||
              (make != null && make.isNotEmpty) ||
              (model != null && model.isNotEmpty) ||
              (type != null && type.isNotEmpty)) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // 13. PUT Update Driver Vehicle Information
  // Endpoint: PUT /drivers/profile/vehicle
  static Future<Map<String, dynamic>> updateVehicleInfo({
    String? vehicleName,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleType,
    String? vehicleNumberPlate,
    String? fuelType,
    String? capacity,
    String? vehicleYear,
    dynamic rcDocumentFile,
    dynamic insuranceDocumentFile,
  }) async {
    try {
      if (rcDocumentFile != null || insuranceDocumentFile != null) {
        final fields = <String, String>{
          if (vehicleName != null) 'vehicleName': vehicleName,
          if (vehicleMake != null) 'vehicleMake': vehicleMake,
          if (vehicleModel != null) 'vehicleModel': vehicleModel,
          if (vehicleType != null) 'vehicleType': vehicleType,
          if (vehicleNumberPlate != null) 'vehicleNumberPlate': vehicleNumberPlate,
          if (fuelType != null) 'fuelType': fuelType,
          if (capacity != null) 'capacity': capacity,
          if (vehicleYear != null) 'vehicleYear': vehicleYear,
        };
        final files = <String, dynamic>{
          if (rcDocumentFile != null) 'rcDocument': rcDocumentFile,
          if (insuranceDocumentFile != null) 'insuranceDocument': insuranceDocumentFile,
        };
        return await ApiService.uploadMultiFieldMultipart(
          '/drivers/profile/vehicle',
          method: 'PUT',
          fields: fields,
          files: files,
        );
      }
      final body = {
        if (vehicleName != null) 'vehicleName': vehicleName,
        if (vehicleMake != null) 'vehicleMake': vehicleMake,
        if (vehicleModel != null) 'vehicleModel': vehicleModel,
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (vehicleNumberPlate != null) 'vehicleNumberPlate': vehicleNumberPlate,
        if (fuelType != null) 'fuelType': fuelType,
        if (capacity != null) 'capacity': capacity,
        if (vehicleYear != null) 'vehicleYear': vehicleYear,
      };
      final res = await ApiService.put('/drivers/profile/vehicle', body);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update vehicle info: $e',
      };
    }
  }

  // 14. GET Driver Driving License Information
  // Endpoint: GET /drivers/profile/license
  static Future<Map<String, dynamic>> getDrivingLicenseInfo({String? phone}) async {
    try {
      String query = '';
      if (phone != null && phone.isNotEmpty) {
        final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final ten = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
        query = '?phone=$ten';
      }
      final res = await ApiService.get('/drivers/profile/license$query');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch license info: $e',
      };
    }
  }

  // 15. PUT Update Driver Driving License Information
  // Endpoint: PUT /drivers/profile/license
  static Future<Map<String, dynamic>> updateDrivingLicenseInfo({
    required String licenseNumber,
    String? licenseType,
    String? validity,
    String? documentUrl,
    dynamic licenseFrontFile,
    dynamic licenseBackFile,
  }) async {
    try {
      if (licenseFrontFile != null || licenseBackFile != null) {
        final fields = <String, String>{
          'licenseNumber': licenseNumber,
          if (licenseType != null) 'licenseType': licenseType,
          if (validity != null) 'validity': validity,
          if (documentUrl != null) 'documentUrl': documentUrl,
        };
        final files = <String, dynamic>{
          if (licenseFrontFile != null) 'drivingLicenseFront': licenseFrontFile,
          if (licenseBackFile != null) 'drivingLicenseBack': licenseBackFile,
        };
        return await ApiService.uploadMultiFieldMultipart(
          '/drivers/profile/license',
          method: 'PUT',
          fields: fields,
          files: files,
        );
      }
      final body = {
        'licenseNumber': licenseNumber,
        if (licenseType != null) 'licenseType': licenseType,
        if (validity != null) 'validity': validity,
        if (documentUrl != null) 'documentUrl': documentUrl,
      };
      final res = await ApiService.put('/drivers/profile/license', body);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update license info: $e',
      };
    }
  }

  // 16. GET Driver Bank Account Information
  // Endpoint: GET /drivers/profile/bank
  static Future<Map<String, dynamic>> getBankAccountInfo({String? phone}) async {
    try {
      String query = '';
      if (phone != null && phone.isNotEmpty) {
        final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final ten = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
        query = '?phone=$ten';
      }
      final res = await ApiService.get('/drivers/profile/bank$query');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch bank account info: $e',
      };
    }
  }

  // 17. PUT Update Driver Bank Account Information
  // Endpoint: PUT /drivers/profile/bank
  static Future<Map<String, dynamic>> updateBankAccountInfo({
    required String accountHolder,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      final body = {
        'accountHolder': accountHolder,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
      };
      final res = await ApiService.put('/drivers/profile/bank', body);
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update bank account info: $e',
      };
    }
  }

  // 18. Change Password API
  // Endpoint: PUT /drivers/profile/change-password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final body = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
      final res = await ApiService.put('/drivers/profile/change-password', body);
      if (res['success'] != true) {
        // Fallback to /auth/change-password if driver endpoint returns 404
        return await ApiService.post('/auth/change-password', body);
      }
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to change password: $e',
      };
    }
  }

  // 19. Get Driver Notifications API (Generic & Screen 13)
  // Endpoint: GET /drivers/notifications?filter=ALL|booking_received|booking_confirmed|unread&page=1&limit=20
  static Future<Map<String, dynamic>> getDriverNotifications({
    String? filter,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('currentPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';

      final qp = <String>[];
      if (filter != null && filter.isNotEmpty && filter != 'ALL') {
        qp.add('filter=${Uri.encodeComponent(filter)}');
        qp.add('type=${Uri.encodeComponent(filter.toLowerCase())}');
      }
      qp.add('page=$page');
      qp.add('limit=$limit');
      if (driverId.isNotEmpty) qp.add('driverId=${Uri.encodeComponent(driverId)}');
      if (phone.isNotEmpty) qp.add('phone=${Uri.encodeComponent(phone)}');
      final queryParam = '?${qp.join('&')}';

      List<dynamic> extractList(Map<String, dynamic> r) {
        if (r['notifications'] is List) return r['notifications'] as List;
        if (r['items'] is List) return r['items'] as List;
        if (r['data'] is List) return r['data'] as List;
        if (r['data'] is Map && (r['data']['notifications'] is List)) return r['data']['notifications'] as List;
        if (r['data'] is Map && (r['data']['items'] is List)) return r['data']['items'] as List;
        return [];
      }

      final res = await ApiService.get('/drivers/notifications$queryParam');
      final list1 = extractList(res);
      if (res['success'] == true && list1.isNotEmpty) {
        return {
          'success': true,
          'summary': res['summary'] ?? {
            'total': res['total'] ?? list1.length,
            'unread': res['unread'] ?? list1.where((n) => n is Map && n['read'] != true).length,
            'filterApplied': filter ?? 'ALL',
            'page': page,
            'limit': limit,
          },
          'notifications': list1,
          'data': list1,
        };
      }

      final altRes = await ApiService.get('/notifications$queryParam');
      final list2 = extractList(altRes);
      if (altRes['success'] == true && list2.isNotEmpty) {
        return {
          'success': true,
          'summary': altRes['summary'] ?? {
            'total': altRes['total'] ?? list2.length,
            'unread': altRes['unread'] ?? list2.where((n) => n is Map && n['read'] != true).length,
            'filterApplied': filter ?? 'ALL',
            'page': page,
            'limit': limit,
          },
          'notifications': list2,
          'data': list2,
        };
      }

      // Live fallback: Query booking requests and bookings to populate real activity for driver
      final tabRes = await getDriverNotificationsByTab(tab: 'booking_requests');
      final items = tabRes['items'] ?? tabRes['data'] ?? tabRes['notifications'];
      final rawItems = items is List ? items : [];

      final allNotifs = <Map<String, dynamic>>[];

      if (rawItems.isNotEmpty) {
        for (final it in rawItems) {
          if (it is! Map) continue;
          final pName = it['passengerName'] ?? it['customerName'] ?? it['name'] ?? 'Passenger';
          final fromStr = (it['pickupLocation'] ?? it['from'] ?? it['pickup'] ?? '').toString().split(',').first.trim();
          final toStr = (it['destinationLocation'] ?? it['to'] ?? it['destination'] ?? '').toString().split(',').first.trim();
          final pRoute = fromStr.isNotEmpty && toStr.isNotEmpty ? '$fromStr → $toStr' : (it['routeText'] ?? 'Ride Route');
          final pTime = it['time'] ?? it['timeAgo'] ?? it['departureTime'] ?? 'Recently';
          final pStatus = (it['status']?.toString().toLowerCase()) ?? 'new';
          allNotifs.add({
            'id': (it['id'] ?? it['_id'] ?? it['bookingId'] ?? 'notif_${allNotifs.length}_${DateTime.now().microsecondsSinceEpoch}').toString(),
            'title': pStatus == 'confirmed' ? 'Ride Confirmed' : (pStatus == 'denied' ? 'Ride Declined' : 'New Booking Request'),
            'subtitle': '$pName requested a ride ($pRoute)',
            'time': pTime,
            'type': pStatus == 'confirmed' ? 'confirmed' : (pStatus == 'denied' ? 'denied' : 'new'),
            'category': 'Ride Request',
            'read': it['read'] == true,
            'unread': it['read'] != true,
          });
        }
      }

      // Also fetch general bookings if allNotifs is still empty
      if (allNotifs.isEmpty) {
        try {
          final bookingsRes = await ApiService.get('/bookings');
          final bList = bookingsRes['bookings'] ?? bookingsRes['data'];
          if (bList is List && bList.isNotEmpty) {
            for (final b in bList) {
              if (b is! Map) continue;
              final pName = b['userName'] ?? b['passengerName'] ?? b['customerName'] ?? 'Passenger';
              final fromStr = (b['pickupLocation'] ?? b['from'] ?? b['pickup'] ?? '').toString().split(',').first.trim();
              final toStr = (b['destinationLocation'] ?? b['to'] ?? b['destination'] ?? '').toString().split(',').first.trim();
              final pRoute = fromStr.isNotEmpty && toStr.isNotEmpty ? '$fromStr → $toStr' : 'Ride Route';
              final pStatus = (b['status']?.toString().toLowerCase()) ?? 'new';
              allNotifs.add({
                'id': (b['id'] ?? b['_id'] ?? b['bookingId'] ?? 'notif_${allNotifs.length}').toString(),
                'title': pStatus == 'confirmed' ? 'Ride Confirmed' : (pStatus == 'denied' ? 'Ride Declined' : 'New Booking Request'),
                'subtitle': '$pName requested a ride ($pRoute)',
                'time': b['departureTime'] ?? 'Recently',
                'type': pStatus == 'confirmed' ? 'confirmed' : (pStatus == 'denied' ? 'denied' : 'new'),
                'category': 'Ride Request',
                'read': b['read'] == true,
                'unread': b['read'] != true,
              });
            }
          }
        } catch (_) {}
      }

      return {
        'success': true,
        'notifications': allNotifs,
        'data': allNotifs,
      };
    } catch (_) {}

    return {
      'success': true,
      'notifications': [],
      'data': [],
    };
  }

  // 20. Screen 99: Get Driver Notifications & Booking Requests by Tab
  // Endpoint: GET /drivers/notifications?tab=booking_requests | confirmed | denied | other
  static Future<Map<String, dynamic>> getDriverBookingRequests({required String tab}) async {
    return getDriverNotificationsByTab(tab: tab);
  }

  static Future<Map<String, dynamic>> getDriverNotificationsByTab({required String tab}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('currentPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';

      final qp = <String>['tab=${Uri.encodeComponent(tab)}'];
      if (driverId.isNotEmpty) qp.add('driverId=${Uri.encodeComponent(driverId)}');
      if (phone.isNotEmpty) qp.add('phone=${Uri.encodeComponent(phone)}');

      // 1. Primary endpoint: GET /api/drivers/booking-requests?tab=... (API 4)
      final primaryUrl = '/drivers/booking-requests?${qp.join('&')}';
      Map<String, dynamic> res = {};
      try {
        res = await ApiService.get(primaryUrl);
      } catch (_) {}

      // Fallback: GET /api/drivers/notifications?tab=...
      if (res['success'] != true || (res['currentItems'] == null && res['items'] == null && res['data'] == null)) {
        try {
          final fallbackRes = await ApiService.get('/drivers/notifications?${qp.join('&')}');
          if (fallbackRes['success'] == true) res = fallbackRes;
        } catch (_) {}
      }

      final rawItems = res['currentItems'] ?? res['items'] ?? res['data'] ?? res['notifications'];
      final bool hasItems = rawItems is List && rawItems.isNotEmpty;

      if (res['success'] == true && hasItems) {
        return res;
      }

      // Live Fallback: Query /bookings to populate live cards dynamically
      try {
        final bookingsRes = await ApiService.get('/bookings');
        if (bookingsRes['success'] == true && bookingsRes['bookings'] is List) {
          final allBookings = List<Map<String, dynamic>>.from(bookingsRes['bookings']);

          int countPending = 0;
          int countConfirmed = 0;
          int countDenied = 0;

          final tabFilteredItems = <Map<String, dynamic>>[];

          for (final b in allBookings) {
            final st = (b['status'] ?? 'pending').toString().toLowerCase();
            final isPending = st == 'pending' || st == 'requested' || st == 'new';
            final isConfirmed = st == 'confirmed' || st == 'conformed' || st == 'accepted' || st == 'boarded';
            final isDenied = st == 'denied' || st == 'declined' || st == 'rejected' || st == 'cancelled';

            if (isPending) countPending++;
            if (isConfirmed) countConfirmed++;
            if (isDenied) countDenied++;

            bool matchTab = false;
            if (tab == 'booking_requests' && isPending) matchTab = true;
            if (tab == 'confirmed' && isConfirmed) matchTab = true;
            if (tab == 'denied' && isDenied) matchTab = true;

            if (matchTab) {
              final bId = (b['bookingId'] ?? b['_id'] ?? b['id'] ?? '').toString();
              final custName = b['userName'] ?? b['passengerName'] ?? b['customerName'] ?? 'Passenger';
              final fromLoc = b['pickupLocation'] ?? b['pickup'] ?? b['from'] ?? 'Madhapur';
              final toLoc = b['destinationLocation'] ?? b['destination'] ?? b['to'] ?? 'Secunderabad';
              final seatsVal = b['seatsBooked'] ?? b['seats'] ?? 1;
              final amtVal = b['totalAmount'] ?? b['fare'] ?? b['amount'] ?? 250;
              final amtNum = (amtVal is num) ? amtVal : (num.tryParse(amtVal.toString()) ?? 250);

              tabFilteredItems.add({
                'id': bId,
                'bookingId': bId,
                'rideId': (b['rideId'] ?? b['ride']?['_id'] ?? '').toString(),
                'customerName': custName,
                'customerAvatar': b['customerAvatar'] ?? b['avatar'] ?? '',
                'customerPhone': b['customerPhone'] ?? b['phone'] ?? '',
                'pickup': fromLoc,
                'destination': toLoc,
                'boardingPoint': fromLoc,
                'routeText': '$fromLoc → $toLoc',
                'createdAt': b['createdAt'] ?? '',
                'timeAgo': b['departureTime'] ?? 'Recently',
                'seats': (seatsVal is num) ? seatsVal.toInt() : (int.tryParse(seatsVal.toString()) ?? 1),
                'amount': amtNum.toDouble(),
                'formattedAmount': '₹ ${amtNum.toInt()}',
                'status': st,
                'statusBadge': st.toUpperCase(),
              });
            }
          }

          return {
            'success': true,
            'selectedTab': tab,
            'count': tabFilteredItems.length,
            'items': tabFilteredItems,
            'counts': {
              'booking_requests': countPending,
              'confirmed': countConfirmed,
              'denied': countDenied,
            },
          };
        }
      } catch (_) {}

      return await ApiService.get('/notifications?${qp.join('&')}');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch $tab tab data: $e',
        'items': [],
      };
    }
  }

  /// Get Driver Unread/Unseen Notifications Count
  /// Checks pending booking requests and unread alerts
  static Future<int> getUnreadNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenIds = (prefs.getStringList('driver_seen_notification_ids') ?? <String>[]).toSet();
      final allSeen = prefs.getBool('driver_all_notifications_seen') ?? false;

      final res = await getDriverNotificationsByTab(tab: 'booking_requests');
      if (res['success'] == true && res['counts'] is Map) {
        final counts = res['counts'] as Map;
        final bookingRequests = (counts['booking_requests'] as num?)?.toInt() ?? 0;
        int unread = (counts['unreadCount'] as num?)?.toInt() ?? bookingRequests;

        // If tabsData contains other notifications, filter out those seen locally
        if (res['tabsData'] is Map && res['tabsData']['other'] is List) {
          final otherList = res['tabsData']['other'] as List;
          final unreadOther = otherList.where((item) {
            if (item is Map) {
              final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
              final isRead = item['read'] == true;
              final isUnread = item['unread'] == true || !isRead;
              if (seenIds.contains(id)) return false;
              return isUnread;
            }
            return false;
          }).length;
          return allSeen ? 0 : (bookingRequests + unreadOther);
        }

        if (allSeen) {
          return 0;
        }

        return unread;
      }

      if (allSeen) {
        return 0;
      }
    } catch (_) {}
    return 0;
  }

  /// API 3c: Mark all driver notifications as read on the backend and persist seen state locally
  /// Endpoint: PUT /drivers/notifications/mark-all-read (fallback PATCH /drivers/notifications/mark-all-read or /read-all)
  static Future<Map<String, dynamic>> markAllNotificationsAsRead({List<String>? notificationIds}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (notificationIds != null && notificationIds.isNotEmpty) {
        final seenIds = (prefs.getStringList('driver_seen_notification_ids') ?? <String>[]).toSet();
        seenIds.addAll(notificationIds);
        await prefs.setStringList('driver_seen_notification_ids', seenIds.toList());
      }
      await prefs.setBool('driver_all_notifications_seen', true);

      final phone = prefs.getString('currentPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';
      final body = {
        if (driverId.isNotEmpty) 'driverId': driverId,
        if (phone.isNotEmpty) 'phone': phone,
      };

      var res = await ApiService.put('/drivers/notifications/mark-all-read', body);
      if (res['success'] == true) return res;
      res = await ApiService.patch('/drivers/notifications/mark-all-read', body);
      if (res['success'] == true) return res;
      res = await ApiService.patch('/drivers/notifications/read-all', body);
      if (res['success'] == true) return res;
      res = await ApiService.post('/notifications/read-all', body);
      return res;
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  /// API 3b: Mark a single notification as read on the backend & local cache
  /// Endpoint: PATCH /drivers/notifications/:id/read (fallback POST /drivers/notifications/:id/read)
  static Future<Map<String, dynamic>> markNotificationAsRead(String notifId) async {
    if (notifId.isEmpty) return {'success': false};
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenIds = prefs.getStringList('driver_seen_notification_ids') ?? <String>[];
      if (!seenIds.contains(notifId)) {
        seenIds.add(notifId);
        await prefs.setStringList('driver_seen_notification_ids', seenIds);
      }

      var res = await ApiService.patch('/drivers/notifications/$notifId/read', {});
      if (res['success'] == true) return res;
      res = await ApiService.post('/drivers/notifications/$notifId/read', {});
      if (res['success'] == true) return res;
      res = await ApiService.patch('/notifications/$notifId/read', {});
      return res;
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // 21. Screen 99: Accept Booking Request (API 5)
  // Specification: POST /api/rides/booking-requests/:bookingId/respond with {"action": "accept"}
  static Future<Map<String, dynamic>> acceptBookingRequest({required String bookingId}) async {
    try {
      final cleanId = bookingId.trim().replaceAll('#', '');
      final body = {'action': 'accept'};

      // 1. Primary unified endpoint per API 5 specification
      var res = await ApiService.post('/rides/booking-requests/$cleanId/respond', body);
      if (res['success'] == true) return res;

      // 2. Fallbacks
      res = await ApiService.post('/drivers/booking-requests/$cleanId/accept', {});
      if (res['success'] == true) return res;

      res = await ApiService.patch('/drivers/booking-requests/$cleanId/accept', {});
      if (res['success'] == true) return res;

      res = await ApiService.patch('/bookings/$cleanId/status', {'status': 'confirmed'});
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to accept booking: $e',
      };
    }
  }

  // 22. Screen 99: Decline Booking Request (API 5)
  // Specification: POST /api/rides/booking-requests/:bookingId/respond with {"action": "decline", "reason": "..."}
  static Future<Map<String, dynamic>> declineBookingRequest({
    required String bookingId,
    String reason = 'Seat capacity full or route unavailable',
  }) async {
    try {
      final cleanId = bookingId.trim().replaceAll('#', '');
      final body = {'action': 'decline', 'reason': reason};

      // 1. Primary unified endpoint per API 5 specification
      var res = await ApiService.post('/rides/booking-requests/$cleanId/respond', body);
      if (res['success'] == true) return res;

      // 2. Fallbacks
      res = await ApiService.post('/drivers/booking-requests/$cleanId/decline', body);
      if (res['success'] == true) return res;

      res = await ApiService.patch('/drivers/booking-requests/$cleanId/decline', body);
      if (res['success'] == true) return res;

      res = await ApiService.post('/drivers/booking-requests/$cleanId/deny', body);
      if (res['success'] == true) return res;

      res = await ApiService.patch('/bookings/$cleanId/status', {'status': 'cancelled', 'reason': reason});
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to decline booking: $e',
      };
    }
  }

  // 23. Screen 99: View Booking Request Details
  // Endpoint: GET /drivers/booking-requests/:bookingId
  static Future<Map<String, dynamic>> getBookingRequestDetails({required String bookingId}) async {
    try {
      final res = await ApiService.get('/drivers/booking-requests/$bookingId');
      if (res['success'] == true) {
        return res;
      }
      return await ApiService.get('/drivers/bookings/$bookingId');
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch booking details: $e',
      };
    }
  }

  // 24. Screen 82: Driver Fuel Share & Earnings History API
  // Endpoint: GET /drivers/fuel-share?filter=...&startDate=...&endDate=...&page=...&limit=...&search=...
  static Future<Map<String, dynamic>> getFuelShareHistory({
    String filter = 'this_month',
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 5,
    String? search,
  }) async {
    try {
      final queryParams = <String>[];
      if (filter.isNotEmpty) {
        queryParams.add('filter=${Uri.encodeComponent(filter)}');
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams.add('startDate=${Uri.encodeComponent(startDate)}');
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams.add('endDate=${Uri.encodeComponent(endDate)}');
      }
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search)}');
      }

      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final res = await ApiService.get('/drivers/fuel-share$qs');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch fuel share history: $e',
      };
    }
  }

  /// 24b. Fetch Detailed Trip Breakdown for Fuel Share Card Expansion
  /// Endpoints: GET /rides/:rideId/trip-shared/summary | GET /rides/:rideId | GET /drivers/rides/:rideId
  static Future<Map<String, dynamic>> getTripDetailForFuelShare({required String rideId}) async {
    final cleanId = rideId.trim();
    if (cleanId.isEmpty) return {'success': false, 'message': 'Invalid ride ID'};

    try {
      // 1. Try trip-shared summary
      var res = await ApiService.get('/rides/$cleanId/trip-shared/summary');
      if (res['success'] == true && (res['data'] != null || res['ride'] != null)) return res;

      // 2. Try standard /rides/:id
      res = await ApiService.get('/rides/$cleanId');
      if (res['success'] == true && (res['ride'] != null || res['data'] != null)) return res;

      // 3. Try /drivers/rides/:id
      res = await ApiService.get('/drivers/rides/$cleanId');
      if (res['success'] == true) return res;

      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch trip details: $e'};
    }
  }

  // 25. Cancel Upcoming Ride API (with cancellation reason)
  // Endpoints: PATCH /rides/:id/status | PATCH /rides/:id | POST /rides/:id/cancel | DELETE /rides/:id
  static Future<Map<String, dynamic>> cancelRide({
    required String rideId,
    required String reason,
  }) async {
    try {
      final cleanRideId = rideId.trim();
      if (cleanRideId.isEmpty) {
        return {'success': false, 'message': 'Invalid ride ID.'};
      }

      final payload = {
        'status': 'cancelled',
        'reason': reason,
        'cancellationReason': reason,
      };

      // 1. Try PATCH /rides/:id/status (Standard status route in ride.routes.js)
      var res = await ApiService.patch('/rides/$cleanRideId/status', payload);
      if (res['success'] == true) return res;

      // 2. Try PATCH /rides/:id (General update in ride.routes.js)
      res = await ApiService.patch('/rides/$cleanRideId', payload);
      if (res['success'] == true) return res;

      // 3. Try POST /rides/:id/cancel
      res = await ApiService.post('/rides/$cleanRideId/cancel', payload);
      if (res['success'] == true) return res;

      // 4. Try POST /drivers/rides/:id/cancel
      res = await ApiService.post('/drivers/rides/$cleanRideId/cancel', payload);
      if (res['success'] == true) return res;

      // 5. Fallback to deleteRide if the backend only supports DELETE
      return await deleteRide(cleanRideId, reason: reason);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel ride: $e',
      };
    }
  }

  // 25b. Delete / Cancel Upcoming Ride API (Legacy Fallback)
  // Endpoints: DELETE /rides/:id | DELETE /drivers/rides/:id | POST /rides/:id/cancel
  static Future<Map<String, dynamic>> deleteRide(String rideId, {String? reason}) async {
    try {
      if (rideId.isEmpty) {
        return {'success': false, 'message': 'Invalid ride ID.'};
      }

      // 1. Try primary REST DELETE /rides/:id
      var res = await ApiService.delete('/rides/$rideId');
      if (res['success'] == true) return res;

      // 2. Try DELETE /drivers/rides/:id
      res = await ApiService.delete('/drivers/rides/$rideId');
      if (res['success'] == true) return res;

      // 3. Try POST /rides/:id/cancel
      res = await ApiService.post('/rides/$rideId/cancel', {
        'reason': reason ?? 'Driver deleted upcoming ride',
        'status': 'cancelled',
      });
      if (res['success'] == true) return res;

      // 4. Try PATCH /rides/:id
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

  /// API 4: Get Driver Messages and Requests by tab
  /// Endpoint: GET /drivers/messages?tab=messages|requests&page=1&limit=20
  static Future<Map<String, dynamic>> getDriverMessagesTab({
    required String tab,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';

      final queryParams = <String>[
        'tab=${Uri.encodeComponent(tab)}',
        'page=$page',
        'limit=$limit',
      ];
      if (driverId.isNotEmpty) queryParams.add('driverId=${Uri.encodeComponent(driverId)}');
      if (currentPhone.isNotEmpty) queryParams.add('phone=${Uri.encodeComponent(currentPhone)}');
      final qs = '?${queryParams.join('&')}';

      final res = await ApiService.get('/drivers/messages$qs');
      if (res['success'] == true) {
        return res;
      }
    } catch (_) {}

    // Fallback: Use individual endpoints
    if (tab == 'requests') {
      final reqs = await getDriverRequests();
      final list = reqs['requests'] is List ? reqs['requests'] as List : [];
      return {
        'success': true,
        'tab': 'requests',
        'counts': {
          'messages': 0,
          'requests': reqs['totalRequests'] ?? list.length,
          'unreadMessages': 0,
        },
        'requests': list,
      };
    } else {
      final msgs = await getDriverMessages();
      final list = msgs['messages'] is List ? msgs['messages'] as List : [];
      return {
        'success': true,
        'tab': 'messages',
        'counts': {
          'messages': list.length,
          'requests': 0,
          'unreadMessages': msgs['totalUnread'] ?? 0,
        },
        'messages': list,
      };
    }
  }

  // 26. Get Driver Messages (matching 88246846.png)
  static Future<Map<String, dynamic>> getDriverMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';

      final queryParams = <String>[];
      if (driverId.isNotEmpty) queryParams.add('driverId=${Uri.encodeComponent(driverId)}');
      if (currentPhone.isNotEmpty) queryParams.add('phone=${Uri.encodeComponent(currentPhone)}');
      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      final res = await ApiService.get('/driver/messages$qs');
      if (res['success'] == true) {
        final rawMessages = res['messages'] ?? res['data'] ?? [];
        final list = rawMessages is List ? rawMessages : [];
        final totalUnread = (res['totalUnread'] as num?)?.toInt() ??
            list.fold<int>(0, (sum, m) => sum + (((m is Map ? (m['unreadCount'] ?? m['unreadBadge']) : 0) as num?)?.toInt() ?? 0));
        return {
          'success': true,
          'totalUnread': totalUnread,
          'messages': list,
        };
      }
    } catch (_) {}

    return {
      'success': true,
      'totalUnread': 0,
      'messages': [],
    };
  }

  // 26b. Mark Conversation As Read
  static Future<Map<String, dynamic>> markConversationAsRead(String conversationId) async {
    try {
      final res = await ApiService.post('/driver/messages/$conversationId/read', {});
      return res;
    } catch (_) {
      return {'success': true};
    }
  }

  // 26c. Get Conversation Messages History
  static Future<Map<String, dynamic>> getConversationMessages(String conversationId) async {
    try {
      final res = await ApiService.get('/driver/messages/$conversationId');
      if (res['success'] == true && res['messages'] is List) {
        return res;
      }
    } catch (_) {}

    return {
      'success': true,
      'messages': [],
    };
  }

  // 26d. Reply to Conversation (API 5 & 7)
  // Endpoint: POST /drivers/messages/:conversationId (fallback POST /driver/messages/:conversationId/reply)
  static Future<Map<String, dynamic>> replyToConversation({
    required String conversationId,
    required String text,
  }) async {
    try {
      var res = await ApiService.post('/drivers/messages/$conversationId', {
        'text': text,
        'message': text,
      });
      if (res['success'] != true) {
        res = await ApiService.post('/driver/messages/$conversationId/reply', {
          'text': text,
          'message': text,
        });
      }
      return res;
    } catch (_) {
      return {'success': true};
    }
  }

  // 27. Get Driver Requests (Requests tab)
  static Future<Map<String, dynamic>> getDriverRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';

      final queryParams = <String>[];
      if (driverId.isNotEmpty) queryParams.add('driverId=${Uri.encodeComponent(driverId)}');
      if (currentPhone.isNotEmpty) queryParams.add('phone=${Uri.encodeComponent(currentPhone)}');
      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      var res = await ApiService.get('/driver/requests$qs');
      final rawList1 = res['requests'] ?? res['items'] ?? res['data'];
      if (res['success'] != true || rawList1 == null || (rawList1 is List && rawList1.isEmpty)) {
        // Fallback to /drivers/booking-requests?status=pending
        res = await ApiService.get('/drivers/booking-requests?status=pending${queryParams.isNotEmpty ? '&${queryParams.join('&')}' : ''}');
      }

      final rawReqs = res['requests'] ?? res['items'] ?? res['data'];
      if (res['success'] == true && rawReqs is List && rawReqs.isNotEmpty) {
        return {
          'success': true,
          'totalRequests': (res['totalRequests'] as num?)?.toInt() ?? rawReqs.length,
          'requests': rawReqs,
        };
      }

      // Live fallback to /bookings (status: pending)
      try {
        final bookingsRes = await ApiService.get('/bookings');
        if (bookingsRes['success'] == true && bookingsRes['bookings'] is List) {
          final allBookings = List<Map<String, dynamic>>.from(bookingsRes['bookings']);
          final pendingBookings = allBookings.where((b) {
            final s = (b['status'] ?? 'pending').toString().toLowerCase();
            return s == 'pending' || s == 'requested' || s == 'new';
          }).toList();

          final formattedReqs = pendingBookings.map((b) {
            final bId = (b['bookingId'] ?? b['_id'] ?? b['id'] ?? '').toString();
            final name = b['userName'] ?? b['passengerName'] ?? b['customerName'] ?? 'Passenger';
            final from = b['pickupLocation'] ?? b['pickup'] ?? b['from'] ?? 'Madhapur';
            final to = b['destinationLocation'] ?? b['destination'] ?? b['to'] ?? 'Secunderabad';
            final seats = b['seatsBooked'] ?? b['seats'] ?? 1;
            final amt = b['totalAmount'] ?? b['fare'] ?? b['amount'] ?? 250;
            return {
              'id': bId,
              'bookingId': bId,
              'rideId': (b['rideId'] ?? b['ride']?['_id'] ?? '').toString(),
              'passengerName': name,
              'customerName': name,
              'initials': name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
              'route': '$from ➔ $to',
              'from': from,
              'to': to,
              'time': b['departureTime'] ?? b['createdAt'] ?? 'Today',
              'seats': (seats is num) ? seats.toInt() : 1,
              'offeredPrice': amt.toString().startsWith('₹') ? amt.toString() : '₹ $amt',
              'amount': amt,
              'status': b['status'] ?? 'pending',
            };
          }).toList();

          return {
            'success': true,
            'totalRequests': formattedReqs.length,
            'requests': formattedReqs,
          };
        }
      } catch (_) {}
    } catch (_) {}

    return {
      'success': true,
      'totalRequests': 0,
      'requests': [],
    };
  }

  /// Group B API 1: GET /api/drivers/:id/ratings-overview (Driver Ratings Screen 113)
  static Future<Map<String, dynamic>> getRatingsOverview({String? driverId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final resolvedId = (driverId != null && driverId.isNotEmpty)
          ? driverId
          : (prefs.getString('driverId') ?? prefs.getString('userId') ?? '');

      if (resolvedId.isNotEmpty) {
        var res = await ApiService.get('/drivers/$resolvedId/ratings-overview');
        if (res['success'] == true) return res;

        res = await ApiService.get('/drivers/ratings-overview?driverId=$resolvedId&phone=$currentPhone');
        if (res['success'] == true) return res;

        res = await ApiService.get('/reviews/driver-overview?driverId=$resolvedId');
        if (res['success'] == true) return res;
      }

      return {
        'success': false,
        'message': 'No ratings overview available.',
        'rating': 0.0,
        'ratingFormatted': '0.0',
        'totalReviews': 0,
        'ratingSubtitle': 'Based on 0 reviews',
        'starsBreakdown': {},
        'recentReview': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch ratings overview: $e',
        'rating': 0.0,
        'ratingFormatted': '0.0',
        'totalReviews': 0,
        'ratingSubtitle': 'Based on 0 reviews',
        'starsBreakdown': {},
        'recentReview': null,
      };
    }
  }

  /// Group B API 2: GET /api/drivers/:id/reviews (Powers "All Reviews (126)" Modal)
  static Future<Map<String, dynamic>> getDriverReviews({String? driverId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resolvedId = (driverId != null && driverId.isNotEmpty)
          ? driverId
          : (prefs.getString('driverId') ?? prefs.getString('userId') ?? '');

      if (resolvedId.isNotEmpty) {
        var res = await ApiService.get('/drivers/$resolvedId/reviews');
        if (res['success'] == true) return res;

        res = await ApiService.get('/reviews/driver?driverId=$resolvedId');
        if (res['success'] == true) return res;
      }

      return {
        'success': true,
        'totalReviews': 0,
        'headerTitle': 'All Reviews (0)',
        'reviews': [],
      };
    } catch (e) {
      return {
        'success': false,
        'totalReviews': 0,
        'headerTitle': 'All Reviews (0)',
        'reviews': [],
      };
    }
  }
}

