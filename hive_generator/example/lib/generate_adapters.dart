import 'package:hive_ce/hive.dart';

part 'generate_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<ClassSpec1>(),
  AdapterSpec<ClassSpec2>(),
])
_() {}

class ClassSpec1 {
  final int value;

  ClassSpec1(this.value);
}

class ClassSpec2 {
  final String value;

  ClassSpec2(this.value);
}