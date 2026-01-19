# Real-Time Bidirectional Translator

A Flutter-based mobile application that enables seamless conversations between users speaking different languages on the same device.

## Features

- **Real-time Translation**: Speech-to-text → Translation → Text-to-speech pipeline
- **Split-Screen Interface**: Optimized for two users on the same device
- **Offline Translation**: Uses Google ML Kit for on-device translation (no internet required for translation)
- **12+ Languages**: Supports major languages including English, Spanish, French, German, Chinese, Japanese, and more
- **AI Assistant**: Integrated with Anthropic Claude API for contextual learning during conversations
- **Cross-Platform**: Works on both Android and iOS

## Technology Stack

- **Framework**: Flutter 3.6+
- **Speech Recognition**: speech_to_text package
- **Translation**: Google ML Kit Translation (on-device)
- **Text-to-Speech**: flutter_tts
- **AI Assistant**: Anthropic Claude API
- **State Management**: Provider pattern

## Getting Started

### Prerequisites

- Flutter SDK (3.6.0 or higher)
- Android Studio / Xcode
- Anthropic Claude API key ([Get one here](https://console.anthropic.com/))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/panam-dodia/translator.git
   cd translator
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Claude API key**

   Create a `.env` file in the root directory:
   ```
   CLAUDE_API_KEY=your_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## How It Works

1. **Language Selection**: On launch, select languages for User 1 and User 2
2. **Model Download**: Translation models are downloaded on first use (30-50MB per language)
3. **Conversation**:
   - Each user speaks into their microphone
   - Speech is recognized and translated in real-time
   - Translated text is spoken to the other user
   - Conversation history is displayed with both original and translated text

## Supported Languages

- English
- Spanish
- French
- German
- Italian
- Portuguese
- Chinese
- Japanese
- Korean
- Arabic
- Russian
- Hindi

## Architecture

```
lib/
├── config/          # App configuration and themes
├── models/          # Data models
├── providers/       # State management (Provider pattern)
├── services/        # Business logic (Speech, Translation, TTS, Claude API)
├── screens/         # UI screens
├── widgets/         # Reusable UI components
└── utils/           # Utilities and constants
```

## Permissions

### Android
- `INTERNET` - For Claude API calls
- `RECORD_AUDIO` - For speech recognition

### iOS
- `NSMicrophoneUsageDescription` - Microphone access for speech-to-text
- `NSSpeechRecognitionUsageDescription` - Speech recognition permission

## Roadmap

- [ ] Claude AI Assistant integration (UI)
- [ ] Voice selection for TTS
- [ ] Conversation export/save
- [ ] Multi-device support (Bluetooth/WiFi)
- [ ] Additional language pairs
- [ ] Offline mode improvements

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Acknowledgments

- Google ML Kit for offline translation
- Anthropic for Claude API
- Flutter community for amazing packages

---

Built with ❤️ using Flutter
