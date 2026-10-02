import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onaria/app/onaria_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('privacy and account deletion entry smoke', (tester) async {
    await tester.pumpWidget(const OnariaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    final privacy = find.text('개인정보·회원탈퇴');
    expect(privacy, findsOneWidget);
    await tester.tap(privacy);
    await tester.pumpAndSettle();

    expect(find.text('개인정보와 기록 관리'), findsOneWidget);
    final deletion = find.byKey(const ValueKey('account-deletion-unavailable'));
    for (var i = 0; i < 5 && deletion.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
      await tester.pumpAndSettle();
    }
    expect(deletion, findsOneWidget);
    final webGuide = find.text('웹에서 계정 삭제 안내 보기');
    for (var i = 0; i < 4 && webGuide.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle(const Duration(milliseconds: 350));
    }
    expect(webGuide, findsOneWidget);
  });
}
