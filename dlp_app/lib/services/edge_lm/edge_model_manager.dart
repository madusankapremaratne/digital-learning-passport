/// Download, lifecycle, and activation management for real on-device
/// models (flutter_gemma / MediaPipe LLM inference).
library;

import 'package:flutter_gemma/flutter_gemma.dart';

import 'edge_lm.dart';
import 'gemma_edge_lm.dart';

/// A downloadable on-device model option.
class EdgeModelOption {
  /// Model filename; used as the install id by flutter_gemma.
  final String id;
  final String displayName;
  final String url;
  final String sizeNote;
  final String deviceNote;
  final ModelType modelType;

  /// True when the Hugging Face repo requires accepting a license before
  /// the file can be downloaded (Gemma models). The user's HF account
  /// must accept the license on the repo page AND the access token must
  /// have "read access to public gated repos" permission.
  final bool gated;

  /// Repo page where the license is accepted, shown in error guidance.
  final String repoPage;

  const EdgeModelOption({
    required this.id,
    required this.displayName,
    required this.url,
    required this.sizeNote,
    required this.deviceNote,
    required this.modelType,
    required this.gated,
    required this.repoPage,
  });
}

/// Curated catalog of LiteRT community conversions served from Hugging
/// Face. The Qwen models are public (no account needed); the Gemma
/// models are license-gated.
const kEdgeModels = <EdgeModelOption>[
  EdgeModelOption(
    id: 'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    displayName: 'Qwen 2.5 0.5B Instruct (q8)',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    sizeNote: '≈550 MB download',
    deviceNote: 'No account needed. Quick start; low-end devices.',
    modelType: ModelType.qwen,
    gated: false,
    repoPage: 'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct',
  ),
  EdgeModelOption(
    id: 'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    displayName: 'Qwen 2.5 1.5B Instruct (q8)',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    sizeNote: '≈1.6 GB download',
    deviceNote: 'No account needed. Best quality; 4 GB+ RAM. Recommended.',
    modelType: ModelType.qwen,
    gated: false,
    repoPage: 'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct',
  ),
  EdgeModelOption(
    id: 'gemma3-270m-it-q8.task',
    displayName: 'Gemma 3 270M (q8)',
    url:
        'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8.task',
    sizeNote: '≈300 MB download',
    deviceNote: 'Gated: needs HF account + Gemma license. Low-end devices.',
    modelType: ModelType.gemmaIt,
    gated: true,
    repoPage: 'https://huggingface.co/litert-community/gemma-3-270m-it',
  ),
  EdgeModelOption(
    id: 'gemma3-1b-it-int4.task',
    displayName: 'Gemma 3 1B (int4)',
    url:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
    sizeNote: '≈555 MB download',
    deviceNote: 'Gated: needs HF account + Gemma license. 4 GB+ RAM.',
    modelType: ModelType.gemmaIt,
    gated: true,
    repoPage: 'https://huggingface.co/litert-community/Gemma3-1B-IT',
  ),
];

class EdgeModelManager {
  EdgeModelManager._();

  static final EdgeModelManager instance = EdgeModelManager._();

  InferenceModel? _loaded;
  String? _loadedId;
  bool _initialized = false;

  String? get loadedModelId => _loadedId;

  /// Plugin services are initialized lazily so that tests and platforms
  /// without the native plugin never touch it.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await FlutterGemma.initialize();
    _initialized = true;
  }

  Future<bool> isInstalled(EdgeModelOption option) async {
    await _ensureInitialized();
    return FlutterGemma.isModelInstalled(option.id);
  }

  /// Downloads and registers the model file. [onProgress] receives 0-100.
  Future<void> download(
    EdgeModelOption option, {
    String? huggingFaceToken,
    void Function(int percent)? onProgress,
  }) async {
    await _ensureInitialized();
    var builder = FlutterGemma.installModel(modelType: option.modelType)
        .fromNetwork(option.url,
            token: (huggingFaceToken?.isEmpty ?? true)
                ? null
                : huggingFaceToken);
    if (onProgress != null) {
      builder = builder.withProgress(onProgress);
    }
    await builder.install();
  }

  /// Loads the installed model into memory and makes it the active
  /// [EdgeLm] engine. Returns the engine's display name.
  Future<String> activate(EdgeModelOption option) async {
    await _ensureInitialized();
    await _loaded?.close();
    _loaded = null;
    _loadedId = null;

    final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
    _loaded = model;
    _loadedId = option.id;
    final engine = GemmaEdgeLm(model, option.displayName);
    EdgeLmRuntime.instance.active = engine;
    return engine.modelName;
  }

  /// Unloads any loaded model and reverts to the lexicon engine.
  Future<void> deactivate() async {
    await _loaded?.close();
    _loaded = null;
    _loadedId = null;
    EdgeLmRuntime.instance.resetToLexicon();
  }

  Future<void> uninstall(EdgeModelOption option) async {
    if (_loadedId == option.id) await deactivate();
    await FlutterGemma.uninstallModel(option.id);
  }
}
