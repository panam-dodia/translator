import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../models/conversation_session.dart';
import '../utils/language_codes.dart';

class SessionDetailScreen extends StatelessWidget {
  final ConversationSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final lang1Info = LanguageCodes.getLanguageInfo(session.user1Language);
    final lang2Info = LanguageCodes.getLanguageInfo(session.user2Language);

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
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ThemeConfig.textPrimaryColor,
              ),
            ),
            Text(
              '${lang1Info?.name} → ${lang2Info?.name}',
              style: TextStyle(
                fontSize: 12,
                color: ThemeConfig.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
      body: session.messages.isEmpty
          ? const Center(
              child: Text('No messages in this conversation'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: session.messages.length,
              itemBuilder: (context, index) {
                final message = session.messages[index];
                final lang1 = lang1Info?.name ?? session.user1Language;
                final lang2 = lang2Info?.name ?? session.user2Language;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: ThemeConfig.borderColor, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original text
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeConfig.primaryAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                message.sourceLanguage.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeConfig.primaryAccent,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: ThemeConfig.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message.originalText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ThemeConfig.textPrimaryColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Divider
                        Divider(color: ThemeConfig.borderColor),
                        const SizedBox(height: 8),
                        // Translated text
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeConfig.textSecondaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                message.targetLanguage.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeConfig.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message.translatedText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: ThemeConfig.textSecondaryColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
