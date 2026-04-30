import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

bool _initialized = false;

void initializeDatabaseFactory() {
  if (_initialized) return;

  databaseFactory = databaseFactoryFfiWeb;
  _initialized = true;
}
