import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:build/build.dart';
import 'package:hive_ce/hive.dart';
import 'dart:async';

import 'package:hive_ce_generator/src/helper/helper.dart';
import 'package:hive_ce_generator/src/model/registrar_intermediate.dart';
import 'package:yaml/yaml.dart';

/// Generate the HiveRegistrar for the entire project
class RegistrarBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$lib$': ['hive_registrar.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final uris = <String>[];
    final adapters = <String>[];
    Uri? registrarUri;
    await for (final input
        in buildStep.findAssets(Glob('**/*.hive_registrar.info'))) {
      final content = await buildStep.readAsString(input);
      final data = RegistrarIntermediate.fromJson(jsonDecode(content));
      final uri = data.uri;
      uris.add(uri.toString());
      adapters.addAll(data.adapters);
      if (data.registrarLocation) {
        if (registrarUri != null) {
          final sortedUris =
              [registrarUri, uri].map((e) => e.toString()).toList()..sort();
          final urisString = sortedUris.map((e) => '- $e').join('\n');
          throw HiveError(
            'GenerateAdapters annotation found in more than one file:\n$urisString',
          );
        }
        registrarUri = uri;
      }
    }

    // Do not create the registrar if there are no adapters
    if (adapters.isEmpty) return;

    adapters.sort();
    uris.sort();

    final ignores = <String>[];
    final buildConfigFile = File('build.yaml');
    if (buildConfigFile.existsSync()) {
      final buildConfigContent = buildConfigFile.readAsStringSync();
      final buildConfig = loadYaml(buildConfigContent);
      final configIgnores = buildConfig?['targets']?[r'$default']?['builders']
                  ?['source_gen|combining_builder']?['options']
              ?['ignore_for_file'] as YamlList? ??
          [];
      ignores.addAll(configIgnores.cast<String>());
    }

    final buffer = StringBuffer('''
// Generated by Hive CE
// Do not modify
// Check in to version control

''');

    if (ignores.isNotEmpty) {
      buffer.writeln('// ignore_for_file: ${ignores.join(', ')}\n');
    }

    buffer.writeln("import 'package:hive_ce/hive.dart';");

    for (final uri in uris) {
      buffer.writeln("import '$uri';");
    }

    buffer.write('''

extension HiveRegistrar on HiveInterface {
  void registerAdapters() {
''');

    for (final adapter in adapters) {
      buffer.writeln('    registerAdapter($adapter());');
    }

    buffer.write('''
  }
}
''');

    var registrarLocation = 'lib';
    if (registrarUri != null) {
      final segments = registrarUri.pathSegments;
      // Skip the package segment and remove the file segment
      final registrarPath = segments.sublist(1, segments.length - 1).join('/');
      registrarLocation += '/$registrarPath';
    }
    registrarLocation += '/hive_registrar.g.dart';

    buildStep.forceWriteAsString(
      buildStep.asset(registrarLocation),
      buffer.toString(),
    );
  }
}