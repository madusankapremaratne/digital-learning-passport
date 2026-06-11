import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../services/edge_lm/edge_lm.dart';
import '../../services/passport_codec.dart';
import '../../services/skill_match.dart';
import '../../theme.dart';
import '../../widgets/gap_tile.dart';

/// Recruiter view of a scanned candidate: verification status, skill match
/// score against a selectable target role, gap map, and verified evidence.
class CandidateScreen extends StatefulWidget {
  final DecodedPassport decoded;

  const CandidateScreen({super.key, required this.decoded});

  @override
  State<CandidateScreen> createState() => _CandidateScreenState();
}

class _CandidateScreenState extends State<CandidateScreen> {
  TargetRole _role = demoRoles.first;
  JdAnalysis? _jdAnalysis;
  String? _edgeExplanation;

  LearnerProfile get _profile => widget.decoded.profile;

  Future<void> _analyzeJd(String jdText) async {
    final analysis = await edgeLm.analyzeJobDescription(jdText);
    final score = matchScore(_profile, analysis.role);
    final gaps = detectGaps(_profile, analysis.role);
    final explanation = await edgeLm.explainMatch(
      profile: _profile,
      role: analysis.role,
      score: score,
      gaps: gaps,
    );
    if (!mounted) return;
    setState(() {
      _jdAnalysis = analysis;
      _role = analysis.role;
      _edgeExplanation = explanation;
    });
  }

