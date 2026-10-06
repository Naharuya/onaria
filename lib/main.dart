import 'package:flutter/material.dart';

import 'app/kakao_auth_config.dart';
import 'app/onaria_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoAuthConfig.initialize();
  runApp(const OnariaApp());
}
