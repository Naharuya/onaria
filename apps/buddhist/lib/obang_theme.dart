import 'package:flutter/material.dart';

/// Obangsaek interpreted as restrained UI accents, not scripture symbolism.
abstract final class ObangTheme {
  static const blue = Color(0xff234E70);
  static const red = Color(0xffA43F36);
  static const yellow = Color(0xffE6BA54);
  static const white = Color(0xffFFFCF5);
  static const black = Color(0xff242A2D);
  static const paper = Color(0xffF4F0E7);
  static const line = Color(0xffD9D3C7);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      onPrimary: white,
      secondary: red,
      onSecondary: white,
      tertiary: yellow,
      onTertiary: black,
      surface: white,
      onSurface: black,
      primaryContainer: const Color(0xffDFEAF1),
      onPrimaryContainer: blue,
      outline: const Color(0xff76736B),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      textTheme:
          base.textTheme.apply(bodyColor: black, displayColor: black).copyWith(
                headlineMedium: const TextStyle(
                    fontSize: 28,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: black),
                titleMedium: const TextStyle(
                    fontSize: 18,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: black),
                bodyMedium:
                    const TextStyle(fontSize: 15, height: 1.65, color: black),
              ),
      appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: black,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: blue, width: 2)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: white,
        selectedColor: const Color(0xffDFEAF1),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: white, indicatorColor: yellow, elevation: 0),
      dividerTheme: const DividerThemeData(color: line),
    );
  }
}

class ObangBand extends StatelessWidget {
  const ObangBand({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
            height: 4,
            child: Row(children: [
              for (final color in [
                ObangTheme.blue,
                ObangTheme.red,
                ObangTheme.yellow,
                ObangTheme.white,
                ObangTheme.black
              ])
                Expanded(
                    child: ColoredBox(
                        color: color, child: const SizedBox.expand())),
            ])),
      );
}
