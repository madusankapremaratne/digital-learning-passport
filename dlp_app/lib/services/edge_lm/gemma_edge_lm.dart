/// Real on-device SLM engine backed by flutter_gemma (MediaPipe LLM
/// inference). Implements the same [EdgeLm] interface as the lexicon
/// engine, so the UI is identical regardless of which engine is active.
///
/// Robustness policy: small instruction-tuned models occasionally return
/// malformed JSON or empty text. Every call has a hard timeout and falls
/// back to the deterministic lexicon engine, so the feature degrades
/// gracefully instead of failing.
library;

import 'dart:convert';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../../models/models.dart';
import 'edge_lm.dart';
import 'lexicon_edge_lm.dart';

class GemmaEdgeLm implements EdgeLm {
  final InferenceModel _model;
  final String _displayName;
  final LexiconEdgeLm _fallback = LexiconEdgeLm();

  static const _timeout = Duration(seconds: 90);

  GemmaEdgeLm(this._model, this._displayName);

  @override
  String get modelName => '$_displayName (on-device SLM)';

  Future<String> _generate(String prompt) async {
    final chat = await _model.createChat(temperature: 0.1);
    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    final response = await chat.generateChatResponse().timeout(_timeout);
    return response is TextResponse ? response.token.trim() : '';
  }

  @override
  Future<JdAnalysis> analyzeJobDescription(String jobDescription) async {
    // The lexicon pass always runs: it supplies the transparent
    // "signals detected" term chips and the fallback vector.
    final lexicon = await _fallback.analyzeJobDescription(jobDescription);
    try {
      final raw = await _generate(_jdPrompt(jobDescription));
      final parsed = _parseRequirements(raw);
      if (parsed == null) return lexicon;
      return JdAnalysis(
        role: TargetRole(
          name: parsed.title ?? lexicon.role.name,
          summary:
              'Requirements inferred on-device by $_displayName from the '
              'job description.',
          required: parsed.requirements,
        ),
        matchedTerms: lexicon.matchedTerms,
      );
    } catch (_) {
      return lexicon;
    }
  }

  @override
  Future<String> explainMatch({
    required LearnerProfile profile,
    required TargetRole role,
    required double score,
    required List<SkillGap> gaps,
  }) async {
    try {
      final text = await _generate(_explainPrompt(
        profile: profile,
        role: role,
        score: score,
        gaps: gaps,
      ));
      if (text.length < 40) throw const FormatException('too short');
      return text;
    } catch (_) {
      return _fallback.explainMatch(
        profile: profile,
        role: role,
        score: score,
        gaps: gaps,
      );
    }
  }

  String _jdPrompt(String jd) => '''
You are a recruitment analyst. Read the job description below and rate
how strongly it requires each of these six skills, from 0 (not needed)
to 100 (essential).

Skills: ${kSkillDimensions.join(', ')}.

Reply with ONLY a JSON object in exactly this shape, no other text:
{"title": "<short job title>", "requirements": {${kSkillDimensions.map((d) => '"$d": <0-100>').join(', ')}}}

Job description:
$jd
''';

  String _explainPrompt({
    required LearnerProfile profile,
    required TargetRole role,
    required double score,
    required List<SkillGap> gaps,
  }) {
    final firstName = profile.name.split(' ').first;
    final gapLines = gaps.isEmpty
        ? 'none'
        : gaps
            .take(3)
            .map((g) =>
                '${g.skill}: requirement ${(g.required * 100).round()}, '
                'candidate ${(g.actual * 100).round()}')
            .join('; ');
    return '''
You are a careers advisor. Write a short, plain-English readiness
summary (3 to 4 sentences, no headings, no lists) for this candidate.
Be factual; use only the data below. Mention the match percentage once.

Candidate first name: $firstName
Target role: ${role.name}
Match score: ${(score * 100).round()}%
Largest skill gaps: $gapLines
Verified result band: ${profile.finalResult}
''';
  }

  ({String? title, Map<String, double> requirements})? _parseRequirements(
      String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final json =
          jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      final reqJson = json['requirements'];
      if (reqJson is! Map<String, dynamic>) return null;
      final requirements = <String, double>{};
      for (final dim in kSkillDimensions) {
        final key = reqJson.keys.firstWhere(
          (k) => k.toLowerCase().trim() == dim.toLowerCase(),
          orElse: () => '',
        );
        final value = key.isEmpty ? null : reqJson[key];
        if (value is! num) return null;
        requirements[dim] = (value / 100).clamp(0.0, 0.95).toDouble();
      }
      return (
        title: (json['title'] as String?)?.trim(),
        requirements: requirements,
      );
    } catch (_) {
      return null;
    }
  }
}
