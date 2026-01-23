import 'dart:convert';
import 'dart:io';

/// Proper BPE tokenizer for OPUS-MT models
/// Implements Byte-Pair Encoding with merge rules
class TokenizerService {
  Map<String, int> _vocab = {};
  Map<int, String> _reverseVocab = {};
  List<List<String>> _bpeMerges = [];
  int _padTokenId = 0;
  int _eosTokenId = 0;
  int _unkTokenId = 3;
  int _bosTokenId = 0;

  bool _isInitialized = false;

  /// Load vocabulary and tokenizer config from JSON files
  Future<void> initialize(String vocabPath, String tokenizerPath) async {
    try {
      // Load vocab.json
      final vocabFile = File(vocabPath);
      final vocabContent = await vocabFile.readAsString();
      final vocabJson = jsonDecode(vocabContent) as Map<String, dynamic>;

      // Build vocabulary mappings
      vocabJson.forEach((token, id) {
        final tokenId = id is int ? id : int.parse(id.toString());
        _vocab[token] = tokenId;
        _reverseVocab[tokenId] = token;
      });

      // Load tokenizer.json for BPE merges and special tokens
      final tokenizerFile = File(tokenizerPath);
      final tokenizerContent = await tokenizerFile.readAsString();
      final tokenizerJson = jsonDecode(tokenizerContent) as Map<String, dynamic>;

      // Extract special token IDs
      if (tokenizerJson.containsKey('model')) {
        final model = tokenizerJson['model'];

        // Get BPE merges if available
        if (model['merges'] is List) {
          for (var merge in model['merges']) {
            final parts = merge.toString().split(' ');
            if (parts.length == 2) {
              _bpeMerges.add(parts);
            }
          }
        }

        // Get vocab from model if not already loaded
        if (model['vocab'] is Map && _vocab.isEmpty) {
          (model['vocab'] as Map).forEach((token, id) {
            final tokenId = id is int ? id : int.parse(id.toString());
            _vocab[token.toString()] = tokenId;
            _reverseVocab[tokenId] = token.toString();
          });
        }
      }

      // Extract special tokens
      if (tokenizerJson.containsKey('added_tokens')) {
        for (var token in tokenizerJson['added_tokens']) {
          final content = token['content'] ?? token['id'].toString();
          final id = token['id'] is int ? token['id'] : int.parse(token['id'].toString());

          if (content == '<pad>') _padTokenId = id;
          if (content == '</s>') _eosTokenId = id;
          if (content == '<unk>') _unkTokenId = id;
          if (content == '<s>') _bosTokenId = id;
        }
      }

      // Fallback: find special tokens in vocab
      _vocab.forEach((token, id) {
        if (token == '<pad>') _padTokenId = id;
        if (token == '</s>') _eosTokenId = id;
        if (token == '<unk>') _unkTokenId = id;
        if (token == '<s>') _bosTokenId = id;
      });

      _isInitialized = true;
      print('Tokenizer initialized: vocab size=${_vocab.length}, merges=${_bpeMerges.length}');
    } catch (e) {
      throw Exception('Failed to initialize tokenizer: $e');
    }
  }

  /// Tokenize text into token IDs using BPE
  List<int> encode(String text) {
    if (!_isInitialized) {
      throw Exception('Tokenizer not initialized');
    }

    // Normalize text
    text = text.trim();
    if (text.isEmpty) return [_eosTokenId];

    // Split into words and apply BPE
    final tokenIds = <int>[];
    final words = text.split(RegExp(r'\s+'));

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      // Add space marker for non-first words (OPUS-MT convention)
      final processedWord = i == 0 ? word : '▁$word';

      // Apply BPE to word
      final wordTokens = _applyBPE(processedWord);

      // Convert to IDs
      for (var token in wordTokens) {
        if (_vocab.containsKey(token)) {
          tokenIds.add(_vocab[token]!);
        } else {
          // Try character-level fallback
          bool found = false;
          for (var char in token.split('')) {
            if (_vocab.containsKey(char)) {
              tokenIds.add(_vocab[char]!);
              found = true;
            }
          }
          if (!found) {
            tokenIds.add(_unkTokenId);
          }
        }
      }
    }

    // Add EOS token at end
    tokenIds.add(_eosTokenId);

    return tokenIds;
  }

  /// Apply BPE merges to a word
  List<String> _applyBPE(String word) {
    if (word.isEmpty) return [];

    // Start with character-level tokens
    List<String> tokens = word.split('');

    if (_bpeMerges.isEmpty) {
      // No merges available, try to match longest tokens in vocab
      return _greedyTokenize(word);
    }

    // Apply BPE merges
    while (tokens.length > 1) {
      // Find the highest priority merge
      int bestMergeIdx = -1;
      int bestMergePriority = -1;

      for (int i = 0; i < tokens.length - 1; i++) {
        final pair = [tokens[i], tokens[i + 1]];
        final mergeIdx = _findMergeIndex(pair);

        if (mergeIdx >= 0 && mergeIdx > bestMergePriority) {
          bestMergePriority = mergeIdx;
          bestMergeIdx = i;
        }
      }

      if (bestMergeIdx < 0) break; // No more merges possible

      // Apply the merge
      final merged = tokens[bestMergeIdx] + tokens[bestMergeIdx + 1];
      tokens = [
        ...tokens.sublist(0, bestMergeIdx),
        merged,
        ...tokens.sublist(bestMergeIdx + 2),
      ];
    }

    return tokens;
  }

  /// Find index of merge in merge list
  int _findMergeIndex(List<String> pair) {
    for (int i = 0; i < _bpeMerges.length; i++) {
      if (_bpeMerges[i][0] == pair[0] && _bpeMerges[i][1] == pair[1]) {
        return i;
      }
    }
    return -1;
  }

  /// Greedy tokenization when no merges available
  List<String> _greedyTokenize(String word) {
    final result = <String>[];
    int i = 0;

    while (i < word.length) {
      // Try to match longest token
      int bestLen = 0;
      for (int len = word.length - i; len > 0; len--) {
        final candidate = word.substring(i, i + len);
        if (_vocab.containsKey(candidate)) {
          result.add(candidate);
          bestLen = len;
          break;
        }
      }

      if (bestLen == 0) {
        // No match found, use single character or unknown
        result.add(word[i]);
        bestLen = 1;
      }

      i += bestLen;
    }

    return result;
  }

  /// Decode token IDs back to text
  String decode(List<int> tokenIds) {
    if (!_isInitialized) {
      throw Exception('Tokenizer not initialized');
    }

    final tokens = <String>[];
    for (var id in tokenIds) {
      // Skip special tokens except BOS which might be needed
      if (id == _padTokenId || id == _eosTokenId || id == _bosTokenId) continue;

      if (_reverseVocab.containsKey(id)) {
        tokens.add(_reverseVocab[id]!);
      } else {
        tokens.add('<unk>');
      }
    }

    // Join tokens
    String text = tokens.join('');

    // Replace BPE space marker with actual space
    text = text.replaceAll('▁', ' ');

    // Clean up
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Get special token IDs
  int get padTokenId => _padTokenId;
  int get eosTokenId => _eosTokenId;
  int get unkTokenId => _unkTokenId;
  int get bosTokenId => _bosTokenId;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get vocabulary size
  int get vocabSize => _vocab.length;
}
