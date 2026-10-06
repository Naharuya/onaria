import 'package:flutter/material.dart';

import 'app/kakao_auth_config.dart';
import 'app/member_session_store.dart';
import 'app/onaria_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoAuthConfig.initialize();
  await MemberSessionStore.instance.restore();
  runApp(const OnariaApp());
}
