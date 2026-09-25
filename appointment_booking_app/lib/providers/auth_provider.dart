import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  // Brevo OTP Password Reset State
  String? _resetEmail;
  String? _resetToken;
  bool _isOtpSending = false;
  bool _isOtpVerifying = false;
  bool _isPasswordResetting = false;

  AuthProvider() {
    _initAuthListener();
  }

  User? get user => _user;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  String? get errorMessage => _errorMessage;

  String? get resetEmail => _resetEmail;
  bool get isOtpSending => _isOtpSending;
  bool get isOtpVerifying => _isOtpVerifying;
  bool get isPasswordResetting => _isPasswordResetting;

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      _user = user;
      _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sign In
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sign Up
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      _user = credential.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sign Out (Strict Account Isolation)
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('SignOut exception: $e');
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    _resetEmail = null;
    _resetToken = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Brevo Email OTP Password Reset Flow
  // ---------------------------------------------------------------------------

  /// Step 1: Send OTP to email via Brevo
  Future<bool> sendResetOtp(String email) async {
    _isOtpSending = true;
    _errorMessage = null;
    _resetEmail = email.trim().toLowerCase();
    notifyListeners();

    try {
      await _apiClient.sendOtp(_resetEmail!);
      _isOtpSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isOtpSending = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Step 2: Verify received 6-digit OTP
  Future<bool> verifyResetOtp(String otp) async {
    if (_resetEmail == null) {
      _errorMessage = 'Session expired. Please re-enter your email.';
      notifyListeners();
      return false;
    }

    _isOtpVerifying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _resetToken = await _apiClient.verifyOtp(_resetEmail!, otp);
      _isOtpVerifying = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isOtpVerifying = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Step 3: Set new password
  Future<bool> resetPassword(String newPassword) async {
    if (_resetEmail == null || _resetToken == null) {
      _errorMessage = 'Invalid reset session. Please restart password reset.';
      notifyListeners();
      return false;
    }

    _isPasswordResetting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.resetPassword(_resetEmail!, _resetToken!, newPassword);
      _isPasswordResetting = false;
      _resetEmail = null;
      _resetToken = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isPasswordResetting = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Update User Display Name
  Future<bool> updateDisplayName(String newName) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(newName.trim());
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update display name: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
