import 'package:flutter/material.dart';

import '../services/edge_lm/edge_lm.dart';
import '../services/edge_lm/edge_model_manager.dart';

/// Manage the real on-device model (Edge LM): download a Gemma model from
/// Hugging Face, load it into memory, run a smoke test, or revert to the
/// built-in lexicon engine.
class EdgeModelScreen extends StatefulWidget {
  const EdgeModelScreen({super.key});

  @override
  State<EdgeModelScreen> createState() => _EdgeModelScreenState();
}

class _EdgeModelScreenState extends State<EdgeModelScreen> {
  final _tokenController = TextEditingController();
  final Map<String, bool> _installed = {};
  final Map<String, int> _downloadProgress = {};
  String? _busyId;
  String? _status;

  @override
  void initState() {
    super.initState();
    _refreshInstalled();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _refreshInstalled() async {
    for (final option in kEdgeModels) {
      bool installed;
      try {
        installed = await EdgeModelManager.instance.isInstalled(option);
      } catch (_) {
        installed = false;
      }
      if (!mounted) return;
      setState(() => _installed[option.id] = installed);
    }
  }

  Future<void> _download(EdgeModelOption option) async {
    setState(() {
      _busyId = option.id;
      _downloadProgress[option.id] = 0;
      _status = 'Downloading ${option.displayName}…';
    });
    try {
      await EdgeModelManager.instance.download(
        option,
        huggingFaceToken: _tokenController.text.trim(),
        onProgress: (percent) {
          if (mounted) {
            setState(() => _downloadProgress[option.id] = percent);
          }
        },
      );
      setState(() => _status = '${option.displayName} downloaded.');
    } catch (e) {
      final message = e.toString();
      final authFailure = message.contains('401') ||
          message.contains('403') ||
          message.toLowerCase().contains('auth');
      setState(() => _status = authFailure && option.gated
          ? 'Download failed: this model is license-gated on Hugging '
            'Face. To use it: (1) sign in at huggingface.co and open '
            '${option.repoPage}, (2) accept the Gemma license on that '
            'page, (3) create an access token with "Read access to '
            'contents of all public gated repos" enabled, and paste it '
            'above. Alternatively, use a Qwen model: no account needed.'
          : 'Download failed: $e');
    } finally {
      setState(() {
        _busyId = null;
        _downloadProgress.remove(option.id);
      });
      await _refreshInstalled();
    }
  }

  Future<void> _activate(EdgeModelOption option) async {
    setState(() {
      _busyId = option.id;
      _status = 'Loading ${option.displayName} into memory…';
    });
    try {
      final name = await EdgeModelManager.instance.activate(option);
      setState(() => _status = 'Active engine: $name');
    } catch (e) {
      setState(() => _status = 'Load failed: $e');
    } finally {
      setState(() => _busyId = null);
    }
  }

  Future<void> _smokeTest() async {
    setState(() => _status = 'Running on-device smoke test…');
    try {
      final analysis = await edgeLm.analyzeJobDescription(
          'Data analyst role: SQL, statistics, dashboards, communication.');
      final top = analysis.role.required.entries.reduce(
          (a, b) => a.value >= b.value ? a : b);
      setState(() => _status =
          'Smoke test OK (${edgeLm.modelName}). Top requirement: '
          '${top.key} ${(top.value * 100).round()}%.');
    } catch (e) {
      setState(() => _status = 'Smoke test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slmActive = EdgeLmRuntime.instance.isSlmActive;
    return Scaffold(
      appBar: AppBar(title: const Text('Edge AI model')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(
                    slmActive ? Icons.memory : Icons.abc,
                    color: scheme.primary,
                  ),
                  title: Text('Active engine: ${edgeLm.modelName}'),
                  subtitle: Text(slmActive
                      ? 'Real on-device language model inference.'
                      : 'Deterministic lexicon engine (no model loaded). '
                        'Download and load a model below for real SLM '
                        'inference.'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Hugging Face token (optional)',
                  helperText:
                      'Only needed if a model repository is gated.',
                ),
              ),
              const SizedBox(height: 16),
              for (final option in kEdgeModels) ...[
                _modelCard(option),
                const SizedBox(height: 12),
              ],
              if (slmActive) ...[
                const SizedBox(height: 4),
                FilledButton.icon(
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('Run on-device smoke test'),
                  onPressed: _busyId == null ? _smokeTest : null,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Revert to lexicon engine'),
                  onPressed: _busyId == null
                      ? () async {
                          await EdgeModelManager.instance.deactivate();
                          setState(() =>
                              _status = 'Reverted to lexicon engine.');
                        }
                      : null,
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_status!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Models run fully on this device after download; job '
                'descriptions and passport data are never uploaded. '
                'Downloads come from Hugging Face (LiteRT community '
                'conversions of Gemma 3) and happen once.',
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

  Widget _modelCard(EdgeModelOption option) {
    final installed = _installed[option.id] ?? false;
    final progress = _downloadProgress[option.id];
    final busy = _busyId != null;
    final isLoaded =
        EdgeModelManager.instance.loadedModelId == option.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(option.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (isLoaded)
                  Chip(
                    label: const Text('Loaded'),
                    visualDensity: VisualDensity.compact,
                  )
                else if (installed)
                  Chip(
                    label: const Text('Downloaded'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${option.sizeNote} · ${option.deviceNote}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (progress != null) ...[
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 4),
              Text('$progress%',
                  style: Theme.of(context).textTheme.labelSmall),
            ] else
              Row(
                children: [
                  if (!installed)
                    FilledButton.tonal(
                      onPressed: busy ? null : () => _download(option),
                      child: const Text('Download'),
                    )
                  else ...[
                    FilledButton(
                      onPressed:
                          busy || isLoaded ? null : () => _activate(option),
                      child: Text(isLoaded ? 'Active' : 'Load & use'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () async {
                              await EdgeModelManager.instance
                                  .uninstall(option);
                              await _refreshInstalled();
                              setState(() {});
                            },
                      child: const Text('Remove'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
