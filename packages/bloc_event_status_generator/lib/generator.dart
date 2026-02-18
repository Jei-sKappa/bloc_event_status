import 'package:bloc_event_status_generator/src/bloc_event_status_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Builder factory for the bloc_event_status code generator.
Builder blocEventStatusGenerator(BuilderOptions options) => PartBuilder(
      [BlocEventStatusGenerator()],
      '.bes.g.dart',
      header: '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
          '// coverage:ignore-file\n'
          '// ignore_for_file: type=lint\n'
          '// dart format off',
      formatOutput: (code, _) => code,
    );
