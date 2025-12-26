import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:dio/io.dart';

class DashboardService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DashboardService() {
    _dio.options.baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080/api';
    
    // Bypass SSL verification
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  Future<List<dynamic>> fetchWidgets(String moduleName) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return [];

      final formData = FormData.fromMap({
        'flowname': 'getwidgetbymodule',
        'menu': moduleName, // 'admin' usually
        'search': 'true',
        'modulename': moduleName,
      });

      print("DashboardService: Fetching widgets for $moduleName...");
      final response = await _dio.post(
        '/admin/execute-flow',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print("DashboardService: Response ${response.statusCode}");
      
      if (response.statusCode == 200) {
        // Expected format: { code: 200, data: { data: [ ...widgets... ] } }
        final data = response.data;
        if (data['data'] != null && data['data']['data'] != null) {
          return data['data']['data'] as List<dynamic>;
        }
      }
    } catch (e) {
      print("DashboardService Error: $e");
    }
    return [];
  }

  Future<dynamic> executeFlow(String flowname, Map<String, dynamic> params) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      final Map<String, dynamic> dataMap = {
        'flowname': flowname,
        'menu': 'admin', // Default for now, or pass as param
        'search': 'true',
        ...params,
      };

      final formData = FormData.fromMap(dataMap);

      final response = await _dio.post(
        '/admin/execute-flow',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("DashboardService executeFlow Error: $e");
    }
    return null;
  }

  // Chat Helpers
  Future<List<dynamic>> getChatUsers(int myUserId) async {
    try {
      final res = await executeFlow('getuserlist', {
        'menu': 'admin',
        'search': 'true',
        'action': 'getuserlist',
        'senderid': myUserId.toString()
      });
      
      if (res == null) return [];
      
      // Handle if res is directly the list (unlikely but possible)
      if (res is List) return res;
      
      // Handle standard structure
      if (res is Map) {
        final data = res['data'];
        if (data is List) return data;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) return result;
        }
      }
      
      return [];
    } catch (e) {
      print("getChatUsers Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> getChatHistory(int myUserId, int targetId) async {
    try {
      final res = await executeFlow('chat', {
        'menu': 'admin',
        'search': 'true',
        'action': 'gethistory',
        'senderid': myUserId.toString(),
        'targetid': targetId.toString()
      });
      
      if (res == null) return [];

      if (res is List) return res;

      if (res is Map) {
        final data = res['data'];
        if (data is List) return data;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) return result;
        }
      }

      return [];
    } catch (e) {
      print("getChatHistory Error: $e");
      return [];
    }
  }

  Future<String?> uploadFile(File file) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      String fileName = file.path.split(Platform.pathSeparator).last;
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'path': 'chat_uploads',
      });

      final response = await _dio.post(
        '/media/upload',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        }),
      );

      if (response.statusCode == 200) {
        // Construct the expected relative path since backend doesn't return it
        return 'chat_uploads/$fileName';
      }
    } catch (e) {
      print("Upload Error: $e");
    }
    return null;
  }
}
