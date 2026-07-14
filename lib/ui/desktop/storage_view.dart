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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Storage & limits',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                'How SannDrive uses your Telegram account — and keeps it in good standing.',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              const _LimitRow(
                icon: Iconsax.document_upload,
                title: 'Up to 2 GB per file',
                body:
                    '4 GB with Telegram Premium. There is no cap on total storage — upload as much as you like.',
              ),
              const _LimitRow(
                icon: Iconsax.shield_tick,
                title: 'Uploads are paced to protect your account',
                body:
                    'SannDrive uploads one file at a time with a short pause between files, and automatically slows down when Telegram asks (FLOOD_WAIT). This keeps your account in good standing.',
              ),
              const _LimitRow(
                icon: Iconsax.warning_2,
                title: 'Avoid mass-dumping files',
                body:
                    'Pushing thousands of files at once can still get an account temporarily limited. Add large libraries in smaller batches.',
              ),
              const _LimitRow(
                icon: Iconsax.key,
                title: 'This is your Telegram account, not a backup',
                body:
                    'Files live in your own Telegram account. If the account is lost or banned, the files go with it — keep copies of anything irreplaceable.',
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
