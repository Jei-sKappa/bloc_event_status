import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:example/domain/domain.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:example/presentation/programmed_failure/cubit/programmed_failure_cubit.dart';

part 'todo_bloc.freezed.dart';
part 'todo_events.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState>
    with BlocEventStatusMixin<TodoEvent, TodoState> {
  TodoBloc({
    required ProgrammedFailureCubit programmedFailureCubit,
  })  : _programmedFailureCubit = programmedFailureCubit,
        super(const TodoState.initial()) {
    on<TodoLoadRequested>(handleEventStatus(_onLoadRequested));
    on<TodoAdded>(handleEventStatus(_onTodoAdded));
    on<TodoToggled>(handleEventStatus(_onTodoToggled));
    on<TodoCompletitionSet>(handleEventStatus(_onTodoCompletitionSet));
    on<TodoDeleted>(handleEventStatus(_onTodoDeleted));
    on<FilterSelected>(_onFilterSelected);
    on<QuerySet>(_onQuerySet);
  }

  final ProgrammedFailureCubit _programmedFailureCubit;

  // Future<void> _onLoadRequested(
  //   TodoLoadRequested event,
  //   Emitter<TodoState> emit,
  // ) async {
  //   if (state.todos.isNotEmpty) return;

  //   emitLoadingStatus(event);
  //   // emitEventStatus(event, LoadingEventStatus());
  //   // emitEventStatus(event, TodoStatus.loading);

  //   try {
  //     await expensiveTask();
  //   } catch (e) {
  //     emitFailureStatus(event, error: e);
  //     // emitEventStatus(event, FailureEventStatus(e));
  //     // emitEventStatus(event, TodoStatus.failure);
  //     return;
  //   }

  //   emit(state.copyWith(todos: initialTodos));

  //   emitSuccessStatus(event);
  //   // emitEventStatus(event, SuccessEventStatus());
  //   // emitEventStatus(event, TodoStatus.success);
  // }
  Future<void> _onLoadRequested(
    TodoLoadRequested event,
    Emitter<TodoState> emit,
  ) async {
    // await _expensiveTask();

    emit(state.copyWith(todos: initialTodos));
  }

  Future<void> _onTodoAdded(
    TodoAdded event,
    Emitter<TodoState> emit,
  ) async {
    await _expensiveTask();

    final newTodo = Todo(title: event.title);
    final updatedTodos = [...state.todos, newTodo];
    emit(state.copyWith(todos: updatedTodos));
  }

  Future<void> _onTodoToggled(
    TodoToggled event,
    Emitter<TodoState> emit,
  ) async {
    await _expensiveTask();

    final updatedTodos = state.todos.map((todo) {
      return todo.id == event.todo.id
          ? todo.copyWith(isDone: !todo.isDone)
          : todo;
    }).toList();
    emit(state.copyWith(todos: updatedTodos));
  }

  Future<void> _onTodoCompletitionSet(
    TodoCompletitionSet event,
    Emitter<TodoState> emit,
  ) async {
    final isAlreadySet =
        state.todos.firstWhere((todo) => todo.id == event.todo.id).isDone ==
            event.isDone;

    if (isAlreadySet) return;

    await _expensiveTask();

    final updatedTodos = state.todos.map((todo) {
      return todo.id == event.todo.id
          ? todo.copyWith(isDone: event.isDone)
          : todo;
    }).toList();
    emit(state.copyWith(todos: updatedTodos));
  }

  Future<void> _onTodoDeleted(
    TodoDeleted event,
    Emitter<TodoState> emit,
  ) async {
    bool isAlreadyDeleted = event.todo.isDeleted;
    if (isAlreadyDeleted) return;

    await _expensiveTask();

    final updatedTodos = state.todos.map((todo) {
      return todo.id == event.todo.id ? todo.copyWith(isDeleted: true) : todo;
    }).toList();
    emit(state.copyWith(todos: updatedTodos));
  }

  void _onFilterSelected(
    FilterSelected event,
    Emitter<TodoState> emit,
  ) {
    emit(state.copyWith(selectedFilter: event.filter));
  }

  void _onQuerySet(
    QuerySet event,
    Emitter<TodoState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  /// This task simulates a long-running task that takes 1.5 seconds to complete.
  /// It also can also randomly fail.
  Future<void> _expensiveTask() async {
    // Simulate a long-running task
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    switch (_programmedFailureCubit.state) {
      case true:
        throw Exception('Failed to perform the task: forced failure');
      case false:
        return;
      // case null:
      //   // Randomly decide whether to fail or not
      //   final randomNumber = Random().nextInt(100);
      //   if (randomNumber > 50) {
      //     throw Exception(
      //         'Failed to perform the task: random failure ($randomNumber)');
      //   }
    }
  }
}
