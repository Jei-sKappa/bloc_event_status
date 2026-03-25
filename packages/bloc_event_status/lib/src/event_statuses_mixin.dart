import 'package:bloc_event_status/bloc_event_status.dart';

/// {@template event_statuses_mixin}
/// A mixin that adds convenience accessors for [EventStatuses] directly
/// on your BLoC state class.
///
/// Requires implementing `EventStatuses<TEvent, TStatus> get eventStatuses`.
/// Delegates [statusOf], [eventOf], [eventStatusOf], and [lastEventStatus]
/// to the underlying [eventStatuses] instance, so you can write
/// `state.statusOf<LoadRequested>()` instead of
/// `state.eventStatuses.statusOf<LoadRequested>()`.
/// {@endtemplate}
mixin EventStatusesMixin<TEvent, TStatus> {
  /// {@macro event_statuses}
  EventStatuses<TEvent, TStatus> get eventStatuses;

  /// {@macro event_statuses.event_status_of}
  EventStatusUpdate<TEventSubType, TStatus>?
      eventStatusOf<TEventSubType extends TEvent>() =>
          eventStatuses.eventStatusOf<TEventSubType>();

  /// {@macro event_statuses.status_of}
  TStatus? statusOf<TEventSubType extends TEvent>() =>
      eventStatuses.statusOf<TEventSubType>();

  /// {@macro event_statuses.event_of}
  TEventSubType? eventOf<TEventSubType extends TEvent>() =>
      eventStatuses.eventOf<TEventSubType>();

  /// {@macro event_statuses.last_event_status}
  EventStatusUpdate<TEvent, TStatus>? get lastEventStatus =>
      eventStatuses.lastEventStatus;
}
