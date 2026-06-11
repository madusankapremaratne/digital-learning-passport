import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../services/edge_lm/edge_lm.dart';
import '../../services/skill_match.dart';
import '../../widgets/gap_tile.dart';

/// Student-side "am I ready for this job?" check.
///
/// The student pastes any job description; the Edge LM extracts the role
/// requirement vector and composes a readiness narrative — entirely on
/// the device, so it works offline and the JD never leaves the phone.
class JobFitScreen extends StatefulWidget {
  final LearnerProfile profile;

  const JobFitScreen({super.key, required this.profile});

  @override
  State<JobFitScreen> createState() => _JobFitScreenState();
}

class _JobFitScreenState extends State<JobFitScreen> {
  final _jdController = TextEditingController();
  bool _analyzing = false;
  JdAnalysis? _analysis;
  String? _explanation;
  double _score = 0;
  List<SkillGap> _gaps = const [];

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _jdController.text.trim();
    if (text.isEmpty) return;
    setState(() => _analyzing = true);
    final analysis = await edgeLm.analyzeJobDescription(text);
    final score = matchScore(widget.profile, analysis.role);
    final gaps = detectGaps(widget.profile, analysis.role);
    final explanation = await edgeLm.explainMatch(
      profile: widget.profile,
      role: analysis.role,
      score: score,
      gaps: gaps,
    );
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      _analysis = analysis;
      _score = score;
      _gaps = gaps;
      _explanation = explanation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Job fit check')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.memory, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Processed on your device by '
                          '${edgeLm.modelName}. The job description never '
                          'leaves your phone.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _jdController,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Paste a job description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: _analyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                          _analyzing ? 'Analyzing…' : 'Analyze on-device'),
                      onPressed: _analyzing ? null : _analyze,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        _jdController.text = kSampleJobDescription,
                    child: const Text('Sample JD'),
                  ),
                ],
              ),
              if (_analysis != null && _explanation != null) ...[
                const SizedBox(height: 24),
                _ResultCard(
                  analysis: _analysis!,
                  score: _score,
                  explanation: _explanation!,
                ),
                const SizedBox(height: 16),
                if (_gaps.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('Your growth plan for this role',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  for (final gap in _gaps) ...[
                    GapTile(gap: gap),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final JdAnalysis analysis;
  final double score;
  final String explanation;

  const _ResultCard({
    required this.analysis,
    required this.score,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score,
                        strokeWidth: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                      Center(
                        child: Text('${(score * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(analysis.role.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text('Fit score from your verified passport',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(explanation,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('Signals detected in the job description',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final term in analysis.allTerms.take(12))
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
}
