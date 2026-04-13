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
    TodoEventStatus status,
    TodoState state,
  ) {
    this(
      state.copyWith(
        eventStatuses: state.eventStatuses.update(event, status),
      ),
    );
  }

  void loading<T extends TodoEvent>(T event, TodoState state) =>
      _emitEventStatus(event, const LoadingTodoEventStatus(), state);

  void success<TData extends Object?, T extends TodoEvent>(T event, TodoState state, [TData? data]) =>
      _emitEventStatus(event, SuccessTodoEventStatus<TData>(data, ), state);

  void failure<T extends TodoEvent>(T event, TodoState state, Exception error) =>
      _emitEventStatus(event, FailureTodoEventStatus(error, ), state);
}

// dart format on
