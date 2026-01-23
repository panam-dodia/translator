import 'dart:io';
import 'dart:typed_data';
import 'package:onnxruntime/onnxruntime.dart';
import 'tokenizer_service.dart';
import 'onnx_model_manager.dart';

/// OPUS-MT translation service using ONNX Runtime Flutter
class OnnxTranslationService {
  final OnnxModelManager _modelManager = OnnxModelManager();
  final Map<String, TokenizerService> _tokenizers = {};
  final Map<String, OrtSession?> _encoderSessions = {};
  final Map<String, OrtSession?> _decoderSessions = {};
  final Map<String, String> _translationCache = {};

  bool _isInitialized = false;

  /// Initialize ONNX Runtime
  Future<void> initialize() async {
    try {
      await _modelManager.initialize();
      // Initialize ONNX Runtime Flutter (synchronous)
      OrtEnv.instance.init();
      _isInitialized = true;
      print('[ONNX] Initialized successfully');
    } catch (e) {
      print('[ONNX] Initialization error: $e');
      throw Exception('Failed to initialize ONNX translation service: $e');
    }
  }

  /// Load models for a specific language pair
  Future<void> loadLanguagePair(String sourceLang, String targetLang) async {
    if (!_isInitialized) await initialize();

    final pair = '$sourceLang-$targetLang';

    // Check if already loaded
    if (_encoderSessions.containsKey(pair) && _encoderSessions[pair] != null) {
      return;
    }

    // Check if models are downloaded
    final isDownloaded = await _modelManager.isLanguagePairDownloaded(sourceLang, targetLang);
    if (!isDownloaded) {
      throw Exception('Models for $pair not downloaded. Please download first.');
    }

    try {
      print('[ONNX] Loading models for $pair...');

      // Load tokenizer
      final vocabPath = _modelManager.getModelPath('$pair-vocab');
      final tokenizerPath = _modelManager.getModelPath('$pair-tokenizer');
      final tokenizer = TokenizerService();
      await tokenizer.initialize(vocabPath, tokenizerPath);
      _tokenizers[pair] = tokenizer;
      print('[ONNX] Tokenizer loaded: vocab size=${tokenizer.vocabSize}');

      // Load ONNX models with session options
      final encoderPath = _modelManager.getModelPath('$pair-encoder');
      final decoderPath = _modelManager.getModelPath('$pair-decoder');

      print('[ONNX] Creating encoder session from: $encoderPath');
      final sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(2)
        ..setIntraOpNumThreads(2)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

      // Convert String paths to File objects
      final encoderFile = File(encoderPath);
      final decoderFile = File(decoderPath);

      _encoderSessions[pair] = await OrtSession.fromFile(encoderFile, sessionOptions);
      print('[ONNX] Encoder session created');

      _decoderSessions[pair] = await OrtSession.fromFile(decoderFile, sessionOptions);
      print('[ONNX] Decoder session created');
      print('[ONNX] Models loaded successfully for $pair');
    } catch (e) {
      print('[ONNX] Failed to load models for $pair: $e');
      throw Exception('Failed to load models for $pair: $e');
    }
  }

  /// Translate text using OPUS-MT model
  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (!_isInitialized) await initialize();

    final pair = '$sourceLang-$targetLang';

    // Check cache
    final cacheKey = '${pair}_$text';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // Ensure models are loaded
    await loadLanguagePair(sourceLang, targetLang);

    final tokenizer = _tokenizers[pair];
    final encoderSession = _encoderSessions[pair];
    final decoderSession = _decoderSessions[pair];

    if (tokenizer == null || encoderSession == null || decoderSession == null) {
      throw Exception('Models not properly loaded for $pair');
    }

