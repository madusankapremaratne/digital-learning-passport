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

/// The active on-device engine.
final EdgeLm edgeLm = LexiconEdgeLm();
