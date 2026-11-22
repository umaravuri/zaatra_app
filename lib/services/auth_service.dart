import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../views/screens/authorization/login_screen_115.dart';
import '../views/screens/authorization/role_selection_screen_27.dart';
import '../views/screens/customer/customer-stay/customer_home_screen_38.dart';
import '../views/screens/driver/driver-main/driver_home_dashboard_screen_83.dart';
import '../views/screens/host/become_host_screen_28.dart';

class AuthService {
  // Session Constants (30-Day Lifespan)
  static const String keyAuthToken = 'authToken';
  static const String keyLoginTimestamp = 'loginTimestamp';
  static const String keySessionExpiryTimestamp = 'sessionExpiryTimestamp';
  static const String keySelectedRole = 'selectedRole';
  static const String keyCurrentUserRole = 'currentUserRole';
  static const String keyActiveRole = 'activeRole';
  static const String keyUserRoles = 'userRoles';
  static const String keyTokenExpiresAt = 'tokenExpiresAt';
  static const String keyCurrentPhone = 'currentPhone';
  static const String keyDriverId = 'driverId';
  static const String keyUserId = 'userId';

  /// 30 Days in milliseconds (30 * 24 * 60 * 60 * 1000 = 2,592,000,000 ms)
  static const int sessionDurationMs = 30 * 24 * 60 * 60 * 1000;
  // 1. User Registration API
  // Endpoint: POST /auth/register
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    String? email,
    String? password,
    required String phone,
    String? city,
    String? state,
    String? country,
    required String role,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final resolvedEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : '$cleanDigits@zaatra.com';
    final resolvedPassword = (password != null && password.trim().isNotEmpty) ? password.trim() : 'ZaatraOTP@123';

    final body = {
      'name': name,
      'email': resolvedEmail,
      'password': resolvedPassword,
      'phone': phone,
      'city': city ?? '',
      'state': state ?? '',
      'country': country ?? 'India',
      'role': role.toLowerCase(),
    };

