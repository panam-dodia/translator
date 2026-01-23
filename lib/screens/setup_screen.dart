import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme_config.dart';
import '../models/user_profile.dart';
import '../providers/conversation_provider.dart';
import '../providers/translation_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/language_codes.dart';
import 'conversation_screen.dart';
import 'history_screen.dart';

class SetupScreen extends StatefulWidget {
  final bool isInNavigation;

  const SetupScreen({super.key, this.isInNavigation = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _user1Language; // Placeholder - null until selected
  String? _user2Language; // Placeholder - null until selected
  bool _isLoading = false;
  String _downloadStatus = '';
  double _downloadProgress = 0.0;
  bool _showDownloadInfo = false;
  int _refreshKey = 0; // Add refresh key to force rebuild

  // Get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double mobileSize) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      // Tablet
      return mobileSize * 1.3;
    } else if (width > 400) {
      // Large phone
      return mobileSize * 1.1;
    } else {
      // Small phone
      return mobileSize;
    }
  }

  double _getResponsivePadding(BuildContext context, double basePadding) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return basePadding * 1.5;
    } else {
      return basePadding;
    }
  }

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

    // Get language info
    final user1Info = LanguageCodes.getLanguageInfo(_user1Language!);
    final user2Info = LanguageCodes.getLanguageInfo(_user2Language!);

    if (user1Info == null || user2Info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid language selection')),
      );
      return;
    }

    // Check if ONNX neural translation models are downloaded
    final translationProvider = context.read<TranslationProvider>();

    final onnxDownloaded = await translationProvider.areOnnxModelsDownloaded(
      user1Info.mlKitLanguage,
      user2Info.mlKitLanguage,
    );

    // Check if models are missing
    if (!onnxDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please download translation models first (click on the language cards)'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _downloadStatus = 'Setting up...';
      });

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
        setState(() {
          _isLoading = false;
          _downloadStatus = '';
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<bool> _showOnnxDownloadDialog() async {
    final theme = Theme.of(context);

    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Neural Translation Models',
          style: TextStyle(fontSize: _getResponsiveSize(context, 18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download high-quality neural translation models for better accuracy.',
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 14),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: theme.colorScheme.primary,
                  size: _getResponsiveSize(context, 20),
                ),
                SizedBox(width: _getResponsiveSize(context, 8)),
                Text(
                  'Size: ~150-300 MB',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 12)),
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.green[700],
                    size: _getResponsiveSize(context, 20),
                  ),
                  SizedBox(width: _getResponsiveSize(context, 8)),
                  Expanded(
                    child: Text(
                      'Much better translation quality - understands context & idioms!',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 13),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 12)),
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[700],
                    size: _getResponsiveSize(context, 20),
                  ),
                  SizedBox(width: _getResponsiveSize(context, 8)),
                  Expanded(
                    child: Text(
                      'Larger download - make sure you have WiFi!',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 13),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Download',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showDownloadWarning(int sizeMB) async {
    final theme = Theme.of(context);

    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Download Fallback Models',
          style: TextStyle(fontSize: _getResponsiveSize(context, 18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app works 100% offline after downloading language models.',
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 14),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: theme.colorScheme.primary,
                  size: _getResponsiveSize(context, 20),
                ),
                SizedBox(width: _getResponsiveSize(context, 8)),
                Text(
                  'Download size: ~$sizeMB MB',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 8)),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: _getResponsiveSize(context, 20),
                ),
                SizedBox(width: _getResponsiveSize(context, 8)),
                Expanded(
                  child: Text(
                    'One-time download. Use offline forever!',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 14),
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[700],
                    size: _getResponsiveSize(context, 20),
                  ),
                  SizedBox(width: _getResponsiveSize(context, 8)),
                  Expanded(
                    child: Text(
                      'You may use mobile data or WiFi',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 13),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Download',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsivePadding(context, 24.0),
                  vertical: _getResponsivePadding(context, 32.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    SizedBox(height: _getResponsiveSize(context, 20)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI Translator',
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, 32),
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        if (!widget.isInNavigation)
                          IconButton(
                            icon: Icon(
                              Icons.history,
                              color: theme.colorScheme.primary,
                              size: _getResponsiveSize(context, 28),
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
                    SizedBox(height: _getResponsiveSize(context, 8)),
                    Text(
                      'Speak naturally, connect globally',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 16),
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: _getResponsiveSize(context, 48)),

                    // Language Selection
                    _buildLanguageCard(
                      label: 'Person 1',
                      selectedLanguage: _user1Language,
                      onChanged: (value) {
                        if (value != null) setState(() => _user1Language = value);
                      },
                    ),
                    SizedBox(height: _getResponsiveSize(context, 24)),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            final temp = _user1Language;
                            _user1Language = _user2Language;
                            _user2Language = temp;
                          });
                        },
                        child: Text(
                          'Swap',
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSize(context, 24)),
                    _buildLanguageCard(
                      label: 'Person 2',
                      selectedLanguage: _user2Language,
                      onChanged: (value) {
                        if (value != null) setState(() => _user2Language = value);
                      },
                    ),

                    SizedBox(height: _getResponsiveSize(context, 32)),

                    // Download progress indicator
                    if (_isLoading && _downloadStatus.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFe2e8f0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _downloadStatus,
                              style: TextStyle(
                                fontSize: _getResponsiveSize(context, 14),
                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 12)),
                            LinearProgressIndicator(
                              value: _downloadProgress > 0 ? _downloadProgress : null,
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _getResponsiveSize(context, 16)),
                    ],
                  ],
                ),
              ),
            ),
            // Start Button (Fixed at bottom)
            Padding(
              padding: EdgeInsets.fromLTRB(
                _getResponsivePadding(context, 24),
                _getResponsiveSize(context, 8),
                _getResponsivePadding(context, 24),
                _getResponsiveSize(context, 16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: _getResponsiveSize(context, 56),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: _getResponsiveSize(context, 20),
                          height: _getResponsiveSize(context, 20),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Start Conversation',
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, 16),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
          ],
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

    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 24),
        vertical: _getResponsiveSize(context, 28),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFe2e8f0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLanguage,
              isExpanded: true,
              dropdownColor: theme.colorScheme.surface,
              menuMaxHeight: 300, // Limit dropdown height and make it scrollable
              icon: Icon(
                Icons.expand_more,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: _getResponsiveSize(context, 24),
              ),
              hint: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: _getResponsiveSize(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(context, 6)),
                  Text(
                    'Select Language',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: _getResponsiveSize(context, 18),
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
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: _getResponsiveSize(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: _getResponsiveSize(context, 6)),
                      Text(
                        entry.value.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: _getResponsiveSize(context, 18),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: _getResponsiveSize(context, 18),
                fontWeight: FontWeight.w600,
              ),
              items: LanguageCodes.supportedLanguages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value.name,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: _getResponsiveSize(context, 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
          if (selectedLanguage != null) ...[
            SizedBox(height: _getResponsiveSize(context, 12)),
            _buildModelStatusIndicator(selectedLanguage),
          ],
        ],
      ),
    );
  }

  Widget _buildModelStatusIndicator(String languageCode) {
    final langInfo = LanguageCodes.getLanguageInfo(languageCode);
    if (langInfo == null) return const SizedBox.shrink();

    // Determine if we need to check pair or individual language
    final otherLanguage = languageCode == _user1Language ? _user2Language : _user1Language;

    // If both languages selected, check the specific pair
    if (otherLanguage != null) {
      return FutureBuilder<bool>(
        key: ValueKey('model_status_${languageCode}_$_refreshKey'),
        future: _checkOnnxModels(_user1Language!, _user2Language!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: _getResponsiveSize(context, 16),
              width: _getResponsiveSize(context, 16),
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final onnxDownloaded = snapshot.data!;

          return Padding(
            padding: EdgeInsets.only(top: _getResponsiveSize(context, 6)),
            child: InkWell(
              onTap: !onnxDownloaded ? () => _downloadModelsForLanguage(languageCode) : null,
              borderRadius: BorderRadius.circular(_getResponsiveSize(context, 14)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSize(context, 10),
                  vertical: _getResponsiveSize(context, 6),
                ),
                decoration: BoxDecoration(
                  color: onnxDownloaded ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(_getResponsiveSize(context, 14)),
                  border: Border.all(
                    color: onnxDownloaded ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      onnxDownloaded ? Icons.check_circle : Icons.download,
                      size: _getResponsiveSize(context, 16),
                      color: onnxDownloaded ? Colors.green[700] : Colors.orange[700],
                    ),
                    SizedBox(width: _getResponsiveSize(context, 6)),
                    Text(
                      onnxDownloaded ? 'Ready' : 'Download',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: onnxDownloaded ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Only this language selected - check if ANY models exist for this language
    return FutureBuilder<bool>(
      key: ValueKey('model_status_single_${languageCode}_$_refreshKey'),
      future: _checkIfLanguageHasAnyModels(languageCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: _getResponsiveSize(context, 16),
            width: _getResponsiveSize(context, 16),
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final hasModels = snapshot.data!;

        return Padding(
          padding: EdgeInsets.only(top: _getResponsiveSize(context, 6)),
          child: InkWell(
            onTap: !hasModels ? () => _downloadModelsForSingleLanguage(languageCode) : null,
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 14)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(context, 10),
                vertical: _getResponsiveSize(context, 6),
              ),
              decoration: BoxDecoration(
                color: hasModels ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 14)),
                border: Border.all(
                  color: hasModels ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasModels ? Icons.check_circle : Icons.download,
                    size: _getResponsiveSize(context, 16),
                    color: hasModels ? Colors.green[700] : Colors.orange[700],
                  ),
                  SizedBox(width: _getResponsiveSize(context, 6)),
                  Text(
                    hasModels ? 'Ready' : 'Download',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 13),
                      fontWeight: FontWeight.w600,
                      color: hasModels ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkIfLanguageHasAnyModels(String languageCode) async {
    // Check if this language has models paired with any common language
    print('[SETUP] Checking if $languageCode has any models...');
    final langInfo = LanguageCodes.getLanguageInfo(languageCode);
    if (langInfo == null) {
      print('[SETUP] Language info not found for $languageCode');
      return false;
    }

    final provider = context.read<TranslationProvider>();

    // Check against common language pairs (en, hi, es, fr, de, etc.)
    final commonLanguages = ['en', 'hi', 'es', 'fr', 'de', 'zh', 'ja', 'ko', 'ar', 'ru'];

    for (var otherLang in commonLanguages) {
      if (otherLang == languageCode) continue;

      final otherInfo = LanguageCodes.getLanguageInfo(otherLang);
      if (otherInfo == null) continue;

      // Check if models exist for this pair in either direction
      print('[SETUP] Checking $languageCode paired with $otherLang...');
      final hasModels1 = await provider.areOnnxModelsDownloaded(
        langInfo.mlKitLanguage,
        otherInfo.mlKitLanguage,
      );

      if (hasModels1) {
        print('[SETUP] Found models for $languageCode-$otherLang pair!');
        return true;
      }
    }

    print('[SETUP] No models found for $languageCode with any common language');
    return false;
  }

  Future<bool> _checkOnnxModels(String lang1, String lang2) async {
    final info1 = LanguageCodes.getLanguageInfo(lang1);
    final info2 = LanguageCodes.getLanguageInfo(lang2);

    if (info1 == null || info2 == null) return false;

    final provider = context.read<TranslationProvider>();
    final result = await provider.areOnnxModelsDownloaded(
      info1.mlKitLanguage,
      info2.mlKitLanguage,
    );
    print('[SETUP] Checking models for $lang1-$lang2: $result');
    return result;
  }

  Future<void> _downloadModelsForSingleLanguage(String languageCode) async {
    final langInfo = LanguageCodes.getLanguageInfo(languageCode);
    if (langInfo == null) return;

    // Choose a common pairing language (English if not English, Hindi if English)
    final defaultPairLanguage = languageCode == 'en' ? 'hi' : 'en';
    final pairLangInfo = LanguageCodes.getLanguageInfo(defaultPairLanguage);
    if (pairLangInfo == null) return;

    // Show confirmation dialog
    final shouldDownload = await _showModelDownloadConfirmation(langInfo, pairLangInfo);
    if (!shouldDownload) return;

    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Downloading models...';
    });

    try {
      final provider = context.read<TranslationProvider>();

      // Download ONNX models for both directions
      print('[SETUP] Downloading models for ${langInfo.name} (paired with ${pairLangInfo.name})');
      setState(() => _downloadStatus = 'Downloading ${langInfo.name} ↔ ${pairLangInfo.name} models...');
      await provider.downloadOnnxModels(
        sourceLanguage: langInfo.mlKitLanguage,
        targetLanguage: pairLangInfo.mlKitLanguage,
      );
      print('[SETUP] Download completed for ${langInfo.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${langInfo.name} language model downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Wait a bit to ensure files are fully written
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _refreshKey++;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
      }
    }
  }

  Future<void> _downloadModelsForLanguage(String languageCode) async {
    final otherLanguage = languageCode == _user1Language ? _user2Language : _user1Language;

    if (otherLanguage == null) {
      // If other language not selected, use the single language download
      await _downloadModelsForSingleLanguage(languageCode);
      return;
    }

    final langInfo = LanguageCodes.getLanguageInfo(languageCode);
    final otherLangInfo = LanguageCodes.getLanguageInfo(otherLanguage);

    if (langInfo == null || otherLangInfo == null) return;

    // Show confirmation dialog
    final shouldDownload = await _showModelDownloadConfirmation(langInfo, otherLangInfo);
    if (!shouldDownload) return;

    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Downloading models...';
    });

    try {
      final provider = context.read<TranslationProvider>();

      // Download ONNX models only
      print('[SETUP] Downloading models for ${langInfo.name} ↔ ${otherLangInfo.name}');
      setState(() => _downloadStatus = 'Downloading neural translation models...');
      await provider.downloadOnnxModels(
        sourceLanguage: langInfo.mlKitLanguage,
        targetLanguage: otherLangInfo.mlKitLanguage,
      );
      print('[SETUP] Download completed for ${langInfo.name} ↔ ${otherLangInfo.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${langInfo.name} language model downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Wait a bit to ensure files are fully written
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _refreshKey++; // Increment to force FutureBuilder refresh
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
      }
    }
  }

  Future<bool> _showModelDownloadConfirmation(dynamic lang1, dynamic lang2) async {
    final theme = Theme.of(context);

    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Download Translation Models?',
          style: TextStyle(fontSize: _getResponsiveSize(context, 18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will download:',
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 12)),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple[700], size: 20),
                SizedBox(width: _getResponsiveSize(context, 8)),
                Text(
                  'Neural models (~150-300 MB)',
                  style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                  SizedBox(width: _getResponsiveSize(context, 8)),
                  Expanded(
                    child: Text(
                      'Works on WiFi or mobile data. One-time download!',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 12),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(fontSize: _getResponsiveSize(context, 14))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Download', style: TextStyle(fontSize: _getResponsiveSize(context, 14))),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _downloadSingleModel(dynamic langInfo) async {
    final theme = Theme.of(context);

    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Download ${langInfo.name}?',
          style: TextStyle(fontSize: _getResponsiveSize(context, 18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download this language model to use offline.',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
            SizedBox(height: _getResponsiveSize(context, 12)),
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: theme.colorScheme.primary,
                  size: _getResponsiveSize(context, 20),
                ),
                SizedBox(width: _getResponsiveSize(context, 8)),
                Text(
                  'Size: ~35 MB',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: _getResponsiveSize(context, 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 12)),
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 10)),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: _getResponsiveSize(context, 18),
                  ),
                  SizedBox(width: _getResponsiveSize(context, 8)),
                  Expanded(
                    child: Text(
                      'WiFi or mobile data will be used',
                      style: TextStyle(fontSize: _getResponsiveSize(context, 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Download',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
        ],
      ),
    );

    if (shouldDownload != true) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: _getResponsiveSize(context, 16)),
            Text(
              'Downloading ${langInfo.name}...',
              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
            ),
          ],
        ),
      ),
    );

    try {
      final translationProvider = context.read<TranslationProvider>();
      await translationProvider.downloadModel(langInfo.mlKitLanguage);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${langInfo.name} language model downloaded'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {}); // Refresh to update badge
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
