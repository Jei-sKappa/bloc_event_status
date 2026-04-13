import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template event_status_update}
/// A record type that associates an event with its updated status.
///
/// Type parameters:
/// - `TEvent`: The type of the event being updated.
/// - `TStatus`: The type of the status assigned to the event.
///
/// Fields:
/// - `event`: The event instance.
/// - `status`: The new status of the event.
/// {@endtemplate}
typedef EventStatusUpdate<TEvent, TStatus> = ({
  TEvent event,
  TStatus status,
});

/// {@template event_statuses}
/// An immutable container that tracks the status of each event type in a BLoC.
///
/// Each event type (`TEventSubType extends TEvent`) can have at most one
/// associated [EventStatusUpdate]. The container is keyed by the event's
/// runtime [Type], not by the event instance, so calling [update] for the
/// same event type replaces the previous entry.
///
/// Extends [Equatable] so that BLoC state changes are detected correctly.
///
/// Use `const EventStatuses()` as the initial value, then call [update]
/// inside your event handler and emit the returned copy via `copyWith`:
///
/// ```dart
/// emit(state.copyWith(
///   eventStatuses: state.eventStatuses.update<LoadRequested>(
///     event,
///     const LoadingEventStatus(),
///   ),
/// ));
/// ```
/// {@endtemplate}
@immutable
class EventStatuses<TEvent, TStatus> extends Equatable {
  /// {@macro event_statuses}
  const EventStatuses() : eventStatusMap = const {}, _lastEventStatus = null;

  const EventStatuses._(this.eventStatusMap, this._lastEventStatus);

  // Key: The type of the event (not the instance of the event itself)
  // Value: The event status
  /// The internal map from event [Type] to [EventStatusUpdate].
  ///
  /// Exposed only for testing; do not depend on this in production code.
  @visibleForTesting
  final Map<Type, EventStatusUpdate<TEvent, TStatus>> eventStatusMap;

  final EventStatusUpdate<TEvent, TStatus>? _lastEventStatus;

  @override
  List<Object?> get props => [eventStatusMap, _lastEventStatus];

  /// {@template event_statuses.event_status_of}
  /// Returns the full [EventStatusUpdate] record for [TEventSubType], or
  /// `null` if no status has been recorded for that event type.
  ///
  /// Throws [ArgumentError] if [TEventSubType] is the same as [TEvent]
  /// (the base event type), because statuses are tracked per concrete
  /// subtype.
  /// {@endtemplate}
  EventStatusUpdate<TEventSubType, TStatus>?
  eventStatusOf<TEventSubType extends TEvent>() {
    if (TEventSubType == TEvent) {
      throw ArgumentError(
        'The type parameter cannot be TEvent',
        'TEventSubType',
      );
    }

    // Cast from `TEvent` to `TEventSubType` because we made sure that it cannot
    // be the same type
    return eventStatusMap[TEventSubType]
        as EventStatusUpdate<TEventSubType, TStatus>?;
  }

  /// {@template event_statuses.status_of}
  /// Returns the current [TStatus] for [TEventSubType], or `null` if no
  /// status has been recorded for that event type.
  ///
  /// Shorthand for `eventStatusOf<TEventSubType>()?.status`.
  /// {@endtemplate}
  TStatus? statusOf<TEventSubType extends TEvent>() =>
      eventStatusOf<TEventSubType>()?.status;

  /// {@template event_statuses.event_of}
  /// Returns the last [TEventSubType] instance that was passed to [update],
  /// or `null` if no status has been recorded for that event type.
  ///
  /// Useful for retry patterns — pass the returned event back to the BLoC.
  ///
  /// Shorthand for `eventStatusOf<TEventSubType>()?.event`.
  /// {@endtemplate}
  TEventSubType? eventOf<TEventSubType extends TEvent>() =>
      eventStatusOf<TEventSubType>()?.event;

  /// {@template event_statuses.last_event_status}
  /// Returns the most recently updated [EventStatusUpdate], regardless of
  /// event type, or `null` if no updates have been recorded.
  ///
  /// Useful for driving a global loading indicator or activity log.
  /// {@endtemplate}
  EventStatusUpdate<TEvent, TStatus>? get lastEventStatus => _lastEventStatus;

  /// {@template event_statuses.update}
  /// Returns a **new** [EventStatuses] with the entry for [TEventSubType]
  /// set to the given [event] and [status].
  ///
  /// This does not mutate the current instance. The returned copy also
  /// records this update as the [lastEventStatus].
  ///
  /// Throws [ArgumentError] if [TEventSubType] is the same as [TEvent].
  /// {@endtemplate}
  EventStatuses<TEvent, TStatus> update<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status,
  ) {
    if (TEventSubType == TEvent) {
      throw ArgumentError(
        'The type parameter cannot be TEvent',
        'TEventSubType',
      );
    }

    final eventStatusMapCopy =
        Map<Type, EventStatusUpdate<TEvent, TStatus>>.from(eventStatusMap);

    final eventStatus = (event: event, status: status);

    // Update the event status map with the new event status
    eventStatusMapCopy[TEventSubType] = eventStatus;

    return EventStatuses._(eventStatusMapCopy, eventStatus);
  }

  @override
  String toString() {
    final buffer = StringBuffer()..write('EventStatuses(eventStatusMap: {');
    eventStatusMap.forEach((key, value) {
      buffer.write('$key: $value,');
    });
    buffer.write('}, _lastEventStatus: $_lastEventStatus');
    return buffer.toString();
  }
}
