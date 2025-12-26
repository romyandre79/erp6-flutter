import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  }

  Future<String?> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        // API response structure: { code: 200, message: "...", data: { token: "..." } }
        final token = response.data['data']['token'];
        final user = response.data['data']['user'];
        
          if (token != null) {
            await _storage.write(key: 'jwt_token', value: token.toString());
            
            if (user != null) {
               if (user['themeid'] != null) {
                 await _storage.write(key: 'theme_id', value: user['themeid'].toString());
               }
               if (user['userid'] != null) {
                 await _storage.write(key: 'user_id', value: user['userid'].toString());
               }
            }
            
            return token.toString();
          }
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<int?> getUserId() async {
     // Retrieve user id from storage if saved during login, or decode token
     // For now, let's assume we saved it or parse it.
     // Nuxt implementation decodes token.
     // Let's see login method:
     // It saves 'jwt_token' and 'theme_id'. It doesn't seem to save user_id explicitly in generic storage.
     // But wait, the previous tool call showed:
     // if (user != null && user['themeid'] != null)
     // We should typically save user_id.
     // Let's update login to save user_id too.
     
     final uid = await _storage.read(key: 'user_id');
     if (uid != null) return int.tryParse(uid);
     return null;
  }
}
