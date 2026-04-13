import 'package:bloc/bloc.dart';
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';

part 'main.bes.g.dart';

// --- Usage ---

Future<void> main() async {
  final bloc = TodoBloc();

  bloc.stream.listen((state) {
    final addStatus = state.statusOf<AddTodo>();
    if (addStatus != null) {
      print('AddTodo status: ${addStatus.runtimeType}');
    }

    final removeStatus = state.statusOf<RemoveTodo>();
    if (removeStatus != null) {
      print('RemoveTodo status: ${removeStatus.runtimeType}');
      if (removeStatus is FailureEventStatus) {
        print('  Failure reason: ${removeStatus.message}');
      }
    }

    print('  Todos: ${state.todos}');
  });

  bloc.add(const AddTodo('Buy groceries'));
  await Future<void>.delayed(const Duration(milliseconds: 50));
  bloc.add(const AddTodo('Walk the dog'));
  await Future<void>.delayed(const Duration(milliseconds: 50));
  bloc.add(const RemoveTodo(0));
  await Future<void>.delayed(const Duration(milliseconds: 50));
  bloc.add(const RemoveTodo(99)); // Will fail — index out of bounds
  await Future<void>.delayed(const Duration(milliseconds: 50));

  await bloc.close();
}

// --- Event Status ---

sealed class EventStatus extends Equatable {
  const EventStatus();

  @override
  List<Object?> get props => [];
}

class LoadingEventStatus extends EventStatus {
  const LoadingEventStatus();
}

class SuccessEventStatus extends EventStatus {
  const SuccessEventStatus();
}

class FailureEventStatus extends EventStatus {
  const FailureEventStatus(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---

@blocEventStatus
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState()) {
    on<AddTodo>(_onAddTodo);
    on<RemoveTodo>(_onRemoveTodo);
  }

  Future<void> _onAddTodo(AddTodo event, Emitter<TodoState> emit) async {
    emit.loading(event, state);

    await Future<void>.delayed(Duration.zero);

    emit.success(event, state.copyWith(todos: [...state.todos, event.title]));
  }

  Future<void> _onRemoveTodo(RemoveTodo event, Emitter<TodoState> emit) async {
    emit.loading(event, state);

    await Future<void>.delayed(Duration.zero);

    if (event.index < 0 || event.index >= state.todos.length) {
      emit.failure(event, state, 'Index out of bounds');
      return;
    }

    final updated = [...state.todos]..removeAt(event.index);
    emit.success(event, state.copyWith(todos: updated));
  }
}

// --- State ---

class TodoState extends Equatable
    with EventStatusesMixin<TodoEvent, EventStatus> {
  const TodoState({
    this.todos = const [],
    this.eventStatuses = const EventStatuses(),
  });

  final List<String> todos;

  @override
  final EventStatuses<TodoEvent, EventStatus> eventStatuses;

  TodoState copyWith({
    List<String>? todos,
    EventStatuses<TodoEvent, EventStatus>? eventStatuses,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      eventStatuses: eventStatuses ?? this.eventStatuses,
    );
  }

  @override
  List<Object?> get props => [todos, eventStatuses];
}

// --- Events ---

sealed class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class AddTodo extends TodoEvent {
  const AddTodo(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

class RemoveTodo extends TodoEvent {
  const RemoveTodo(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}
