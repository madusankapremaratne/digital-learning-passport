/// Deterministic on-device JD analysis engine.
///
/// Extracts a role requirement vector from free-text job descriptions
/// using a weighted competency lexicon, and composes the match narrative
/// from templates. Runs offline on any target (mobile, web, tests).
/// It implements the same [EdgeLm] interface a quantized SLM will, so the
/// upgrade path is a drop-in replacement.
library;

import 'dart:math';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import 'edge_lm.dart';

class LexiconEdgeLm implements EdgeLm {
  @override
  String get modelName => 'Knivok Edge LM v1 (on-device, lexicon)';

  /// Competency lexicon: term → weight, per skill dimension. Multi-word
  /// terms are matched as phrases.
  static const Map<String, Map<String, double>> _lexicon = {
    'Data analysis': {
      'sql': 0.18, 'excel': 0.12, 'tableau': 0.15, 'power bi': 0.15,
      'dashboard': 0.12, 'dashboards': 0.12, 'visualization': 0.12,
      'visualisation': 0.12, 'reporting': 0.10, 'analytics': 0.15,
      'data analysis': 0.18, 'etl': 0.12, 'pandas': 0.15, 'data': 0.06,
    },
    'Programming': {
      'python': 0.15, 'java': 0.15, 'javascript': 0.15, 'flutter': 0.15,
      'dart': 0.12, 'react': 0.12, 'git': 0.10, 'api': 0.10,
      'apis': 0.10, 'coding': 0.15, 'programming': 0.18, 'c++': 0.12,
      'software development': 0.18, 'debugging': 0.10, 'developer': 0.12,
    },
    'Maths & statistics': {
      'statistics': 0.18, 'statistical': 0.15, 'regression': 0.15,
      'probability': 0.12, 'mathematics': 0.15, 'forecasting': 0.12,
      'machine learning': 0.15, 'modelling': 0.10, 'modeling': 0.10,
      'hypothesis': 0.10, 'quantitative': 0.12,
    },
    'Communication': {
      'communication': 0.18, 'presentation': 0.12, 'presentations': 0.12,
      'stakeholder': 0.15, 'stakeholders': 0.15, 'collaboration': 0.12,
      'teamwork': 0.12, 'interpersonal': 0.12, 'negotiation': 0.10,
      'client facing': 0.12, 'writing': 0.08,
    },
    'Domain knowledge': {
      'industry': 0.10, 'domain': 0.12, 'business': 0.10, 'finance': 0.12,
      'marketing': 0.12, 'healthcare': 0.12, 'logistics': 0.12,
      'operations': 0.10, 'compliance': 0.10, 'requirements': 0.08,
    },
    'Engagement consistency': {
      'deadline': 0.12, 'deadlines': 0.12, 'self-motivated': 0.15,
      'reliable': 0.12, 'consistent': 0.12, 'organised': 0.10,
      'organized': 0.10, 'time management': 0.15, 'proactive': 0.10,
      'punctual': 0.10, 'independently': 0.10,
    },
  };

  /// Requirement floor for dimensions the JD never mentions.
  static const _baseRequirement = 0.20;

  /// Starting requirement once a dimension is mentioned at all.
  static const _mentionedFloor = 0.35;

  @override
  Future<JdAnalysis> analyzeJobDescription(String jobDescription) async {
    final normalized = ' ${jobDescription.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+\-]'), ' ').replaceAll(RegExp(r'\s+'), ' ')} ';
    final required = <String, double>{};
    final matched = <String, List<String>>{};

    for (final dim in kSkillDimensions) {
      final hits = <String>[];
      var weight = 0.0;
      _lexicon[dim]!.forEach((term, w) {
        if (normalized.contains(' $term ')) {
          hits.add(term);
          weight += w;
        }
      });
      required[dim] = hits.isEmpty
          ? _baseRequirement
          : min(0.95, _mentionedFloor + weight);
      if (hits.isNotEmpty) matched[dim] = hits;
    }

    return JdAnalysis(
      role: TargetRole(
        name: _extractTitle(jobDescription),
        summary: 'Requirements extracted on-device from the job description.',
        required: required,
      ),
      matchedTerms: matched,
    );
  }

  String _extractTitle(String jd) {
    for (final line in jd.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cleaned = trimmed
          .replaceFirst(RegExp(r'^(job\s*title|role|position)\s*[:\-]\s*',
              caseSensitive: false), '')
          .trim();
      return cleaned.length > 42 ? '${cleaned.substring(0, 39)}…' : cleaned;
    }
    return 'Custom role';
  }

  @override
  Future<String> explainMatch({
    required LearnerProfile profile,
    required TargetRole role,
    required double score,
    required List<SkillGap> gaps,
  }) async {
    final firstName = profile.name.split(' ').first;
    final pct = (score * 100).round();

    final strengths = <String>[
      for (final dim in kSkillDimensions)
        if ((profile.skills[dim] ?? 0) >= (role.required[dim] ?? 0) + 0.05)
          dim.toLowerCase(),
    ];

    final buffer = StringBuffer()
      ..write('$firstName shows a $pct% alignment with the requirements '
          'extracted for "${role.name}". ');

    if (strengths.isNotEmpty) {
      buffer.write('Verified strengths exceeding the role bar: '
          '${strengths.take(3).join(', ')}. ');
    }

    if (gaps.isEmpty) {
      buffer.write('No material skill gaps were detected — the candidate '
          'profile meets or exceeds every extracted requirement.');
    } else {
      buffer.write('Development areas, worst first: '
          '${gaps.take(3).map((g) => '${g.skill.toLowerCase()} '
              '(-${(g.severity * 100).round()} pts)').join('; ')}. ');
      final top = gaps.first;
      final recommendation = skillRecommendations[top.skill];
      if (recommendation != null) {
        buffer.write('Suggested first step: '
            '${recommendation[0].toLowerCase()}${recommendation.substring(1)}');
      }
    }

    return buffer.toString();
  }
}
