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

/// Resolves sources, finds a non-class element [elementName] in [targetAsset],
/// and runs [BlocEventStatusGenerator.generateForAnnotatedElement] on it.
Future<String> _generateForNonClass(
  Map<String, String> sources,
  String targetAsset,
  String elementName,
) {
  return resolveSources(
    sources,
    (resolver) async {
      final library = await resolver.libraryFor(AssetId.parse(targetAsset));
      final reader = LibraryReader(library);
      final element = reader.enums.firstWhere(
        (e) => e.name == elementName,
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

    test(
      'const constructor produces const instantiation when no args',
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
      },
    );

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

    test('strips shared prefix when base name has a prefix', () async {
      // CustomSuccessEventStatus / CustomEventStatus → success
      final output = await _generate(
        {
          'a|lib/prefixed_status.dart': '''
import 'package:equatable/equatable.dart';

sealed class CustomEventStatus with EquatableMixin {
  const CustomEventStatus();
}

class CustomLoadingEventStatus extends CustomEventStatus {
  const CustomLoadingEventStatus();
  @override
  List<Object?> get props => [];
}

class CustomSuccessEventStatus extends CustomEventStatus {
  const CustomSuccessEventStatus();
  @override
  List<Object?> get props => [];
}

class CustomFailureEventStatus extends CustomEventStatus {
  const CustomFailureEventStatus([this.error]);
  final Exception? error;
  @override
  List<Object?> get props => [error];
}
''',
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/prefixed_state.dart': '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'prefixed_status.dart';
import 'test_event.dart';

class PrefixedState extends Equatable with EventStatusesMixin<TestEvent, CustomEventStatus> {
  const PrefixedState({
    this.eventStatuses = const EventStatuses(),
  });

  @override
  final EventStatuses<TestEvent, CustomEventStatus> eventStatuses;

  @override
  List<Object?> get props => [eventStatuses];

  PrefixedState copyWith({EventStatuses<TestEvent, CustomEventStatus>? eventStatuses}) {
    return PrefixedState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''',
          'a|lib/prefixed_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'prefixed_status.dart';
import 'test_event.dart';
import 'prefixed_state.dart';

class PrefixedBloc extends Bloc<TestEvent, PrefixedState> {
  PrefixedBloc() : super(const PrefixedState());
}
''',
        },
        'a|lib/prefixed_bloc.dart',
      );

      // CustomLoadingEventStatus → loading
      expect(output, contains('void loading<T extends TestEvent>'));
      // CustomSuccessEventStatus → success
      expect(output, contains('void success<T extends TestEvent>'));
      // CustomFailureEventStatus → failure
      expect(output, contains('void failure'));
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

    test('error when annotation is on a non-class element', () async {
      expect(
        () => _generateForNonClass(
          {
            'a|lib/some_enum.dart': '''
enum SomeEnum { a, b, c }
''',
          },
          'a|lib/some_enum.dart',
          'SomeEnum',
        ),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('can only be applied to classes'),
          ),
        ),
      );
    });

    test('error when no concrete subtypes exist', () async {
      expect(
        () => _generate(
          {
            'a|lib/empty_status.dart': '''
import 'package:equatable/equatable.dart';

sealed class EmptyStatus with EquatableMixin {
  const EmptyStatus();
}
''',
            'a|lib/test_event.dart': _eventHeader,
            'a|lib/empty_state.dart': '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'empty_status.dart';
import 'test_event.dart';

class EmptyState extends Equatable with EventStatusesMixin<TestEvent, EmptyStatus> {
  const EmptyState({this.eventStatuses = const EventStatuses()});
  @override
  final EventStatuses<TestEvent, EmptyStatus> eventStatuses;
  @override
  List<Object?> get props => [eventStatuses];
  EmptyState copyWith({EventStatuses<TestEvent, EmptyStatus>? eventStatuses}) {
    return EmptyState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''',
            'a|lib/empty_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'empty_status.dart';
import 'test_event.dart';
import 'empty_state.dart';

class EmptyBloc extends Bloc<TestEvent, EmptyState> {
  EmptyBloc() : super(const EmptyState());
}
''',
          },
          'a|lib/empty_bloc.dart',
          className: 'EmptyBloc',
        ),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('No concrete subtypes found'),
          ),
        ),
      );
    });

    test('handles bounded type params and default param values', () async {
      final output = await _generate(
        {
          'a|lib/adv_status.dart': '''
import 'package:equatable/equatable.dart';

sealed class AdvStatus with EquatableMixin {
  const AdvStatus();
}

class BoundedAdvStatus<T extends Comparable<T>> extends AdvStatus {
  const BoundedAdvStatus(this.value);
  final T value;
  @override
  List<Object?> get props => [value];
}

class DefaultNamedAdvStatus extends AdvStatus {
  const DefaultNamedAdvStatus({this.count = 0});
  final int count;
  @override
  List<Object?> get props => [count];
}

class DefaultPosAdvStatus extends AdvStatus {
  const DefaultPosAdvStatus([this.tag = 'default']);
  final String tag;
  @override
  List<Object?> get props => [tag];
}
''',
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/adv_state.dart': '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'adv_status.dart';
import 'test_event.dart';

class AdvState extends Equatable with EventStatusesMixin<TestEvent, AdvStatus> {
  const AdvState({this.eventStatuses = const EventStatuses()});
  @override
  final EventStatuses<TestEvent, AdvStatus> eventStatuses;
  @override
  List<Object?> get props => [eventStatuses];
  AdvState copyWith({EventStatuses<TestEvent, AdvStatus>? eventStatuses}) {
    return AdvState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''',
          'a|lib/adv_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'adv_status.dart';
import 'test_event.dart';
import 'adv_state.dart';

class AdvBloc extends Bloc<TestEvent, AdvState> {
  AdvBloc() : super(const AdvState());
}
''',
        },
        'a|lib/adv_bloc.dart',
      );

      // Bounded type param: <T extends Comparable<T>>
      expect(output, contains('extends Comparable<T>'));
      expect(output, contains('BoundedAdvStatus<T>('));

      // Optional named param with default value
      expect(output, contains('{int count = 0}'));

      // Optional positional param with default value
      expect(output, contains("[String tag = 'default']"));
    });

    test('handles subtype name shorter than base name', () async {
      final output = await _generate(
        {
          'a|lib/long_status.dart': '''
import 'package:equatable/equatable.dart';

sealed class VeryLongStatusBase with EquatableMixin {
  const VeryLongStatusBase();
}

class Short extends VeryLongStatusBase {
  const Short();
  @override
  List<Object?> get props => [];
}
''',
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/long_state.dart': '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'long_status.dart';
import 'test_event.dart';

class LongState extends Equatable with EventStatusesMixin<TestEvent, VeryLongStatusBase> {
  const LongState({this.eventStatuses = const EventStatuses()});
  @override
  final EventStatuses<TestEvent, VeryLongStatusBase> eventStatuses;
  @override
  List<Object?> get props => [eventStatuses];
  LongState copyWith({EventStatuses<TestEvent, VeryLongStatusBase>? eventStatuses}) {
    return LongState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''',
          'a|lib/long_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'long_status.dart';
import 'test_event.dart';
import 'long_state.dart';

class LongBloc extends Bloc<TestEvent, LongState> {
  LongBloc() : super(const LongState());
}
''',
        },
        'a|lib/long_bloc.dart',
      );

      // 'Short' is shorter than 'VeryLongStatusBase', covers min-length branch
      expect(output, contains('void short<T extends TestEvent>'));
      expect(output, contains('const Short()'));
    });

    test('strips common suffix when base has a different prefix', () async {
      // LoadingEventStatus / CounterEventStatus → loading
      // (no shared prefix, but shared suffix "EventStatus")
      final output = await _generate(
        {
          'a|lib/counter_status.dart': '''
import 'package:equatable/equatable.dart';

sealed class CounterEventStatus with EquatableMixin {
  const CounterEventStatus();
}

class LoadingEventStatus extends CounterEventStatus {
  const LoadingEventStatus();
  @override
  List<Object?> get props => [];
}

class SuccessEventStatus extends CounterEventStatus {
  const SuccessEventStatus();
  @override
  List<Object?> get props => [];
}

class FailureEventStatus extends CounterEventStatus {
  const FailureEventStatus(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
''',
          'a|lib/test_event.dart': _eventHeader,
          'a|lib/counter_state.dart': '''
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'counter_status.dart';
import 'test_event.dart';

class CounterState extends Equatable with EventStatusesMixin<TestEvent, CounterEventStatus> {
  const CounterState({
    this.eventStatuses = const EventStatuses(),
  });

  @override
  final EventStatuses<TestEvent, CounterEventStatus> eventStatuses;

  @override
  List<Object?> get props => [eventStatuses];

  CounterState copyWith({EventStatuses<TestEvent, CounterEventStatus>? eventStatuses}) {
    return CounterState(eventStatuses: eventStatuses ?? this.eventStatuses);
  }
}
''',
          'a|lib/counter_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'counter_status.dart';
import 'test_event.dart';
import 'counter_state.dart';

class CounterBloc extends Bloc<TestEvent, CounterState> {
  CounterBloc() : super(const CounterState());
}
''',
        },
        'a|lib/counter_bloc.dart',
      );

      // LoadingEventStatus → loading (not loadingEventStatus)
      expect(output, contains('void loading<T extends TestEvent>'));
      // SuccessEventStatus → success
      expect(output, contains('void success<T extends TestEvent>'));
      // FailureEventStatus → failure
      expect(output, contains('void failure'));
    });
  });
}
