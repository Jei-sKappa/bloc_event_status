// ignore_reason: used for testing
// ignore_for_file: invalid_use_of_protected_member

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

@immutable
class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;
  @override
  int get hashCode => message.hashCode;
}

const _myFailure = Failure('error');

class TestBloc extends Bloc<Event, int> with BlocEventStatusMixin<Event, int> {
  TestBloc() : super(0) {
    on<EventA>(
      handleEventStatus((event, emit) async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }),
    );
    on<EventB>(
      handleEventStatus<EventB, Failure>((event, emit) async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        throw _myFailure;
      }),
    );
    on<EventC>(
      handleEventStatus((event, emit) async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        throw _myFailure;
      }),
    );
  }
}

// Test Events
sealed class Event {}

@immutable
class EventA extends Event {
  EventA(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventA && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class EventB extends Event {
  EventB(this.value);
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventB &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
class EventC extends Event {
  EventC(this.value);
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventC &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

void main() {
  group('BlocEventStatusMixin', () {
    late TestBloc bloc;

    setUp(() {
      bloc = TestBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('no event status is available initially', () {
      expect(bloc.statusOfAllEvents(), isNull);
    });

    test('main event class can\t be used', () {
      expect(
        () => bloc.statusOf<Event>(),
        throwsArgumentError,
      );
    });

    test('event statuses are available once emitted', () {
      bloc.emitLoadingStatus(EventA('1'));
      expect(bloc.statusOfAllEvents(), equals(const LoadingEventStatus()));

      bloc.emitSuccessStatus<EventB, Null>(EventB(10));
      expect(
        bloc.statusOf<EventB>(),
        equals(const SuccessEventStatus<Null>()),
      );
    });

    test('event statuses are available once events are emitted', () {
      final eventA = EventA('1');
      final eventB = EventB(10);
      final eventC = EventC(11.1);

      expect(
        bloc.streamStatusOf<EventA>(),
        emitsInOrder([
          (event: eventA, status: const LoadingEventStatus()),
          (event: eventA, status: const SuccessEventStatus<Null>()),
        ]),
      );

      expect(
        bloc.streamStatusOf<EventB>(),
        emitsInOrder([
          (event: eventB, status: const LoadingEventStatus()),
          (event: eventB, status: const FailureEventStatus(_myFailure)),
        ]),
      );

      expect(
        bloc.streamStatusOf<EventC>(),
        emitsInOrder([
          (event: eventC, status: const LoadingEventStatus()),
          (
            event: eventC,
            status: const FailureEventStatus<Exception>(_myFailure),
          ),
        ]),
      );

      bloc
        ..add(eventA)
        ..add(eventB)
        ..add(eventC);
    });

    test(
        'event statuses of specific type remain available when an event of '
        'another type is emitted', () {
      bloc.emitLoadingStatus(EventA('1'));
      expect(bloc.statusOf<EventA>(), equals(const LoadingEventStatus()));

      bloc.emitSuccessStatus<EventB, Null>(EventB(10));
      expect(
        bloc.statusOf<EventB>(),
        equals(const SuccessEventStatus<Null>()),
      );

      // Check that the status of EventA is still available
      expect(bloc.statusOf<EventA>(), equals(const LoadingEventStatus()));
    });

    test('event statuses are emitted', () {
      final eventA = EventA('1');
      const statusA = LoadingEventStatus();

      final eventB = EventB(10);
      const statusB = SuccessEventStatus<Null>();

      expect(
        bloc.streamStatusOfAllEvents(),
        emitsInOrder([
          (event: eventA, status: statusA),
          (event: eventB, status: statusB),
        ]),
      );

      expect(
        bloc.streamStatusOf<EventA>(),
        emitsInOrder([
          (event: eventA, status: statusA),
        ]),
      );

      expect(
        bloc.streamStatusOf<EventB>(),
        emitsInOrder([
          (event: eventB, status: statusB),
        ]),
      );

      bloc
        ..emitLoadingStatus(eventA)
        ..emitSuccessStatus<EventB, Null>(eventB);
    });

    test('event statuses streams are closed when the container is closed',
        () async {
      final eventA = EventA('1');
      const failure = Failure('error');
      const statusA = FailureEventStatus(failure);

      expect(
        bloc.streamStatusOfAllEvents(),
        emitsInOrder([
          (event: eventA, status: statusA),
          emitsDone,
        ]),
      );

      expect(
        bloc.streamStatusOf<EventA>(),
        emitsInOrder([
          (event: eventA, status: statusA),
          emitsDone,
        ]),
      );

      bloc.emitFailureStatus(eventA, error: failure);
      await bloc.close();

      // Verify that emitting new statuses after closing the container throws an
      // error
      expect(
        () => bloc.emitSuccessStatus<EventA, Null>(eventA),
        throwsStateError,
      );
    });
  });
}
