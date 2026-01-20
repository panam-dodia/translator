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
import 'history_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _user1Language; // Placeholder - null until selected
  String? _user2Language; // Placeholder - null until selected
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    // Don't load saved preferences - always start fresh with no selection
    // Users must select languages each time
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user1Language != null && _user2Language != null) {
      await prefs.setString(AppConstants.user1LanguageKey, _user1Language!);
      await prefs.setString(AppConstants.user2LanguageKey, _user2Language!);
    }
  }

  Future<void> _startConversation() async {
    if (_user1Language == null || _user2Language == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both languages'),
        ),
      );
      return;
    }

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
      final user1Info = LanguageCodes.getLanguageInfo(_user1Language!);
      final user2Info = LanguageCodes.getLanguageInfo(_user2Language!);

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
      backgroundColor: ThemeConfig.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Translator',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: ThemeConfig.textPrimaryColor,
                      letterSpacing: -1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.history,
                      color: ThemeConfig.primaryAccent,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Speak naturally, connect globally',
                style: TextStyle(
                  fontSize: 16,
                  color: ThemeConfig.textSecondaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 48),

              // Language Selection
              _buildLanguageCard(
                label: 'Person 1',
                selectedLanguage: _user1Language,
                onChanged: (value) {
                  if (value != null) setState(() => _user1Language = value);
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      final temp = _user1Language;
                      _user1Language = _user2Language;
                      _user2Language = temp;
                    });
                  },
                  child: const Text(
                    'Swap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.primaryAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageCard(
                label: 'Person 2',
                selectedLanguage: _user2Language,
                onChanged: (value) {
                  if (value != null) setState(() => _user2Language = value);
                },
              ),

              const Spacer(),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Start Conversation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String label,
    required String? selectedLanguage,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedLanguageName = selectedLanguage != null
        ? LanguageCodes.getLanguageInfo(selectedLanguage)?.name
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: ThemeConfig.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeConfig.borderColor,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguage,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.expand_more, color: ThemeConfig.textSecondaryColor, size: 24),
          hint: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: ThemeConfig.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select Language',
                style: const TextStyle(
                  color: ThemeConfig.textSecondaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          selectedItemBuilder: (BuildContext context) {
            return LanguageCodes.supportedLanguages.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ThemeConfig.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.value.name,
                    style: const TextStyle(
                      color: ThemeConfig.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          style: const TextStyle(
            color: ThemeConfig.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          items: LanguageCodes.supportedLanguages.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(
                entry.value.name,
                style: const TextStyle(
                  color: ThemeConfig.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
