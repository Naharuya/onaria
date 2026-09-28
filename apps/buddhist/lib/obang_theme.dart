import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ONARIA's dark surfaces, 20px shapes and 54px actions in Obangsaek.
abstract final class ObangTheme {
  static const blue = Color(0xff80BCE0);
  static const red = Color(0xffEF9588);
  static const yellow = Color(0xffE6BA54);
  static const white = Color(0xffFAF6ED);
  static const black = Color(0xff111820);
  static const paper = black;
  static const line = Color(0xff455363);
  static ThemeData get theme {
    final scheme =
        ColorScheme.fromSeed(seedColor: yellow, brightness: Brightness.dark)
            .copyWith(
      primary: yellow,
      onPrimary: black,
      secondary: blue,
      onSecondary: black,
      tertiary: red,
      onTertiary: black,
      surface: black,
      onSurface: white,
      surfaceContainer: const Color(0xff202C39),
      primaryContainer: const Color(0xff2D3D4D),
      onPrimaryContainer: white,
      onSurfaceVariant: const Color(0xffCCD5DF),
      outlineVariant: line,
      error: red,
    );
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: black,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light),
      cardTheme: CardThemeData(
          color: scheme.surfaceContainer,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: shape.copyWith(side: const BorderSide(color: line))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: shape,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 50),
              shape: shape,
              side: const BorderSide(color: line),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainer,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: yellow, width: 2))),
      chipTheme: ChipThemeData(
          backgroundColor: scheme.surfaceContainer,
          selectedColor: scheme.primaryContainer,
          side: const BorderSide(color: line),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          labelStyle:
              const TextStyle(color: white, fontWeight: FontWeight.w600),
          showCheckmark: true,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12)),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: black,
          indicatorColor: scheme.primaryContainer,
          elevation: 0),
      dividerTheme: const DividerThemeData(color: line),
    );
  }
}

class ObangBand extends StatelessWidget {
  const ObangBand({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: SizedBox(
          height: 3,
          child: Row(children: [
            for (final color in [
              ObangTheme.blue,
              ObangTheme.red,
              ObangTheme.yellow,
              ObangTheme.white,
              ObangTheme.black
            ])
              Expanded(
                  child:
                      ColoredBox(color: color, child: const SizedBox.expand())),
          ])));
}

class ObangSky extends StatelessWidget {
  const ObangSky({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: ExcludeSemantics(
                child: RepaintBoundary(
                    child: CustomPaint(painter: _SkyPainter())))),
        child,
      ]);
}

class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = ObangTheme.black);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
              center: const Alignment(.8, -.7),
              radius: 1.2,
              colors: [
                ObangTheme.blue.withValues(alpha: .18),
                ObangTheme.black
              ]).createShader(rect));
    final random = math.Random(27);
    for (var i = 0; i < 100; i++) {
      canvas.drawCircle(
          Offset(random.nextDouble() * size.width,
              random.nextDouble() * size.height),
          i % 9 == 0 ? 1.2 : .6,
          Paint()
            ..color = ObangTheme.white
                .withValues(alpha: .12 + random.nextDouble() * .25));
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => false;
}
