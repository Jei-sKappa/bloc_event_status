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

// Test State using the mixin
class TestState with EventStatusesMixin<Event, TestStatus> {
  const TestState({this.eventStatuses = const EventStatuses()});

  @override
  final EventStatuses<Event, TestStatus> eventStatuses;
}

void main() {
  group('EventStatusesMixin', () {
    test('statusOf delegates to eventStatuses', () {
      final event = EventA('1');
      final state = TestState(
        eventStatuses: const EventStatuses<Event, TestStatus>()
            .update<EventA>(event, TestStatus.loading),
      );

      expect(state.statusOf<EventA>(), TestStatus.loading);
      expect(
        state.statusOf<EventA>(),
        state.eventStatuses.statusOf<EventA>(),
      );
    });

    test('eventOf delegates to eventStatuses', () {
      final event = EventA('abc');
      final state = TestState(
        eventStatuses: const EventStatuses<Event, TestStatus>()
            .update<EventA>(event, TestStatus.success),
      );

      expect(state.eventOf<EventA>(), event);
      expect(
        state.eventOf<EventA>(),
        state.eventStatuses.eventOf<EventA>(),
      );
    });

    test('eventStatusOf delegates to eventStatuses', () {
      final event = EventA('1');
      final state = TestState(
        eventStatuses: const EventStatuses<Event, TestStatus>()
            .update<EventA>(event, TestStatus.loading),
      );

      final result = state.eventStatusOf<EventA>();
      expect(result, isNotNull);
      expect(result!.event, event);
      expect(result.status, TestStatus.loading);
      expect(
        state.eventStatusOf<EventA>(),
        state.eventStatuses.eventStatusOf<EventA>(),
      );
    });

    test('lastEventStatus delegates to eventStatuses', () {
      final event = EventA('1');
      final state = TestState(
        eventStatuses: const EventStatuses<Event, TestStatus>()
            .update<EventA>(event, TestStatus.loading),
      );

      expect(state.lastEventStatus, isNotNull);
      expect(state.lastEventStatus?.event, event);
      expect(state.lastEventStatus, state.eventStatuses.lastEventStatus);
    });

    test('returns null values when no entries exist', () {
      const state = TestState();

      expect(state.statusOf<EventA>(), isNull);
      expect(state.eventOf<EventA>(), isNull);
      expect(state.eventStatusOf<EventA>(), isNull);
      expect(state.lastEventStatus, isNull);
    });
  });
}
