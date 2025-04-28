import 'package:equatable/equatable.dart';

/// {@template event_status}
/// Represents the status of an event.
///
/// This class serves as the base for different event status states.
///
/// See also:
///   * [LoadingEventStatus], which represents a loading state
///   * [SuccessEventStatus], which represents a successful state with optional data
///   * [FailureEventStatus], which represents a failed state with optional error
/// {@endtemplate}
sealed class EventStatus with EquatableMixin {
  /// {@macro event_status}
  const EventStatus();

  @override
  List<Object?> get props => [];
}

/// {@template loading_event_status}
/// Represents the loading state of an event.
///
/// This status indicates that an operation is currently in progress.
/// {@endtemplate}
class LoadingEventStatus extends EventStatus {
  /// {@macro loading_event_status}
  const LoadingEventStatus();

  @override
  String toString() => 'LoadingEventStatus()';

  @override
  List<Object?> get props => [];
}

/// {@template success_event_status}
/// Represents a successful event status with optional data.
///
/// [TData] is the type of the data that can be carried by this status.
///
/// Example:
/// ```dart
/// final status = SuccessEventStatus<String>('Operation completed');
/// ```
/// {@endtemplate}
class SuccessEventStatus<TData> extends EventStatus {
  /// {@macro success_event_status}
  const SuccessEventStatus([this.data]);

  /// The optional data payload associated with the event status.
  ///
  /// Can be null if no data is associated with the event.
  final TData? data;

  @override
  String toString() => 'SuccessEventStatus($data)';

  @override
  List<Object?> get props => [data];
}

/// {@template failure_event_status}
/// Represents a failed event status with optional error information.
///
/// [TFailure] is the type of the error that can be carried by this status.
///
/// Example:
/// ```dart
/// final status = FailureEventStatus<String>('Operation failed');
/// ```
/// {@endtemplate}
class FailureEventStatus<TFailure extends Exception> extends EventStatus {
  /// {@macro failure_event_status}
  const FailureEventStatus([this.error]);

  /// The optional error payload associated with the event status.
  ///
  /// Can be null if no error is associated with the event.
  final TFailure? error;

  @override
  String toString() => 'FailureEventStatus($error)';

  @override
  List<Object?> get props => [error];
}
