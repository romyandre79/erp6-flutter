import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:dio/io.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService() {
    _dio.options.baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080/api';
    
    // Bypass SSL verification for development
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    // Add interceptor to load base URL from settings
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final savedUrl = prefs.getString('api_url');
        // Use saved URL if available, otherwise keep default from .env or fallback
        if (savedUrl != null && savedUrl.isNotEmpty) {
          options.baseUrl = savedUrl;
        }
        return handler.next(options);
      },
    ));
  }

  Future<String?> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        // API response structure: { code: 200, message: "...", data: { token: "...", user: {...} } }
        final data = response.data['data'];
        final token = data['token'];
        final user = data['user'];
        
          if (token != null) {
            await _storage.write(key: 'jwt_token', value: token.toString());
            
            if (user != null) {
               if (user['themeid'] != null) {
                 await _storage.write(key: 'theme_id', value: user['themeid'].toString());
               }
               if (user['userid'] != null) {
                 await _storage.write(key: 'user_id', value: user['userid'].toString());
               }
               // Store full user object
               await _storage.write(key: 'user_data', value: jsonEncode(user));
            }
            
            return token.toString();
          }
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> getUser() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'theme_id');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<int?> getUserId() async {
     final uid = await _storage.read(key: 'user_id');
     if (uid != null) return int.tryParse(uid);
     return null;
  }

  Future<bool> canAccess(String menu) async {
    // TODO: Implement real RBAC based on token roles or permissions API
    // For now, allow access if authenticated
    return await isAuthenticated();
  }
}
