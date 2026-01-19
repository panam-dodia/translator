import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
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
      appBar: AppBar(
        title: const Text('Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<ConversationProvider>().clearHistory();
            },
            tooltip: 'Clear conversation',
          ),
        ],
      ),
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
                  color: ThemeConfig.user1Color,
                  isRotated: false,
                ),
              ),

              // Divider
              Container(
                height: 2,
                color: Colors.grey[300],
              ),

              // User 2 Section (Bottom - Rotated)
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _buildUserSection(
                    userId: AppConstants.user2Id,
                    profile: user2Profile,
                    color: ThemeConfig.user2Color,
                    isRotated: true,
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
    required Color color,
    required bool isRotated,
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
          color: color.withOpacity(0.05),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'User ${userId == AppConstants.user1Id ? "1" : "2"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($languageName)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: ThemeConfig.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: allMessages.isEmpty
                    ? Center(
                        child: Text(
                          'Tap the microphone to start',
                          style: TextStyle(color: Colors.grey[600]),
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
                            color: color,
                          );
                        },
                      ),
              ),

              // Speech status
              if (isListening || isProcessing || isSpeaking)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: color.withOpacity(0.1),
                  child: Text(
                    isListening
                        ? 'Listening... ${speechProvider.partialText}'
                        : isProcessing
                            ? 'Translating...'
                            : 'Speaking...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Microphone button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  heroTag: 'mic_$userId',
                  onPressed: isListening
                      ? () => context.read<SpeechProvider>().stopListening()
                      : () => _handleSpeech(userId),
                  backgroundColor: isListening ? Colors.red : color,
                  child: Icon(
                    isListening ? Icons.stop : Icons.mic,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required dynamic message,
    required bool isOwnMessage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwnMessage ? color.withOpacity(0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show original text for own messages, translation for others
              Text(
                isOwnMessage ? message.originalText : message.translatedText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // Show translation in smaller text
              Text(
                isOwnMessage ? message.translatedText : message.originalText,
                style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConfig.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
