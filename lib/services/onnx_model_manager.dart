import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Manages downloading and caching of OPUS-MT ONNX models
class OnnxModelManager {
  static final OnnxModelManager _instance = OnnxModelManager._internal();
  factory OnnxModelManager() => _instance;
  OnnxModelManager._internal();

  // HuggingFace model URLs (quantized int8 models for mobile)
  static const Map<String, String> _modelUrls = {
    // English to Hindi
    'en-hi-encoder': 'https://huggingface.co/Helsinki-NLP/opus-mt-en-hi/resolve/main/encoder_model.onnx',
    'en-hi-decoder': 'https://huggingface.co/Helsinki-NLP/opus-mt-en-hi/resolve/main/decoder_model.onnx',
    'en-hi-vocab': 'https://huggingface.co/Helsinki-NLP/opus-mt-en-hi/resolve/main/vocab.json',
    'en-hi-tokenizer': 'https://huggingface.co/Helsinki-NLP/opus-mt-en-hi/resolve/main/tokenizer.json',

    // Hindi to English
    'hi-en-encoder': 'https://huggingface.co/Helsinki-NLP/opus-mt-hi-en/resolve/main/encoder_model.onnx',
    'hi-en-decoder': 'https://huggingface.co/Helsinki-NLP/opus-mt-hi-en/resolve/main/decoder_model.onnx',
    'hi-en-vocab': 'https://huggingface.co/Helsinki-NLP/opus-mt-hi-en/resolve/main/vocab.json',
    'hi-en-tokenizer': 'https://huggingface.co/Helsinki-NLP/opus-mt-hi-en/resolve/main/tokenizer.json',
  };

  Directory? _modelDir;
  final Map<String, double> _downloadProgress = {};

  /// Initialize model directory
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _modelDir = Directory('${appDir.path}/opus_mt_models');
    if (!await _modelDir!.exists()) {
      await _modelDir!.create(recursive: true);
    }
  }

  /// Get local path for a model file
  String getModelPath(String modelKey) {
    if (_modelDir == null) {
      throw Exception('Model manager not initialized');
    }
    return '${_modelDir!.path}/$modelKey.model';
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelKey) async {
    if (_modelDir == null) await initialize();
    final file = File(getModelPath(modelKey));
    final exists = await file.exists();
    print('[MODEL_MGR] Checking $modelKey: exists=$exists, path=${file.path}');
    return exists;
  }

  /// Get download progress for a model (0.0 to 1.0)
  double getDownloadProgress(String modelKey) {
    return _downloadProgress[modelKey] ?? 0.0;
  }

  /// Download a model file with progress tracking
  Future<bool> downloadModel(String modelKey, {Function(double)? onProgress}) async {
    if (_modelDir == null) await initialize();

    final url = _modelUrls[modelKey];
    if (url == null) {
      print('[MODEL_MGR] ERROR: Unknown model key: $modelKey');
      print('[MODEL_MGR] Available keys: ${_modelUrls.keys.toList()}');
      throw Exception('Unknown model key: $modelKey');
    }

    print('[MODEL_MGR] Starting download for $modelKey from $url');

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode != 200) {
        print('[MODEL_MGR] Download failed with status: ${response.statusCode}');
        throw Exception('Failed to download model: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      print('[MODEL_MGR] Download size for $modelKey: ${totalBytes / 1024 / 1024} MB');
      int receivedBytes = 0;
      final chunks = <int>[];

      await for (var chunk in response.stream) {
        chunks.addAll(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          final progress = receivedBytes / totalBytes;
          _downloadProgress[modelKey] = progress;
          onProgress?.call(progress);
        }
      }

      // Save to file
      final file = File(getModelPath(modelKey));
      print('[MODEL_MGR] Saving to: ${file.path}');
      await file.writeAsBytes(chunks);
      _downloadProgress[modelKey] = 1.0;

      final fileExists = await file.exists();
      final fileSize = await file.length();
      print('[MODEL_MGR] Download complete for $modelKey: exists=$fileExists, size=${fileSize / 1024 / 1024} MB');

      return true;
    } catch (e) {
      print('[MODEL_MGR] Download error for $modelKey: $e');
      _downloadProgress.remove(modelKey);
      throw Exception('Failed to download $modelKey: $e');
    }
  }

  /// Download all required models for a language pair
  Future<void> downloadLanguagePair(String sourceLang, String targetLang, {Function(String, double)? onProgress}) async {
    final pair = '$sourceLang-$targetLang';
    final requiredModels = [
      '$pair-encoder',
      '$pair-decoder',
      '$pair-vocab',
      '$pair-tokenizer',
    ];

    // Download in parallel for faster initial setup
    await Future.wait(
      requiredModels.map((key) => downloadModel(key, onProgress: (progress) {
        onProgress?.call(key, progress);
      })),
    );
  }

  /// Check if all models for a language pair are downloaded
  Future<bool> isLanguagePairDownloaded(String sourceLang, String targetLang) async {
    final pair = '$sourceLang-$targetLang';
    final requiredModels = [
      '$pair-encoder',
      '$pair-decoder',
      '$pair-vocab',
      '$pair-tokenizer',
    ];

    print('[MODEL_MGR] Checking language pair: $pair');
    int downloadedCount = 0;

    for (var key in requiredModels) {
      if (await isModelDownloaded(key)) {
        downloadedCount++;
      }
    }

    final allDownloaded = downloadedCount == requiredModels.length;
    print('[MODEL_MGR] Language pair $pair: $downloadedCount/${requiredModels.length} models downloaded. Result: $allDownloaded');
    return allDownloaded;
  }

  /// Delete a model file
  Future<bool> deleteModel(String modelKey) async {
    try {
      final file = File(getModelPath(modelKey));
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get total size of downloaded models in bytes
  Future<int> getModelsCacheSize() async {
    if (_modelDir == null) await initialize();

    int totalSize = 0;
    await for (var entity in _modelDir!.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  /// Clear all downloaded models
  Future<void> clearAllModels() async {
    if (_modelDir == null) await initialize();

    if (await _modelDir!.exists()) {
      await _modelDir!.delete(recursive: true);
      await _modelDir!.create(recursive: true);
    }
  }
}
