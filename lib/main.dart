import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'shared/core/form_factor.dart';
import 'shared/services/telegram/tdlib_ffi.dart';

void _logTdlibStatus() {
  final td = TdLib.tryLoad();
  if (td == null) {
    debugPrint('tdjson: not bundled, demo engine only');
    return;
  }
  td.execute({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': 1});
  final version = td.execute({'@type': 'getOption', 'name': 'version'});
  debugPrint('tdjson: loaded, TDLib version ${version?['value']}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) _logTdlibStatus();

  if (isDesktopPlatform) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1180, 760),
        minimumSize: Size(900, 620),
        center: true,
        title: 'SannDrive',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(const ProviderScope(child: SannDriveApp()));
}
