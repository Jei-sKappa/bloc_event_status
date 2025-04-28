// ignore_reason: Use it only for testing
// ignore_for_file: invalid_use_of_protected_member

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fakes.dart';

class MockBloc extends Mock
    implements BlocCustomEventStatusMixin<TestEvent, int, TestStatus> {}

// Test Bloc
class TestBloc extends Bloc<TestEvent, int>
    with BlocCustomEventStatusMixin<TestEvent, int, TestStatus> {
  TestBloc() : super(0) {
    on<EventA>((event, emit) => emit(state + 1));
    on<EventB>((event, emit) => emit(state - 1));
  }
}

// Test Events
sealed class TestEvent {}

@immutable
class EventA extends TestEvent {
  EventA(this.data);
  final String data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventA && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'EventA(data: $data)';
}

@immutable
class EventB extends TestEvent {
  EventB(this.data);
  final int data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventB && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'EventB(data: $data)';
}

// Test Status
enum TestStatus { initial, loading, success, failure }

void main() {
  group('MultiBlocBuilderWithCustomEventStatus', () {
    late TestBloc testBloc;

    setUpAll(() {
      registerFakes();
      registerFallbackValue(EventA(''));
      registerFallbackValue(EventB(-1));
      registerFallbackValue(TestStatus.initial);
    });

    setUp(() {
      testBloc = TestBloc();
    });

    tearDown(() async {
      await testBloc.close();
    });

    // Helper to create a standard builder for tests
    Widget testBuilder(
      BuildContext context,
      TestEvent? event,
      TestStatus? status,
      int state,
    ) {
      final eventDesc = switch (event) {
        null => 'None',
        final EventA event => 'EventA(${event.data})',
        final EventB event => 'EventB(${event.data})',
      };
      return Text(
        'Event: $eventDesc, Status: ${status?.name ?? "None"}, State: $state',
      );
    }

    testWidgets('renders initial state correctly (event and status are null)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);
    });

    testWidgets('rebuilds with correct event and status when status changes',
        (tester) async {
      final eventA = EventA('eventA');
      final eventB = EventB(123);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      testBloc.emitEventStatus(eventA, TestStatus.loading);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(eventA), Status: loading, State: 0'),
        findsOneWidget,
      );

      testBloc.emitEventStatus(eventB, TestStatus.success);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventB(123), Status: success, State: 0'),
        findsOneWidget,
      );
    });

    testWidgets('rebuilds when eventFilter returns true', (tester) async {
      final eventA = EventA('allowed');
      final eventB = EventB(10); // Also allowed

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                eventFilter: (event) =>
                    (event is EventA && event.data == 'allowed') ||
                    (event is EventB && event.data == 10),
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      testBloc.emitEventStatus(eventA, TestStatus.loading);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(allowed), Status: loading, State: 0'),
        findsOneWidget,
      );

      testBloc.emitEventStatus(eventB, TestStatus.success);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventB(10), Status: success, State: 0'),
        findsOneWidget,
      );
    });

    testWidgets('does not rebuild when eventFilter returns false',
        (tester) async {
      final allowedEvent = EventA('allowed');
      final blockedEventA = EventA('blocked');
      final blockedEventB = EventB(99);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                eventFilter: (event) =>
                    event is EventA && event.data == 'allowed',
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // Emit allowed event - should rebuild
      testBloc.emitEventStatus(allowedEvent, TestStatus.loading);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(allowed), Status: loading, State: 0'),
        findsOneWidget,
      );

      // Emit blocked EventA - should NOT rebuild
      testBloc.emitEventStatus(blockedEventA, TestStatus.success);
      await tester.pumpAndSettle();
      // The widget should still show the previous state
      expect(
        find.text('Event: EventA(allowed), Status: loading, State: 0'),
        findsOneWidget,
      );
      // The blocked event should not be shown
      expect(
        find.text('Event: EventA(blocked), Status: success, State: 0'),
        findsNothing,
      );

      // Emit blocked EventB - should NOT rebuild
      testBloc.emitEventStatus(blockedEventB, TestStatus.failure);
      await tester.pumpAndSettle();
      // The widget should still show the previous state
      expect(
        find.text('Event: EventA(allowed), Status: loading, State: 0'),
        findsOneWidget,
      );
      // The blocked event should not be shown
      expect(
        find.text('Event: EventB(99), Status: failure, State: 0'),
        findsNothing,
      );
    });

    testWidgets('rebuilds when buildWhenStatus returns true', (tester) async {
      final event1 = EventA('event1');
      final event2 = EventB(2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                // Only rebuild when status changes to success
                buildWhenStatus: (_, current) => current == TestStatus.success,
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // Emit loading status (EventA)
      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pumpAndSettle();
      // Should not have rebuilt yet
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // Emit success status (EventB)
      testBloc.emitEventStatus(event2, TestStatus.success);
      await tester.pumpAndSettle();
      // Should rebuild
      expect(
        find.text('Event: EventB(2), Status: success, State: 0'),
        findsOneWidget,
      );
    });

    testWidgets('does not rebuild when buildWhenStatus returns false',
        (tester) async {
      final event1 = EventA('event1');
      final event2 = EventB(2);
      final event3 = EventA('event3');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                // Only rebuild when status changes from loading to success
                buildWhenStatus: (prev, current) =>
                    prev == TestStatus.loading && current == TestStatus.success,
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // First update: initial -> loading (EventA)
      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pumpAndSettle();
      // Should not have rebuilt yet
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // Second update: loading -> success (EventB)
      testBloc.emitEventStatus(event2, TestStatus.success);
      await tester.pumpAndSettle();
      // Should Rebuild
      expect(
        find.text('Event: EventB(2), Status: success, State: 0'),
        findsOneWidget,
      );

      // Third update: success -> failure (EventA)
      testBloc.emitEventStatus(event3, TestStatus.failure);
      await tester.pumpAndSettle();
      // Should not have rebuilt (should still show the previous state)
      expect(
        find.text('Event: EventB(2), Status: success, State: 0'),
        findsOneWidget,
      );
      // The failure event should not be shown
      expect(
        find.text('Event: EventA(event3), Status: failure, State: 0'),
        findsNothing,
      );
    });

    testWidgets('uses bloc from context if bloc parameter is null',
        (tester) async {
      final event1 = EventA('event1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                // No bloc explicitly provided
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pumpAndSettle();

      expect(
        find.text('Event: EventA(event1), Status: loading, State: 0'),
        findsOneWidget,
      );
    });

    testWidgets('uses provided bloc parameter if available', (tester) async {
      final event1 = EventB(1);

      final contextBloc = TestBloc();
      addTearDown(() async => contextBloc.close());

      final providedBloc = TestBloc();
      addTearDown(() async => providedBloc.close());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: contextBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                bloc: providedBloc, // Explicitly provide the BLoC
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // Emit from the provided bloc - should rebuild
      providedBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventB(1), Status: loading, State: 0'),
        findsOneWidget,
      );

      // Emit from the context bloc - should be ignored
      contextBloc.emitEventStatus(EventA('ignored'), TestStatus.success);
      await tester.pumpAndSettle();
      // Builder should not have changed
      expect(
        find.text('Event: EventB(1), Status: loading, State: 0'),
        findsOneWidget,
      );
      expect(
        find.text('Event: EventA(ignored), Status: success, State: 0'),
        findsNothing,
      );
    });

    testWidgets('updates subscription and rebuilds when bloc instance changes',
        (tester) async {
      final eventA = EventA('fromA');
      final eventB = EventB(55);

      // Initial Bloc
      final blocA = TestBloc();
      addTearDown(() async => blocA.close());

      // New Bloc
      final blocB = TestBloc();
      addTearDown(() async => blocB.close());

      // Build with Bloc A
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                int, TestStatus>(
              bloc: blocA,
              builder: testBuilder,
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // Emit from Bloc A - should rebuild
      blocA.emitEventStatus(eventA, TestStatus.loading);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(fromA), Status: loading, State: 0'),
        findsOneWidget,
      );

      // Rebuild with Bloc B
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                int, TestStatus>(
              bloc: blocB, // Switch to Bloc B
              builder: testBuilder,
            ),
          ),
        ),
      );

      // NOTE: When the bloc instance changes, the state resets (_event=null, _status=null)
      // before the new bloc potentially emits.
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);

      // Emit from Bloc A (should be ignored now)
      blocA.emitEventStatus(EventA('ignored'), TestStatus.failure);
      await tester.pumpAndSettle();
      // State should still be the reset state from the bloc change
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);
      expect(
        find.text('Event: EventA(ignored), Status: failure, State: 0'),
        findsNothing,
      );

      // Emit from Bloc B (should be listened to)
      blocB.emitEventStatus(eventB, TestStatus.success);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventB(55), Status: success, State: 0'),
        findsOneWidget,
      );
    });

    testWidgets(
        'handles initial status correctly in buildWhenStatus (previous is null)',
        (tester) async {
      final event1 = EventA('event1');
      TestStatus? capturedPreviousStatus;
      TestStatus? capturedCurrentStatus;
      var buildWhenCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocBuilderWithCustomEventStatus<TestBloc, TestEvent,
                  int, TestStatus>(
                buildWhenStatus: (prev, current) {
                  buildWhenCalled = true;
                  capturedPreviousStatus = prev;
                  capturedCurrentStatus = current;
                  return true; // Always rebuild for verification
                },
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None, State: 0'), findsOneWidget);
      // buildWhen not called on initial build
      expect(buildWhenCalled, isFalse);

      // First update
      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pumpAndSettle();

      // buildWhen should have been called
      expect(buildWhenCalled, isTrue);
      // Previous should be null for the first emission
      expect(capturedPreviousStatus, isNull);
      expect(capturedCurrentStatus, TestStatus.loading);
      // Rebuilt
      expect(
        find.text('Event: EventA(event1), Status: loading, State: 0'),
        findsOneWidget,
      );
    });
  });
}
