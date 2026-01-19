import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme_config.dart';
import '../models/user_profile.dart';
import '../providers/conversation_provider.dart';
import '../providers/translation_provider.dart';
import '../utils/constants.dart';
import '../utils/language_codes.dart';
import 'conversation_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String _user1Language = 'en'; // English
  String _user2Language = 'es'; // Spanish
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _user1Language = prefs.getString(AppConstants.user1LanguageKey) ?? 'en';
      _user2Language = prefs.getString(AppConstants.user2LanguageKey) ?? 'es';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.user1LanguageKey, _user1Language);
    await prefs.setString(AppConstants.user2LanguageKey, _user2Language);
  }

  Future<void> _startConversation() async {
    if (_user1Language == _user2Language) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select different languages for each user'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get language info
      final user1Info = LanguageCodes.getLanguageInfo(_user1Language);
      final user2Info = LanguageCodes.getLanguageInfo(_user2Language);

      if (user1Info == null || user2Info == null) {
        throw Exception('Invalid language selection');
      }

      // Check and download translation models
      final translationProvider = context.read<TranslationProvider>();

      // Download models if needed
      await translationProvider.downloadModel(user1Info.mlKitLanguage);
      await translationProvider.downloadModel(user2Info.mlKitLanguage);

      // Create user profiles
      final user1Profile = UserProfile(
        userId: AppConstants.user1Id,
        languageCode: user1Info.code,
      );

      final user2Profile = UserProfile(
        userId: AppConstants.user2Id,
        languageCode: user2Info.code,
      );

      // Save profiles to conversation provider
      context.read<ConversationProvider>().setUserProfiles(
            user1Profile,
            user2Profile,
          );

      // Save preferences
      await _savePreferences();

      // Navigate to conversation screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ConversationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Translator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.translate,
              size: 80,
              color: ThemeConfig.user1Color,
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Languages',
              style: ThemeConfig.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // User 1 Language Selection
            _buildUserLanguageCard(
              userNumber: 1,
              color: ThemeConfig.user1Color,
              selectedLanguage: _user1Language,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _user1Language = value);
                }
              },
            ),

            const SizedBox(height: 24),

            // Swap languages button
            Center(
              child: IconButton(
                onPressed: () {
                  setState(() {
                    final temp = _user1Language;
                    _user1Language = _user2Language;
                    _user2Language = temp;
                  });
                },
                icon: const Icon(Icons.swap_vert),
                iconSize: 32,
                tooltip: 'Swap languages',
              ),
            ),

            const SizedBox(height: 24),

            // User 2 Language Selection
            _buildUserLanguageCard(
              userNumber: 2,
              color: ThemeConfig.user2Color,
              selectedLanguage: _user2Language,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _user2Language = value);
                }
              },
            ),

            const SizedBox(height: 48),

            // Start button
            ElevatedButton(
              onPressed: _isLoading ? null : _startConversation,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Conversation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLanguageCard({
    required int userNumber,
    required Color color,
    required String selectedLanguage,
    required ValueChanged<String?> onChanged,
  }) {
    final languageInfo = LanguageCodes.getLanguageInfo(selectedLanguage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$userNumber',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'User $userNumber',
                  style: ThemeConfig.subheadingStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: LanguageCodes.supportedLanguages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.name),
                );
              }).toList(),
              onChanged: onChanged,
            ),
            if (languageInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Code: ${languageInfo.code}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConfig.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
