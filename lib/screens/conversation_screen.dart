import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../providers/claude_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/history_provider.dart';
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

  // Auto-save conversation when leaving screen
  Future<void> _autoSaveConversation() async {
    try {
      final conversationProvider = context.read<ConversationProvider>();
      final historyProvider = context.read<HistoryProvider>();

      final messages = conversationProvider.messages;

      // Only save if there are messages
      if (messages.isEmpty) return;

      final user1Profile = conversationProvider.user1Profile;
      final user2Profile = conversationProvider.user2Profile;

      if (user1Profile == null || user2Profile == null) return;

      await historyProvider.saveCurrentConversation(
        messages: messages,
        user1Language: user1Profile.languageCode.split('-')[0],
        user2Language: user2Profile.languageCode.split('-')[0],
      );
    } catch (e) {
      // Silently fail - don't show error on dispose
      print('Auto-save error: $e');
    }
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _autoSaveConversation();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
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
                  backgroundColor: ThemeConfig.user1Background,
                ),
              ),

              // Center Divider
              Container(
                height: 1,
                color: ThemeConfig.borderColor,
              ),

              // User 2 Section (Bottom - Rotated)
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _buildUserSection(
                    userId: AppConstants.user2Id,
                    profile: user2Profile,
                    isRotated: true,
                    backgroundColor: ThemeConfig.user2Background,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildUserSection({
    required String userId,
    required dynamic profile,
    required bool isRotated,
    required Color backgroundColor,
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
          color: backgroundColor,
          child: SafeArea(
            bottom: !isRotated,
            top: isRotated,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    children: [
                      if (!isRotated)
                        GestureDetector(
                          onTap: () async {
                            await _autoSaveConversation();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      Text(
                        languageName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      if (!isRotated)
                        PopupMenuButton(
                          icon: const Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'insights',
                              child: Text('AI Insights'),
                            ),
                            const PopupMenuItem(
                              value: 'clear',
                              child: Text('Clear History'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'insights') {
                              _showAIInsights(context);
                            } else if (value == 'clear') {
                              context.read<ConversationProvider>().clearHistory();
                            }
                          },
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: allMessages.isEmpty
                      ? Center(
                          child: Text(
                            'Tap to speak',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isListening
                          ? 'Listening...'
                          : isProcessing
                              ? 'Translating...'
                              : 'Speaking...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Microphone button
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 20),
                  child: GestureDetector(
                    onTap: isListening
                        ? () => context.read<SpeechProvider>().stopListening()
                        : () => _handleSpeech(userId),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? ThemeConfig.primaryAccent : Colors.white,
                      ),
                      child: Icon(
                        isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: isListening ? Colors.white : ThemeConfig.primaryDark,
                        size: 28,
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isOwnMessage
                ? Colors.white.withOpacity(0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isOwnMessage
                ? Border.all(color: Colors.white.withOpacity(0.2), width: 1)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main message text
              Text(
                isOwnMessage ? message.originalText : message.translatedText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isOwnMessage ? Colors.white : ThemeConfig.textPrimaryColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              // Translation text
              Text(
                isOwnMessage ? message.translatedText : message.originalText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isOwnMessage
                      ? Colors.white.withOpacity(0.7)
                      : ThemeConfig.textSecondaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Save current conversation to history
  void _saveConversation(BuildContext context) async {
    final conversationProvider = context.read<ConversationProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final messages = conversationProvider.messages;

    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conversation to save')),
      );
      return;
    }

    final user1Profile = conversationProvider.user1Profile;
    final user2Profile = conversationProvider.user2Profile;

    if (user1Profile == null || user2Profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User profiles not available')),
      );
      return;
    }

    try {
      await historyProvider.saveCurrentConversation(
        messages: messages,
        user1Language: user1Profile.languageCode.split('-')[0],
        user2Language: user2Profile.languageCode.split('-')[0],
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation saved to history!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving conversation: $e')),
        );
      }
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: const Text(
          'AI Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ThemeConfig.textPrimaryColor,
          ),
        ),
        content: FutureBuilder<String>(
          future: claudeProvider.getConversationInsights(messages: messages),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ThemeConfig.primaryAccent,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing...',
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeConfig.textSecondaryColor,
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              );
            } else {
              return SingleChildScrollView(
                child: Text(
                  snapshot.data ?? 'No insights available',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: ThemeConfig.textPrimaryColor,
                  ),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ThemeConfig.primaryAccent,
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
