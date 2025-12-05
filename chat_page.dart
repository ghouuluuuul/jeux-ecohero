import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Adresse de ton serveur Ollama (Gemma 2 2B)
  // Sur émulateur Android : remplace localhost par 10.0.2.2 si besoin.
  final String _ollamaBaseUrl = 'http://localhost:11434';
  final String _modelName = 'gemma2:2b';

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
        "Bonjour ! 👋 Je suis votre assistant virtuel (Gemma 2 2B local). Comment puis-je vous aider aujourd'hui ?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Ajout du message utilisateur
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Appel au modèle local Gemma 2 2B via Ollama
    String response;
    try {
      response = await _callGemma(text);
    } catch (e) {
      response =
      "Une erreur est survenue lors de l'appel au modèle local : $e\nVérifie que Ollama tourne bien avec le modèle gemma2:2b.";
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = false;
    });

    _scrollToBottom();
  }

  /// Appel HTTP au serveur Ollama local (endpoint /api/chat, modèle gemma2:2b)
  Future<String> _callGemma(String userMessage) async {
    final uri = Uri.parse('$_ollamaBaseUrl/api/chat');

    final body = jsonEncode({
      'model': _modelName,
      'messages': [
        {
          'role': 'system',
          'content':
          'Tu es un assistant utile pour une application de jeux éducatifs. Réponds en français par défaut, de façon courte et claire.',
        },
        {
          'role': 'user',
          'content': userMessage,
        },
      ],
      'stream': false, // réponse non streamée, plus simple à gérer ici
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    // Réponse JSON de /api/chat (Ollama)
    // Structure typique : { "message": { "role": "assistant", "content": "..." }, ... }
    final Map<String, dynamic> json = jsonDecode(response.body);
    if (json['message'] != null && json['message']['content'] != null) {
      return json['message']['content'] as String;
    }

    // Fallback si le format diffère
    return jsonEncode(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 10),
            Text('Chat Assistant'),
          ],
        ),
        backgroundColor: const Color(0xFF10A37F),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Indicateur de saisie
            if (_isTyping)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Assistant écrit...',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Zone de saisie
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Posez votre question...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF10A37F),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFF10A37F),
              radius: 16,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF10A37F)
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
