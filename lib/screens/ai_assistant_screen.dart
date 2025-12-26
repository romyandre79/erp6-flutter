import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../core/constants/app_colors.dart';
import '../widgets/glass_container.dart';
import '../services/ai_service.dart';
import '../services/websocket_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello! I am your AI Assistant. How can I help you today?', 'isAi': true},
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() async {
    try {
      final wsService = Provider.of<WebSocketService>(context, listen: false);
      
      // Connect to WebSocket if not already connected
      try {
        await wsService.connect();
      } catch (e) {
        print('WebSocket already connected or connection error: $e');
      }
      
      // Listen for AI responses
      wsService.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          
          // Check if this is an AI response - type: "chat" with message field
          if (data['type'] == 'chat' && data['message'] != null) {
            if (mounted) {
              setState(() {
                _messages.add({'text': data['message'], 'isAi': true});
                _isLoading = false;
              });
            }
          }
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      });
    } catch (e) {
      print('Error setting up WebSocket listener: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    
    final userMessage = _controller.text;
    setState(() {
      _messages.add({'text': userMessage, 'isAi': false});
      _controller.clear();
      _isLoading = true;
    });

    try {
      // Send command - response will come via WebSocket
      await _aiService.sendCommand(userMessage);
      // Don't add response here - it will come via WebSocket
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'text': 'Error: ${e.toString()}', 'isAi': true});
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isAi = msg['isAi'] as bool;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    if (isAi)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const HeroIcon(HeroIcons.sparkles, size: 20, color: AppColors.primary),
                      ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAi ? Colors.white.withOpacity(0.9) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          border: isAi ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isAi ? AppColors.textLight : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HeroIcon(HeroIcons.sparkles, size: 20, color: AppColors.primary),
                ),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                const Text('AI is thinking...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Row(
            children: [
              IconButton(
                onPressed: () {}, 
                icon: const HeroIcon(HeroIcons.microphone, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Ask AI anything... (Press send button to submit)',
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
}
