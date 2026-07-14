import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/controllers/setup_controller.dart';
import '../../shared/core/env.dart';
import '../../shared/services/telegram/credentials.dart';
import '../../theme/app_theme.dart';
import '../common/brand_mark.dart';

class MobileOnboarding extends ConsumerStatefulWidget {
  const MobileOnboarding({super.key});

  @override
  ConsumerState<MobileOnboarding> createState() => _MobileOnboardingState();
}

class _MobileOnboardingState extends ConsumerState<MobileOnboarding> {
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
      setState(() => _error = 'api_id should be a positive number.');
      return;
    }
    if (!isValidApiHash(_apiHash.text)) {
      setState(() =>
          _error = 'api_hash should be the 32-character key from my.telegram.org.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    await ref
        .read(setupControllerProvider.notifier)
        .saveCredentials(TgCredentials(apiId: id, apiHash: _apiHash.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GridBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandMark(size: 68)),
                      const SizedBox(height: AppSpace.base),
                      Center(
                        child: Text(Env.appName,
                            style: AppText.wordmark(context, size: 22)),
                      ),
                      const SizedBox(height: AppSpace.section),
                      Text('Connect your Telegram',
                          textAlign: TextAlign.center,
                          style: AppText.screenTitle(context)),
                      const SizedBox(height: AppSpace.half),
                      Text(
                        'SannDrive uses your own Telegram API credentials. '
                        'Create them free at my.telegram.org → API development '
                        'tools, then paste them here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            height: 1.5,
                            color: scheme.onSurface.withOpacity(0.65)),
                      ),
                      const SizedBox(height: AppSpace.hero),
                      TextField(
                        controller: _apiId,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(hintText: 'api_id'),
                      ),
                      const SizedBox(height: AppSpace.base),
                      TextField(
                        controller: _apiHash,
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _continue(),
                        decoration: const InputDecoration(hintText: 'api_hash'),
                      ),
                      const SizedBox(height: AppSpace.base),
                      Center(
                        child: SelectableText('my.telegram.org',
                            style: TextStyle(
                                fontSize: 13, color: scheme.primary)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: scheme.error, fontSize: 13)),
                      ],
                      const SizedBox(height: AppSpace.hero),
                      FilledButton.tonal(
                        onPressed: _saving ? null : _continue,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Continue'),
                      ),
                      const SizedBox(height: AppSpace.half),
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
          ),
        ],
      ),
    );
  }
}
