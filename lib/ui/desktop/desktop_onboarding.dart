import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/controllers/setup_controller.dart';
import '../../shared/services/telegram/credentials.dart';
import '../../theme/desktop_theme.dart';

class DesktopOnboarding extends ConsumerStatefulWidget {
  const DesktopOnboarding({super.key});

  @override
  ConsumerState<DesktopOnboarding> createState() => _DesktopOnboardingState();
}

class _DesktopOnboardingState extends ConsumerState<DesktopOnboarding> {
  final _apiId = TextEditingController();
  final _apiHash = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _apiId.dispose();
    _apiHash.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final id = parseApiId(_apiId.text);
    if (id == null) {
      setState(() => _error = 'API ID should be a positive number.');
      return;
    }
    if (!isValidApiHash(_apiHash.text)) {
      setState(() => _error =
          'API hash should be the 32-character key from my.telegram.org.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    await ref.read(setupControllerProvider.notifier).saveCredentials(
        TgCredentials(apiId: id, apiHash: _apiHash.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DesktopTheme.dark,
      child: Builder(builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                width: 460,
                padding: const EdgeInsets.fromLTRB(36, 40, 36, 28),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child:
                            Icon(Iconsax.key, size: 30, color: scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Connect your Telegram',
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'SannDrive uses your own Telegram API credentials.\n'
                        'Create them free at my.telegram.org → API development '
                        'tools, then paste them here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('API ID',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiId,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '1234567'),
                    ),
                    const SizedBox(height: 16),
                    Text('API hash',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiHash,
                      onSubmitted: (_) => _continue(),
                      decoration:
                          const InputDecoration(hintText: '32-character key'),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      'my.telegram.org',
                      style: TextStyle(fontSize: 12.5, color: scheme.primary),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: scheme.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : _continue,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => ref
                              .read(setupControllerProvider.notifier)
                              .useDemo(),
                      child: const Text('Try the demo instead'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
