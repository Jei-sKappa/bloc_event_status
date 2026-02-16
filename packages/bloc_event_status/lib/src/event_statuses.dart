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
/// // TODO: Add Docs
/// {@endtemplate}
@immutable
class EventStatuses<TEvent, TStatus> extends Equatable {
  /// {@macro event_statuses}
  const EventStatuses()
      : eventStatusMap = const {},
        _lastEventStatus = null;

  const EventStatuses._(this.eventStatusMap, this._lastEventStatus);

  // Key: The type of the event (not the instance of the event itself)
  // Value: The event status
  @visibleForTesting
  // ignore_reason: This is a test-only property
  // ignore: public_member_api_docs
  final Map<Type, EventStatusUpdate<TEvent, TStatus>> eventStatusMap;

  final EventStatusUpdate<TEvent, TStatus>? _lastEventStatus;

  @override
  List<Object?> get props => [eventStatusMap, _lastEventStatus];

  /// {@template event_statuses.event_status_of}
  /// // TODO: Add Docs
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
  /// // TODO: Add Docs
  /// {@endtemplate}
  TStatus? statusOf<TEventSubType extends TEvent>() =>
      eventStatusOf<TEventSubType>()?.status;

  /// {@template event_statuses.event_of}
  /// // TODO: Add Docs
  /// {@endtemplate}
  TEventSubType? eventOf<TEventSubType extends TEvent>() =>
      eventStatusOf<TEventSubType>()?.event;

  /// {@template event_statuses.last_event_status}
  /// // TODO: Add Docs
  /// {@endtemplate}
  EventStatusUpdate<TEvent, TStatus>? get lastEventStatus => _lastEventStatus;

  /// {@template event_statuses.update}
  /// // TODO: Add Docs
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
