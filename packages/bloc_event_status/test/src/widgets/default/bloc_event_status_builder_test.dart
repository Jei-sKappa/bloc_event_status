// ignore_reason: Use it only for testing
// ignore_for_file: invalid_use_of_protected_member

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fakes.dart';

class MockBloc extends Mock implements BlocEventStatusMixin<TestEvent, int> {}

// Test Bloc
class TestBloc extends Bloc<TestEvent, int>
    with BlocEventStatusMixin<TestEvent, int> {
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

void main() {
  group('BlocEventStatusBuilder', () {
    late TestBloc testBloc;

    setUpAll(() {
      registerFakes();
      registerFallbackValue(EventA(''));
      registerFallbackValue(EventB(-1));
      registerFallbackValue(const LoadingEventStatus());
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
      EventA? event,
      EventStatus? status,
    ) {
      final statusString = switch (status) {
        null => 'None',
        LoadingEventStatus() => 'loading',
        SuccessEventStatus() => 'success',
        FailureEventStatus() => 'failure',
      };
      return Text(
        'Event: ${event?.data ?? "None"}, Status: $statusString',
      );
    }

    testWidgets('renders initial state correctly (event and status are null)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None'), findsOneWidget);
    });

    testWidgets('rebuilds with correct event and status when status changes',
        (tester) async {
      final event1 = EventA('event1');
      final event2 = EventA('event2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None'), findsOneWidget);

      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();
      expect(find.text('Event: event1, Status: loading'), findsOneWidget);

      testBloc.emitSuccessStatus<EventA, Null>(event2);
      await tester.pumpAndSettle();
      expect(find.text('Event: event2, Status: success'), findsOneWidget);
    });

    testWidgets('rebuilds when filter returns true', (tester) async {
      final event1 = EventA('allowed');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                filter: (event) => event.data == 'allowed',
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();
      expect(find.text('Event: allowed, Status: loading'), findsOneWidget);
    });

    testWidgets('does not rebuild when filter returns false', (tester) async {
      final allowdEvent = EventA('allowed');
      final blockedEvent = EventA('blocked');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                // Only allow 'allowed' event
                filter: (event) => event.data == 'allowed',
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit allowed event - should rebuild
      testBloc.emitLoadingStatus(allowdEvent);
      await tester.pumpAndSettle();
      expect(find.text('Event: allowed, Status: loading'), findsOneWidget);

      // Emit blocked event - should NOT rebuild
      testBloc.emitSuccessStatus<EventA, Null>(blockedEvent);
      await tester.pumpAndSettle();
      // The widget should still show the previous state
      expect(find.text('Event: allowed, Status: loading'), findsOneWidget);
      // The blocked event should not be shown
      expect(find.text('Event: blocked, Status: success'), findsNothing);
    });

    testWidgets('rebuilds when buildWhen returns true', (tester) async {
      final event1 = EventA('event1');
      final event2 = EventA('event2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                // Only rebuild when status changes to success
                buildWhen: (_, current) =>
                    current == const SuccessEventStatus<Null>(),
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit loading status
      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();
      // Should not have rebuilt yet
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit success status
      testBloc.emitSuccessStatus<EventA, Null>(event2);
      await tester.pumpAndSettle();
      // Should rebuild
      expect(find.text('Event: event2, Status: success'), findsOneWidget);
    });

    testWidgets('does not rebuild when buildWhen returns false',
        (tester) async {
      final event1 = EventA('event1');
      final event2 = EventA('event2');
      final event3 = EventA('event3');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                // Only rebuild when status changes from loading to success
                buildWhen: (prev, current) =>
                    prev == const LoadingEventStatus() &&
                    current == const SuccessEventStatus<Null>(),
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // First update: initial -> loading
      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();
      // Should not have rebuilt yet
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Second update: loading -> success
      testBloc.emitSuccessStatus<EventA, Null>(event2);
      await tester.pumpAndSettle();
      // Should Rebuild
      expect(find.text('Event: event2, Status: success'), findsOneWidget);

      // Third update: success -> failure
      testBloc.emitFailureStatus(event3);
      await tester.pumpAndSettle();
      // Should not have rebuilt (should still show the previous state)
      expect(find.text('Event: event2, Status: success'), findsOneWidget);
      // The failure event should not be shown
      expect(find.text('Event: event3, Status: failure'), findsNothing);
    });

    testWidgets('uses bloc from context if bloc parameter is null',
        (tester) async {
      final event1 = EventA('event1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                // No bloc explicitly provided
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();

      expect(find.text('Event: event1, Status: loading'), findsOneWidget);
    });

    testWidgets('uses provided bloc parameter if available', (tester) async {
      final event1 = EventA('event1');

      final contextBloc = TestBloc();
      addTearDown(() async => contextBloc.close());

      final providedBloc = TestBloc();
      addTearDown(() async => providedBloc.close());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: contextBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                bloc: providedBloc, // Explicitly provide the BLoC
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit from the provided bloc - should rebuild
      providedBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();
      expect(find.text('Event: event1, Status: loading'), findsOneWidget);

      // Emit from the context bloc - should be ignored
      contextBloc.emitSuccessStatus<EventA, Null>(EventA('ignored'));
      await tester.pumpAndSettle();
      // Builder should not have changed
      expect(find.text('Event: event1, Status: loading'), findsOneWidget);
      expect(find.text('Event: ignored, Status: success'), findsNothing);
    });

    testWidgets('updates subscription and rebuilds when bloc instance changes',
        (tester) async {
      final eventA = EventA('fromA');
      final eventB = EventA('fromB');

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
            body: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
              bloc: blocA,
              builder: testBuilder,
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit from Bloc A - should rebuild
      blocA.emitLoadingStatus(eventA);
      await tester.pumpAndSettle();
      expect(find.text('Event: fromA, Status: loading'), findsOneWidget);

      // Rebuild with Bloc B
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
              bloc: blocB, // Switch to Bloc B
              builder: testBuilder,
            ),
          ),
        ),
      );

      // NOTE: When the bloc instance changes, the state resets (_event=null, _status=null)
      // before the new bloc potentially emits.
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit from Bloc A (should be ignored now)
      blocA.emitFailureStatus(EventA('ignored'));
      await tester.pumpAndSettle();
      // State should still be the reset state from the bloc change
      expect(find.text('Event: None, Status: None'), findsOneWidget);
      expect(find.text('Event: ignored, Status: failure'), findsNothing);

      // Emit from Bloc B (should be listened to)
      blocB.emitSuccessStatus<EventA, Null>(eventB);
      await tester.pumpAndSettle();
      expect(find.text('Event: fromB, Status: success'), findsOneWidget);
    });

    testWidgets(
        'handles initial status correctly in buildWhen (previous is null)',
        (tester) async {
      final event1 = EventA('event1');
      EventStatus? capturedPreviousStatus;
      EventStatus? capturedCurrentStatus;
      var buildWhenCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                buildWhen: (prev, current) {
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
      expect(find.text('Event: None, Status: None'), findsOneWidget);
      // buildWhen not called on initial build
      expect(buildWhenCalled, isFalse);

      // First update
      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();

      // buildWhen should have been called
      expect(buildWhenCalled, isTrue);
      // Previous should be null for the first emission
      expect(capturedPreviousStatus, isNull);
      expect(capturedCurrentStatus, const LoadingEventStatus());
      // Rebuilt
      expect(find.text('Event: event1, Status: loading'), findsOneWidget);
    });

    testWidgets('only listens to and rebuilds for the specified event subtype',
        (tester) async {
      final subEvent = EventA('sub');
      final otherEvent = EventB(10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: BlocEventStatusBuilder<TestBloc, TestEvent, EventA, int>(
                // Building specifically for EventA
                builder: testBuilder, // Uses EventA?
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit the correct subtype
      testBloc.emitLoadingStatus(subEvent);
      await tester.pumpAndSettle();
      expect(find.text('Event: sub, Status: loading'), findsOneWidget);

      // Emit a different subtype (should be ignored by the builder's listener)
      testBloc.emitSuccessStatus<EventB, Null>(otherEvent);
      await tester.pumpAndSettle();
      // The builder should not have changed state
      expect(find.text('Event: sub, Status: loading'), findsOneWidget);
    });
  });
}
