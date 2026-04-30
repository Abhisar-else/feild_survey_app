import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _initialized = false;

void initializeDatabaseFactory() {
  if (_initialized) return;

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  _initialized = true;
}
