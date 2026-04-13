import 'package:bloc_event_status/bloc_event_status.dart';

/// Extension that adds `buildWhen` / `listenWhen` helper methods to any
/// state that mixes in [EventStatusesMixin].
///
/// Call these on the **previous** state, passing **current** as the argument:
/// ```dart
/// buildWhen: (previous, current) => previous.statusChanged<MyEvent>(current),
/// ```
///
/// For pure change detection ([statusChanged], [eventStatusChanged],
/// [lastEventStatusChanged]) the call is symmetric — order doesn't matter.
/// For type-matching variants ([statusChangedTo], [eventStatusChangedTo],
/// [lastEventStatusChangedTo]) the type check is always against `current`.
extension EventStatusConditions<TEvent, TStatus>
    on EventStatusesMixin<TEvent, TStatus> {
  /// Returns `true` if `statusOf<E>()` differs between `this` and [current].
  ///
  /// Compares only the status value, ignoring event instance changes.
  /// Prefer this for `buildWhen` — avoids rebuilds when the same status
  /// type is re-emitted for a different event instance.
  ///
  /// ```dart
  /// buildWhen: (previous, current) =>
  ///     previous.statusChanged<MyEvent>(current),
  /// ```
  bool statusChanged<E extends TEvent>(
    EventStatusesMixin<TEvent, TStatus> current,
  ) => statusOf<E>() != current.statusOf<E>();

  /// Returns `true` if `eventStatusOf<E>()` differs between `this` and
  /// [current].
  ///
  /// Compares the full `({TEvent event, TStatus status})` record —
  /// detects re-emissions even when the status type is unchanged.
  /// Prefer this for `listenWhen` — reacts to every new emission.
  ///
  /// ```dart
  /// listenWhen: (previous, current) =>
  ///     previous.eventStatusChanged<MyEvent>(current),
  /// ```
  bool eventStatusChanged<E extends TEvent>(
    EventStatusesMixin<TEvent, TStatus> current,
  ) => eventStatusOf<E>() != current.eventStatusOf<E>();

  /// Returns `true` if `statusOf<E>()` changed AND [current]'s status
  /// for `E` is of type [S].
  ///
  /// ```dart
  /// buildWhen: (previous, current) =>
  ///     previous.statusChangedTo<MyEvent, LoadingStatus>(current),
  /// ```
  bool statusChangedTo<E extends TEvent, S extends TStatus>(
    EventStatusesMixin<TEvent, TStatus> current,
  ) => statusOf<E>() != current.statusOf<E>() && current.statusOf<E>() is S;

  /// Returns `true` if `eventStatusOf<E>()` changed AND [current]'s status
  /// for `E` is of type [S].
  ///
  /// The most common `listenWhen` helper — detects every new emission
  /// that lands on a specific status type.
  ///
  /// ```dart
  /// listenWhen: (previous, current) =>
  ///     previous.eventStatusChangedTo<MyEvent, FailureStatus>(current),
  /// ```
  bool eventStatusChangedTo<E extends TEvent, S extends TStatus>(
    EventStatusesMixin<TEvent, TStatus> current,
  ) =>
      eventStatusOf<E>() != current.eventStatusOf<E>() &&
      current.statusOf<E>() is S;

  /// Returns `true` if `lastEventStatus` differs between `this` and [current].
  ///
  /// ```dart
  /// listenWhen: (previous, current) =>
  ///     previous.lastEventStatusChanged(current),
  /// ```
  bool lastEventStatusChanged(
    EventStatusesMixin<TEvent, TStatus> current,
  ) => lastEventStatus != current.lastEventStatus;

  /// Returns `true` if `lastEventStatus` changed AND [current]'s last status
  /// is of type [S].
  ///
  /// ```dart
  /// listenWhen: (previous, current) =>
  ///     previous.lastEventStatusChangedTo<FailureStatus>(current),
  /// ```
  bool lastEventStatusChangedTo<S extends TStatus>(
    EventStatusesMixin<TEvent, TStatus> current,
  ) =>
      lastEventStatus != current.lastEventStatus &&
      current.lastEventStatus?.status is S;
}
