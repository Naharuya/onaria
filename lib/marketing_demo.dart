import 'dart:async';
import 'package:flutter/material.dart';
import 'app/onaria_app.dart';
import 'features/check_in_page.dart';
import 'features/conversation_page.dart';
import 'features/growth_page.dart';
import 'src/conversation/conversation_models.dart';

void main() => runApp(const MarketingDemoController());

class MarketingDemoController extends StatefulWidget {
  const MarketingDemoController({super.key});
  @override
  State<MarketingDemoController> createState() =>
      _MarketingDemoControllerState();
}

class _MarketingDemoControllerState extends State<MarketingDemoController> {
  int _scene = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _scene = (_scene + 1) % 5);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _page() {
    switch (_scene) {
      case 0:
        return const CheckInPage();
      case 1:
        return const ConversationPage(
            emotion: EmotionType.anxiety, intensity: 7);
      case 2:
        return const ConversationPage(
            emotion: EmotionType.anxiety, intensity: 5);
      case 3:
        return const GrowthPage();
      default:
        return const CheckInPage();
    }
  }

  @override
  Widget build(BuildContext context) => OnariaApp(homeOverride: _page());
}
