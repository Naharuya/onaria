import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onaria/app/onaria_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('check-in to conversation smoke', (tester) async {
    await tester.pumpWidget(const OnariaApp());
    await tester.pumpAndSettle();

    final anxiety = find.byKey(const ValueKey('emotion-anxiety'));
    expect(anxiety, findsOneWidget);
    await tester.tap(anxiety);
    await tester.pumpAndSettle();

    final start = find.byKey(const ValueKey('start-conversation'));
    for (var i = 0; i < 4 && start.evaluate().isEmpty; i++) {
      await tester.drag(
        find.byKey(const ValueKey('check-in-scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
    }
    expect(start, findsOneWidget);
    await tester.tap(start);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('마음 대화'), findsWidgets);
  });
}
