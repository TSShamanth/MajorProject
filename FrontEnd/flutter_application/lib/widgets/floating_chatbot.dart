import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/institution_provider.dart';
import '../services/api_service.dart';

class FloatingChatbot extends StatefulWidget {
  final String? institutionId;

  const FloatingChatbot({super.key, this.institutionId});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'text': 'Hello! How can I help you today?'}
  ];
  bool _isTyping = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _messageController.clear();
    
    // Add a slight delay for better UI UX
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    try {
      final reply = await _apiService.askChatbot(text);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'bot', 'text': reply});
          _isTyping = false;
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': "I'm having trouble connecting right now, please try again later."
          });
          _isTyping = false;
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        final primaryColor = provider.primaryColor;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return Positioned(
          bottom: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isExpanded)
                ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 320,
                    height: 450,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'AI Assistant',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _toggleChat,
                              ),
                            ],
                          ),
                        ),
                        // Chat Area
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length && _isTyping) {
                                return _buildTypingIndicator(primaryColor, isDarkMode);
                              }
                              final msg = _messages[index];
                              final isUser = msg['role'] == 'user';
                              return _buildMessageBubble(msg['text']!, isUser, primaryColor, isDarkMode);
                            },
                          ),
                        ),
                        // Input Area
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isDarkMode ? const Color(0xFF374151) : Colors.grey[200]!,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF111827) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                    decoration: const InputDecoration(
                                      hintText: 'Type a message...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _sendMessage,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Floating Button
              FloatingActionButton(
                onPressed: _toggleChat,
                backgroundColor: primaryColor,
                elevation: 4,
                child: Icon(
                  _isExpanded ? Icons.close_rounded : Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, Color primaryColor, bool isDarkMode) {
    final textColor = isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black87);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isUser
              ? primaryColor
              : (isDarkMode ? const Color(0xFF374151) : Colors.grey[100]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: isUser
            ? Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: textColor, fontSize: 14),
                  listBullet: TextStyle(color: textColor, fontSize: 14),
                  strong: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                  a: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    context.go(href);
                    _toggleChat(); // close chat after redirecting
                  }
                },
              ),
      ),
    );
  }

  Widget _buildTypingIndicator(Color primaryColor, bool isDarkMode) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF374151) : Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const Text('...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
      ),
    );
  }
}
