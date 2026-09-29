import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'app/onaria_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep browser accessibility/keyboard controls available across dialogs.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  runApp(const OnariaApp());
}
