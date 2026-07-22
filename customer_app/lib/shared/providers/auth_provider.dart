import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

const _role = 'customer';
const _storageKey = 'customer_auth_token';

class AuthState {
  final String? token;
  final User? user;
  final bool loading;

  const AuthState({this.token, this.user, this.loading = true});

  bool get isAuthenticated => token != null && user != null;
}

class AuthController extends StateNotifier<AuthState> {
  final http.Client _client;

  AuthController(this._client) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_storageKey);
    if (token == null) {
      state = const AuthState(loading: false);
      return;
    }
    await _fetchMe(token);
  }

  Future<void> _fetchMe(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$apiBaseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        await _clear();
        return;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      state = AuthState(
        token: token,
        user: User.fromJson(data['user'] as Map<String, dynamic>),
        loading: false,
      );
    } catch (_) {
      await _clear();
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': _role}),
    );
    await _handleAuthResponse(response);
  }

  Future<void> register(String email, String password, String name) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': _role,
      }),
    );
    await _handleAuthResponse(response);
  }

  Future<void> _handleAuthResponse(http.Response response) async {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, data['error'] as String? ?? 'Request failed');
    }

    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, token);

    state = AuthState(token: token, user: user, loading: false);
  }

  Future<void> logout() async {
    final token = state.token;
    if (token != null) {
      try {
        await _client.post(
          Uri.parse('$apiBaseUrl/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        // token may already be invalid/expired — clearing locally is enough
      }
    }
    await _clear();
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = const AuthState(loading: false);
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(httpClientProvider));
});
