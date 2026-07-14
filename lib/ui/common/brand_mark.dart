import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(0.10),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Iconsax.cloud, color: AppColors.brand, size: size * 0.55),
    );
  }
}

class PulsingBrandMark extends StatefulWidget {
  const PulsingBrandMark({super.key, this.size = 64});

  final double size;

  @override
  State<PulsingBrandMark> createState() => _PulsingBrandMarkState();
}

class _PulsingBrandMarkState extends State<PulsingBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: 0.8 + 0.2 * t,
          child: Transform.scale(scale: 0.95 + 0.1 * t, child: child),
        );
      },
      child: BrandMark(size: widget.size),
    );
  }
}

class GridBackdrop extends StatelessWidget {
  const GridBackdrop({super.key, this.spacing = 36});

  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(spacing),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.spacing);

  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.spacing != spacing;
}
