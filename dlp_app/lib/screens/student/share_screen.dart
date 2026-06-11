import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/models.dart';
import '../../services/passport_codec.dart';

/// Consent-controlled QR sharing: the student decides what enters the
/// payload before it is generated. The QR encodes a signed, self-contained
/// passport that the recruiter app can verify offline.
class ShareScreen extends StatefulWidget {
  final LearnerProfile profile;

  const ShareScreen({super.key, required this.profile});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  bool _includeScores = true;
  bool _includeEngagement = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final payload = encodePassport(
      widget.profile,
      includeScores: _includeScores,
      includeEngagement: _includeEngagement,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Share passport')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: payload,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(widget.profile.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        'Signed passport · verifiable offline',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('You control what is shared',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Assessment scores'),
                subtitle:
                    const Text('Module TMA averages and exam results'),
                value: _includeScores,
                onChanged: (v) => setState(() => _includeScores = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Engagement trail'),
                subtitle: const Text('Weekly VLE activity pattern'),
                value: _includeEngagement,
                onChanged: (v) => setState(() => _includeEngagement = v),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy payload (for demo without camera)'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: payload));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Passport payload copied')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'The QR contains a signed snapshot of your passport. '
                'Recruiters see only what you enable above; your consent '
                'choices are embedded at generation time.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
