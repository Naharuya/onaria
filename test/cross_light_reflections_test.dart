import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/engagement/mini_games/cross_light/cross_light_reflections.dart';

void main() {
  test('cross light exposes exactly 365 original reflection templates', () {
    final templates = crossLightReflectionTemplates;
    expect(templates, hasLength(365));
    expect(templates.toSet(), hasLength(365));
  });

  test('daily reflection is stable for the same calendar day', () {
    final a = crossLightReflectionForDate(DateTime(2026, 9, 21, 8));
    final b = crossLightReflectionForDate(DateTime(2026, 9, 21, 23));
    expect(a, b);
  });
}
