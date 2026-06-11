import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import 'recruiter/scan_screen.dart';
import 'student/passport_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Icon(Icons.workspace_premium_outlined,
                    size: 56, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Digital Learning Passport',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-enabled living learner profile with skill gap '
                  'detection and an industry-integrated recruitment '
                  'interface. Proof of concept.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                _RoleCard(
                  icon: Icons.school_outlined,
                  title: 'I am a student',
                  subtitle:
                      'View your living passport, skill profile and share '
                      'it via QR.',
                  onTap: () => _pickLearner(context),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.badge_outlined,
                  title: 'I am a recruiter',
                  subtitle:
                      'Scan a candidate passport, see the skill match score '
                      'and gap map (IIDLP).',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Knovik Private Limited — research prototype on the OULAD '
                  'schema (Kuzilek et al., 2017)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickLearner(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Choose a demo learner',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final learner in demoLearners)
              ListTile(
                leading: CircleAvatar(
                  child: Text(learner.name
                      .split(' ')
                      .map((w) => w[0])
                      .take(2)
                      .join()),
                ),
                title: Text(learner.name),
                subtitle: Text(learner.programme),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PassportScreen(profile: learner),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
