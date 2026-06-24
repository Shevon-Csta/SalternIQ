import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String get userName => _user?['name'] ?? 'Farmer';
  String get farmName => _user?['farm_name'] ?? 'My Saltern';

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    if (token != null && userData != null) {
      _user = jsonDecode(userData);
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? farmName,
    String? location,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.register(
        name: name, email: email, password: password,
        farmName: farmName, location: location,
      );
      _user = data['user'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.login(email: email, password: password);
      _user = data['user'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }
}
