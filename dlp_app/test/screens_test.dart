import 'package:dlp_app/data/demo_data.dart';
import 'package:dlp_app/screens/recruiter/candidate_screen.dart';
import 'package:dlp_app/screens/student/job_fit_screen.dart';
import 'package:dlp_app/screens/student/passport_screen.dart';
import 'package:dlp_app/screens/student/share_screen.dart';
import 'package:dlp_app/services/passport_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('passport screen shows profile, skills and modules',
      (tester) async {
    final learner = demoLearners.first;
    await tester.pumpWidget(_wrap(PassportScreen(profile: learner)));
    await tester.pumpAndSettle();

    expect(find.text(learner.name), findsOneWidget);
    expect(find.text('Institution verified'), findsOneWidget);
    expect(find.text('Data analysis'), findsOneWidget);
    expect(find.text('Share via QR'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Statistical methods'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Statistical methods'), findsOneWidget);
  });

  testWidgets('share screen renders QR and consent toggles', (tester) async {
    await tester
        .pumpWidget(_wrap(ShareScreen(profile: demoLearners.first)));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Assessment scores'), findsOneWidget);
    expect(find.text('Engagement trail'), findsOneWidget);

    // Toggling consent regenerates the QR without errors.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('candidate screen shows match score, gaps and evidence',
      (tester) async {
    final decoded = decodePassport(encodePassport(demoLearners[1]))!;
    await tester.pumpWidget(_wrap(CandidateScreen(decoded: decoded)));
    await tester.pumpAndSettle();

    expect(find.text(demoLearners[1].name), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Skill match'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Detected skill gaps'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Detected skill gaps'), findsOneWidget);

    // Verified evidence list shows shared modules.
    await tester.scrollUntilVisible(
        find.text('Warm start — onboarding plan'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Warm start — onboarding plan'), findsOneWidget);
  });

  testWidgets('student job fit check analyzes a JD on-device',
      (tester) async {
    await tester
        .pumpWidget(_wrap(JobFitScreen(profile: demoLearners.first)));
    await tester.pumpAndSettle();

    // Load the sample JD and analyze.
    await tester.tap(find.text('Sample JD'));
    await tester.pump();
    await tester.tap(find.text('Analyze on-device'));
    await tester.pumpAndSettle();

    expect(find.textContaining('alignment with the requirements'),
        findsOneWidget);
    expect(find.text('Signals detected in the job description'),
        findsOneWidget);
    expect(find.text('sql'), findsOneWidget);
  });

  testWidgets('recruiter can match candidate against a pasted JD',
      (tester) async {
    final decoded = decodePassport(encodePassport(demoLearners[1]))!;
    await tester.pumpWidget(_wrap(CandidateScreen(decoded: decoded)));
    await tester.pumpAndSettle();

    await tester.tap(
        find.text('Match a job description (on-device AI)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sample JD'));
    await tester.pump();
    await tester.tap(find.text('Analyze on-device'));
    await tester.pumpAndSettle();

    // Custom role becomes the active target with the Edge LM card shown.
    expect(find.textContaining('Edge LM analysis'), findsOneWidget);
    expect(find.textContaining('alignment with the requirements'),
        findsOneWidget);
  });

  testWidgets('unverified passport shows the unverified badge',
      (tester) async {
    final decoded = DecodedPassport(demoLearners[2], false);
    await tester.pumpWidget(_wrap(CandidateScreen(decoded: decoded)));
    await tester.pumpAndSettle();

    expect(find.text('Unverified'), findsOneWidget);
  });

  testWidgets('candidate screen hides evidence when scores not shared',
      (tester) async {
    final decoded = decodePassport(
        encodePassport(demoLearners.first, includeScores: false))!;
    await tester.pumpWidget(_wrap(CandidateScreen(decoded: decoded)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.text('Scores not shared by candidate'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Scores not shared by candidate'), findsOneWidget);
  });
}
