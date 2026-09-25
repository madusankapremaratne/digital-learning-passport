/// Edge LM — on-device language model interface.
///
/// Everything behind this interface runs locally on the student or
/// recruiter device: no network, no cloud. Two capabilities are exposed:
///
/// 1. [analyzeJobDescription] — turn free-text JD into a [TargetRole]
///    requirement vector over [kSkillDimensions].
/// 2. [explainMatch] — generate a natural-language readiness narrative for
///    a profile/role pair.
///
/// The default implementation ([LexiconEdgeLm]) is a deterministic
/// extractive engine that runs on any device including web. Swapping in a
/// quantized SLM (e.g. Gemma 1B via llama.cpp or MediaPipe) means
/// implementing this same interface — the UI and tests do not change.
library;

import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import 'lexicon_edge_lm.dart';

/// Result of on-device JD analysis.
class JdAnalysis {
  /// Requirement vector extracted from the JD text.
  final TargetRole role;

  /// Terms in the JD that drove the extraction, per skill dimension —
  /// surfaced in the UI so the inference is transparent.
  final Map<String, List<String>> matchedTerms;

  const JdAnalysis({required this.role, required this.matchedTerms});

  List<String> get allTerms =>
      [for (final terms in matchedTerms.values) ...terms];
}

abstract interface class EdgeLm {
  /// Shown in the UI so users know which on-device model produced the
  /// result.
  String get modelName;

  Future<JdAnalysis> analyzeJobDescription(String jobDescription);

  Future<String> explainMatch({
    required LearnerProfile profile,
    required TargetRole role,
    required double score,
    required List<SkillGap> gaps,
  });
}

/// Holds the currently active engine. Defaults to the lexicon engine,
/// which runs everywhere; the Edge model screen swaps in a real SLM
/// (Gemma via flutter_gemma) once a model is downloaded and loaded.
class EdgeLmRuntime extends ChangeNotifier {
  EdgeLmRuntime._();

  static final EdgeLmRuntime instance = EdgeLmRuntime._();

  EdgeLm _active = LexiconEdgeLm();

  EdgeLm get active => _active;

  set active(EdgeLm engine) {
    _active = engine;
    notifyListeners();
  }

  bool get isSlmActive => _active is! LexiconEdgeLm;

  void resetToLexicon() => active = LexiconEdgeLm();
}

/// The active on-device engine.
EdgeLm get edgeLm => EdgeLmRuntime.instance.active;
