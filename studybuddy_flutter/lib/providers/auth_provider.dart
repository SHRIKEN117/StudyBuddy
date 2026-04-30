import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final res = await ApiService.get(ApiConstants.profile);
      _user = User.fromJson(res['data'] as Map<String, dynamic>);
      notifyListeners();
    } on Object {
      // Token invalid or network down — clear token and stay on login screen
      await prefs.remove('token');
      ApiService.clearToken();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.post(
        ApiConstants.login,
        {'email': email, 'password': password},
        auth: false,
      );
      // Login endpoint returns user/token at root level (no data wrapper)
      final token = res['token'] as String?;
      final userMap = res['user'] as Map<String, dynamic>?;
      if (token == null || userMap == null) {
        _error = 'Unexpected server response. Please try again.';
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      ApiService.cacheToken(token);
      _user = User.fromJson(userMap);
      return true;
    } on Object catch (e) {
      _error = e is ApiException ? e.message : 'Connection failed. Check your network.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.post(
        ApiConstants.register,
        {'username': username, 'email': email, 'password': password},
        auth: false,
      );
      // Register endpoint wraps user/token inside data
      final data = res['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final userMap = data?['user'] as Map<String, dynamic>?;
      if (token == null || userMap == null) {
        _error = 'Unexpected server response. Please try again.';
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      ApiService.cacheToken(token);
      _user = User.fromJson(userMap);
      return true;
    } on Object catch (e) {
      _error = e is ApiException ? e.message : 'Connection failed. Check your network.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiService.clearToken();
    _user = null;
    notifyListeners();
  }
}