    try {
      print('[ONNX] Starting translation: "$text"');

      // Tokenize input
      final inputIds = tokenizer.encode(text);
      print('[ONNX] Input tokens: $inputIds (length: ${inputIds.length})');

      // Create attention mask (1 for real tokens, 0 for padding)
      final attentionMask = List<int>.filled(inputIds.length, 1);

      // Prepare input tensors for encoder
      // Convert to Int64 for ONNX
      final inputIdsInt64 = Int64List.fromList(inputIds);
      final attentionMaskInt64 = Int64List.fromList(attentionMask);

      print('[ONNX] Creating input tensors...');

      // Create ONNX tensors
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        inputIdsInt64,
        [1, inputIds.length],
      );

      final attentionMaskTensor = OrtValueTensor.createTensorWithDataList(
        attentionMaskInt64,
        [1, attentionMask.length],
      );

      print('[ONNX] Running encoder...');

      // Run encoder
      final encoderInputs = {
        'input_ids': inputTensor,
        'attention_mask': attentionMaskTensor,
      };

      final encoderOutputs = await encoderSession!.runAsync(
        OrtRunOptions(),
        encoderInputs,
      );

      if (encoderOutputs == null || encoderOutputs.isEmpty) {
        throw Exception('Encoder produced no output');
      }

      print('[ONNX] Encoder output count: ${encoderOutputs.length}');

      // Get encoder hidden states (first output)
      final encoderHiddenStates = encoderOutputs[0]!;
      print('[ONNX] Encoder hidden states received');

      print('[ONNX] Starting decoder...');

      // Decode with greedy decoding
      final outputTokens = await _greedyDecode(
        decoderSession!,
        encoderHiddenStates,
        inputIds.length,
        tokenizer,
        maxLength: 512,
      );

      print('[ONNX] Output tokens: $outputTokens (length: ${outputTokens.length})');

      // Decode tokens to text
      final translatedText = tokenizer.decode(outputTokens);
      print('[ONNX] Translated text: "$translatedText"');

      // Cache result
      _translationCache[cacheKey] = translatedText;

      // Cleanup
      inputTensor.release();
      attentionMaskTensor.release();
      encoderHiddenStates?.release();

