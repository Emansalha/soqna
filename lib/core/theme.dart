import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sneaker store identity: dark ink + warm bone + ember orange
class AppColors {
  static const ink = Color(0xFF111014);
  static const ink2 = Color(0xFF1E1C22);
  static const ink3 = Color(0xFF2C2A31);
  static const bone = Color(0xFFF4F1EB);
  static const sand = Color(0xFFE9E3D8);
  static const sand2 = Color(0xFFDCD3C4);
  static const surface = Colors.white;
  static const ember = Color(0xFFFF5A1F);
  static const emberDark = Color(0xFFE2420A);
  static const emberSoft = Color(0xFFFFE8DE);
  static const text = Color(0xFF16141A);
  static const muted = Color(0xFF8C867D);
  static const body = Color(0xFF5D5850); // long-form body text
  static const line = Color(0xFFE6E0D6);
  static const success = Color(0xFF1FA971);
  static const danger = Color(0xFFE5484D);

  // Supporting tones — all tuned to sit with ink / bone / ember
  static const gold = Color(0xFFD9A441); // pending, ratings
  static const amber = Color(0xFFF08A3C); // in-progress
  static const slate = Color(0xFF6B7A8F); // neutral info
  static const mint = Color(0xFF6EE7B7); // positive on dark surfaces

  static const emberGradient = LinearGradient(
    colors: [Color(0xFFFF7A3D), ember],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  static const inkGradient = LinearGradient(
    colors: [ink3, ink],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  /// Soft alternating tints for sneaker cards
  static const tints = [
    Color(0xFFEDE8DF),
    Color(0xFFE4E7EA),
    Color(0xFFF1E4DC),
    Color(0xFFE6E4DD),
    Color(0xFFEAE2E6),
  ];
  static Color tint(int i) => tints[i.abs() % tints.length];
}

class AppTheme {
  static TextStyle font({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double? height,
    double? spacing,
  }) =>
      GoogleFonts.readexPro(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );

  /// Outlined text (stroke only) — for big decorative numbers and words
  static TextStyle outline({
    required double size,
    Color color = Colors.white,
    double stroke = 1.5,
    double? height,
  }) =>
      GoogleFonts.readexPro(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: height,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color,
      );

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        primary: AppColors.ink,
        secondary: AppColors.ember,
        surface: AppColors.bone,
      ),
      scaffoldBackgroundColor: AppColors.bone,
      splashFactory: InkSparkle.splashFactory,
      // Soft ember ripples, no grey square highlights
      splashColor: AppColors.ember.withValues(alpha: .14),
      highlightColor: Colors.transparent,
      hoverColor: AppColors.ember.withValues(alpha: .06),
    );
    final text = GoogleFonts.readexProTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bone,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.text,
        titleTextStyle: font(size: 18, weight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: font(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.ink, 1.4),
        errorBorder: border(AppColors.danger),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: font(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bone,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          highlightColor: AppColors.ember.withValues(alpha: .12),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.ember),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.ember,
        selectionColor: AppColors.ember.withValues(alpha: .25),
        selectionHandleColor: AppColors.ember,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.ember : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.ember : AppColors.sand2),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

String money(num v, {String currency = '₪'}) {
  final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  return '$s $currency';
}

void showMsg(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: error ? const Color(0xFFFF9A9D) : AppColors.ember, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    ));
}
