import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../providers/claude_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/speech_provider.dart';
import '../providers/translation_provider.dart';
import '../providers/tts_provider.dart';
import '../utils/constants.dart';
import '../utils/language_codes.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final speechProvider = context.read<SpeechProvider>();
    await speechProvider.initialize();
  }

  Future<void> _handleSpeech(String userId) async {
    final conversationProvider = context.read<ConversationProvider>();
    final speechProvider = context.read<SpeechProvider>();
    final translationProvider = context.read<TranslationProvider>();
    final ttsProvider = context.read<TtsProvider>();

    final userProfile = conversationProvider.getProfileForUser(userId);
    if (userProfile == null) return;

    final otherUserId = conversationProvider.getOtherUserId(userId);
    final otherProfile = conversationProvider.getProfileForUser(otherUserId);
    if (otherProfile == null) return;

    // Set active user
    conversationProvider.setActiveUser(userId);

    // Get language info
    final userLangCode = userProfile.languageCode.split('-')[0];
    final otherLangCode = otherProfile.languageCode.split('-')[0];

    final userLangInfo = LanguageCodes.getLanguageInfo(userLangCode);
    final otherLangInfo = LanguageCodes.getLanguageInfo(otherLangCode);

    if (userLangInfo == null || otherLangInfo == null) return;

    try {
      // Set language for speech recognition
      speechProvider.setLanguage(userProfile.languageCode);

      // Start listening
      await speechProvider.startListening(
        onFinalResult: (text) async {
          if (text.isEmpty) return;

          conversationProvider.setProcessing(true);

          try {
            // Translate the text
            final translatedText = await translationProvider.translate(
              text: text,
              sourceLanguage: userLangInfo.mlKitLanguage,
              targetLanguage: otherLangInfo.mlKitLanguage,
            );

            // Add message to conversation
            conversationProvider.createMessage(
              originalText: text,
              translatedText: translatedText,
              userId: userId,
              sourceLanguage: userLangCode,
              targetLanguage: otherLangCode,
            );

            // Speak the translation to the other user
            await ttsProvider.speak(
              translatedText,
              languageCode: otherProfile.languageCode,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Translation error: $e')),
              );
            }
          } finally {
            conversationProvider.setProcessing(false);
            speechProvider.reset();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ConversationProvider>(
        builder: (context, conversationProvider, _) {
          final user1Profile = conversationProvider.user1Profile;
          final user2Profile = conversationProvider.user2Profile;

          if (user1Profile == null || user2Profile == null) {
            return const Center(child: Text('Error: User profiles not set'));
          }

          return Column(
            children: [
              // User 1 Section (Top)
              Expanded(
                child: _buildUserSection(
                  userId: AppConstants.user1Id,
                  profile: user1Profile,
                  isRotated: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
              ),

              // Center Divider
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFFf093fb)],
                  ),
                ),
              ),

              // User 2 Section (Bottom - Rotated)
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _buildUserSection(
                    userId: AppConstants.user2Id,
                    profile: user2Profile,
                    isRotated: true,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserSection({
    required String userId,
    required dynamic profile,
    required bool isRotated,
    required Gradient gradient,
  }) {
    return Consumer3<ConversationProvider, SpeechProvider, TtsProvider>(
      builder: (context, conversationProvider, speechProvider, ttsProvider, _) {
        final isActive = conversationProvider.activeUserId == userId;
        final isListening = speechProvider.isListening && isActive;
        final isSpeaking = ttsProvider.isSpeaking;
        final isProcessing = conversationProvider.isProcessing && isActive;

        // Get language name
        final langCode = profile.languageCode.split('-')[0];
        final langInfo = LanguageCodes.getLanguageInfo(langCode);
        final languageName = langInfo?.name ?? 'Unknown';

        // Get messages for this user
        final allMessages = conversationProvider.messages;

        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            bottom: !isRotated,
            top: isRotated,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      if (!isRotated)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            languageName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      if (!isRotated)
                        PopupMenuButton(
                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('AI Insights'),
                                ],
                              ),
                              onTap: () => Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _showAIInsights(context),
                              ),
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('Clear History'),
                                ],
                              ),
                              onTap: () => context.read<ConversationProvider>().clearHistory(),
                            ),
                          ],
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: allMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_none_rounded,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to speak',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: allMessages.length,
                          itemBuilder: (context, index) {
                            final reversedIndex = allMessages.length - 1 - index;
                            final message = allMessages[reversedIndex];
                            final isOwnMessage = message.userId == userId;

                            return _buildMessageBubble(
                              message: message,
                              isOwnMessage: isOwnMessage,
                            );
                          },
                        ),
                ),

                // Speech status
                if (isListening || isProcessing || isSpeaking)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isListening
                              ? 'Listening...'
                              : isProcessing
                                  ? 'Translating...'
                                  : 'Speaking...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Microphone button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 16),
                  child: GestureDetector(
                    onTap: isListening
                        ? () => context.read<SpeechProvider>().stopListening()
                        : () => _handleSpeech(userId),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? Colors.red : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening ? Colors.red : Colors.white)
                                .withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: isListening ? Colors.white : const Color(0xFF667eea),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required dynamic message,
    required bool isOwnMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isOwnMessage ? 0.25 : 0.9),
            borderRadius: BorderRadius.circular(20),
            border: isOwnMessage
                ? Border.all(color: Colors.white.withOpacity(0.3))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isOwnMessage ? 0.1 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main message text
              Text(
                isOwnMessage ? message.originalText : message.translatedText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isOwnMessage ? Colors.white : const Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Translation text with icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: 14,
                    color: isOwnMessage
                        ? Colors.white.withOpacity(0.6)
                        : const Color(0xFF94a3b8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isOwnMessage ? message.translatedText : message.originalText,
                      style: TextStyle(
                        fontSize: 14,
                        color: isOwnMessage
                            ? Colors.white.withOpacity(0.85)
                            : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  // AI Feature: Show conversation insights
  void _showAIInsights(BuildContext context) async {
    final conversationProvider = context.read<ConversationProvider>();
    final claudeProvider = context.read<ClaudeProvider>();
    final messages = conversationProvider.messages;

    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conversation yet')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Conversation Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: FutureBuilder<String>(
          future: claudeProvider.getConversationInsights(messages: messages),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing...'),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 14));
            } else {
              return SingleChildScrollView(
                child: Text(
                  snapshot.data ?? 'No insights available',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
