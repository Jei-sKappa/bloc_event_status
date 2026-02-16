import 'package:bloc_event_status_builder/src/bloc_event_status_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Builder factory for the bloc_event_status code generator.
Builder blocEventStatusBuilder(BuilderOptions options) =>
    SharedPartBuilder([BlocEventStatusGenerator()], 'bloc_event_status');
