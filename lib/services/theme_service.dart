import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class ThemeService extends ChangeNotifier {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ThemeData? _themeData;
  ThemeData? get themeData => _themeData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ThemeService() {
    _dio.options.baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080/api';
    
    // Bypass SSL verification for development
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  Future<void> loadTheme() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      print("ThemeService: Fetching theme from custom API...");
      final response = await _dio.post(
        '/auth/load-theme',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print("ThemeService: Response status ${response.statusCode}");
      print("ThemeService: API Data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        // Handle nested structure: { data: { data: [ ... ] } }
        dynamic dynamicData = data['data'];
        
        List themes = [];
        if (dynamicData is Map && dynamicData['data'] is List) {
           themes = dynamicData['data'];
        } else if (dynamicData is List) {
           themes = dynamicData;
        } else if (dynamicData is Map) {
           themes = [dynamicData];
        }

        if (themes.isNotEmpty) {
           // Read user's theme preference
           final storedThemeId = await _storage.read(key: 'theme_id');
           print("ThemeService: User stored theme_id: $storedThemeId");

           dynamic themeRecord;
           
           if (storedThemeId != null) {
              themeRecord = themes.firstWhere(
                (t) => t['themeid']?.toString() == storedThemeId,
                orElse: () => themes.first,
              );
           } else {
              themeRecord = themes.first;
           }

           print("ThemeService: Selected theme: ${themeRecord['description']} (ID: ${themeRecord['themeid']})");
           
           // Parse themedata (JSON String or Map)
           Map<String, dynamic> themeProps = {};
           if (themeRecord['themedata'] is String) {
             try {
                // Remove newlines and problematic chars if any, but standard json decode should handle it
                String jsonStr = themeRecord['themedata'];
                themeProps = jsonDecode(jsonStr);
             } catch (e) {
               print("ThemeService: Error parsing themedata JSON: $e");
             }
           } else if (themeRecord['themedata'] is Map) {
             themeProps = themeRecord['themedata'];
           }
           
           if (themeProps.isNotEmpty) {
             print("ThemeService: Parsing theme properties...");
             // Extract 'sidebar-menu-color' as Primary (Example mapping)
             // Or 'primary-color' if exists.
             // User's example has 'sidebar-menu-color': '#f57f17'
             
             Color? primaryColor;
             String? colorHex = themeProps['sidebar-menu-color'] ?? themeProps['primary-color'];
             
             if (colorHex != null && colorHex.startsWith('#')) {
               try {
                 colorHex = colorHex.replaceAll('#', '');
                 if (colorHex.length == 6) colorHex = "FF$colorHex";
                 primaryColor = Color(int.parse("0x$colorHex"));
               } catch (e) {
                 print("ThemeService: Invalid color format: $colorHex");
               }
             }
             
             if (primaryColor != null) {
               print("ThemeService: Applying dynamic primary color: $primaryColor");
               _themeData = ThemeData(
                 useMaterial3: true,
                 colorScheme: ColorScheme.fromSeed(
                   seedColor: primaryColor,
                   primary: primaryColor,
                   brightness: Brightness.light, 
                 ),
                 textTheme: GoogleFonts.interTextTheme(),
               );
             }
           }
        }
      }
    } catch (e) {
      print("ThemeService Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
