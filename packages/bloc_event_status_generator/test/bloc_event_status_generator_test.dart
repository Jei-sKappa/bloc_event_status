@Timeout.factor(3)
library;

import 'package:bloc_event_status_generator/bloc_event_status_generator.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

const _statusHeader = '''
import 'package:equatable/equatable.dart';

sealed class EventStatus with EquatableMixin {
  const EventStatus();
}

class LoadingEventStatus extends EventStatus {
  const LoadingEventStatus();
  @override
  List<Object?> get props => [];
}

class SuccessEventStatus extends EventStatus {
  const SuccessEventStatus();
  @override
  List<Object?> get props => [];
}

class FailureEventStatus extends EventStatus {
  const FailureEventStatus([this.error]);
  final Exception? error;
  @override
  List<Object?> get props => [error];
}
''';

const _eventHeader = '''
import 'package:equatable/equatable.dart';

abstract class TestEvent extends Equatable {
  const TestEvent();
  @override
  List<Object> get props => [];
}

class LoadRequested extends TestEvent {
  const LoadRequested();
}
''';

const _stateHeader = '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'event_status.dart';
import 'test_event.dart';

class TestState extends Equatable with EventStatusesMixin<TestEvent, EventStatus> {
  const TestState({
    this.eventStatuses = const EventStatuses(),
  });

  @override
  final EventStatuses<TestEvent, EventStatus> eventStatuses;

  @override
  List<Object?> get props => [eventStatuses];

