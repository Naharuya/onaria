import 'package:onaria/app/asset_loader.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Fresh-install public receipt storage. Individual storage-failure tests supply their own adapters.
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await rootBundle.loadString('assets/data/content_release_baseline.json');
    await FlutterVerseAssetLoader.initializeLocal();
  });
  await testMain();
}
