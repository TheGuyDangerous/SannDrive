import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class FloodWaitCopy {
  FloodWaitCopy._();

  static const title = 'Telegram asked us to slow down';

  static String resumeIn(int seconds) =>
      'Resuming automatically in ${seconds}s — this keeps your account safe.';
}

class FloodCountdown extends StatefulWidget {
  const FloodCountdown({
    super.key,
    required this.untilEpochMs,
    required this.builder,
  });

  final int untilEpochMs;
  final Widget Function(BuildContext context, int secondsLeft) builder;

  @override
  State<FloodCountdown> createState() => _FloodCountdownState();
}

class _FloodCountdownState extends State<FloodCountdown> {
  Timer? _timer;

  int get _secondsLeft {
    final ms = widget.untilEpochMs - DateTime.now().millisecondsSinceEpoch;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _secondsLeft);
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, height: 1.35, color: scheme.error),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: scheme.error,
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class FloodWaitBanner extends StatelessWidget {
  const FloodWaitBanner({super.key, required this.untilEpochMs, this.dense = false});

  final int untilEpochMs;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloodCountdown(
      untilEpochMs: untilEpochMs,
      builder: (context, seconds) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 16, vertical: dense ? 10 : 14),
        decoration: BoxDecoration(
          color: scheme.tertiary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(dense ? 10 : 14),
        ),
        child: Row(
          children: [
            Icon(Iconsax.timer_1, size: dense ? 18 : 20, color: scheme.tertiary),
            SizedBox(width: dense ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FloodWaitCopy.title,
                    style: TextStyle(
                      fontSize: dense ? 12.5 : 13.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FloodWaitCopy.resumeIn(seconds),
                    style: TextStyle(
                      fontSize: dense ? 11.5 : 12,
                      height: 1.3,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
