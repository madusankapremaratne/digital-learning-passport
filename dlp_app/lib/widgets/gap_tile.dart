import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/models.dart';

/// One detected skill gap: severity bar plus learning recommendation.
/// Used by both the recruiter candidate view and the student job fit
/// check.
class GapTile extends StatelessWidget {
  final SkillGap gap;

  const GapTile({super.key, required this.gap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final severe = gap.severity > 0.25;
    final color =
        severe ? const Color(0xFFA32D2D) : const Color(0xFF854F0B);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(gap.skill,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '-${(gap.severity * 100).round()} pts',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: gap.actual / (gap.required == 0 ? 1 : gap.required),
                minHeight: 6,
                color: color,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              skillRecommendations[gap.skill] ?? '',
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
}
