import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Adapts to the logical short side; rotation and the keyboard never masquerade as a tablet.
class DeviceTextScaler extends TextScaler {
  const DeviceTextScaler(this.platform, this.shortSide);
  final TextScaler platform;
  final double shortSide;

  static double factorFor(double side) {
    if (!side.isFinite || side <= 0) return 1;
    if (side <= 320) return .94;
    if (side < 390) return .94 + (side - 320) / 70 * .06;
    if (side < 600) return 1 + (side - 390) / 210 * .06;
    if (side < 900) return 1.06 + (side - 600) / 300 * .06;
    return 1.12;
  }

  @override
  double scale(double fontSize) {
    final device = factorFor(shortSide);
    // Never reduce body text, small labels or accessibility preferences.
    final factor = fontSize <= 20 ? math.max(1.0, device) : device;
    return platform.scale(fontSize * factor);
  }

  @override
  double get textScaleFactor => scale(14) / 14;
}

class ResponsiveTypography extends StatelessWidget {
  const ResponsiveTypography({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inherited = media.textScaler;
    final platform =
        inherited is DeviceTextScaler ? inherited.platform : inherited;
    return MediaQuery(
      data: media.copyWith(
        textScaler: DeviceTextScaler(platform, media.size.shortestSide),
      ),
      child: child,
    );
  }
}
