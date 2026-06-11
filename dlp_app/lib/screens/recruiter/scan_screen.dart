import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/demo_data.dart';
import '../../services/passport_codec.dart';
import 'candidate_screen.dart';

/// Recruiter entry point (IIDLP): scan a candidate's passport QR.
/// Falls back to pasting the payload (web demos, devices without a
/// camera) and offers a bundled sample candidate for one-device demos.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _pasteController = TextEditingController();
  bool _handled = false;
  String? _error;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _open(String raw) {
    final decoded = decodePassport(raw);
    if (decoded == null) {
      setState(() => _error = 'Not a valid DLP passport payload.');
      return;
    }
    if (_handled) return;
    _handled = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CandidateScreen(decoded: decoded),
          ),
        )
        .then((_) => _handled = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IIDLP — scan candidate'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Camera'),
            Tab(icon: Icon(Icons.content_paste), text: 'Paste code'),
          ]),
        ),
        body: TabBarView(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final value = capture.barcodes.firstOrNull?.rawValue;
                if (value != null) _open(value);
              },
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextField(
                      controller: _pasteController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Paste passport payload',
                        errorText: _error,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Open candidate profile'),
                      onPressed: () => _open(_pasteController.text),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                    ]),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_search),
                      label: const Text('Load sample candidate'),
                      onPressed: () =>
                          _open(encodePassport(demoLearners.first)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
