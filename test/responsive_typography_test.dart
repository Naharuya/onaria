import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/responsive_typography.dart';

class NonlinearScaler extends TextScaler {
  const NonlinearScaler();
  @override
  double scale(double size) => size <= 20 ? size * 2 : size * 1.5;
  @override
  double get textScaleFactor => 2;
}

void main() {
  test('bounded continuous device scaling preserves body readability', () {
    expect(DeviceTextScaler.factorFor(320), .94);
    expect(DeviceTextScaler.factorFor(390), 1);
    expect(DeviceTextScaler.factorFor(600), 1.06);
    expect(DeviceTextScaler.factorFor(900), 1.12);
    expect(DeviceTextScaler.factorFor(4000), 1.12);
    for (final width in [280.0, 320.0, 390.0, 600.0, 768.0, 1280.0]) {
      final scaler = DeviceTextScaler(TextScaler.noScaling, width);
      expect(scaler.scale(14), greaterThanOrEqualTo(14));
      expect(scaler.scale(20), greaterThanOrEqualTo(20));
    }
    expect(const DeviceTextScaler(TextScaler.noScaling, 320).scale(32),
        closeTo(30.08, .001));
  });
  test('retains nonlinear platform accessibility scaling', () {
    const platform = NonlinearScaler();
    const scaler = DeviceTextScaler(platform, 768);
    final factor = DeviceTextScaler.factorFor(768);
    expect(scaler.scale(16), platform.scale(16 * factor));
    expect(scaler.scale(32), platform.scale(32 * factor));
  });
  testWidgets(
      'nested wrappers do not multiply scaling and preserve keyboard insets',
      (tester) async {
    late MediaQueryData result;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(
          size: Size(768, 1024),
          textScaler: TextScaler.linear(2),
          viewInsets: EdgeInsets.only(bottom: 300)),
      child: ResponsiveTypography(
          child: ResponsiveTypography(child: Builder(builder: (context) {
        result = MediaQuery.of(context);
        return const SizedBox();
      }))),
    ));
    expect(result.textScaler.scale(16),
        closeTo(16 * DeviceTextScaler.factorFor(768) * 2, .001));
    expect(result.viewInsets.bottom, 300);
    expect(result.size, const Size(768, 1024));
  });
  testWidgets('rotation uses short side rather than landscape width',
      (tester) async {
    double? portrait;
    double? landscape;
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(size: size),
          child: ResponsiveTypography(child: Builder(builder: (context) {
            final value = MediaQuery.textScalerOf(context).scale(24);
            if (size.width < size.height) {
              portrait = value;
            } else {
              landscape = value;
            }
            return const SizedBox();
          }))));
    }
    expect(portrait, landscape);
  });
}
