import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme.dart';
import 'job_fit_screen.dart';
import 'share_screen.dart';

class PassportScreen extends StatelessWidget {
  final LearnerProfile profile;

  const PassportScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My learning passport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline),
            tooltip: 'Job fit check (on-device AI)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JobFitScreen(profile: profile),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Share via QR'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ShareScreen(profile: profile)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              _header(context),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Skill profile'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      for (final dim in kSkillDimensions) ...[
                        _SkillRow(
                            label: dim, value: profile.skills[dim] ?? 0),
                        if (dim != kSkillDimensions.last)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'VLE engagement — weekly activity'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                  child: SizedBox(
                    height: 160,
                    child: _EngagementChart(clicks: profile.weeklyClicks),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Verified module record'),
              for (final module in profile.modules) ...[
                _ModuleTile(module: module),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              _sectionTitle(context, 'External certifications'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cert in profile.certifications)
                    Chip(
                      avatar: Icon(Icons.verified_outlined,
                          size: 18, color: scheme.primary),
                      label: Text(cert),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                profile.name.split(' ').map((w) => w[0]).take(2).join(),
                style: TextStyle(
                    fontSize: 20, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(profile.programme,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(profile.institution,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ResultChip(result: profile.finalResult),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              size: 16, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text('Institution verified',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.primary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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
}

class _SkillRow extends StatelessWidget {
  final String label;
  final double value;

  const _SkillRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text('${(value * 100).round()}%',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _EngagementChart extends StatelessWidget {
  final List<int> clicks;

  const _EngagementChart({required this.clicks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (clicks.isEmpty) {
      return Center(
        child: Text('Engagement data not shared',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.surfaceContainerHighest,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('W${value.toInt() + 1}',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var week = 0; week < clicks.length; week++)
                FlSpot(week.toDouble(), clicks[week].toDouble()),
            ],
            isCurved: true,
            color: scheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final ModuleRecord module;

  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(module.code,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(module.title,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${module.presentation} · TMA avg '
                    '${module.tmaAverage.round()}'
                    '${module.examScore != null ? ' · Exam ${module.examScore!.round()}' : ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            _ResultChip(result: module.result),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String result;

  const _ResultChip({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = resultColor(result, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(result,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
