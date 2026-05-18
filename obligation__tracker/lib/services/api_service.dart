import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api',
  );

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map
          ? (body['message'] ?? body['error'] ?? 'Request failed')
          : 'Request failed';
      throw Exception(message.toString());
    }
    return body;
  }

  static Future<void> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/signup'),
      headers: await _headers(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    final data = _decode(response);
    if (data['token'] != null) await saveToken(data['token']);
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(response);
    if (data['token'] == null) throw Exception('Login token was not returned');
    await saveToken(data['token']);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(auth: true),
    );
    final data = _decode(response);
    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? profileImageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );
    final data = _decode(response);
    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  static Future<String> uploadProfileAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/avatar'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'imageBase64': base64Encode(bytes),
        'fileName': fileName,
      }),
    );
    final data = _decode(response);
    return data['profileImageUrl']?.toString() ?? '';
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/change-password'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    _decode(response);
  }

  static Future<List<Map<String, dynamic>>> getObligations({
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl/obligations').replace(queryParameters: query);
    final response = await http.get(uri, headers: await _headers(auth: true));
    final data = _decode(response);
    final list = (data['obligations'] ?? []) as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> createObligation(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/obligations'),
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> updateObligation(String id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/obligations/$id'),
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> deleteObligation(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/obligations/$id'),
      headers: await _headers(auth: true),
    );
    _decode(response);
  }

  static Future<void> createFeedback(String feedback) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feedbacks'),
      headers: await _headers(auth: true),
      body: jsonEncode({'feedback': feedback}),
    );
    _decode(response);
  }
}
