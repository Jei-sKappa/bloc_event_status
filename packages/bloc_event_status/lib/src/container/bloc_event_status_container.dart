import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:meta/meta.dart';

typedef _MapData<TEvent, TStatus> = ({
  TStatus? status,
  StreamController<EventStatusUpdate<TEvent, TStatus>> streamController,
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
  /// Creates a [BlocEventStatusContainer] that wraps the given [_bloc].
  ///
  /// The container uses the bloc to report errors when emitting statuses and
  /// to close resources when [close] is called.
  ///
  /// Parameters:
  /// - bloc: The underlying bloc whose lifecycle and error handling will be
  /// used.
  BlocEventStatusContainer(this._bloc);

  /// Whether the container is closed.
  ///
  /// A container is considered closed once [close] is called.
  /// Subsequent state changes cannot occur within a closed container.
  bool isClosed = false;

  final BlocCustomEventStatusMixin<TEvent, TState, TStatus> _bloc;

  // Retrieved only by type
  final Map<Type, _MapData<TEvent, TStatus>> _eventStatusMap = {};

  TStatus? _lastStatusOfAllEvents;

  final _allEventStatusStreamController =
      StreamController<EventStatusUpdate<TEvent, TStatus>>.broadcast();

  _MapData<TEventSubType, TStatus>
      _getEventStatusMapValue<TEventSubType extends TEvent>() {
    if (TEventSubType == TEvent) {
      throw ArgumentError(
        'The type parameter cannot be TEvent',
        'TEventSubType',
      );
    }

    return _eventStatusMap.putIfAbsent(TEventSubType, _ifAbsent<TEventSubType>)
        as _MapData<TEventSubType, TStatus>;
  }

  _MapData<TEventSubType, TStatus> _ifAbsent<TEventSubType extends TEvent>() =>
      (
        status: null,
        streamController: StreamController<
            EventStatusUpdate<TEventSubType, TStatus>>.broadcast()
      );

  void _updateStatusInMap<TEventSubType extends TEvent>(TStatus status) {
    final record = _getEventStatusMapValue<TEventSubType>();

    _eventStatusMap[TEventSubType] = (
      // Update the status
      status: status,
      // Keep the stream controller as is
      streamController: record.streamController,
    );
  }

  /// {@template bloc_event_status_container.status_of_all_events}
  /// Returns the most recent status emitted across all event types.
  ///
  /// Returns `null` if no statuses have been emitted yet.
  /// {@endtemplate}
  TStatus? statusOfAllEvents() {
    return _lastStatusOfAllEvents;
  }

  /// {@template bloc_event_status_container.stream_status_of_all_events}
  /// Returns a broadcast [Stream] of all event status updates.
  ///
  /// Each subscriber will receive every [EventStatusUpdate] emitted via
  /// [emitEventStatus], regardless of the event subtype.
  /// {@endtemplate}
  Stream<EventStatusUpdate<TEvent, TStatus>> streamStatusOfAllEvents() =>
      _allEventStatusStreamController.stream;

  /// {@template bloc_event_status_container.status_of}
  /// Returns the most recent status emitted for events of type [TEventSubType].
  ///
  /// Returns `null` if no statuses for that subtype have been emitted yet.
  ///
  /// Type parameters:
  /// - TEventSubType: The specific subtype of [TEvent] to query.
  /// {@endtemplate}
  TStatus? statusOf<TEventSubType extends TEvent>() {
    return _getEventStatusMapValue<TEventSubType>().status;
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
      streamStatusOf<TEventSubType extends TEvent>() {
    return _getEventStatusMapValue<TEventSubType>().streamController.stream;
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

    try {
      // This is wrong
      //// if (status == statusOf<TEventSubType>()) return;

      // Update the status
      _updateStatusInMap<TEventSubType>(status);

      // Update the last status
      _lastStatusOfAllEvents = status;

      // Add the status to the stream
      _getEventStatusMapValue<TEventSubType>().streamController.add(
        (
          event: event,
          status: status,
        ),
      );

      // Add the event with the status to the event-specific streamcontroller
      _allEventStatusStreamController.add(
        (
          event: event,
          status: status,
        ),
      );
    } catch (error, stackTrace) {
      // This class is wrapping a Bloc
      // ignore: invalid_use_of_protected_member
      _bloc.onError(error, stackTrace);
      rethrow;
    }
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
    await _allEventStatusStreamController.close();
    // Single events
    for (final record in _eventStatusMap.values) {
      await record.streamController.close();
    }
    _eventStatusMap.clear();
  }
}
