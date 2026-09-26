import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Base URL for API: 10.0.2.2 is Android Emulator localhost, localhost for web/desktop/iOS
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/v1';
    }
    // Android emulator access to host machine
    return 'http://10.0.2.2:3000/v1';
  }

  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'veyho_access_token';
  static const String _refreshTokenKey = 'veyho_refresh_token';

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

  // Clear Tokens
  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
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

  // GET Request
  static Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await http.get(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST Request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PATCH Request
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
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
