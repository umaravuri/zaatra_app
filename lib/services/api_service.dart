import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_env.dart';

class ApiService {
  /// Base API URL dynamically fetched from AppEnv (.env or fallback)
  static String get baseUrl => AppEnv.baseUrl;

  /// Server root URL (without '/api' suffix), used for relative media/uploads URLs
  static String get serverBaseUrl => baseUrl.replaceAll('/api', '');

  /// Backwards-compatibility alias for server root URL
  static String get tunnelUrl => serverBaseUrl;

  static Future<Map<String, String>> _getHeaders({String? token}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
    };

    String activeToken = token ?? '';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (activeToken.isEmpty) {
        activeToken = prefs.getString('authToken') ?? '';
      }
      final phone = prefs.getString('currentPhone') ?? '';
      final driverId = prefs.getString('driverId') ?? prefs.getString('userId') ?? '';
      if (driverId.isNotEmpty) {
        headers['x-driver-id'] = driverId;
        headers['x-user-id'] = driverId;
      }
      if (phone.isNotEmpty) {
        headers['x-driver-phone'] = phone;
        headers['x-phone'] = phone;
      }
    } catch (_) {}

    if (activeToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $activeToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    try {
      final headers = await _getHeaders(token: token);
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          if (data is Map<String, dynamic>) ...data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': (data is Map ? data['message'] : null) ?? 'Request failed with status ${response.statusCode}',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: Could not reach backend server at $baseUrl. Please ensure "npm start" is running in Zaatra_Backend-main.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      final headers = await _getHeaders(token: token);
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(url, headers: headers);

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          if (data is Map<String, dynamic>) ...data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': (data is Map ? data['message'] : null) ?? 'Request failed with status ${response.statusCode}',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: Could not reach backend server at $baseUrl.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    try {
      final headers = await _getHeaders(token: token);
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          if (data is Map<String, dynamic>) ...data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': (data is Map ? data['message'] : null) ?? 'Request failed with status ${response.statusCode}',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: Could not reach backend server at $baseUrl.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body, {String? token}) async {
    try {
      final headers = await _getHeaders(token: token);
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          if (data is Map<String, dynamic>) ...data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': (data is Map ? data['message'] : null) ?? 'Request failed with status ${response.statusCode}',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: Could not reach backend server at $baseUrl.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint, {Map<String, dynamic>? body, String? token}) async {
    try {
      final headers = await _getHeaders(token: token);
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          if (data is Map<String, dynamic>) ...data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': (data is Map ? data['message'] : null) ?? 'Request failed with status ${response.statusCode}',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: Could not reach backend server at $baseUrl.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> uploadMultipart(
    String endpoint, {
    required String fieldName,
    required List<dynamic> files,
    Map<String, String>? fields,
    String? token,
  }) async {
    try {
      final headers = await _getHeaders(token: token);
      headers.remove('Content-Type');

      final url = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      for (int i = 0; i < files.length; i++) {
        final f = files[i];
        if (f is http.MultipartFile) {
          request.files.add(f);
        } else if (f != null) {
          try {
            final bytes = await (f as dynamic).readAsBytes();
            final filename = (f as dynamic).name ?? 'photo_$i.jpg';
            request.files.add(http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: filename.toString(),
            ));
          } catch (_) {
            final strPath = f.toString();
            request.files.add(await http.MultipartFile.fromPath(
              fieldName,
              strPath,
            ));
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          if (data is Map<String, dynamic>) ...data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': (data is Map ? data['message'] : null) ?? 'Upload failed with status ${response.statusCode}',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload error: Could not connect to $baseUrl.',
        'error': e.toString(),
      };
    }
  }

  /// Uploads multiple distinct named files along with text fields (POST or PUT).
  /// [files] maps multipart fieldName (e.g. 'drivingLicense') -> file object (XFile, PlatformFile, path, or http.MultipartFile).
  static Future<Map<String, dynamic>> uploadMultiFieldMultipart(
    String endpoint, {
    String method = 'POST',
    Map<String, String>? fields,
    Map<String, dynamic>? files,
    String? token,
  }) async {
    try {
      final headers = await _getHeaders(token: token);
      headers.remove('Content-Type');

      final url = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest(method.toUpperCase(), url);
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        for (final entry in files.entries) {
          final fieldName = entry.key;
          final f = entry.value;
          if (f == null) continue;

          if (f is http.MultipartFile) {
            request.files.add(f);
            continue;
          }

          MediaType? getMediaType(String fname) {
            final ext = fname.split('.').last.toLowerCase();
            if (ext == 'pdf') return MediaType('application', 'pdf');
            if (ext == 'png') return MediaType('image', 'png');
            if (ext == 'jpg' || ext == 'jpeg') return MediaType('image', 'jpeg');
            return null;
          }

          bool added = false;
          // Try reading as bytes (works for XFile or web/memory PlatformFile)
          try {
            final dynamic fileObj = f;
            if (fileObj.bytes != null) {
              final List<int> bytes = List<int>.from(fileObj.bytes);
              final filename = fileObj.name?.toString() ?? '$fieldName.jpg';
              request.files.add(http.MultipartFile.fromBytes(
                fieldName,
                bytes,
                filename: filename,
                contentType: getMediaType(filename),
              ));
              added = true;
            } else if (fileObj.readAsBytes != null) {
              final List<int> bytes = await fileObj.readAsBytes();
              final filename = fileObj.name?.toString() ?? '$fieldName.jpg';
              request.files.add(http.MultipartFile.fromBytes(
                fieldName,
                bytes,
                filename: filename,
                contentType: getMediaType(filename),
              ));
              added = true;
            }
          } catch (_) {}

          if (!added) {
            try {
              final dynamic fileObj = f;
              final String? strPath = fileObj.path?.toString() ?? (f is String ? f : null);
              if (strPath != null && strPath.isNotEmpty) {
                final filename = (fileObj.name?.toString()) ?? strPath.split(RegExp(r'[\\/]')).last;
                request.files.add(await http.MultipartFile.fromPath(
                  fieldName,
                  strPath,
                  filename: filename,
                  contentType: getMediaType(filename),
                ));
                added = true;
              }
            } catch (_) {}
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          if (data is Map<String, dynamic>) ...data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': (data is Map ? data['message'] : null) ?? 'Upload failed with status ${response.statusCode}',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload error: Could not connect to $baseUrl.',
        'error': e.toString(),
      };
    }
  }
}
