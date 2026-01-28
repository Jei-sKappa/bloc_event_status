// ignore_reason: used for testing
// ignore_for_file: invalid_use_of_protected_member

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

class TestBloc extends Bloc<Event, int>
    with BlocCustomEventStatusMixin<Event, int, TestStatus> {
  TestBloc() : super(0) {
    on<EventA>((event, emit) {});
    on<EventB>((event, emit) {});
  }
}

// Test Statuses
enum TestStatus { initial, loading, success, failure }

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

void main() {
  group('BlocCustomEventStatusMixin', () {
    late TestBloc bloc;

    setUp(() {
      bloc = TestBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('no event status is available initially', () {
      expect(bloc.eventStatusOfAllEvents(), isNull);
    });

    test('main event class cannot be used', () {
      expect(
        () => bloc.eventStatusOf<Event>(),
        throwsArgumentError,
      );
    });

    test('event statuses are available once emitted', () {
      const statusA = TestStatus.loading;
      const statusB = TestStatus.success;

      bloc.emitEventStatus<EventA>(EventA('1'), statusA);
      expect(
        bloc.eventStatusOfAllEvents(),
        equals((event: EventA('1'), status: statusA)),
      );

      bloc.emitEventStatus<EventB>(EventB(10), statusB);
      expect(
        bloc.eventStatusOfAllEvents(),
        equals((event: EventB(10), status: statusB)),
      );
    });

    test(
        'event statuses of specific type remain available when an event of '
        'another type is emitted', () {
      const statusA = TestStatus.loading;
      const statusB = TestStatus.success;

      bloc.emitEventStatus<EventA>(EventA('1'), statusA);
      expect(
        bloc.eventStatusOf<EventA>(),
        equals((event: EventA('1'), status: statusA)),
      );

      bloc.emitEventStatus<EventB>(EventB(10), statusB);
      expect(
        bloc.eventStatusOf<EventB>(),
        equals((event: EventB(10), status: statusB)),
      );

      // Check that the status of EventA is still available
      expect(
        bloc.eventStatusOf<EventA>(),
        equals((event: EventA('1'), status: statusA)),
      );
    });

    test('event statuses are emitted', () {
      final eventA = EventA('1');
      const statusA = TestStatus.loading;

      final eventB = EventB(10);
      const statusB = TestStatus.success;

      expect(
        bloc.streamEventStatusOfAllEvents(),
        emitsInOrder([
          (event: eventA, status: statusA),
          (event: eventB, status: statusB),
        ]),
      );

      expect(
        bloc.streamEventStatusOf<EventA>(),
        emitsInOrder([
          (event: eventA, status: statusA),
        ]),
      );

      expect(
        bloc.streamEventStatusOf<EventB>(),
        emitsInOrder([
          (event: eventB, status: statusB),
        ]),
      );

      bloc
        ..emitEventStatus<EventA>(eventA, statusA)
        ..emitEventStatus<EventB>(eventB, statusB);
    });

    test('event statuses streams are closed when the container is closed',
        () async {
      final eventA = EventA('1');
      const statusA = TestStatus.loading;
      const statusB = TestStatus.success;

      expect(
        bloc.streamEventStatusOfAllEvents(),
        emitsInOrder([
          (event: eventA, status: statusA),
          emitsDone,
        ]),
      );

      expect(
        bloc.streamEventStatusOf<EventA>(),
        emitsInOrder([
          (event: eventA, status: statusA),
          emitsDone,
        ]),
      );

      bloc.emitEventStatus(eventA, statusA);
      await bloc.close();

      // Verify that the statuses are cleared
      expect(
        bloc.eventStatusOfAllEvents(),
        isNull,
      );

      expect(
        bloc.eventStatusOf<EventA>(),
        isNull,
      );

      // Verify that emitting new statuses after closing the container DO NOT
      // throw an error
      expect(
        () => bloc.emitEventStatus<EventA>(eventA, statusB),
        returnsNormally,
      );

      // Verify that the statuses are unchanged
      expect(
        bloc.eventStatusOfAllEvents(),
        isNull,
      );

      expect(
        bloc.eventStatusOf<EventA>(),
        isNull,
      );
    });
  });
}
