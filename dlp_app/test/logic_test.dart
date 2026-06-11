import 'dart:convert';

import 'package:dlp_app/data/demo_data.dart';
import 'package:dlp_app/models/models.dart';
import 'package:dlp_app/services/passport_codec.dart';
import 'package:dlp_app/services/skill_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('passport codec', () {
    test('round-trips a full profile and verifies the signature', () {
      final original = demoLearners.first;
      final decoded = decodePassport(encodePassport(original));
      expect(decoded, isNotNull);
      expect(decoded!.verified, isTrue);
      expect(decoded.profile.id, original.id);
      expect(decoded.profile.skills, original.skills);
      expect(decoded.profile.modules.length, original.modules.length);
      expect(decoded.profile.weeklyClicks, original.weeklyClicks);
    });

    test('consent flags strip scores and engagement from the payload', () {
      final decoded = decodePassport(encodePassport(
        demoLearners.first,
        includeScores: false,
        includeEngagement: false,
      ));
      expect(decoded!.profile.modules, isEmpty);
      expect(decoded.profile.weeklyClicks, isEmpty);
      expect(decoded.verified, isTrue);
    });

    test('wrong signature decodes but is flagged unverified', () {
      final body = jsonEncode(demoLearners.first.toJson());
      final envelope = jsonEncode({'v': 1, 'sig': '00000000', 'p': body});
      final decoded =
          decodePassport(base64UrlEncode(utf8.encode(envelope)));
      expect(decoded, isNotNull);
      expect(decoded!.verified, isFalse);
    });

    test('garbage input returns null', () {
      expect(decodePassport('not-a-passport'), isNull);
      expect(decodePassport(''), isNull);
    });
  });

  group('skill match engine', () {
    test('match score is within [0, 1] for all demo pairs', () {
      for (final learner in demoLearners) {
        for (final role in demoRoles) {
          final score = matchScore(learner, role);
          expect(score, inInclusiveRange(0, 1));
        }
      }
    });

    test('data-strong learner matches data analyst above developer', () {
      final nadeesha = demoLearners[0];
      final analyst = demoRoles.firstWhere((r) => r.name == 'Data analyst');
      final developer =
          demoRoles.firstWhere((r) => r.name == 'Software developer');
      expect(matchScore(nadeesha, analyst),
          greaterThan(matchScore(nadeesha, developer)));
    });

    test('gaps are sorted by severity, worst first', () {
      final gaps = detectGaps(demoLearners[2],
          demoRoles.firstWhere((r) => r.name == 'Software developer'));
      expect(gaps, isNotEmpty);
      for (var i = 1; i < gaps.length; i++) {
        expect(gaps[i - 1].severity, greaterThanOrEqualTo(gaps[i].severity));
      }
      // Amaya (programming 0.38) vs developer (0.90) → programming worst.
      expect(gaps.first.skill, 'Programming');
    });

    test('every skill dimension has a learning recommendation', () {
      for (final dim in kSkillDimensions) {
        expect(skillRecommendations[dim], isNotNull,
            reason: 'missing recommendation for $dim');
      }
    });
  });
}
