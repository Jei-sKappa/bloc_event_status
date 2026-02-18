// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// dart format off

part of 'todo_bloc.dart';

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

  void success<TData extends dynamic, T extends TodoEvent>(T event, TodoState state, [TData? data]) =>
      _emitEventStatus(event, SuccessEventStatus<TData>(data, ), state);

  void failure<TFailure extends Exception, T extends TodoEvent>(T event, TodoState state, [TFailure? error]) =>
      _emitEventStatus(event, FailureEventStatus<TFailure>(error, ), state);
}

// dart format on
