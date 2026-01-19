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
        Navigator.of(context).push(
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'AI Translator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Speak naturally, connect globally',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Language Cards
                _buildLanguageCard(
                  label: 'Person 1 speaks',
                  selectedLanguage: _user1Language,
                  onChanged: (value) {
                    if (value != null) setState(() => _user1Language = value);
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        final temp = _user1Language;
                        _user1Language = _user2Language;
                        _user2Language = temp;
                      });
                    },
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLanguageCard(
                  label: 'Person 2 speaks',
                  selectedLanguage: _user2Language,
                  onChanged: (value) {
                    if (value != null) setState(() => _user2Language = value);
                  },
                ),

                const Spacer(),

                // Start Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFf5576c).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _startConversation,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.white, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Start Conversation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String label,
    required String selectedLanguage,
    required ValueChanged<String?> onChanged,
  }) {
    final languageInfo = LanguageCodes.getLanguageInfo(selectedLanguage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLanguage,
              isExpanded: true,
              dropdownColor: const Color(0xFF764ba2),
              icon: const Icon(Icons.expand_more, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              items: LanguageCodes.supportedLanguages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
