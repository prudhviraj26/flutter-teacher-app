import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Base URL for Azure Web App API
  static String get baseUrl {
    return 'https://veyho-fgcqeafwcbgdfhek.centralindia-01.azurewebsites.net/v1';
  }

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const String _tokenKey = 'veyho_access_token';
  static const String _refreshTokenKey = 'veyho_refresh_token';

  static Completer<bool>? _refreshCompleter;

  // Save Token
  static Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    try {
      await _storage.write(key: _tokenKey, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (e) {
      debugPrint('[ApiService] Keystore saveTokens error: $e');
    }
  }

  // Get Access Token
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('[ApiService] Keystore getToken error: $e');
      return null;
    }
  }

  // Get Refresh Token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('[ApiService] Keystore getRefreshToken error: $e');
      return null;
    }
  }

  // Clear Tokens
  static Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('[ApiService] Keystore clearTokens error: $e');
    }
  }

  // Silent Token Renewal with Completer Mutex
  static Future<bool> refreshTokenSilently() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        if (!completer.isCompleted) completer.complete(false);
        return false;
      }

      final url = Uri.parse('$baseUrl/auth/refresh');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-refresh-token': refreshToken,
          'x-app-context': 'teacher',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
          'app': 'teacher',
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic> && body['accessToken'] != null) {
          final newAccess = body['accessToken'] as String;
          final newRefresh = body['refreshToken'] as String? ?? refreshToken;
          await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          debugPrint('Teacher App silent token refresh succeeded');
          if (!completer.isCompleted) completer.complete(true);
          return true;
        }
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        debugPrint('Teacher App refresh token rejected: ${res.statusCode}');
        try {
          final errBody = jsonDecode(res.body);
          final msg = (errBody['message'] ?? errBody['error'] ?? '').toString().toLowerCase();
          if (msg.contains('session expired or revoked') || msg.contains('invalid or expired refresh token')) {
            await clearTokens();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Teacher App silent token refresh network issue (tokens kept): $e');
    } finally {
      if (!completer.isCompleted) completer.complete(false);
      _refreshCompleter = null;
    }
    return false;
  }

  // Headers Helper
  static Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET Request with Auto-Token Refresh Retry
  static Future<dynamic> get(String endpoint, {bool requireAuth = true, bool isRetry = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final http.Response response;
    try {
      response = await http.get(url, headers: headers);
    } catch (e) {
      throw Exception('Unable to connect to server. Please check your internet connection.');
    }

    if (response.statusCode == 401 && requireAuth && !isRetry) {
      final refreshed = await refreshTokenSilently();
      if (refreshed) {
        return await get(endpoint, requireAuth: requireAuth, isRetry: true);
      }
    }
    return _processResponse(response);
  }

  // POST Request with Auto-Token Refresh Retry
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
    bool isRetry = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw Exception('Unable to connect to server. Please check your internet connection.');
    }

    if (response.statusCode == 401 && requireAuth && !isRetry) {
      final refreshed = await refreshTokenSilently();
      if (refreshed) {
        return await post(endpoint, body, requireAuth: requireAuth, isRetry: true);
      }
    }
    return _processResponse(response);
  }

  // PATCH Request with Auto-Token Refresh Retry
  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
    bool isRetry = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final http.Response response;
    try {
      response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw Exception('Unable to connect to server. Please check your internet connection.');
    }

    if (response.statusCode == 401 && requireAuth && !isRetry) {
      final refreshed = await refreshTokenSilently();
      if (refreshed) {
        return await patch(endpoint, body, requireAuth: requireAuth, isRetry: true);
      }
    }
    return _processResponse(response);
  }

  // DELETE Request with Auto-Token Refresh Retry
  static Future<dynamic> delete(
    String endpoint, {
    bool requireAuth = true,
    bool isRetry = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final http.Response response;
    try {
      response = await http.delete(url, headers: headers);
    } catch (e) {
      throw Exception('Unable to connect to server. Please check your internet connection.');
    }

    if (response.statusCode == 401 && requireAuth && !isRetry) {
      final refreshed = await refreshTokenSilently();
      if (refreshed) {
        return await delete(endpoint, requireAuth: requireAuth, isRetry: true);
      }
    }
    return _processResponse(response);
  }

  // Upload Multipart File (with upload progress tracking)
  static Future<dynamic> uploadMultipart(
    String endpoint, {
    required File file,
    String fieldName = 'file',
    bool requireAuth = true,
    bool isRetry = false,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    if (requireAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final int fileLength = await file.length();
    final filename = file.path.split(Platform.pathSeparator).last;

    if (onProgress != null) {
      final stream = file.openRead();
      int bytesSent = 0;
      final byteStream = stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            sink.add(data);
            onProgress(bytesSent, fileLength);
          },
        ),
      );
      request.files.add(
        http.MultipartFile(
          fieldName,
          byteStream,
          fileLength,
          filename: filename,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path, filename: filename),
      );
    }

    final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send();
    } catch (e) {
      throw Exception('Unable to connect to server. Please check your internet connection.');
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401 && requireAuth && !isRetry) {
      final refreshed = await refreshTokenSilently();
      if (refreshed) {
        return await uploadMultipart(
          endpoint,
          file: file,
          fieldName: fieldName,
          requireAuth: requireAuth,
          isRetry: true,
          onProgress: onProgress,
        );
      }
    }
    return _processResponse(response);
  }

  // Response Processing
  static dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(responseBody);
    } catch (_) {
      jsonBody = responseBody;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return jsonBody;
    } else {
      String errorMessage = 'An error occurred';
      if (jsonBody is Map<String, dynamic>) {
        final msg = jsonBody['message'];
        if (msg is List && msg.isNotEmpty) {
          errorMessage = msg.map((m) => m.toString()).join(', ');
        } else if (msg != null && msg.toString().trim().isNotEmpty) {
          errorMessage = msg.toString();
        } else if (jsonBody['error'] != null && jsonBody['error'].toString().trim().isNotEmpty) {
          errorMessage = jsonBody['error'].toString();
        }
      }
      throw Exception(errorMessage);
    }
  }

  // Legal & Clickwrap Endpoints
  static Future<Map<String, dynamic>?> fetchActiveLegalDocuments() async {
    try {
      final res = await get('/legal/active', requireAuth: false);
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('[ApiService] Failed to fetch active legal documents: $e');
    }
    return null;
  }

  static Future<bool> recordLegalConsent({
    required List<Map<String, dynamic>> consents,
    String? deviceUuid,
    String? deviceToken,
  }) async {
    try {
      final payload = <String, dynamic>{
        'consents': consents,
      };
      if (deviceUuid != null) payload['deviceUuid'] = deviceUuid;
      if (deviceToken != null) payload['deviceToken'] = deviceToken;

      final res = await post('/legal/consent', payload, requireAuth: true);
      return res != null && res['success'] == true;
    } catch (e) {
      debugPrint('[ApiService] Failed to record legal consent: $e');
      return false;
    }
  }

}
