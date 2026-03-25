import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

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
  group('EventStatuses', () {
    late EventStatuses<Event, TestStatus> eventStatuses;

    setUp(() {
      eventStatuses = const EventStatuses();
    });

    test('initially empty', () {
      expect(eventStatuses.eventStatusMap, isEmpty);
      expect(eventStatuses.lastEventStatus, isNull);
    });

    group('update', () {
      test('stores event status for a single event type', () {
        final event = EventA('1');
        final updated = eventStatuses.update<EventA>(event, TestStatus.loading);

        expect(updated.statusOf<EventA>(), TestStatus.loading);
        expect(updated.eventOf<EventA>(), event);
      });

      test('tracks multiple event types independently', () {
        final eventA = EventA('1');
        final eventB = EventB(42);

        final updated = eventStatuses
            .update<EventA>(eventA, TestStatus.loading)
            .update<EventB>(eventB, TestStatus.success);

        expect(updated.statusOf<EventA>(), TestStatus.loading);
        expect(updated.statusOf<EventB>(), TestStatus.success);
      });

      test('overwrites previous status for the same event type', () {
        final event1 = EventA('1');
        final event2 = EventA('2');

        final updated = eventStatuses
            .update<EventA>(event1, TestStatus.loading)
            .update<EventA>(event2, TestStatus.success);

        expect(updated.statusOf<EventA>(), TestStatus.success);
        expect(updated.eventOf<EventA>(), event2);
      });

      test('returns a new instance (immutability)', () {
        final event = EventA('1');
        final updated = eventStatuses.update<EventA>(event, TestStatus.loading);

        expect(identical(updated, eventStatuses), isFalse);
        expect(eventStatuses.eventStatusMap, isEmpty);
        expect(eventStatuses.lastEventStatus, isNull);
      });

      test('throws ArgumentError when TEventSubType is TEvent', () {
        expect(
          () => eventStatuses.update<Event>(EventA('1'), TestStatus.loading),
          throwsArgumentError,
        );
      });
    });

    group('statusOf', () {
      test('returns the status for an existing entry', () {
        final updated =
            eventStatuses.update<EventA>(EventA('1'), TestStatus.loading);

        expect(updated.statusOf<EventA>(), TestStatus.loading);
      });

      test('returns null when no entry exists', () {
        expect(eventStatuses.statusOf<EventA>(), isNull);
      });

      test('throws ArgumentError when TEventSubType is TEvent', () {
        expect(
          () => eventStatuses.statusOf<Event>(),
          throwsArgumentError,
        );
      });
    });

    group('eventOf', () {
      test('returns the event instance for an existing entry', () {
        final event = EventA('abc');
        final updated = eventStatuses.update<EventA>(event, TestStatus.success);

        expect(updated.eventOf<EventA>(), event);
        expect(updated.eventOf<EventA>()?.id, 'abc');
      });

      test('returns null when no entry exists', () {
        expect(eventStatuses.eventOf<EventA>(), isNull);
      });

      test('throws ArgumentError when TEventSubType is TEvent', () {
        expect(
          () => eventStatuses.eventOf<Event>(),
          throwsArgumentError,
        );
      });
    });

    group('eventStatusOf', () {
      test('returns the full record for an existing entry', () {
        final event = EventA('1');
        final updated = eventStatuses.update<EventA>(event, TestStatus.loading);

        final result = updated.eventStatusOf<EventA>();
        expect(result, isNotNull);
        expect(result!.event, event);
        expect(result.status, TestStatus.loading);
      });

      test('returns null when no entry exists', () {
        expect(eventStatuses.eventStatusOf<EventA>(), isNull);
      });

      test('throws ArgumentError when TEventSubType is TEvent', () {
        expect(
          () => eventStatuses.eventStatusOf<Event>(),
          throwsArgumentError,
        );
      });
    });

    group('lastEventStatus', () {
      test('returns null when empty', () {
        expect(eventStatuses.lastEventStatus, isNull);
      });

      test('tracks the most recent update', () {
        final eventA = EventA('1');
        final eventB = EventB(42);

        final updated = eventStatuses
            .update<EventA>(eventA, TestStatus.loading)
            .update<EventB>(eventB, TestStatus.success);

        expect(updated.lastEventStatus?.event, eventB);
        expect(updated.lastEventStatus?.status, TestStatus.success);
      });

      test('updates when the same event type is updated again', () {
        final event1 = EventA('1');
        final event2 = EventA('2');

        final updated = eventStatuses
            .update<EventA>(event1, TestStatus.loading)
            .update<EventA>(event2, TestStatus.success);

        expect(updated.lastEventStatus?.event, event2);
        expect(updated.lastEventStatus?.status, TestStatus.success);
      });
    });

    group('equality', () {
      test('two instances with the same updates are equal', () {
        final event = EventA('1');

        final a = eventStatuses.update<EventA>(event, TestStatus.loading);
        final b = eventStatuses.update<EventA>(event, TestStatus.loading);

        expect(a, equals(b));
      });

      test('two instances with different updates are not equal', () {
        final a = eventStatuses.update<EventA>(EventA('1'), TestStatus.loading);
        final b = eventStatuses.update<EventA>(EventA('1'), TestStatus.success);

        expect(a, isNot(equals(b)));
      });

      test('empty instances are equal', () {
        const a = EventStatuses<Event, TestStatus>();
        const b = EventStatuses<Event, TestStatus>();

        expect(a, equals(b));
      });
    });

    group('toString', () {
      test('produces readable output for empty instance', () {
        final result = eventStatuses.toString();
        expect(result, contains('EventStatuses'));
        expect(result, contains('eventStatusMap'));
      });

      test('includes event status entries', () {
        final updated =
            eventStatuses.update<EventA>(EventA('1'), TestStatus.loading);
        final result = updated.toString();

        expect(result, contains('EventA'));
      });
    });
  });
}
