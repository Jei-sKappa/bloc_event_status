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
      expect(bloc.statusOfAllEvents(), isNull);
    });

    test('main event class can\t be used', () {
      expect(
        () => bloc.statusOf<Event>(),
        throwsArgumentError,
      );
    });

    test('event statuses are available once emitted', () {
      const statusA = TestStatus.loading;
      const statusB = TestStatus.success;

      bloc.emitEventStatus<EventA>(EventA('1'), statusA);
      expect(bloc.statusOfAllEvents(), equals(statusA));

      bloc.emitEventStatus<EventB>(EventB(10), statusB);
      expect(bloc.statusOfAllEvents(), equals(statusB));
    });

    test(
        'event statuses of specific type remain available when an event of '
        'another type is emitted', () {
      const statusA = TestStatus.loading;
      const statusB = TestStatus.success;

      bloc.emitEventStatus<EventA>(EventA('1'), statusA);
      expect(bloc.statusOf<EventA>(), equals(statusA));

      bloc.emitEventStatus<EventB>(EventB(10), statusB);
      expect(bloc.statusOf<EventB>(), equals(statusB));

      // Check that the status of EventA is still available
      expect(bloc.statusOf<EventA>(), equals(statusA));
    });

    test('event statuses are emitted', () {
      final eventA = EventA('1');
      const statusA = TestStatus.loading;

      final eventB = EventB(10);
      const statusB = TestStatus.success;

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
        ..emitEventStatus<EventA>(eventA, statusA)
        ..emitEventStatus<EventB>(eventB, statusB);
    });

    test('event statuses streams are closed when the container is closed',
        () async {
      final eventA = EventA('1');
      const statusA = TestStatus.loading;

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

      bloc.emitEventStatus(eventA, statusA);
      await bloc.close();

      // Verify that emitting new statuses after closing the container throws an
      // error
      expect(
        () => bloc.emitEventStatus<EventA>(eventA, statusA),
        throwsStateError,
      );
    });
  });
}