      return translatedText;
    } catch (e, stackTrace) {
      print('[ONNX] Translation error: $e');
      print('[ONNX] Stack trace: $stackTrace');
      throw Exception('Translation failed: $e');
    }
  }

  /// Greedy decoding for sequence generation with proper logits extraction
  Future<List<int>> _greedyDecode(
    OrtSession decoderSession,
    OrtValue encoderHiddenStates,
    int encoderLength,
    TokenizerService tokenizer,
    {int maxLength = 512}
  ) async {
    final outputTokens = <int>[];

    // Start with BOS (beginning of sequence) token
    final decoderInputIds = [tokenizer.bosTokenId];

    print('[ONNX] Starting greedy decode with BOS token: ${tokenizer.bosTokenId}');

    for (int step = 0; step < maxLength; step++) {
      try {
        // Prepare decoder input tensor (Int64)
        final decoderInputIdsInt64 = Int64List.fromList(decoderInputIds);
        final decoderInputTensor = OrtValueTensor.createTensorWithDataList(
          decoderInputIdsInt64,
          [1, decoderInputIds.length],
        );

        // Create decoder attention mask
        final decoderAttentionMask = List<int>.filled(decoderInputIds.length, 1);
        final decoderAttentionMaskInt64 = Int64List.fromList(decoderAttentionMask);
        final decoderAttentionMaskTensor = OrtValueTensor.createTensorWithDataList(
          decoderAttentionMaskInt64,
          [1, decoderAttentionMask.length],
        );

        // Run decoder step
        final decoderInputs = {
          'input_ids': decoderInputTensor,
          'encoder_hidden_states': encoderHiddenStates,
          'attention_mask': decoderAttentionMaskTensor,
        };

        final decoderOutputs = await decoderSession.runAsync(
          OrtRunOptions(),
          decoderInputs,
        );

        if (decoderOutputs == null || decoderOutputs.isEmpty) {
          print('[ONNX] Decoder produced no output at step $step');
          break;
        }

        // Get logits (first output) - should be Float32 tensor
        final logitsValue = decoderOutputs[0]!;

        // Extract next token using proper tensor data access
        final nextToken = _extractNextToken(logitsValue, tokenizer.vocabSize);

        if (step < 5) {
          print('[ONNX] Step $step: next token = $nextToken');
        }

        // Cleanup step tensors
        decoderInputTensor.release();
        decoderAttentionMaskTensor.release();

        // Check for EOS
        if (nextToken == tokenizer.eosTokenId) {
          print('[ONNX] Hit EOS token, stopping decode');
          break;
        }

        // Add to output
        outputTokens.add(nextToken);
        decoderInputIds.add(nextToken);

      } catch (e) {
        print('[ONNX] Error at decode step $step: $e');
        break;
      }
    }

    print('[ONNX] Greedy decode complete: ${outputTokens.length} tokens generated');
    return outputTokens;
  }

  /// Extract next token from logits tensor using proper data access
  /// This is where onnxruntime_flutter shines - we can actually read the tensor!
  int _extractNextToken(OrtValue logitsValue, int vocabSize) {
    try {
      // Cast to OrtValueTensor to access tensor data
      if (logitsValue is! OrtValueTensor) {
        print('[ONNX] Output is not a tensor');
        return 3; // UNK token
      }

      final logitsTensor = logitsValue as OrtValueTensor;

      // Get the tensor data as Float32List
      // Shape should be [batch_size, sequence_length, vocab_size]
      // We want the last token's logits
      final logits = logitsTensor.value as Float32List?;

      if (logits == null || logits.isEmpty) {
        print('[ONNX] No logits data available');
        return 3; // UNK token
      }

      // Get shape information from tensor type info
      print('[ONNX] Logits data length: ${logits.length}');

      // For OPUS-MT decoder: output shape is usually [batch, seq_len, vocab_size]
      // We'll need to infer the shape from the data length and vocab size
      // Assuming batch_size = 1
      final totalSize = logits.length;

      // Simple approach: assume the logits are for the last token position
      // The last vocab_size elements should be the logits for the final token
      if (totalSize < vocabSize) {
        print('[ONNX] Data size $totalSize is less than vocab size $vocabSize');
        return 3;
      }

      // Get logits for last token (last vocab_size elements)
      final startIdx = totalSize - vocabSize;

      // Find argmax (token with highest logit value)
      int bestToken = 0;
      double bestScore = logits[startIdx];

      for (int i = 0; i < vocabSize; i++) {
        final score = logits[startIdx + i];
        if (score > bestScore) {
          bestScore = score;
          bestToken = i;
        }
      }

      return bestToken;

    } catch (e) {
      print('[ONNX] Error extracting next token: $e');
      return 3; // Return UNK token on error
    }
  }

  /// Download models for a language pair
  Future<void> downloadModels({
    required String sourceLang,
    required String targetLang,
    Function(String, double)? onProgress,
  }) async {
    if (!_isInitialized) await initialize();
    await _modelManager.downloadLanguagePair(sourceLang, targetLang, onProgress: onProgress);
  }

  /// Check if models are downloaded
  Future<bool> areModelsDownloaded(String sourceLang, String targetLang) async {
    if (!_isInitialized) await initialize();
    return await _modelManager.isLanguagePairDownloaded(sourceLang, targetLang);
  }

  /// Get download progress
  double getDownloadProgress(String modelKey) {
    return _modelManager.getDownloadProgress(modelKey);
  }

  /// Clear cache
  void clearCache() {
    _translationCache.clear();
  }

  /// Dispose resources
  void dispose() {
    try {
      // Release all sessions (synchronous in this package)
      for (var session in _encoderSessions.values) {
        session?.release();
      }
      for (var session in _decoderSessions.values) {
        session?.release();
      }

      _encoderSessions.clear();
      _decoderSessions.clear();
      _tokenizers.clear();
      _translationCache.clear();

      OrtEnv.instance.release();
      print('[ONNX] Resources disposed');
    } catch (e) {
      print('[ONNX] Error disposing resources: $e');
    }
  }
}
