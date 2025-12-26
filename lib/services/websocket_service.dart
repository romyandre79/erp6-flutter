import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/config_helper.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  StreamController<dynamic>? _broadcastController;

  Stream get stream {
    if (_channel == null) {
      throw Exception("WebSocket not connected. Call connect() first.");
    }
    // We can't easily turn the existing single-sub stream into broadcast if it's already listened.
    // Better pattern: listen to channel internally and forward to a broadcast controller.
    if (_broadcastController == null) {
       _broadcastController = StreamController<dynamic>.broadcast();
       _channel!.stream.listen((data) {
         _broadcastController?.add(data);
       }, onError: (e) {
         _broadcastController?.addError(e);
       }, onDone: () {
         // _broadcastController?.close(); 
         // Don't close immediately if we want to reconnect?
       });
    }
    return _broadcastController!.stream;
  }

  Future<void> connect() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      // Get URL from SharedPreferences or .env
      var finalUrl = await ConfigHelper.getWsUrl();

      // Ensure correct scheme
      if (finalUrl.startsWith('https://')) {
        finalUrl = finalUrl.replaceFirst('https://', 'wss://');
      } else if (finalUrl.startsWith('http://')) {
        finalUrl = finalUrl.replaceFirst('http://', 'ws://');
      }

      // Fix path if it points to old /ws but needs /api/ws/notifications
      // User likely has WS_URL=.../ws in .env
      if (finalUrl.endsWith('/ws')) {
         finalUrl = finalUrl.replaceFirst('/ws', '/api/ws/notifications');
      } else if (!finalUrl.contains('/api/ws/notifications')) {
          // If just base url like 192.168.1.4:8888 without path
          if (!finalUrl.endsWith('/')) finalUrl += '/';
          if (!finalUrl.endsWith('api/ws/notifications')) {
             // Append if missing, but be careful not to double append if user has something else.
             // Safest is to rely on exact mismatch fix above, but let's try to be robust.
             // If looks like root, add path.
             // finalUrl += 'api/ws/notifications';
          }
      }
      
      // Append token as query parameter
      if (token != null) {
        final separator = finalUrl.contains('?') ? '&' : '?';
        finalUrl = "$finalUrl${separator}token=$token";
      }

      print("Connecting to WS: $finalUrl");

      // Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      _channel = IOWebSocketChannel.connect(
        Uri.parse(finalUrl),
        customClient: client,
        // Remove headers as we are using query param
        // headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
    } catch (e) {
      print("WebSocket Connection Error: $e");
      rethrow;
    }
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }
}