  TestState copyWith({EventStatuses<TestEvent, EventStatus>? eventStatuses}) {
    return TestState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''';

const _blocSource = '''
import 'package:bloc/bloc.dart';
import 'package:bloc_event_status/bloc_event_status.dart';
import 'event_status.dart';
import 'test_event.dart';
import 'test_state.dart';

class TestBloc extends Bloc<TestEvent, TestState> {
  TestBloc() : super(const TestState());
}
''';

/// Resolves sources, finds the class [className] in [targetAsset], and runs
/// [BlocEventStatusGenerator.generateForAnnotatedElement] on it.
Future<String> _generate(
  Map<String, String> sources,
  String targetAsset, {
  String? className,
}) {
  return resolveSources(
    sources,
    (resolver) async {
      final library = await resolver.libraryFor(AssetId.parse(targetAsset));
      final reader = LibraryReader(library);

      // Find the target class element
      final targetClass = className ?? _defaultClassName(targetAsset);
      final element = reader.classes.firstWhere(
        (c) => c.name == targetClass,
      );

      final generator = BlocEventStatusGenerator();
      return generator.generateForAnnotatedElement(
        element,
        ConstantReader(null),
        _FakeBuildStep(resolver),
      );
    },
    resolverFor: targetAsset,
    readAllSourcesFromFilesystem: true,
  );
}

String _defaultClassName(String assetId) {
  // Extract from 'a|lib/test_bloc.dart' -> 'TestBloc'
  final fileName = assetId.split('/').last.replaceAll('.dart', '');
  return fileName
      .split('_')
      .map((s) => s[0].toUpperCase() + s.substring(1))
      .join();
}

class _FakeBuildStep implements BuildStep {
  _FakeBuildStep(this.resolver);

  @override
  final Resolver resolver;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('BlocEventStatusGenerator', () {
    test('generates correct extension for a standard Bloc', () async {
      final output = await _generate(
        {
          'a|lib/event_status.dart': _statusHeader,
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/test_state.dart': _stateHeader,
          'a|lib/test_bloc.dart': _blocSource,
        },
        'a|lib/test_bloc.dart',
      );

      expect(
        output,
        contains(r'extension $TestBlocEmitterX on Emitter<TestState>'),
      );
      expect(output, contains('void _emitEventStatus<T extends TestEvent>'));
      expect(
        output,
        contains(
          'void loading<T extends TestEvent>(T event, TestState state)',
        ),
      );
      expect(
        output,
        contains(
          'void success<T extends TestEvent>(T event, TestState state)',
        ),
      );
      expect(output, contains('void failure'));
      expect(output, contains('const LoadingEventStatus()'));
      expect(output, contains('const SuccessEventStatus()'));
      expect(output, contains('FailureEventStatus('));
    });

    test('method names strip base class name suffix', () async {
      final output = await _generate(
        {
          'a|lib/event_status.dart': _statusHeader,
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/test_state.dart': _stateHeader,
          'a|lib/test_bloc.dart': _blocSource,
        },
        'a|lib/test_bloc.dart',
      );

      // LoadingEventStatus -> loading
      expect(output, contains('void loading<T extends TestEvent>'));
      // SuccessEventStatus -> success
      expect(output, contains('void success<T extends TestEvent>'));
      // FailureEventStatus -> failure
      expect(output, contains('void failure'));
    });

    test('optional positional params stay optional', () async {
      final output = await _generate(
        {
          'a|lib/event_status.dart': _statusHeader,
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/test_state.dart': _stateHeader,
          'a|lib/test_bloc.dart': _blocSource,
        },
        'a|lib/test_bloc.dart',
      );

      expect(output, contains('[Exception? error]'));
    });

    test('const constructor produces const instantiation when no args',
        () async {
      final output = await _generate(
        {
          'a|lib/event_status.dart': _statusHeader,
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/test_state.dart': _stateHeader,
          'a|lib/test_bloc.dart': _blocSource,
        },
        'a|lib/test_bloc.dart',
      );

      expect(output, contains('const LoadingEventStatus()'));
      expect(output, contains('const SuccessEventStatus()'));
    });

    test('error when annotation is on a non-Bloc class', () async {
      expect(
        () => _generate(
          {
            'a|lib/not_bloc.dart': '''
class NotABloc {}
''',
          },
          'a|lib/not_bloc.dart',
          className: 'NotABloc',
        ),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('can only be applied to classes that extend Bloc'),
          ),
        ),
      );
    });

    test('error when state does not use EventStatusesMixin', () async {
      expect(
        () => _generate(
          {
            'a|lib/test_event.dart': _eventHeader,
            'a|lib/bad_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'test_event.dart';

class BadState extends Equatable {
  const BadState();
  @override
  List<Object?> get props => [];

  BadState copyWith() => const BadState();
}

class BadBloc extends Bloc<TestEvent, BadState> {
  BadBloc() : super(const BadState());
}
''',
          },
          'a|lib/bad_bloc.dart',
          className: 'BadBloc',
        ),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('must use EventStatusesMixin'),
          ),
        ),
      );
    });

    test('handles status subtypes with generic type params', () async {
      final output = await _generate(
        {
          'a|lib/generic_status.dart': '''
import 'package:equatable/equatable.dart';

sealed class Status with EquatableMixin {
  const Status();
}

class IdleStatus extends Status {
  const IdleStatus();
  @override
  List<Object?> get props => [];
}

class DataStatus<T> extends Status {
  const DataStatus(this.data);
  final T data;
  @override
  List<Object?> get props => [data];
}
''',
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/generic_state.dart': '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'generic_status.dart';
import 'test_event.dart';

class GenericState extends Equatable with EventStatusesMixin<TestEvent, Status> {
  const GenericState({
    this.eventStatuses = const EventStatuses(),
  });

  @override
  final EventStatuses<TestEvent, Status> eventStatuses;

  @override
  List<Object?> get props => [eventStatuses];

  GenericState copyWith({EventStatuses<TestEvent, Status>? eventStatuses}) {
    return GenericState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''',
          'a|lib/generic_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'generic_status.dart';
import 'test_event.dart';
import 'generic_state.dart';

class GenericBloc extends Bloc<TestEvent, GenericState> {
  GenericBloc() : super(const GenericState());
}
''',
        },
        'a|lib/generic_bloc.dart',
      );

      expect(output, contains('void idle<T extends TestEvent>'));
      expect(output, contains('const IdleStatus()'));
      expect(output, contains('void data<T, '));
      expect(output, contains('DataStatus<T>('));
    });

    test('handles status with required named params', () async {
      final output = await _generate(
        {
          'a|lib/named_status.dart': '''
import 'package:equatable/equatable.dart';

sealed class MyStatus with EquatableMixin {
  const MyStatus();
}

class PendingMyStatus extends MyStatus {
  const PendingMyStatus();
  @override
  List<Object?> get props => [];
}

class ErrorMyStatus extends MyStatus {
  const ErrorMyStatus({required this.message, this.code});
  final String message;
  final int? code;
  @override
  List<Object?> get props => [message, code];
}
''',
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/named_state.dart': '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'named_status.dart';
import 'test_event.dart';

class NamedState extends Equatable with EventStatusesMixin<TestEvent, MyStatus> {
  const NamedState({
    this.eventStatuses = const EventStatuses(),
  });

  @override
  final EventStatuses<TestEvent, MyStatus> eventStatuses;

  @override
  List<Object?> get props => [eventStatuses];

  NamedState copyWith({EventStatuses<TestEvent, MyStatus>? eventStatuses}) {
    return NamedState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''',
          'a|lib/named_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'named_status.dart';
import 'test_event.dart';
import 'named_state.dart';

class NamedBloc extends Bloc<TestEvent, NamedState> {
  NamedBloc() : super(const NamedState());
}
''',
        },
        'a|lib/named_bloc.dart',
      );

      expect(output, contains('void pending<T extends TestEvent>'));
      expect(output, contains('const PendingMyStatus()'));
      expect(output, contains('{required String message'));
      expect(output, contains('int? code}'));
      expect(output, contains('message: message'));
      expect(output, contains('code: code'));
    });
  });
}
