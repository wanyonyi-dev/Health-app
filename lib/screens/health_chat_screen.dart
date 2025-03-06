import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../config/api_config.dart';

class HealthChatScreen extends StatefulWidget {
  const HealthChatScreen({super.key});

  @override
  State<HealthChatScreen> createState() => _HealthChatScreenState();
}

class _HealthChatScreenState extends State<HealthChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Initialize Gemini AI
  late final GenerativeModel model;
  late final ChatSession chat;

  @override
  void initState() {
    super.initState();
    model = GenerativeModel(
      model: 'gemini-2.0-flash', // Updated model name
      apiKey: ApiConfig.geminiApiKey,
    );
    chat = model.startChat(
      history: [
        Content.text(
          'You are a medical assistant specialized in providing health-related information. '
          'Only answer health-related questions. For non-health questions, '
          'respond with "I can only answer health-related questions."'
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Assistant'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF3B82F6),
              child: Icon(Icons.health_and_safety, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF3B82F6)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: message.isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(color: Colors.white),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask a health-related question...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(userMessage, true));
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await chat.sendMessage(
        Content.text(userMessage)
      );

      final botMessage = response.text ?? 'Sorry, I could not process your request.';
      
      setState(() {
        _messages.add(ChatMessage(botMessage, false));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error details: $e'); // For debugging
      _handleError(e);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleError(dynamic error) {
    print('Error details: $error'); // For debugging
    String errorMessage = 'An error occurred while processing your request.';
    
    if (error.toString().contains('API key')) {
      errorMessage = 'Invalid API key. Please check your configuration.';
    } else if (error.toString().contains('network')) {
      errorMessage = 'Network error. Please check your internet connection.';
    }
    
    setState(() {
      _messages.add(ChatMessage(errorMessage, false));
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage(this.content, this.isUser);
}