  void _openJdSheet() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Match against a job description',
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Analyzed on this device by ${edgeLm.modelName} — the JD is '
              'not uploaded anywhere.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Paste job description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Analyze on-device'),
                    onPressed: () {
                      final text = controller.text.trim();
                      Navigator.of(sheetContext).pop();
                      if (text.isNotEmpty) _analyzeJd(text);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => controller.text = kSampleJobDescription,
                  child: const Text('Sample JD'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final score = matchScore(_profile, _role);
    final gaps = detectGaps(_profile, _role);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidate profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _identityCard(context),
              const SizedBox(height: 16),
              DropdownMenu<TargetRole>(
                key: ValueKey(_role.name),
                initialSelection: _role,
                label: const Text('Target role'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final role in demoRoles)
                    DropdownMenuEntry(value: role, label: role.name),
                  if (_jdAnalysis != null)
                    DropdownMenuEntry(
                      value: _jdAnalysis!.role,
                      label: '${_jdAnalysis!.role.name} (from JD)',
                    ),
                ],
                onSelected: (role) {
                  if (role != null) setState(() => _role = role);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.memory, size: 18),
                label: const Text('Match a job description (on-device AI)'),
                onPressed: _openJdSheet,
              ),
              const SizedBox(height: 16),
              if (_edgeExplanation != null &&
                  identical(_role, _jdAnalysis?.role)) ...[
                _edgeAnalysisCard(context),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _scoreCard(context, score)),
                  const SizedBox(width: 12),
                  Expanded(child: _readinessCard(context, gaps)),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Skill match map'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 260,
                        child: _GapRadar(profile: _profile, role: _role),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(scheme.primary, 'Candidate'),
                          const SizedBox(width: 16),
                          _legendDot(scheme.tertiary, 'Role requirement'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Detected skill gaps'),
              if (gaps.isEmpty)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline,
                        color: scheme.primary),
                    title: const Text('No material gaps for this role'),
                  ),
                )
              else
                for (final gap in gaps) ...[
                  GapTile(gap: gap),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 8),
              _sectionTitle(context, 'Verified academic evidence'),
              if (_profile.modules.isEmpty)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline, color: scheme.outline),
                    title: const Text('Scores not shared by candidate'),
                    subtitle: const Text(
                        'The candidate chose not to include assessment '
                        'detail in this passport.'),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final module in _profile.modules)
                        ListTile(
                          dense: true,
                          leading: Text(module.code,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          title: Text(module.title),
                          subtitle: Text(
                              '${module.presentation} · TMA '
                              '${module.tmaAverage.round()}'
                              '${module.examScore != null ? ' · Exam ${module.examScore!.round()}' : ''}'),
                          trailing: Text(
                            module.result,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: resultColor(module.result, scheme),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _warmStartCard(context, gaps),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verified = widget.decoded.verified;
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
              _profile.name.split(' ').map((w) => w[0]).take(2).join(),
              style: TextStyle(color: scheme.onPrimaryContainer)),
        ),
        title: Text(_profile.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text('${_profile.programme}\n${_profile.institution}'),
        isThreeLine: true,
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: verified
                ? scheme.primary.withValues(alpha: 0.12)
                : const Color(0xFF854F0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(verified ? Icons.verified : Icons.warning_amber,
                  size: 16,
                  color: verified
                      ? scheme.primary
                      : const Color(0xFF854F0B)),
              const SizedBox(width: 4),
              Text(
                verified ? 'Verified' : 'Unverified',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: verified
                          ? scheme.primary
                          : const Color(0xFF854F0B),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard(BuildContext context, double score) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score,
                    strokeWidth: 7,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  Center(
                    child: Text('${(score * 100).round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Skill match',
                style: Theme.of(context).textTheme.labelMedium),
            Text(_role.name,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _readinessCard(BuildContext context, List<SkillGap> gaps) {
    final scheme = Theme.of(context).colorScheme;
    final band = gaps.isEmpty
        ? 'Role-ready'
        : gaps.first.severity > 0.25
            ? 'Needs development'
            : 'Near-ready';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights, color: scheme.primary),
            const SizedBox(height: 10),
            Text(band,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              gaps.isEmpty
                  ? 'Meets all role requirements.'
                  : '${gaps.length} development '
                      'area${gaps.length == 1 ? '' : 's'} identified for '
                      'onboarding.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warmStartCard(BuildContext context, List<SkillGap> gaps) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Warm start — onboarding plan',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              gaps.isEmpty
                  ? 'No remedial onboarding required; proceed directly to '
                      'role-specific induction.'
                  : 'Skip the generic orientation needs assessment. Focus '
                      'first-quarter development on: '
                      '${gaps.take(3).map((g) => g.skill.toLowerCase()).join(', ')}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _edgeAnalysisCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final analysis = _jdAnalysis!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Edge LM analysis — ${edgeLm.modelName}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: scheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_edgeExplanation!,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final term in analysis.allTerms.take(10))
                  Chip(
                    label: Text(term),
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _GapRadar extends StatelessWidget {
  final LearnerProfile profile;
  final TargetRole role;

  const _GapRadar({required this.profile, required this.role});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle:
            const TextStyle(color: Colors.transparent, fontSize: 9),
        tickBorderData: BorderSide(color: scheme.outlineVariant, width: 0.5),
        gridBorderData:
            BorderSide(color: scheme.outlineVariant, width: 0.5),
        radarBorderData:
            BorderSide(color: scheme.outlineVariant, width: 0.5),
        titleTextStyle: Theme.of(context).textTheme.labelSmall!,
        getTitle: (index, angle) => RadarChartTitle(
          text: _shortLabel(kSkillDimensions[index]),
        ),
        dataSets: [
          RadarDataSet(
            dataEntries: [
              for (final value in role.vector) RadarEntry(value: value),
            ],
            fillColor: scheme.tertiary.withValues(alpha: 0.10),
            borderColor: scheme.tertiary,
            borderWidth: 2,
            entryRadius: 2.5,
          ),
          RadarDataSet(
            dataEntries: [
              for (final value in profile.skillVector)
                RadarEntry(value: value),
            ],
            fillColor: scheme.primary.withValues(alpha: 0.15),
            borderColor: scheme.primary,
            borderWidth: 2,
            entryRadius: 2.5,
          ),
        ],
      ),
    );
  }

  String _shortLabel(String dim) => switch (dim) {
        'Maths & statistics' => 'Maths/stats',
        'Engagement consistency' => 'Consistency',
        'Domain knowledge' => 'Domain',
        'Data analysis' => 'Data',
        'Communication' => 'Comms',
        _ => dim,
      };
}
