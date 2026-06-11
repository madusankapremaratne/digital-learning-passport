import 'package:dlp_app/data/demo_data.dart';
import 'package:dlp_app/models/models.dart';
import 'package:dlp_app/services/edge_lm/edge_lm.dart';
import 'package:dlp_app/services/skill_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('edge LM job description analysis', () {
    test('data analyst JD weights data and statistics dimensions highest',
        () async {
      final analysis =
          await edgeLm.analyzeJobDescription(kSampleJobDescription);
      final required = analysis.role.required;

      expect(required['Data analysis']!,
          greaterThan(required['Programming']!));
      expect(required['Maths & statistics']!,
          greaterThan(required['Programming']!));
      // SQL, Power BI, statistics etc. should surface as matched terms.
      expect(analysis.allTerms, contains('sql'));
      expect(analysis.allTerms, contains('statistics'));
    });

    test('developer JD weights programming highest', () async {
      final analysis = await edgeLm.analyzeJobDescription('''
Software Engineer

We need a developer with strong Python and Java programming skills,
experience with Git, APIs and debugging. Coding excellence required.
''');
      final required = analysis.role.required;
      final maxDim = kSkillDimensions.reduce(
          (a, b) => required[a]! >= required[b]! ? a : b);
      expect(maxDim, 'Programming');
      expect(analysis.role.name, 'Software Engineer');
    });

    test('title prefixes like "Job title:" are stripped', () async {
      final analysis = await edgeLm
          .analyzeJobDescription('Job title: Data Analyst\nSQL required.');
      expect(analysis.role.name, 'Data Analyst');
    });

    test('unmentioned dimensions get the base requirement floor', () async {
      final analysis =
          await edgeLm.analyzeJobDescription('SQL dashboards analytics');
      expect(analysis.role.required['Communication'], 0.20);
      expect(analysis.role.required['Data analysis']!, greaterThan(0.35));
    });

    test('requirements never exceed 0.95', () async {
      final spam = List.filled(1, '''
sql excel tableau power bi dashboard dashboards visualization reporting
analytics data analysis etl pandas data
''').join();
      final analysis = await edgeLm.analyzeJobDescription(spam);
      expect(analysis.role.required['Data analysis'],
          lessThanOrEqualTo(0.95));
    });
  });

  group('edge LM match explanation', () {
    test('narrative mentions score, strengths and worst gap', () async {
      final profile = demoLearners[1]; // Kasun — programming strong
      final analysis =
          await edgeLm.analyzeJobDescription(kSampleJobDescription);
      final score = matchScore(profile, analysis.role);
      final gaps = detectGaps(profile, analysis.role);
      final text = await edgeLm.explainMatch(
        profile: profile,
        role: analysis.role,
        score: score,
        gaps: gaps,
      );

      expect(text, contains('Kasun'));
      expect(text, contains('${(score * 100).round()}%'));
      if (gaps.isNotEmpty) {
        expect(text, contains(gaps.first.skill.toLowerCase()));
      }
    });

    test('gap-free profile gets a no-gaps narrative', () async {
      final perfect = LearnerProfile(
        id: 'X',
        name: 'Test Student',
        institution: 'U',
        programme: 'P',
        finalResult: 'Distinction',
        skills: {for (final d in kSkillDimensions) d: 0.95},
        modules: const [],
        weeklyClicks: const [],
        certifications: const [],
      );
      final analysis =
          await edgeLm.analyzeJobDescription(kSampleJobDescription);
      final text = await edgeLm.explainMatch(
        profile: perfect,
        role: analysis.role,
        score: matchScore(perfect, analysis.role),
        gaps: detectGaps(perfect, analysis.role),
      );
      expect(text, contains('No material skill gaps'));
    });
  });
}
