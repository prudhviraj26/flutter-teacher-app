import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Base URL for Azure Web App API
  static String get baseUrl {
    return 'https://veyho-gdbth8e2d4angha9.centralindia-01.azurewebsites.net/v1';
  }

  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'veyho_access_token';
  static const String _refreshTokenKey = 'veyho_refresh_token';

  static bool _isRefreshing = false;

  // Save Token
  static Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  // Get Access Token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get Refresh Token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Clear Tokens
  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // Silent Token Renewal
  static Future<bool> refreshTokenSilently() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _isRefreshing = false;
        return false;
      }

      final url = Uri.parse('$baseUrl/auth/refresh');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-refresh-token': refreshToken,
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic> && body['accessToken'] != null) {
          final newAccess = body['accessToken'] as String;
          final newRefresh = body['refreshToken'] as String?;
          await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          debugPrint('Silent token refresh succeeded');
          _isRefreshing = false;
          return true;
        }
      }
    } catch (e) {
      debugPrint('Silent token refresh failed: $e');
    } finally {
      _isRefreshing = false;
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

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 401 && requireAuth && !isRetry) {
        final refreshed = await refreshTokenSilently();
        if (refreshed) {
          return await get(endpoint, requireAuth: requireAuth, isRetry: true);
        }
      }
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
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

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 401 && requireAuth && !isRetry) {
        final refreshed = await refreshTokenSilently();
        if (refreshed) {
          return await post(endpoint, body, requireAuth: requireAuth, isRetry: true);
        }
      }
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
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

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 401 && requireAuth && !isRetry) {
        final refreshed = await refreshTokenSilently();
        if (refreshed) {
          return await patch(endpoint, body, requireAuth: requireAuth, isRetry: true);
        }
      }
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
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
        errorMessage = jsonBody['message']?.toString() ?? jsonBody['error']?.toString() ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }
}
