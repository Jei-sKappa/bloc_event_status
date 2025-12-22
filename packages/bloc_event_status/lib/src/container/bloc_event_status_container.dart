import 'dart:async';

import 'package:meta/meta.dart';

typedef _EventStatusStreamControllerWithLastUpdate<TEvent, TStatus> = ({
  EventStatusUpdate<TEvent, TStatus>? lastEventStatusUpdate,
  StreamController<
      EventStatusUpdate<TEvent, TStatus>> eventStatusStreamController,
});

/// A record type that associates an event with its updated status.
///
/// Type parameters:
/// - `TEvent`: The type of the event being updated.
/// - `TStatus`: The type of the status assigned to the event.
///
/// Fields:
/// - `event`: The event instance.
/// - `status`: The new status of the event.
typedef EventStatusUpdate<TEvent, TStatus> = ({
  TEvent event,
  TStatus status,
});

/// {@template bloc_event_status_container}
/// A container that tracks and broadcasts status updates for bloc events.
///
/// Maintains the latest status per event subtype and across all events, and
/// exposes broadcast streams for listening to updates globally or by subtype.
/// Errors encountered during emission are forwarded to the underlying bloc’s
/// error handler.
///
/// Type parameters:
/// - TEvent: The base type of events handled by the bloc.
/// - TState: The state type of the wrapped bloc (unused internally).
/// - TStatus: The type used to represent status values.
/// {@endtemplate}
@visibleForTesting
class BlocEventStatusContainer<TEvent, TState, TStatus> {
  /// {@macro bloc_event_status_container}
  ///
  /// Creates a [BlocEventStatusContainer].
  ///
  /// The container uses the bloc to report errors when emitting statuses and
  /// to close resources when [close] is called.
  ///
  /// Parameters:
  /// - bloc: The underlying bloc whose lifecycle and error handling will be
  /// used.
  BlocEventStatusContainer();

  /// Whether the container is closed.
  ///
  /// A container is considered closed once [close] is called.
  /// Subsequent state changes cannot occur within a closed container.
  bool isClosed = false;

  // Retrieved only by type
  final Map<Type, _EventStatusStreamControllerWithLastUpdate<TEvent, TStatus>>
      _eventStatusStreamControllerWithLastUpdateMap = {};

  _EventStatusStreamControllerWithLastUpdate<TEvent, TStatus>
      _allEventStatusStreamControllerWithLastUpdate = (
    lastEventStatusUpdate: null,
    eventStatusStreamController:
        StreamController<EventStatusUpdate<TEvent, TStatus>>.broadcast(),
  );

  _EventStatusStreamControllerWithLastUpdate<TEventSubType, TStatus>
      _getEventStatusStreamControllerWithLastUpdateValue<
          TEventSubType extends TEvent>() {
    _EventStatusStreamControllerWithLastUpdate<TEventSubType, TStatus>
        createEmptyData() => (
              lastEventStatusUpdate: null,
              eventStatusStreamController: StreamController<
                  EventStatusUpdate<TEventSubType, TStatus>>.broadcast()
            );

    if (TEventSubType == TEvent) {
      throw ArgumentError(
        'The type parameter cannot be TEvent',
        'TEventSubType',
      );
    }

    final eventStatusStreamControllerWithLastUpdate =
        _eventStatusStreamControllerWithLastUpdateMap.putIfAbsent(
      TEventSubType,
      createEmptyData,
    );

    // Cast from TEvent to TEventSubType because we prevented it from being the
    // same type
    return eventStatusStreamControllerWithLastUpdate
        as _EventStatusStreamControllerWithLastUpdate<TEventSubType, TStatus>;
  }

  /// {@template bloc_event_status_container.status_of_all_events}
  /// Returns the most recent event status update emitted across all event
  /// types.
  ///
  /// Returns `null` if no statuses have been emitted yet.
  /// {@endtemplate}
  EventStatusUpdate<TEvent, TStatus>? eventStatusOfAllEvents() {
    return _allEventStatusStreamControllerWithLastUpdate.lastEventStatusUpdate;
  }

