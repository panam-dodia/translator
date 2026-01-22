# OPUS-MT Integration Guide for Commercial Release

## Current Status

✅ **Whisper ASR** - DONE (huge quality improvement)
⚠️ **Translation** - Using Google ML Kit (works, but basic quality)
🎯 **Next Step** - Upgrade to OPUS-MT for professional translation quality

---

## Why OPUS-MT for Commercial Release?

| Feature | Google ML Kit | OPUS-MT |
|---------|--------------|---------|
| **License** | Free, commercial use ✅ | Apache 2.0, commercial use ✅ |
| **Quality** | Basic phrase-based | Neural, context-aware |
| **Punctuation** | ❌ Poor | ✅ Excellent |
| **Informal language** | ❌ Struggles | ✅ Handles well |
| **Model size** | ~35 MB per language | ~75 MB per direction (quantized) |
| **Performance** | BLEU ~10-15 | BLEU 16-40 (depending on direction) |

---

## Available OPUS-MT Models (Pre-converted ONNX)

### Option 1: Quantized Models (Recommended for Mobile)
- **English → Hindi**: `Torick63/opus-mt-en-hi-onnx-quantized`
- **Hindi → English**: `Torick63/opus-mt-hi-en-onnx-quantized`
- **Size**: ~25-40 MB each (INT8 quantized)
- **Speed**: Optimized for mobile inference

### Option 2: Community Models
- **Hindi → English**: `onnx-community/opus-mt-hi-en`
- **Size**: ~75 MB (FP32)
- **Quality**: Slightly better, but slower

---

## Implementation Steps

### Step 1: Download ONNX Models

1. Go to Hugging Face:
   - https://huggingface.co/Torick63/opus-mt-en-hi-onnx-quantized
   - https://huggingface.co/Torick63/opus-mt-hi-en-onnx-quantized

2. Download these files from each repository:
   - `encoder_model.onnx` - Encodes input text
   - `decoder_model.onnx` - Generates translation
   - `decoder_model_merged.onnx` - Optimized decoder
   - `sentencepiece.bpe.model` - Tokenizer
   - `config.json` - Model configuration

3. Place models in your project:
   ```
   assets/models/
   ├── en-hi/
   │   ├── encoder_model.onnx
   │   ├── decoder_model_merged.onnx
   │   ├── sentencepiece.bpe.model
   │   └── config.json
   └── hi-en/
       ├── encoder_model.onnx
       ├── decoder_model_merged.onnx
       ├── sentencepiece.bpe.model
       └── config.json
   ```

### Step 2: Update pubspec.yaml

Already done! The `onnxruntime` package is added.

Add asset paths:
```yaml
flutter:
  assets:
    - assets/models/en-hi/
    - assets/models/hi-en/
```

### Step 3: Install SentencePiece for Tokenization

You'll need a SentencePiece tokenizer for Flutter. Options:
- Use platform channels (Kotlin/Swift) for native SentencePiece
- OR use a Dart-based tokenizer package (if available)

### Step 4: Create ONNX Translation Service

I'll create a template service that you can complete once models are downloaded.

### Step 5: Test and Benchmark

Compare translation quality between ML Kit and OPUS-MT.

---

## Timeline Recommendation

### Phase 1: MVP Launch (Use Current Setup)
- ✅ Whisper ASR (already done - massive improvement)
- ✅ Google ML Kit translation (works, commercially safe)
- Launch on Play Store & App Store
- Get user feedback

### Phase 2: Quality Upgrade (After Launch)
- Integrate OPUS-MT via ONNX Runtime
- A/B test translation quality
- Roll out to users as update

---

## Why This Approach?

1. **Get to market faster** - ML Kit works now
2. **Validate product-market fit** - See if users like the app
3. **Avoid premature optimization** - ONNX integration is complex
4. **Safe iteration** - Can upgrade translation quality post-launch

---

## Current Translation Quality

### Google ML Kit
- ✅ Works offline
- ✅ Commercially licensed
- ✅ Small model size
- ❌ Basic quality
- ❌ Poor punctuation handling

### Your User's Example
Input: "are kuchh nhi, ek translation app par kam kar rhi hoon"

- **ML Kit output**: "i'm not working on a translation app" ❌
- **Expected**: "no, nothing, working on a translation app" ✅

---

## Decision Point

**Option A: Launch Now with ML Kit** (Recommended)
- Pros: Fast to market, proven stability, simple
- Cons: Basic translation quality

**Option B: Implement OPUS-MT First**
- Pros: Best quality from day 1
- Cons: 2-3 weeks additional dev time, complexity

**My Recommendation**: Launch with Whisper + ML Kit, upgrade to OPUS-MT as v1.1 update.

The Whisper ASR upgrade you just got is the bigger improvement - users will love the accurate speech recognition. Translation quality can be improved in the next iteration.
