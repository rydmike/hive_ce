// Generated by Hive CE
// Do not modify
// Check into version control

import 'package:hive_ce/hive.dart';
import 'package:example/hive/hive_adapters.dart';

extension HiveRegistrar on HiveInterface {
  void registerAdapters() {
    registerAdapter(FreezedPersonAdapter());
    registerAdapter(PersonAdapter());
  }
}
