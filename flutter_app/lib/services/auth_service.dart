import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';

  // ── Register ───────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _handleResponse(res);
  }

  // ── Login ──────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false, // ÚJ: Checkbox paraméter (alapértelmezetten false)
  }) async {

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    // 1. Feldolgozzuk a választ
    final responseData = _handleResponse(res);

    // 2. ÚJ LOGIKA: Ha a user kérte a mentést, és a szerver küldött tokent
    if (rememberMe && responseData.containsKey('token')) {
      await saveToken(responseData['token']);
    }

    // 3. Visszaadjuk a teljes választ az AuthProvider-nek
    return responseData;
  }

  // ── Token persistence ──────────────────────────────────
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Helper ─────────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['error'] ?? 'Unknown error');
  }
}