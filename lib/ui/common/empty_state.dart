import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';
import 'brand_mark.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsingBrandMark(),
            const SizedBox(height: AppSpace.hero),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpace.half),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    height: 1.5,
                    color: scheme.onSurface.withOpacity(0.65))),
            if (action != null) ...[
              const SizedBox(height: AppSpace.hero),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ShimmerTiles extends StatelessWidget {
  const ShimmerTiles({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerHighest.withOpacity(0.4),
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 72,
                padding: const EdgeInsets.all(AppSpace.base),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 12,
                            width: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 10,
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SkeletonThenEmpty extends StatefulWidget {
  const SkeletonThenEmpty({
    super.key,
    required this.empty,
    this.delay = const Duration(milliseconds: 1200),
  });

  final EmptyState empty;
  final Duration delay;

  @override
  State<SkeletonThenEmpty> createState() => _SkeletonThenEmptyState();
}

class _SkeletonThenEmptyState extends State<SkeletonThenEmpty> {
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _loading = false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _loading
          ? const Align(
              key: ValueKey('skeleton'),
              alignment: Alignment.topCenter,
              child: ShimmerTiles(),
            )
          : widget.empty,
    );
  }
}
