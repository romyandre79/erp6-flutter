import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/websocket_service.dart';
import '../core/constants/app_colors.dart';
import '../widgets/glass_container.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/websocket_service.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../core/constants/app_colors.dart';
import '../widgets/glass_container.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final WebSocketService _wsService = WebSocketService();
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  int? _myUserId;
  Map<String, dynamic>? _selectedUser;
  List<dynamic> _users = [];
  bool _isLoadingUsers = false;

  // Chat History: userId -> List of messages
  final Map<int, List<Map<String, dynamic>>> _chatHistory = {};
  
  // Unread Counts: userId -> count
  final Map<int, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _myUserId = await _authService.getUserId();
    await _initWebSocket();
    await _fetchUsers();
  }

  Future<void> _initWebSocket() async {
    try {
      await _wsService.connect();
      // Listen to broadcast stream
      _wsService.stream.listen(_handleWebSocketMessage, onError: (e) => print("WS Error: $e"));
    } catch (e) {
      print("Failed to connect WS: $e");
    }
  }

  void _handleWebSocketMessage(dynamic data) {
    try {
      final parsed = jsonDecode(data.toString());
      
      if (parsed['type'] == 'status_update') {
          // Update user status
          final userId = parsed['user_id'];
          final isOnline = parsed['isonline'] == 1 || parsed['isonline'] == true;
          if (mounted) {
             setState(() {
                final idx = _users.indexWhere((u) => u['useraccessid'] == userId);
                if (idx != -1) {
                   _users[idx]['isonline'] = isOnline ? 1 : 0;
                } else {
                   // User not in list, refresh
                   _fetchUsers();
                }
             });
          }
      } else if (parsed['type'] == 'chat') {
          // Incoming Chat
          final senderId = parsed['senderid'];
          final content = parsed['data'];
          final msg = {
             'text': content['text'] ?? '',
             'attachment': content['attachment'],
             'filesize': content['filesize'],
             'timestamp': content['timestamp'],
             'isMe': false,
             'senderId': senderId
          };

          if (mounted) {
             setState(() {
                if (_chatHistory[senderId] == null) _chatHistory[senderId] = [];
                _chatHistory[senderId]!.add(msg);
                
                // If not currently chatting with this user, increment unread
                if (_selectedUser == null || _selectedUser!['useraccessid'] != senderId) {
                   _unreadCounts[senderId] = (_unreadCounts[senderId] ?? 0) + 1;
                }
             });
          }
      }
    } catch (e) {
      print("WS Parse Error: $e");
    }
  }

  Future<void> _fetchUsers() async {
    if (_myUserId == null) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _dashboardService.getChatUsers(_myUserId!);
      if (mounted) {
         setState(() {
           _users = users;
         });
      }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _selectUser(Map<String, dynamic> user) async {
    setState(() {
      _selectedUser = user;
      // Clear unread
      _unreadCounts[user['useraccessid']] = 0;
    });

    // Load History if empty
    final targetId = user['useraccessid'];
    if (_chatHistory[targetId] == null || _chatHistory[targetId]!.isEmpty) {
        // Fetch history
        final history = await _dashboardService.getChatHistory(_myUserId!, targetId);
        if (mounted) {
           setState(() {
             _chatHistory[targetId] = history.map((h) => {
                'text': h['message'],
                'attachment': h['attachment'], // Check key from actual API response if different
                'timestamp': h['created_at'],
                'isMe': h['senderid'] == _myUserId,
                'senderId': h['senderid']
             }).toList();
           });
        }
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty || _selectedUser == null) return;
    
    final text = _controller.text;
    final targetId = _selectedUser!['useraccessid'];
    final timestamp = DateTime.now().toIso8601String();

    // Send via WS
    final payload = jsonEncode({
       'type': 'chat',
       'targetid': targetId,
       'data': {
          'text': text,
          'timestamp': timestamp,
          'attachment': null
       }
    });
    _wsService.sendMessage(payload);
    
    setState(() {
      if (_chatHistory[targetId] == null) _chatHistory[targetId] = [];
      _chatHistory[targetId]!.add({
        'text': text,
        'timestamp': timestamp,
        'isMe': true,
        'senderId': _myUserId
      });
    });
    _controller.clear();
  }
  
  Future<void> _pickAttachment() async {
    if (_selectedUser == null) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: 150,
        child: Column(
           children: [
             ListTile(
               leading: const Icon(Icons.image),
               title: const Text('Image'),
               onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                     final File file = File(image.path);
                     final int size = await file.length();
                     final uploadedPath = await _dashboardService.uploadFile(file);
                     if (uploadedPath != null) {
                        _sendAttachmentMessage("[Image] ${image.name}", uploadedPath, size);
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload Failed")));
                     }
                  }
               },
             ),
             ListTile(
               leading: const Icon(Icons.attach_file),
               title: const Text('File'),
               onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                     final file = File(result.files.single.path!);
                     final int size = await file.length();
                     final uploadedPath = await _dashboardService.uploadFile(file);
                     if (uploadedPath != null) {
                        _sendAttachmentMessage("[File] ${result.files.single.name}", uploadedPath, size);
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload Failed")));
                     }
                  }
               },
             ),
           ],
        ),
      )
    );
  }

  void _sendAttachmentMessage(String placeholderText, String path, [int? size]) {
    if (_selectedUser == null) return;
    final targetId = _selectedUser!['useraccessid'];
    
    // For now simple text placeholder
    // Real impl requires upload API then sending URL
    
    final payload = jsonEncode({
       'type': 'chat',
       'targetid': targetId,
       'data': {
          'text': placeholderText,
          'timestamp': DateTime.now().toIso8601String(),
          'attachment': path,
          'filesize': size
       }
    });
    _wsService.sendMessage(payload);

    setState(() {
       _chatHistory[targetId]!.add({
          'text': placeholderText,
          'timestamp': DateTime.now().toIso8601String(),
          'isMe': true, 
          'senderId': _myUserId,
          'attachment': path,
          'filesize': size
       });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedUser == null) {
       return _buildUserList();
    } else {
       return _buildChatRoom();
    }
  }

  Widget _buildUserList() {
    if (_isLoadingUsers) return const Center(child: CircularProgressIndicator());
    if (_users.isEmpty) return const Center(child: Text("No users found"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final unread = _unreadCounts[user['useraccessid']] ?? 0;
        final isOnline = user['isonline'] == 1 || user['isonline'] == true;

        return Card(
           margin: const EdgeInsets.only(bottom: 8),
           child: ListTile(
             leading: Stack(
               children: [
                 CircleAvatar(
                   backgroundColor: Colors.grey[200],
                   child: Text(user['realname']?[0] ?? '?', style: const TextStyle(color: Colors.black)),
                 ),
                 if (isOnline)
                   Positioned(
                     right: 0,
                     bottom: 0,
                     child: Container(
                       width: 12, height: 12,
                       decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                     ),
                   )
               ],
             ),
             title: Text(user['realname'] ?? 'Unknown'),
             subtitle: Text(user['email'] ?? ''),
             trailing: unread > 0 
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )
                : null,
             onTap: () => _selectUser(user),
           ),
        );
      },
    );
  }

  Widget _buildChatRoom() {
    final messages = _chatHistory[_selectedUser!['useraccessid']] ?? [];

    return Column(
      children: [
        // Chat Header
        Container(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           color: Colors.white,
           child: Row(
             children: [
               IconButton(
                 icon: const Icon(Icons.arrow_back),
                 onPressed: () => setState(() => _selectedUser = null),
               ),
               const SizedBox(width: 8),
               Text(_selectedUser!['realname'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             ],
           ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg['isMe'] as bool;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg['attachment'] != null)
                        _buildAttachmentThumbnail(msg['attachment'], filesize: msg['filesize']),
                      if (msg['text'] != null && msg['text'].toString().isNotEmpty)
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Row(
            children: [
              IconButton(onPressed: _pickAttachment, icon: const Icon(Icons.attach_file, color: AppColors.textSecondary)),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: const HeroIcon(HeroIcons.paperAirplane, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentThumbnail(String path, {int? filesize}) {
    // Use API_URL from .env to support both localhost and network IP
    final apiUrl = dotenv.env['API_URL'] ?? 'https://localhost:8888';
    final baseUrl = apiUrl.replaceAll('/api', ''); // Remove /api suffix if present
    final url = path.startsWith('http') ? path : '$baseUrl/$path';
    
    // Simple check for images
    final isImage = path.toLowerCase().endsWith('.jpg') || 
                    path.toLowerCase().endsWith('.jpeg') || 
                    path.toLowerCase().endsWith('.png') || 
                    path.toLowerCase().endsWith('.gif') ||
                    path.toLowerCase().endsWith('.webp');

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: InkWell(
          onTap: () => _launchURL(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
               url,
               height: 150,
               width: 150,
               fit: BoxFit.cover,
               errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
        ),
      );
    } else {
      return InkWell(
        onTap: () => _launchURL(url),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Icon(Icons.attach_file, size: 24, color: Colors.white),
               const SizedBox(width: 8),
               Flexible(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(path.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                     if (filesize != null)
                        Text(_formatBytes(filesize), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                   ],
                 ),
               ),
            ],
          ),
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length - 1) ~/ 3; // Approximate index logic or log
    // Better log logic
    // But since no math.log easily without import 'dart:math', use standard loop or division
    // Simple division implementation:
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < suffixes.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return "${size.toStringAsFixed(2)} ${suffixes[unitIndex]}";
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }
}
