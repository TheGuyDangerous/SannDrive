import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const brand = Color(0xFF7EB6FF);
}

class AppSpace {
  static const half = 8.0;
  static const base = 16.0;
  static const page = 20.0;
  static const hero = 24.0;
  static const section = 32.0;
}

class AppText {
  static TextStyle wordmark(BuildContext context, {double size = 18}) =>
      GoogleFonts.raleway(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.2,
      );

  static TextStyle screenTitle(BuildContext context) => GoogleFonts.raleway(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle sectionTitle(BuildContext context) => GoogleFonts.raleway(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle meta(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 12,
      height: 1.4,
      color: scheme.onSurface.withOpacity(0.65),
    );
  }
}

class _FadeTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeTransitionsBuilder(),
          TargetPlatform.iOS: _FadeTransitionsBuilder(),
          TargetPlatform.windows: _FadeTransitionsBuilder(),
          TargetPlatform.macOS: _FadeTransitionsBuilder(),
          TargetPlatform.linux: _FadeTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: InputBorder.none,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.4)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.05),
        side: BorderSide(color: scheme.onSurface.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary.withOpacity(0.10),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
      ),
      dialogTheme: DialogTheme(
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
