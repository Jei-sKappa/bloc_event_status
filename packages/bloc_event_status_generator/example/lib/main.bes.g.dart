// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// dart format off

part of 'main.dart';

// **************************************************************************
// BlocEventStatusGenerator
// **************************************************************************

// dart format off

extension $TodoBlocEmitterX on Emitter<TodoState> {
  void _emitEventStatus<T extends TodoEvent>(
    T event,
    EventStatus status,
    TodoState state,
  ) {
    this(
      state.copyWith(
        eventStatuses: state.eventStatuses.update(event, status),
      ),
    );
  }

  void loading<T extends TodoEvent>(T event, TodoState state) =>
      _emitEventStatus(event, const LoadingEventStatus(), state);

  void success<T extends TodoEvent>(T event, TodoState state) =>
      _emitEventStatus(event, const SuccessEventStatus(), state);

  void failure<T extends TodoEvent>(T event, TodoState state, String message) =>
      _emitEventStatus(event, FailureEventStatus(message, ), state);
}

// dart format on
