import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _currentUser = await _authService.getUser();
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Vui long nhap day du thong tin';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    final response = await _authService.login(
      email: email.trim(),
      password: password,
    );

    if (response.success) {
      _currentUser = response.user ?? await _authService.getUser();
      _setLoading(false);
      return true;
    }

    _errorMessage = response.message ?? 'Dang nhap that bai';
    _setLoading(false);
    return false;
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '985763535068-mdtqp9enodsfref03irhdi8qferjqh4u.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? serverAuthCode = googleUser.serverAuthCode;

      String? tokenToSend;
      String tokenType = 'idToken';

      if (idToken != null) {
        tokenToSend = idToken;
      } else if (serverAuthCode != null) {
        tokenToSend = serverAuthCode;
        tokenType = 'authCode';
      }

      if (tokenToSend == null) {
        _errorMessage = 'Khong the lay token tu Google';
        _setLoading(false);
        return false;
      }

      final response = await _authService.googleLogin(
        googleToken: tokenToSend,
        tokenType: tokenType,
      );

      if (response.success) {
        _currentUser = response.user ?? await _authService.getUser();
        _setLoading(false);
        return true;
      }

      _errorMessage = response.message ?? 'Dang nhap Google that bai';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString().contains('ApiException: 10')
          ? 'Google Sign-In bi loi cau hinh (ApiException: 10). Hay kiem tra SHA-1/SHA-256 trong Firebase, bat Google Authentication va cap nhat google-services.json.'
          : 'Loi dang nhap Google: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
