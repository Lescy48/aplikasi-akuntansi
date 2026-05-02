import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary     = Color(0xFF4F8EF7);
  static const Color primaryDeep = Color(0xFF2563EB);
  static const Color secondary   = Color(0xFF818CF8);

  static const Color success     = Color(0xFF34D399);
  static const Color successDeep = Color(0xFF059669);
  static const Color danger      = Color(0xFFF87171);
  static const Color dangerDeep  = Color(0xFFDC2626);
  static const Color warning     = Color(0xFFFBBF24);

  // ── LIGHT ─────────────────────────────────────────────────
  static const Color bgLight       = Color(0xFFEEF2FF);
  static const Color surfaceLight  = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFF7F9FF);
  static const Color textPrimLight = Color(0xFF0F172A);
  static const Color textSecLight  = Color(0xFF64748B);
  static const Color textHintLight = Color(0xFFB0BEC5);

  // ── DARK ──────────────────────────────────────────────────
  static const Color bgDark       = Color(0xFF0B1120);
  static const Color surfaceDark  = Color(0xFF141E2E);
  static const Color surface2Dark = Color(0xFF1C2A3E);
  static const Color textPrimDark = Color(0xFFE2E8F0);
  static const Color textSecDark  = Color(0xFF7A8FA6);
  static const Color textHintDark = Color(0xFF3D5166);

  // ── GRADIENTS ─────────────────────────────────────────────
  static const LinearGradient gradientBg = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFDCEEFD)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gradientBgDark = LinearGradient(
    colors: [Color(0xFF0B1120), Color(0xFF111827)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF6C63FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gradientDanger = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Helper warna dari context
  static Color bg(BuildContext ctx) =>
      ctx.isDark ? bgDark : bgLight;
  static Color surface(BuildContext ctx) =>
      ctx.isDark ? surfaceDark : surfaceLight;
  static Color surface2(BuildContext ctx) =>
      ctx.isDark ? surface2Dark : surface2Light;
  static Color textPrim(BuildContext ctx) =>
      ctx.isDark ? textPrimDark : textPrimLight;
  static Color textSec(BuildContext ctx) =>
      ctx.isDark ? textSecDark : textSecLight;
  static Color textHint(BuildContext ctx) =>
      ctx.isDark ? textHintDark : textHintLight;
  static Color divider(BuildContext ctx) => ctx.isDark
      ? Colors.white.withOpacity(0.07)
      : Colors.black.withOpacity(0.06);

  // ── THEMES ────────────────────────────────────────────────
  static ThemeData lightTheme = _buildTheme(Brightness.light);
  static ThemeData darkTheme  = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? bgDark : bgLight,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: brightness)
          .copyWith(primary: primary, secondary: secondary,
              surface: isDark ? surfaceDark : surfaceLight),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
            color: isDark ? textPrimDark : textPrimLight,
            fontWeight: FontWeight.w700, fontSize: 18),
        iconTheme: IconThemeData(color: isDark ? textPrimDark : textPrimLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceDark : surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.indigo.withOpacity(0.15))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.indigo.withOpacity(0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: danger, width: 2)),
        hintStyle: TextStyle(color: isDark ? textHintDark : textHintLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      )),
    );
  }
}

// Extension untuk kemudahan cek dark mode
extension BuildContextTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ── ELEVATED CARD ─────────────────────────────────────────
class ElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const ElevatedCard({
    super.key, required this.child,
    this.padding, this.radius = 18,
    this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cardColor = color ?? (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isDark
              ? [
                  BoxShadow(color: Colors.black.withOpacity(0.4),
                      blurRadius: 16, offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.black.withOpacity(0.2),
                      blurRadius: 4, offset: const Offset(0, 1)),
                ]
              : [
                  BoxShadow(color: const Color(0xFF4F8EF7).withOpacity(0.08),
                      blurRadius: 20, offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 6, offset: const Offset(0, 2)),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Alias agar kode lama tidak error
class GlassCard extends ElevatedCard {
  const GlassCard({
    super.key, required super.child,
    super.padding, double borderRadius = 18,
    super.color, super.onTap,
  }) : super(radius: borderRadius);
}