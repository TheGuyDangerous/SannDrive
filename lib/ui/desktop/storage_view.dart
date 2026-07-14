import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class StorageView extends StatelessWidget {
  const StorageView({super.key});

  static const _cats = [
    (icon: Iconsax.video, label: 'Video', count: 32, size: '5.1 GB', frac: 0.41),
    (icon: Iconsax.music, label: 'Audio', count: 87, size: '2.3 GB', frac: 0.19),
    (icon: Iconsax.gallery, label: 'Image', count: 640, size: '2.9 GB', frac: 0.23),
    (
      icon: Iconsax.document_text,
      label: 'Document',
      count: 214,
      size: '780 MB',
      frac: 0.06
    ),
    (
      icon: Iconsax.archive_1,
      label: 'Archive',
      count: 12,
      size: '1.1 GB',
      frac: 0.09
    ),
    (icon: Iconsax.document, label: 'Other', count: 19, size: '240 MB', frac: 0.02),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    Icon(Iconsax.cloud, size: 30, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 28),
              const _HeroStat(label: 'Used Space', value: '12.4 GB'),
              const SizedBox(width: 56),
              const _HeroStat(label: 'Total Files', value: '1,004'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 152,
          ),
          itemCount: _cats.length,
          itemBuilder: (context, i) {
            final c = _cats[i];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(c.icon,
                        size: 20, color: scheme.onSecondaryContainer),
                  ),
                  const Spacer(),
                  Text(c.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    '${c.count} files · ${c.size}',
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: c.frac,
                      minHeight: 2,
                      backgroundColor: scheme.outlineVariant.withOpacity(0.6),
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
        ),
      ],
    );
  }
}
