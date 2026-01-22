import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../config/theme_config.dart';
import '../providers/translation_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/language_codes.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;

  const SettingsScreen({super.key, this.onNavigateToHome});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double mobileSize) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return mobileSize * 1.3;
    } else if (width > 400) {
      return mobileSize * 1.1;
    } else {
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
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsivePadding(context, 24.0),
            vertical: _getResponsivePadding(context, 32.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onNavigateToHome != null) {
                        widget.onNavigateToHome!();
                      }
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.onSurface,
                      size: _getResponsiveSize(context, 24),
                    ),
                  ),
                  SizedBox(width: _getResponsiveSize(context, 16)),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 32),
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getResponsiveSize(context, 8)),
              Text(
                'Manage your preferences',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 16),
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: _getResponsiveSize(context, 32)),

              // Theme Section
              _buildSectionHeader(context, 'Appearance'),
              SizedBox(height: _getResponsiveSize(context, 12)),
              _buildThemeSelector(context, themeProvider),

              SizedBox(height: _getResponsiveSize(context, 32)),

              // Model Management Section
              _buildSectionHeader(context, 'Offline Models'),
              SizedBox(height: _getResponsiveSize(context, 12)),
              _buildModelManagement(context),

              SizedBox(height: _getResponsiveSize(context, 32)),

              // Language Preferences Section
              _buildSectionHeader(context, 'Language Preferences'),
              SizedBox(height: _getResponsiveSize(context, 12)),
              _buildLanguagePreferences(context),

              SizedBox(height: _getResponsiveSize(context, 32)),

              // About Section
              _buildSectionHeader(context, 'About'),
              SizedBox(height: _getResponsiveSize(context, 12)),
              _buildAboutSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: _getResponsiveSize(context, 18),
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFe2e8f0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
                size: _getResponsiveSize(context, 24),
              ),
              SizedBox(width: _getResponsiveSize(context, 12)),
              Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 16),
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildModelManagement(BuildContext context) {
    final translationProvider = context.watch<TranslationProvider>();
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download_outlined,
                color: theme.colorScheme.primary,
                size: _getResponsiveSize(context, 24),
              ),
              SizedBox(width: _getResponsiveSize(context, 12)),
              Text(
                'Manage Language Models',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 16)),
          Text(
            'Download or delete language models to save storage space.',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: _getResponsiveSize(context, 18),
                ),
                SizedBox(width: _getResponsiveSize(context, 8)),
                Expanded(
                  child: Text(
                    'Offline models work best for simple phrases. Complex sentences may not translate perfectly.',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 12),
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 16)),

          // List of languages
          ...LanguageCodes.supportedLanguages.entries.map((entry) {
            return _buildLanguageModelItem(context, entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLanguageModelItem(BuildContext context, String langCode, dynamic langInfo) {
    final translationProvider = context.watch<TranslationProvider>();
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return FutureBuilder<bool>(
      future: translationProvider.isModelDownloaded(langInfo.mlKitLanguage),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final isDownloaded = snapshot.data!;

        return Container(
          margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 8)),
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(context, 12),
            vertical: _getResponsiveSize(context, 12),
          ),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
            border: Border.all(
              color: isDownloaded ? Colors.green[200]! : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isDownloaded ? Icons.check_circle : Icons.download_outlined,
                color: isDownloaded ? Colors.green[700] : Colors.grey[600],
                size: _getResponsiveSize(context, 20),
              ),
              SizedBox(width: _getResponsiveSize(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langInfo.name,
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isDownloaded ? 'Downloaded (~35 MB)' : 'Not downloaded',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 12),
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDownloaded)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[700],
                    size: _getResponsiveSize(context, 20),
                  ),
                  onPressed: () => _deleteModel(context, langInfo),
                )
              else
                TextButton(
                  onPressed: () => _downloadModel(context, langInfo),
                  child: Text(
                    'Download',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 12),
                      color: ThemeConfig.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadModel(BuildContext context, dynamic langInfo) async {
    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Download ${langInfo.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Download this language model to use offline.'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.download, color: ThemeConfig.primaryAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Size: ~35 MB',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (shouldDownload != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Downloading ${langInfo.name}...'),
          ],
        ),
      ),
    );

    try {
      final translationProvider = context.read<TranslationProvider>();
      await translationProvider.downloadModel(langInfo.mlKitLanguage);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${langInfo.name} language model downloaded'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteModel(BuildContext context, dynamic langInfo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${langInfo.name}?'),
        content: const Text(
          'This will free up ~35 MB of storage. You can download it again anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final translationProvider = context.read<TranslationProvider>();
      await translationProvider.deleteModel(langInfo.mlKitLanguage);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${langInfo.name} model deleted'),
          backgroundColor: Colors.orange,
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLanguagePreferences(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: theme.colorScheme.primary,
                size: _getResponsiveSize(context, 24),
              ),
              SizedBox(width: _getResponsiveSize(context, 12)),
              Text(
                'Default Languages',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 16)),
          Text(
            'Set default languages for quick conversations.',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 16)),
          Text(
            'Coming soon: Save favorite language pairs and recent combinations.',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 13),
              color: Colors.blue[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: _getResponsiveSize(context, 24),
              ),
              SizedBox(width: _getResponsiveSize(context, 12)),
              Text(
                'AI Translator',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 12)),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          Text(
            'Speak naturally, connect globally',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
