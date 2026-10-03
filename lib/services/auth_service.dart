import 'api_service.dart';

class AuthService {
  // Staff Login
  static Future<Map<String, dynamic>> login({
    required String emailOrMobile,
    required String password,
  }) async {
    final isEmail = emailOrMobile.contains('@');
    final Map<String, dynamic> body = {
      if (isEmail) 'email': emailOrMobile else 'mobile': emailOrMobile,
      'password': password,
      'platform': 'mobile',
    };

    final response = await ApiService.post(
      '/auth/login',
      body,
      requireAuth: false,
    );

    if (response is Map<String, dynamic> && response.containsKey('accessToken')) {
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String?;
      await ApiService.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    }

    return response as Map<String, dynamic>;
  }

  // Get Current Authenticated Staff Profile
  static Future<Map<String, dynamic>> getMe() async {
    final response = await ApiService.get('/auth/me');
    return response as Map<String, dynamic>;
  }

  // Change Staff Password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final refreshToken = await ApiService.getRefreshToken();
    await ApiService.post(
      '/auth/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken': refreshToken,
      },
      requireAuth: true,
    );
  }

  // Logout
  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout', {});
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await ApiService.clearTokens();
    }
  }
}