  /// {@template bloc_event_status_container.stream_status_of_all_events}
  /// Returns a broadcast [Stream] of all event status updates.
  ///
  /// Each subscriber will receive every [EventStatusUpdate] emitted via
  /// [emitEventStatus], regardless of the event subtype.
  /// {@endtemplate}
  Stream<EventStatusUpdate<TEvent, TStatus>> streamEventStatusOfAllEvents() =>
      _allEventStatusStreamControllerWithLastUpdate
          .eventStatusStreamController.stream;

  /// {@template bloc_event_status_container.status_of}
  /// Returns the most recent event status update emitted for events of type
  /// [TEventSubType].
  ///
  /// Returns `null` if no statuses for that subtype have been emitted yet.
  ///
  /// Type parameters:
  /// - TEventSubType: The specific subtype of [TEvent] to query.
  /// {@endtemplate}
  EventStatusUpdate<TEventSubType, TStatus>?
      eventStatusOf<TEventSubType extends TEvent>() {
    return _getEventStatusStreamControllerWithLastUpdateValue<TEventSubType>()
        .lastEventStatusUpdate;
  }

  /// {@template bloc_event_status_container.stream_status_of}
  /// Returns a broadcast [Stream] of [EventStatusUpdate]s for events of type
  /// [TEventSubType].
  ///
  /// Subscribers only receive updates for the specified event subtype.
  ///
  /// Type parameters:
  /// - TEventSubType: The specific subtype of [TEvent] to listen for.
  /// {@endtemplate}
  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamEventStatusOf<TEventSubType extends TEvent>() {
    return _getEventStatusStreamControllerWithLastUpdateValue<TEventSubType>()
        .eventStatusStreamController
        .stream;
  }

  /// {@template bloc_event_status_container.emit_event_status}
  /// Emits a new [status] for the given [event] of type [TEventSubType].
  ///
  /// Updates internal state (per-subtype and global last status) and broadcasts
  /// the update to both the type-specific and global streams. Throws a
  /// [StateError] if the container or underlying bloc has been closed.
  /// Any errors during emission are forwarded to the bloc’s `onError`.
  ///
  /// Type parameters:
  /// - TEventSubType: The subtype of [TEvent] being emitted.
  ///
  /// Parameters:
  /// - event: The event instance for which the status is emitted.
  /// - status: The new status value to emit.
  /// {@endtemplate}
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status,
  ) {
    if (isClosed) {
      throw StateError('Cannot emit new states after calling close');
    }

    // This is wrong
    //// if (status == statusOf<TEventSubType>()) return;

    final eventStatusStreamControllerWithLastUpdate =
        _getEventStatusStreamControllerWithLastUpdateValue<TEventSubType>();

    // Save the last update for the specific event type
    _eventStatusStreamControllerWithLastUpdateMap[TEventSubType] = (
      // Update the status
      lastEventStatusUpdate: (
        event: event,
        status: status,
      ),
      // Keep the stream controller as is
      eventStatusStreamController:
          eventStatusStreamControllerWithLastUpdate.eventStatusStreamController,
    );

    // Add the status to the stream controller for the specific event type
    eventStatusStreamControllerWithLastUpdate.eventStatusStreamController.add(
      (
        event: event,
        status: status,
      ),
    );

    // Save the last update for all events
    _allEventStatusStreamControllerWithLastUpdate = (
      lastEventStatusUpdate: (
        event: event,
        status: status,
      ),
      eventStatusStreamController: _allEventStatusStreamControllerWithLastUpdate
          .eventStatusStreamController,
    );

    // Add the status to the global stream controller
    _allEventStatusStreamControllerWithLastUpdate.eventStatusStreamController
        .add(
      (
        event: event,
        status: status,
      ),
    );
  }

  /// {@template bloc_event_status_container.close}
  /// Closes all internal resources.
  ///
  /// After calling this method, no further status updates can be emitted.
  /// Returns a [Future] that completes once all streams have been properly
  /// closed.
  /// {@endtemplate}
  @mustCallSuper
  Future<void> close() async {
    await _allEventStatusStreamControllerWithLastUpdate
        .eventStatusStreamController
        .close();
    // Single events
    for (final record in _eventStatusStreamControllerWithLastUpdateMap.values) {
      await record.eventStatusStreamController.close();
    }
    _eventStatusStreamControllerWithLastUpdateMap.clear();
  }
}
