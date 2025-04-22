import 'package:equatable/equatable.dart';

sealed class EventStatus with EquatableMixin {
  const EventStatus();

  @override
  List<Object?> get props => [];
}

class InitialEventStatus extends EventStatus {
  const InitialEventStatus();

  @override
  String toString() => 'InitialEventStatus()';

  @override
  List<Object?> get props => [];
}

class LoadingEventStatus extends EventStatus {
  const LoadingEventStatus();

  @override
  String toString() => 'LoadingEventStatus()';

  @override
  List<Object?> get props => [];
}

class SuccessEventStatus<TData> extends EventStatus {
  const SuccessEventStatus([this.data]);

  final TData? data;

  @override
  String toString() => 'SuccessEventStatus($data)';

  @override
  List<Object?> get props => [data];
}

class FailureEventStatus<TFailure> extends EventStatus {
  const FailureEventStatus([this.error]);

  final TFailure? error;

  @override
  String toString() => 'FailureEventStatus($error)';

  @override
  List<Object?> get props => [error];
}
