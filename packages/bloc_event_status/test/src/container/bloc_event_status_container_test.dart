import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

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
  group('BlocEventStatusContainer', () {
    late BlocEventStatusContainer<Event, int, TestStatus> container;

    setUp(() {
      container = BlocEventStatusContainer();
    });

    tearDown(() async {
      await container.close();
    });

    test('no event status is available initially', () {
      expect(container.statusOfAllEvents(), isNull);
    });

    test('main event class can\t be used', () {
      expect(
        () => container.statusOf<Event>(),
        throwsArgumentError,
      );
    });

    test('event statuses are available once emitted', () {
      const statusA = TestStatus.loading;
      const statusB = TestStatus.success;

      container.emitEventStatus<EventA>(EventA('1'), statusA);
      expect(container.statusOfAllEvents(), equals(statusA));

      container.emitEventStatus<EventB>(EventB(10), statusB);
      expect(container.statusOfAllEvents(), equals(statusB));
    });

    test(
        'event statuses of specific type remain available when an event of '
        'another type is emitted', () {
      const statusA = TestStatus.loading;
      const statusB = TestStatus.success;

      container.emitEventStatus<EventA>(EventA('1'), statusA);
      expect(container.statusOf<EventA>(), equals(statusA));

      container.emitEventStatus<EventB>(EventB(10), statusB);
      expect(container.statusOf<EventB>(), equals(statusB));

      // Check that the status of EventA is still available
      expect(container.statusOf<EventA>(), equals(statusA));
    });

    test('event statuses are emitted', () {
      final eventA = EventA('1');
      const statusA = TestStatus.loading;

      final eventB = EventB(10);
      const statusB = TestStatus.success;

      expect(
        container.streamStatusOfAllEvents(),
        emitsInOrder([
          (event: eventA, status: statusA),
          (event: eventB, status: statusB),
        ]),
      );

      expect(
        container.streamStatusOf<EventA>(),
        emitsInOrder([
          (event: eventA, status: statusA),
        ]),
      );

      expect(
        container.streamStatusOf<EventB>(),
        emitsInOrder([
          (event: eventB, status: statusB),
        ]),
      );

      container
        ..emitEventStatus<EventA>(eventA, statusA)
        ..emitEventStatus<EventB>(eventB, statusB);
    });

    test('event statuses streams are closed when the container is closed',
        () async {
      final eventA = EventA('1');
      const statusA = TestStatus.loading;

      expect(
        container.streamStatusOfAllEvents(),
        emitsInOrder([
          (event: eventA, status: statusA),
          emitsDone,
        ]),
      );

      expect(
        container.streamStatusOf<EventA>(),
        emitsInOrder([
          (event: eventA, status: statusA),
          emitsDone,
        ]),
      );

      container.emitEventStatus(eventA, statusA);
      await container.close();

      // Verify that emitting new statuses after closing the container throws an
      // error
      expect(
        () => container.emitEventStatus<EventA>(eventA, statusA),
        throwsStateError,
      );
    });
  });
}
