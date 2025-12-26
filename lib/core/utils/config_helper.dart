import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigHelper {
  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_url') ?? dotenv.env['API_URL'] ?? 'https://localhost:8888/api';
  }

  static Future<String> getWsUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ws_url') ?? dotenv.env['WS_URL'] ?? 'wss://localhost:8888/api/ws/notifications';
  }
}
