import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

bool get isDesktopPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