    final result = await ApiService.post('/auth/register', body);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name_$cleanPhone', name);
      await prefs.setString('currentUserName', name);
      await prefs.setString('user_email_$cleanPhone', resolvedEmail);
    } catch (_) {}
    return result;
  }

  // 2. Mobile Login Step 1: Initialize Login & Receive OTP (Passwordless)
  // Endpoint: POST /api/auth/mobile/login-init (Aliases: /api/auth/mobile/send-otp, /api/auth/send-otp)
  static Future<Map<String, dynamic>> loginInitMobile({
    required String phone,
    String? password, // Deprecated optional legacy param
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;
    final formattedPhone = '+91 $tenDigits';

    final body = {
      'phone': formattedPhone,
      'mobileNumber': tenDigits,
    };

    // Primary endpoint: POST /api/auth/mobile/login-init
    var result = await ApiService.post('/auth/mobile/login-init', body);

    // Fallback alias: POST /api/auth/mobile/send-otp
    if (result['statusCode'] == 404 ||
        (result['success'] != true && (result['message'] ?? '').toString().contains('Cannot POST'))) {
      result = await ApiService.post('/auth/mobile/send-otp', body);
    }

    // Normalize response
    if (result['success'] == true) {
      final data = result['data'] is Map ? result['data'] : result;
      final extractedOtp = (data['otp'] ?? result['otp'])?.toString() ?? '123456';
      final normalizedPhone = (data['phone'] ?? result['phone'] ?? formattedPhone).toString();

      return {
        'success': true,
        'otp': extractedOtp,
        'phone': normalizedPhone,
        'matchedPhone': normalizedPhone,
        'expiresInSeconds': data['expiresInSeconds'] ?? 600,
        'nextStep': data['nextStep'] ?? 'VERIFY_OTP',
        'message': data['message'] ?? 'OTP code sent successfully',
        'data': data,
      };
    }

    return result;
  }

  // User IDs are issued with a role prefix (C- customer, H- host, D- driver) and never change,
  // unlike the mutable `role` field, so they identify the role the account was registered with.
  static String? roleFromUserId(dynamic id) {
    final s = id?.toString().trim().toUpperCase() ?? '';
    if (s.startsWith('D-')) return 'driver';
    if (s.startsWith('H-')) return 'host';
    if (s.startsWith('C-')) return 'customer';
    return null;
  }

  // Looks the account up on the backend by phone and returns its registered role,
  // or null if it could not be determined (e.g. network failure / not found).
  static Future<String?> resolveRegisteredRole(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (tenDigits.isEmpty) return null;

    for (final endpoint in const ['/hosts', '/drivers']) {
      final res = await ApiService.get(endpoint);
      if (res['success'] != true) continue;

      List<dynamic>? records;
      for (final k in const ['hosts', 'drivers', 'users', 'data']) {
        if (res[k] is List) {
          records = res[k] as List;
          break;
        }
      }
      if (records == null) continue;

      for (final r in records) {
        if (r is! Map) continue;
        final rDigits = (r['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
        if (rDigits.length < 10 || rDigits.substring(rDigits.length - 10) != tenDigits) continue;
        final role = roleFromUserId(r['userId'] ?? r['id']);
        if (role != null) return role;
      }
    }
    return null;
  }

  // 3. Mobile Login Step 2: Verify 6-Digit OTP
  // Endpoint: POST /api/auth/mobile/verify-otp (Alias: /api/auth/verify-otp)
  static Future<Map<String, dynamic>> verifyOtpMobile({
    required String phone,
    required String otp,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;
    final formattedPhone = '+91 $tenDigits';

    final body = {
      'phone': formattedPhone,
      'otp': otp,
    };

    var result = await ApiService.post('/auth/mobile/verify-otp', body);
    if (result['statusCode'] == 404 ||
        (result['success'] != true && (result['message'] ?? '').toString().contains('Cannot POST'))) {
      result = await ApiService.post('/auth/verify-otp', body);
    }

    final data = result['data'] is Map ? result['data'] : result;
    final isVerified = data['verified'] == true || result['success'] == true;

    return {
      'success': isVerified,
      'verified': isVerified,
      'phone': data['phone'] ?? formattedPhone,
      'isExistingUser': data['isExistingUser'] == true,
      'roles': data['roles'] ?? result['roles'],
      'nextStep': data['nextStep'] ?? 'CHOOSE_ROLE',
      'message': data['message'] ?? 'OTP verified successfully.',
      'data': data,
    };
  }

  // 4. Mobile Login Step 3: Choose Role & Complete Login (Receive JWT Token)
  // Endpoint: POST /api/auth/mobile/select-role?soft=true (Aliases: /api/auth/mobile/choose-role, /api/auth/select-role)
  static Future<Map<String, dynamic>> selectRoleMobile({
    required String phone,
    required String role,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;
    final formattedPhone = '+91 $tenDigits';

    final body = {
      'phone': formattedPhone,
      'role': role.toLowerCase(),
    };

    // Use ?soft=true so unlinked roles return 200 with popup object instead of a hard 404
    var result = await ApiService.post('/auth/mobile/select-role?soft=true', body);

    if (result['statusCode'] == 404 ||
        (result['success'] != true && (result['message'] ?? '').toString().contains('Cannot POST'))) {
      result = await ApiService.post('/auth/mobile/choose-role?soft=true', body);
      if (result['statusCode'] == 404) {
        result = await ApiService.post('/auth/select-role?soft=true', body);
      }
    }

    final data = result['data'] is Map ? result['data'] : result;
    // Strictly respect canLogin if explicitly specified by backend.
    // If backend returns canLogin: false (even with success: true / soft=true), the user CANNOT log in directly.
    final bool canLogin = data['canLogin'] == true;
    final popup = data['popup'] ?? (data is Map && data['popup'] is Map ? data['popup'] : null);

    if (canLogin) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'] ?? result['token'];
        final user = data['user'] ?? result['user'];

        // Reset previous user's session if phone changed
        final existingPhone = prefs.getString('currentPhone') ?? '';
        final existingClean = existingPhone.replaceAll(RegExp(r'[^0-9]'), '');
        final bool phoneChanged = existingClean.isNotEmpty && existingClean != cleanDigits && existingClean != tenDigits;
        if (phoneChanged) {
          await logout();
        }

        if (token != null) {
          await prefs.setString(keyAuthToken, token.toString());
        }

        // Establish or preserve 30-day session timestamp
        final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
        final existingLoginTs = prefs.getInt(keyLoginTimestamp);
        if (existingLoginTs == null || existingLoginTs <= 0 || phoneChanged) {
          await prefs.setInt(keyLoginTimestamp, nowMs);
          await prefs.setInt(keySessionExpiryTimestamp, nowMs + sessionDurationMs);
        }

        // Cache driverId if returned
        final dynamic returnedDriverId = result['driverId'] ??
            data['driverId'] ??
            (user is Map ? user['driverId'] ?? user['id'] ?? user['_id'] : null);
        if (returnedDriverId != null && returnedDriverId.toString().isNotEmpty) {
          final dId = returnedDriverId.toString().trim();
          await prefs.setString('driverId', dId);
          await prefs.setString('driver_id_$cleanDigits', dId);
          await prefs.setString('driver_id_$tenDigits', dId);
        }

        if (user != null) {
          await prefs.setString('userProfile', jsonEncode(user));
          if (user is Map) {
            if (user['name'] != null && user['name'].toString().isNotEmpty) {
              final uName = user['name'].toString().trim();
              await prefs.setString('currentUserName', uName);
              await prefs.setString('user_name_$cleanDigits', uName);
              await prefs.setString('user_name_$tenDigits', uName);
            }
            if (user['avatar'] != null && user['avatar'].toString().isNotEmpty) {
              await prefs.setString('current_user_avatar', user['avatar'].toString());
            }
            if (user['email'] != null && user['email'].toString().isNotEmpty) {
              await prefs.setString('currentUserEmail', user['email'].toString());
              await prefs.setString('user_email_$cleanDigits', user['email'].toString());
              await prefs.setString('user_email_$tenDigits', user['email'].toString());
            }
            if (user['city'] != null && user['city'].toString().isNotEmpty) {
              await prefs.setString('currentUserCity', user['city'].toString());
              await prefs.setString('user_city_$cleanDigits', user['city'].toString());
            }
            if (user['location'] != null && user['location'].toString().isNotEmpty) {
              await prefs.setString('currentUserLocation', user['location'].toString());
              await prefs.setString('user_location_$cleanDigits', user['location'].toString());
            }
          }
        }
        await prefs.setString('currentPhone', formattedPhone);
        await prefs.setString('selectedRole', role.toLowerCase());
        await prefs.setString('currentUserRole', role.toLowerCase());
        await prefs.setString('user_role_$cleanDigits', role.toLowerCase());
        await prefs.setString('user_role_$tenDigits', role.toLowerCase());
      } catch (_) {}
    }

    return {
      'success': canLogin,
      'canLogin': canLogin,
      'isRegistered': data['isRegistered'] == true,
      'role': role.toLowerCase(),
      'targetDashboard': data['targetDashboard'],
      'message': data['message'] ?? result['message'],
      'token': data['token'] ?? result['token'],
      'user': data['user'] ?? result['user'],
      'popup': popup,
      'action': data['action'],
      'data': data,
    };
  }

  // Session Helpers
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken');
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('userProfile');
      if (userStr != null && userStr.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(userStr);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // If stringified Dart map format, extract key-values via regex
          final parsed = <String, dynamic>{};
          final nameMatch = RegExp(r'name:\s*([^,}]+)').firstMatch(userStr);
          final emailMatch = RegExp(r'email:\s*([^,}]+)').firstMatch(userStr);
          final phoneMatch = RegExp(r'phone:\s*([^,}]+)').firstMatch(userStr);
          final cityMatch = RegExp(r'city:\s*([^,}]+)').firstMatch(userStr);
          final locMatch = RegExp(r'location:\s*([^,}]+)').firstMatch(userStr);
          if (nameMatch != null) parsed['name'] = nameMatch.group(1)?.trim();
          if (emailMatch != null) parsed['email'] = emailMatch.group(1)?.trim();
          if (phoneMatch != null) parsed['phone'] = phoneMatch.group(1)?.trim();
          if (cityMatch != null) parsed['city'] = cityMatch.group(1)?.trim();
          if (locMatch != null) parsed['location'] = locMatch.group(1)?.trim();
          if (parsed.isNotEmpty) return parsed;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String> getCurrentUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(keyCurrentPhone) ?? prefs.getString('currentPhone');
      if (phone != null && phone.trim().isNotEmpty) {
        return phone.trim();
      }
      final user = await getCurrentUser();
      if (user != null && user['phone'] != null && user['phone'].toString().trim().isNotEmpty) {
        return user['phone'].toString().trim();
      }
    } catch (_) {}
    return '';
  }

  static Future<String> getUserName({String? phone, String defaultFallback = 'User'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (phone != null && phone.isNotEmpty) {
        final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
        final nameByPhone = prefs.getString('user_name_$cleanPhone');
        if (nameByPhone != null && nameByPhone.trim().isNotEmpty) {
          return nameByPhone.trim();
        }
      }
      final current = prefs.getString('currentUserName');
      if (current != null && current.trim().isNotEmpty) {
        return current.trim();
      }
      final user = await getCurrentUser();
      if (user != null && user['name'] != null && user['name'].toString().trim().isNotEmpty) {
        return user['name'].toString().trim();
      }
    } catch (_) {}
    return defaultFallback;
  }

  static Future<void> saveUserName(String name, {String? phone}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserName', name);
      if (phone != null && phone.isNotEmpty) {
        final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
        await prefs.setString('user_name_$cleanPhone', name);
      }
    } catch (_) {}
  }

  // ==========================================
  // Centralized 30-Day Session Management
  // ==========================================

  /// Explicitly initializes or updates a session
  static Future<void> createSession({
    required String token,
    required String role,
    required String phone,
    String? userId,
    String? driverId,
    Map<String, dynamic>? userProfile,
    bool preserveExistingLoginTime = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await prefs.setString(keyAuthToken, token);
    await prefs.setString(keySelectedRole, role.toLowerCase());
    await prefs.setString(keyCurrentUserRole, role.toLowerCase());
    await prefs.setString(keyCurrentPhone, phone);

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(keyUserId, userId);
    }
    if (driverId != null && driverId.isNotEmpty) {
      await prefs.setString(keyDriverId, driverId);
    }
    if (userProfile != null) {
      await prefs.setString('userProfile', jsonEncode(userProfile));
    }

    final existingTimestamp = prefs.getInt(keyLoginTimestamp);
    if (!preserveExistingLoginTime || existingTimestamp == null || existingTimestamp <= 0) {
      await prefs.setInt(keyLoginTimestamp, nowMs);
      await prefs.setInt(keySessionExpiryTimestamp, nowMs + sessionDurationMs);
    }
  }

  // ---------------------------------------------------------------------------
  // Centralized Session Management (v2 /api/auth/session/*)
  // ---------------------------------------------------------------------------

  /// 1. Validate Session with Backend
  /// Endpoint: GET /api/auth/session
  /// Headers: Authorization: Bearer <token>
  static Future<Map<String, dynamic>> validateSession({String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeToken = (token != null && token.isNotEmpty)
          ? token
          : (prefs.getString(keyAuthToken) ?? '');

      if (activeToken.isEmpty) {
        return {
          'success': false,
          'valid': false,
          'code': 'NO_TOKEN',
          'message': 'No authentication token found',
        };
      }

      final res = await ApiService.get('/auth/session', token: activeToken);
      final statusCode = res['statusCode'] as int?;
      final rawData = res['data'];

      // Check if token expired (401 / TOKEN_EXPIRED)
      if (statusCode == 401 || (rawData is Map && rawData['code'] == 'TOKEN_EXPIRED')) {
        return {
          'success': false,
          'valid': false,
          'statusCode': 401,
          'code': 'TOKEN_EXPIRED',
          'message': (rawData is Map ? rawData['message'] : null) ?? res['message'] ?? 'Session expired. Please log in again.',
        };
      }

      // Check valid flag
      final bool isValid = res['valid'] == true || (rawData is Map && rawData['valid'] == true);
      if (res['success'] == true && isValid) {
        final sessionData = (res['session'] is Map ? res['session'] : (rawData is Map ? rawData['session'] : null)) as Map?;
        final userData = (res['user'] is Map ? res['user'] : (rawData is Map ? rawData['user'] : null)) as Map?;

        if (sessionData != null) {
          final activeRole = sessionData['activeRole']?.toString();
          if (activeRole != null && activeRole.isNotEmpty) {
            await prefs.setString(keyActiveRole, activeRole.toLowerCase());
            await prefs.setString(keySelectedRole, activeRole.toLowerCase());
            await prefs.setString(keyCurrentUserRole, activeRole.toLowerCase());
          }
          if (sessionData['roles'] is List) {
            final rolesList = (sessionData['roles'] as List).map((e) => e.toString()).toList();
            await prefs.setStringList(keyUserRoles, rolesList);
          }
          if (sessionData['tokenExpiresAt'] != null) {
            await prefs.setString(keyTokenExpiresAt, sessionData['tokenExpiresAt'].toString());
          }
        }

        if (userData != null) {
          final name = userData['name']?.toString();
          final phone = userData['phone']?.toString();
          final avatar = userData['avatar']?.toString();
          final userId = userData['id']?.toString() ?? userData['userId']?.toString();

          if (name != null && name.isNotEmpty) {
            await prefs.setString('currentUserName', name);
            await prefs.setString('driverName', name);
          }
          if (phone != null && phone.isNotEmpty) {
            await prefs.setString(keyCurrentPhone, phone);
          }
          if (avatar != null && avatar.isNotEmpty) {
            await prefs.setString('current_user_avatar', avatar);
          }
          if (userId != null && userId.isNotEmpty) {
            await prefs.setString(keyUserId, userId);
            await prefs.setString(keyDriverId, userId);
          }
          await prefs.setString('userProfile', jsonEncode(userData));
        }

        return {
          'success': true,
          'valid': true,
          'session': sessionData,
          'user': userData,
          ...res,
        };
      }

      return res;
    } catch (e) {
      return {
        'success': false,
        'valid': false,
        'error': e.toString(),
      };
    }
  }

  /// 2. Silent Token Renewal
  /// Endpoint: POST /api/auth/session/refresh
  /// Headers: Authorization: Bearer <token>
  static Future<Map<String, dynamic>> refreshToken({String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeToken = (token != null && token.isNotEmpty)
          ? token
          : (prefs.getString(keyAuthToken) ?? '');

      if (activeToken.isEmpty) {
        return {'success': false, 'message': 'No token to refresh'};
      }

      final body = {'token': activeToken};
      final res = await ApiService.post('/auth/session/refresh', body, token: activeToken);

      final rawData = res['data'];
      final newToken = res['token']?.toString() ?? (rawData is Map ? rawData['token']?.toString() : null);

      if (res['success'] == true && newToken != null && newToken.isNotEmpty) {
        await prefs.setString(keyAuthToken, newToken);

        final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
        await prefs.setInt(keyLoginTimestamp, nowMs);
        await prefs.setInt(keySessionExpiryTimestamp, nowMs + sessionDurationMs);

        final sessionData = (res['session'] is Map ? res['session'] : (rawData is Map ? rawData['session'] : null)) as Map?;
        final userData = (res['user'] is Map ? res['user'] : (rawData is Map ? rawData['user'] : null)) as Map?;

        if (sessionData != null) {
          final activeRole = sessionData['activeRole']?.toString();
          if (activeRole != null && activeRole.isNotEmpty) {
            await prefs.setString(keyActiveRole, activeRole.toLowerCase());
            await prefs.setString(keySelectedRole, activeRole.toLowerCase());
            await prefs.setString(keyCurrentUserRole, activeRole.toLowerCase());
          }
        }
        if (userData != null) {
          final name = userData['name']?.toString();
          if (name != null && name.isNotEmpty) {
            await prefs.setString('currentUserName', name);
            await prefs.setString('driverName', name);
          }
        }

        return {
          'success': true,
          'token': newToken,
          'session': sessionData,
          'user': userData,
          ...res,
        };
      }

      return res;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 3. Switch Active Role
  /// Endpoint: POST /api/auth/session/switch-role
  /// Headers: Authorization: Bearer <token>
  /// Body: { "role": "<customer|driver|host>" }
  static Future<Map<String, dynamic>> switchRole(String newRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeToken = prefs.getString(keyAuthToken) ?? '';
      final targetRole = newRole.toLowerCase().trim();

      final body = {'role': targetRole};
      final res = await ApiService.post('/auth/session/switch-role', body, token: activeToken);

      final rawData = res['data'];
      final newToken = res['token']?.toString() ?? (rawData is Map ? rawData['token']?.toString() : null);
      final String activeRole = (res['activeRole']?.toString() ?? (rawData is Map ? rawData['activeRole']?.toString() : null) ?? targetRole).toLowerCase();

      if (res['success'] == true) {
        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString(keyAuthToken, newToken);
        }
        await prefs.setString(keyActiveRole, activeRole);
        await prefs.setString(keySelectedRole, activeRole);
        await prefs.setString(keyCurrentUserRole, activeRole);
        await prefs.setString('lastActiveRole', activeRole);

        final rawRoles = res['roles'] ?? (rawData is Map ? rawData['roles'] : null);
        if (rawRoles is List) {
          final rolesList = rawRoles.map((e) => e.toString()).toList();
          await prefs.setStringList(keyUserRoles, rolesList);
        }

        return {
          'success': true,
          'token': newToken ?? activeToken,
          'activeRole': activeRole,
          ...res,
        };
      }

      return res;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Returns the registered roles for current user
  static Future<List<String>> getAvailableRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keyUserRoles) ?? [];
  }

  /// Centralized Session Validation (Local sliding 30-day window check)
  static Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(keyAuthToken);
      if (token == null || token.trim().isEmpty) {
        return false;
      }

      final loginTimestamp = prefs.getInt(keyLoginTimestamp);
      final nowUtc = DateTime.now().toUtc();
      final nowMs = nowUtc.millisecondsSinceEpoch;

      if (loginTimestamp == null || loginTimestamp <= 0) {
        final sessionRes = await validateSession(token: token);
        if (sessionRes['success'] == true && sessionRes['valid'] == true) {
          await prefs.setInt(keyLoginTimestamp, nowMs);
          await prefs.setInt(keySessionExpiryTimestamp, nowMs + sessionDurationMs);
          return true;
        } else if (sessionRes['statusCode'] == 401 || sessionRes['code'] == 'TOKEN_EXPIRED') {
          await logout();
          return false;
        } else {
          return prefs.getString('userProfile') != null;
        }
      }

      // Check future timestamp anomaly (clock skew > 1 minute)
      if (loginTimestamp > nowMs + 60000) {
        await logout();
        return false;
      }

      // Check exact 30-day expiration (2,592,000,000 ms)
      final elapsedMs = nowMs - loginTimestamp;
      if (elapsedMs >= sessionDurationMs) {
        await logout();
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Backwards-compatible session validator
  static Future<bool?> validateSessionWithBackend(String token) async {
    try {
      final res = await validateSession(token: token);
      if (res['statusCode'] == 401 || res['code'] == 'TOKEN_EXPIRED') {
        return false;
      }
      if (res['success'] == true && res['valid'] == true) {
        return true;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Resolves initial destination screen with backend session check, silent refresh, and offline resilience
  static Future<Widget> getInitialScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(keyAuthToken);

      if (token == null || token.trim().isEmpty) {
        return const LoginScreen();
      }

      // 1. Authoritative Backend Validation: GET /api/auth/session
      final sessionRes = await validateSession(token: token);

      if (sessionRes['success'] == true && sessionRes['valid'] == true) {
        final session = sessionRes['session'] as Map?;
        final activeRole = (session?['activeRole']?.toString() ??
                prefs.getString(keyActiveRole) ??
                prefs.getString(keySelectedRole) ??
                prefs.getString(keyCurrentUserRole) ??
                '')
            .toLowerCase();
        final phone = prefs.getString(keyCurrentPhone) ?? '';
        return _buildScreenForRole(activeRole, phone);
      }

      // 2. Token Expired Case (401 / TOKEN_EXPIRED) -> Attempt Silent Token Refresh
      final rawData = sessionRes['data'];
      final bool isExpired = sessionRes['statusCode'] == 401 ||
          sessionRes['code'] == 'TOKEN_EXPIRED' ||
          (rawData is Map && rawData['code'] == 'TOKEN_EXPIRED');

      if (isExpired) {
        final refreshRes = await refreshToken(token: token);
        if (refreshRes['success'] == true) {
          final refreshedSession = refreshRes['session'] as Map?;
          final activeRole = (refreshedSession?['activeRole']?.toString() ??
                  prefs.getString(keyActiveRole) ??
                  prefs.getString(keySelectedRole) ??
                  prefs.getString(keyCurrentUserRole) ??
                  '')
              .toLowerCase();
          final phone = prefs.getString(keyCurrentPhone) ?? '';
          return _buildScreenForRole(activeRole, phone);
        } else {
          // Token refresh failed -> Force clean logout
          await logout();
          return const LoginScreen();
        }
      }

      // 3. Network Outage / Offline Grace Fallback -> Check local 30-day session
      final isLocalValid = await isSessionValid();
      if (isLocalValid) {
        final role = (prefs.getString(keyActiveRole) ??
                prefs.getString(keySelectedRole) ??
                prefs.getString(keyCurrentUserRole) ??
                '')
            .toLowerCase();
        final phone = prefs.getString(keyCurrentPhone) ?? '';
        return _buildScreenForRole(role, phone);
      }

      return const LoginScreen();
    } catch (_) {
      return const LoginScreen();
    }
  }

  static Future<Widget> _buildScreenForRole(String role, String phone) async {
    switch (role) {
      case 'driver':
        final driverName = await getUserName();
        return DriverHomeDashboardScreen83(driverName: driverName);
      case 'customer':
        return const CustomerHomeScreen();
      case 'host':
        return BecomeHostScreen(phoneNumber: phone, isExistingHost: true);
      default:
        return const RoleSelectionScreen();
    }
  }

  /// Logout: POST /api/auth/session/logout
  /// Notifies backend to invalidate session & mark offline, then flushes local preferences.
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(keyAuthToken);

      // 1. Notify Backend
      if (token != null && token.isNotEmpty) {
        try {
          await ApiService.post('/auth/session/logout', {}, token: token);
        } catch (_) {}
      }

      // 2. Clear local session keys
      await prefs.remove(keyAuthToken);
      await prefs.remove(keyLoginTimestamp);
      await prefs.remove(keySessionExpiryTimestamp);
      await prefs.remove(keyActiveRole);
      await prefs.remove(keyUserRoles);
      await prefs.remove(keyTokenExpiresAt);
      await prefs.remove('userProfile');
      await prefs.remove(keySelectedRole);
      await prefs.remove(keyCurrentUserRole);
      await prefs.remove('currentUserName');
      await prefs.remove('driverName');
      await prefs.remove('last_registered_role');
      await prefs.remove(keyCurrentPhone);
      await prefs.remove('currentUserEmail');
      await prefs.remove('currentUserCity');
      await prefs.remove('currentUserLocation');
      await prefs.remove(keyDriverId);
      await prefs.remove(keyUserId);
      await prefs.remove('current_user_avatar');
    } catch (_) {}
  }

  /// Permanently delete account, notify backend, and clear all local storage
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      Map<String, dynamic> res = {};
      try {
        res = await ApiService.delete('/auth/account');
      } catch (_) {
        try {
          res = await ApiService.post('/auth/delete-account', {});
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return {'success': true, 'message': 'Account deleted successfully', ...res};
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return {'success': true, 'message': 'Account deleted successfully: $e'};
    }
  }
}
