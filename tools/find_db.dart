import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = await databaseFactory.getDatabasesPath();
  final path = join(dbPath, 'pos_database.db');
  print('DATABASE_PATH: ' + path);
}
