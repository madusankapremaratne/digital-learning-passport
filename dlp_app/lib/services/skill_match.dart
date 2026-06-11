/// Skill matching engine: cosine similarity between a learner's skill
/// vector and a target role's requirement vector, plus ranked gap detection.
///
/// This mirrors the paper's Section 4.2 design. The vectors here are the
/// device-side artefacts; in the full system the campus-edge pipeline
/// computes them from OULAD-style signals (relative achievement, missed
/// assessments, engagement velocity).
library;

import 'dart:math';

import '../models/models.dart';

/// Cosine similarity in [0, 1] for non-negative skill vectors.
double matchScore(LearnerProfile profile, TargetRole role) {
  final a = profile.skillVector;
  final b = role.vector;
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 0;
  return dot / (sqrt(na) * sqrt(nb));
}

/// Gaps where the learner is below the role requirement, worst first.
List<SkillGap> detectGaps(LearnerProfile profile, TargetRole role) {
  final gaps = <SkillGap>[
    for (final dim in kSkillDimensions)
      SkillGap(dim, role.required[dim] ?? 0, profile.skills[dim] ?? 0),
  ]..removeWhere((g) => g.severity <= 0.005);
  gaps.sort((x, y) => y.severity.compareTo(x.severity));
  return gaps;
}
