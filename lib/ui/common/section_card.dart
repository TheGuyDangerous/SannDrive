import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.size = 18});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size, color: primary),
    );
  }
}

class IconBadgeRow extends StatelessWidget {
  const IconBadgeRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.base, vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.meta(context)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: row,
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.icon,
    this.title,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final IconData? icon;
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.base, AppSpace.base, AppSpace.base, AppSpace.half),
              child: Row(
                children: [
                  if (icon != null) ...[
                    IconBadge(icon: icon!),
                    const SizedBox(width: 12),
                  ],
                  Text(title!,
                      style: GoogleFonts.raleway(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
