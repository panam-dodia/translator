import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme_config.dart';
import 'providers/conversation_provider.dart';
import 'providers/history_provider.dart';
import 'providers/speech_provider.dart';
import 'providers/translation_provider.dart';
import 'providers/tts_provider.dart';
import 'providers/claude_provider.dart';
import 'screens/setup_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration (load .env file)
  try {
    await AppConfig.initialize();
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => SpeechProvider()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => TtsProvider()),
        ChangeNotifierProvider(create: (_) => ClaudeProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeConfig.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SetupScreen(),
      ),
    );
  }
}
