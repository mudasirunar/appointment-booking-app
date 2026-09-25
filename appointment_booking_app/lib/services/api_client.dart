import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class ApiClient {
  final String baseUrl;
  final String appSecret;

  ApiClient({
    this.baseUrl = AppConstants.defaultBackendUrl,
    this.appSecret = AppConstants.appSecretToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-App-Secret': appSecret,
      };

  /// Dispatches 6-digit Brevo OTP email to user
  Future<void> sendOtp(String email) async {
    final url = Uri.parse('$baseUrl/auth/send-otp');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to send OTP email.');
    }
  }

  /// Verifies 6-digit OTP and returns resetToken
  Future<String> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Invalid or expired OTP.');
    }

    return data['resetToken'] as String;
  }

  /// Resets user password securely in Firebase Auth via backend Admin SDK
  Future<void> resetPassword(String email, String resetToken, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'resetToken': resetToken,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to reset password.');
    }
  }
}
