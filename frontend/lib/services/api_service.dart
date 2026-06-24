import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ── Token management ──────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? farmName,
    String? location,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'farm_name': farmName,
        'location': location,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(data['user']));
      return data;
    }
    throw Exception(data['detail'] ?? 'Registration failed');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(data['user']));
      return data;
    }
    throw Exception(data['detail'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    final headers = await _authHeaders();
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: headers);
    await clearToken();
  }

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Not authenticated');
  }

  // ── Predictions ───────────────────────────────────────────
  static Future<Map<String, dynamic>> predictManual(Map<String, dynamic> params) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: headers,
      body: jsonEncode(params),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Prediction failed');
  }

  static Future<Map<String, dynamic>> predictGeo({
    required double latitude,
    required double longitude,
    required double landArea,
    required double soilPermeability,
    required double brineSalinity,
    String? notes,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/predict/geo'),
      headers: headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'land_area': landArea,
        'soil_permeability': soilPermeability,
        'brine_salinity': brineSalinity,
        'notes': notes,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Geo prediction failed');
  }

  // ── History & Stats ───────────────────────────────────────
  static Future<List<dynamic>> getHistory() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/history'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['predictions'];
    }
    throw Exception('Failed to load history');
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/dashboard/stats'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load stats');
  }
}
