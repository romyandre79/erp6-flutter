import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dio/io.dart';
import '../core/utils/config_helper.dart';

class AiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AiService() {
    _initializeBaseUrl();
    
    // Bypass SSL verification for development
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  Future<void> _initializeBaseUrl() async {
    _dio.options.baseUrl = await ConfigHelper.getApiUrl();
  }

  Future<String> sendCommand(String message) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final userId = await _storage.read(key: 'user_id');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Use FormData to match web implementation
      final formData = FormData.fromMap({
        'flowname': 'aicommand',
        'menu': 'admin',
        'search': 'false',
        'command': message,
        'user_id': userId ?? '',
      });

      final response = await _dio.post(
        '/admin/execute-flow',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        // Parse response data - it might be a string or already parsed
        dynamic data = response.data;
        
        if (data is String) {
          // Check if string is not empty before parsing
          if (data.trim().isEmpty) {
            return 'Command sent successfully';
          }
          try {
            data = jsonDecode(data);
          } catch (e) {
            // If JSON parsing fails, return the raw string or success message
            return data.isNotEmpty ? data : 'Command sent successfully';
          }
        }
        
        // Backend returns {code: 200, message: "...", data: {...}}
        // The actual AI response comes via WebSocket, but we'll return success message
        if (data is Map) {
          return data['message']?.toString() ?? 'Command sent successfully';
        }
        return 'Command sent successfully';
      } else {
        throw Exception('Failed to send command');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
