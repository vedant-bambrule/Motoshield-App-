import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF0D1017);
  static const ink2 = Color(0xFF151A23);
  static const surface = Color(0xFF1B212C);
  static const surface2 = Color(0xFF232A37);
  static const line = Color(0x14FFFFFF);
  static const lineStrong = Color(0x24FFFFFF);
  static const text = Color(0xFFF2F3F5);
  static const textDim = Color(0xFF9AA1AE);
  static const textFaint = Color(0xFF6B7280);

  static const orange = Color(0xFFFF5A1F);
  static const orangeDim = Color(0x29FF5A1F);
  static const green = Color(0xFF2BD97A);
  static const greenDim = Color(0x242BD97A);
  static const red = Color(0xFFFF3B4E);
  static const redDim = Color(0x29FF3B4E);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.ink,
        colorScheme: const ColorScheme.dark(primary: AppColors.orange, secondary: AppColors.green, error: AppColors.red, surface: AppColors.surface),
        useMaterial3: true,
      );
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, letterSpacing: 1.2, color: AppColors.textFaint));
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? bg;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderColor, this.bg});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: bg ?? AppColors.surface, border: Border.all(color: borderColor ?? AppColors.line), borderRadius: BorderRadius.circular(20)),
        child: child,
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const Pill({super.key, required this.text, required this.color, required this.bg});
  factory Pill.green(String t) => Pill(text: t, color: AppColors.green, bg: AppColors.greenDim);
  factory Pill.orange(String t) => Pill(text: t, color: AppColors.orange, bg: AppColors.orangeDim);
  factory Pill.red(String t) => Pill(text: t, color: AppColors.red, bg: AppColors.redDim);
  factory Pill.dim(String t) => Pill(text: t, color: AppColors.textDim, bg: AppColors.surface2);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      );
}
