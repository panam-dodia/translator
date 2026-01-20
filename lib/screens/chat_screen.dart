import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../providers/history_provider.dart';
import '../providers/claude_provider.dart';
import '../models/claude_query.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _chatMessages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatMessages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Get all conversation history
    final historyProvider = context.read<HistoryProvider>();
    final allMessages = historyProvider.getAllMessages();

    // Add loading message
    setState(() {
      _chatMessages.add(ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });

    _scrollToBottom();

    try {
      final claudeProvider = context.read<ClaudeProvider>();

      // Send query to Claude with conversation history as context
      final response = await claudeProvider.sendQuery(
        queryText: message,
        contextMessages: allMessages,
      );

      // Remove loading message
      setState(() {
        _chatMessages.removeLast();
        _chatMessages.add(ChatMessage(
          text: response.response ?? 'No response',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _scrollToBottom();
    } catch (e) {
      // Remove loading message
      setState(() {
        _chatMessages.removeLast();
        _chatMessages.add(ChatMessage(
          text: 'Error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });

      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeConfig.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeConfig.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ThemeConfig.textPrimaryColor,
              ),
            ),
            Text(
              'Ask questions about your conversations',
              style: TextStyle(
                fontSize: 12,
                color: ThemeConfig.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          if (_chatMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: ThemeConfig.textSecondaryColor,
              onPressed: () {
                setState(() {
                  _chatMessages.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _chatMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: ThemeConfig.textSecondaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me anything about your',
                          style: TextStyle(
                            fontSize: 16,
                            color: ThemeConfig.textSecondaryColor,
                          ),
                        ),
                        Text(
                          'conversation history!',
                          style: TextStyle(
                            fontSize: 16,
                            color: ThemeConfig.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSuggestionChip('Summarize my conversations'),
                        const SizedBox(height: 8),
                        _buildSuggestionChip('What languages have I practiced?'),
                        const SizedBox(height: 8),
                        _buildSuggestionChip('Show common phrases I used'),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeConfig.surfaceColor,
              border: Border(
                top: BorderSide(color: ThemeConfig.borderColor, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your conversations...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeConfig.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeConfig.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ThemeConfig.borderColor, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: ThemeConfig.primaryAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ThemeConfig.primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: ThemeConfig.primaryAccent,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? ThemeConfig.primaryAccent
                    : message.isError
                        ? Colors.red.shade50
                        : ThemeConfig.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: message.isUser
                    ? null
                    : Border.all(color: ThemeConfig.borderColor, width: 1),
              ),
              child: message.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ThemeConfig.primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            fontSize: 15,
                            color: ThemeConfig.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: message.isUser
                            ? Colors.white
                            : message.isError
                                ? Colors.red.shade700
                                : ThemeConfig.textPrimaryColor,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ThemeConfig.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
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
  final bool isLoading;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
  });
}
