import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'main.bes.g.dart';

void main() {
  runApp(const TodoExampleApp());
}

class TodoExampleApp extends StatelessWidget {
  const TodoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) =>
            TodoBloc()..add(const TodoLoadRequested(reason: 'app start')),
        child: const TodoHomePage(),
      ),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTodo() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      return;
    }

    context.read<TodoBloc>().add(TodoAdded(title));
  }

  void _showMessage(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction,
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TodoBloc, TodoState>(
          listenWhen: (previous, current) =>
              previous.statusChangedTo<
                TodoLoadRequested,
                SuccessTodoEventStatus<String>
              >(current),
          listener: (context, state) {
            final loadEvent = state.eventOf<TodoLoadRequested>();
            if (loadEvent?.reason == 'app start') {
              return;
            }

            final status = state.statusOf<TodoLoadRequested>();
            if (status is SuccessTodoEventStatus<String>) {
              _showMessage(context, status.data ?? 'Sample todos loaded');
            }
          },
        ),
        BlocListener<TodoBloc, TodoState>(
          listenWhen: (previous, current) =>
              previous.eventStatusChanged<TodoAdded>(current) &&
              current.statusOf<TodoAdded>() is SuccessTodoEventStatus<String>,
          listener: (context, state) {
            final event = state.eventOf<TodoAdded>()!;
            final status =
                state.statusOf<TodoAdded>()! as SuccessTodoEventStatus<String>;

            _controller.clear();
            _showMessage(
              context,
              status.data ?? 'Added "${event.title}"',
            );
          },
        ),
        BlocListener<TodoBloc, TodoState>(
          listenWhen: (previous, current) => previous
              .eventStatusChangedTo<TodoLoadRequested, FailureTodoEventStatus>(
                current,
              ),
          listener: (context, state) {
            final eventStatus = state.eventStatusOf<TodoLoadRequested>()!;
            final error = (eventStatus.status as FailureTodoEventStatus).error;

            _showMessage(
              context,
              'Loading failed: ${_formatException(error)}',
              actionLabel: 'Retry',
              onAction: () {
                context.read<TodoBloc>().add(eventStatus.event);
              },
            );
          },
        ),
        BlocListener<TodoBloc, TodoState>(
          listenWhen: (previous, current) =>
              previous.lastEventStatusChangedTo<FailureTodoEventStatus>(
                current,
              ) &&
              current.lastEventStatus?.event is! TodoLoadRequested,
          listener: (context, state) {
            final lastEventStatus = state.lastEventStatus!;
            final error =
                (lastEventStatus.status as FailureTodoEventStatus).error;

            _showMessage(
              context,
              '${_describeEvent(lastEventStatus.event)} failed: '
              '${_formatException(error)}',
              actionLabel: 'Retry',
              onAction: () {
                context.read<TodoBloc>().add(lastEventStatus.event);
              },
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BlocEventStatus Example'),
          actions: [
            IconButton(
              tooltip: 'Reload sample todos',
              onPressed: () {
                context.read<TodoBloc>().add(
                  const TodoLoadRequested(reason: 'toolbar reload'),
                );
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            BlocSelector<
              TodoBloc,
              TodoState,
              EventStatusUpdate<TodoEvent, TodoEventStatus>?
            >(
              selector: (state) => state.lastEventStatus,
              builder: (context, lastEventStatus) {
                if (lastEventStatus?.status is LoadingTodoEventStatus) {
                  return const LinearProgressIndicator(minHeight: 3);
                }

                return const SizedBox(height: 3);
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ComposerCard(
                    controller: _controller,
                    onAdd: _addTodo,
                    onFailureModeChanged: (value) {
                      context.read<TodoBloc>().add(
                        FailureModeToggled(enabled: value),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Todos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const _TodoListSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.controller,
    required this.onAdd,
    required this.onFailureModeChanged,
  });

  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<bool> onFailureModeChanged;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoState, bool>(
      selector: (state) => state.isFailureArmed,
      builder: (context, isFailureArmed) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try the package',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'This demo focuses on the Todo flow while still using '
                  '`bloc_event_status` to drive loading, success, failure, '
                  'retry, and per-item progress states.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onAdd(),
                        decoration: const InputDecoration(
                          labelText: 'New todo',
                          hintText: 'Write docs, ship package, review PR',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_task),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: isFailureArmed,
                  onChanged: onFailureModeChanged,
                  title: const Text('Fail the next async todo action'),
                  subtitle: const Text(
                    'The next load, add, toggle, or delete emits '
                    'FailureTodoEventStatus, then the switch turns itself off.',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodoListSection extends StatelessWidget {
  const _TodoListSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      buildWhen: (previous, current) =>
          previous.todos.map((todo) => todo.id).join(',') !=
          current.todos.map((todo) => todo.id).join(','),
      builder: (context, state) {
        if (state.todos.isEmpty) {
          return const _EmptyTodosCard();
        }

        return Column(
          children: [
            for (final todo in state.todos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TodoTile(todoId: todo.id),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyTodosCard extends StatelessWidget {
  const _EmptyTodosCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 32),
            const SizedBox(height: 12),
            Text(
              'No todos yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the field above to add one, or tap refresh to reload the '
              'sample data.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.todoId});

  final String todoId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      buildWhen: (previous, current) =>
          previous.eventStatusChanged<TodoToggled>(current) &&
          current.eventStatusOf<TodoToggled>()?.event.todo.id == todoId,
      builder: (context, state) {
        final todo = state.todos.firstWhere((todo) => todo.id == todoId);
        return Card(
          child: ListTile(
            leading: _TodoToggleButton(todo: todo),
            title: Text(
              todo.title,
              style: TextStyle(
                decoration: todo.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: _TodoDeleteButton(todo: todo),
          ),
        );
      },
    );
  }
}

class _TodoToggleButton extends StatelessWidget {
  const _TodoToggleButton({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      buildWhen: (previous, current) {
        final previousEvent = previous.eventOf<TodoToggled>();
        final currentEvent = current.eventOf<TodoToggled>();

        final isThisTodo =
            previousEvent?.todo.id == todo.id ||
            currentEvent?.todo.id == todo.id;

        return isThisTodo && previous.eventStatusChanged<TodoToggled>(current);
      },
      builder: (context, state) {
        final isLoading =
            state.statusOf<TodoToggled>() is LoadingTodoEventStatus &&
            state.eventOf<TodoToggled>()?.todo.id == todo.id;

        if (isLoading) {
          return const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return Checkbox(
          value: todo.isDone,
          onChanged: (_) {
            context.read<TodoBloc>().add(TodoToggled(todo));
          },
        );
      },
    );
  }
}

class _TodoDeleteButton extends StatelessWidget {
  const _TodoDeleteButton({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      buildWhen: (previous, current) {
        final previousEvent = previous.eventOf<TodoDeleted>();
        final currentEvent = current.eventOf<TodoDeleted>();

        final isThisTodo =
            previousEvent?.todo.id == todo.id ||
            currentEvent?.todo.id == todo.id;

        return isThisTodo && previous.eventStatusChanged<TodoDeleted>(current);
      },
      builder: (context, state) {
        final isLoading =
            state.statusOf<TodoDeleted>() is LoadingTodoEventStatus &&
            state.eventOf<TodoDeleted>()?.todo.id == todo.id;

        if (isLoading) {
          return const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return IconButton(
          tooltip: 'Delete todo',
          onPressed: () {
            context.read<TodoBloc>().add(TodoDeleted(todo));
          },
          icon: const Icon(Icons.delete_outline),
        );
      },
    );
  }
}

class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  final String id;
  final String title;
  final bool isDone;

  Todo copyWith({
    String? id,
    String? title,
    bool? isDone,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [id, title, isDone];
}

sealed class TodoEventStatus extends Equatable {
  const TodoEventStatus();

  @override
  List<Object?> get props => [];
}

class LoadingTodoEventStatus extends TodoEventStatus {
  const LoadingTodoEventStatus();
}

class SuccessTodoEventStatus<TData extends Object?> extends TodoEventStatus {
  const SuccessTodoEventStatus([this.data]);

  final TData? data;

  @override
  List<Object?> get props => [data];
}

class FailureTodoEventStatus extends TodoEventStatus {
  const FailureTodoEventStatus(this.error);

  final Exception error;

  @override
  List<Object?> get props => [error];
}

sealed class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class TodoLoadRequested extends TodoEvent {
  const TodoLoadRequested({required this.reason});

  final String reason;

  @override
  List<Object?> get props => [reason];
}

class TodoAdded extends TodoEvent {
  const TodoAdded(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

class TodoToggled extends TodoEvent {
  const TodoToggled(this.todo);

  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.todo);

  final Todo todo;

  @override
  List<Object?> get props => [todo];
}

class FailureModeToggled extends TodoEvent {
  const FailureModeToggled({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class TodoState extends Equatable
    with EventStatusesMixin<TodoEvent, TodoEventStatus> {
  const TodoState({
    required this.todos,
    required this.nextId,
    required this.isFailureArmed,
    required this.eventStatuses,
  });

  const TodoState.initial()
    : todos = const [],
      nextId = 1,
      isFailureArmed = false,
      eventStatuses = const EventStatuses();

  final List<Todo> todos;
  final int nextId;
  final bool isFailureArmed;

  @override
  final EventStatuses<TodoEvent, TodoEventStatus> eventStatuses;

  TodoState copyWith({
    List<Todo>? todos,
    int? nextId,
    bool? isFailureArmed,
    EventStatuses<TodoEvent, TodoEventStatus>? eventStatuses,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      nextId: nextId ?? this.nextId,
      isFailureArmed: isFailureArmed ?? this.isFailureArmed,
      eventStatuses: eventStatuses ?? this.eventStatuses,
    );
  }

  @override
  List<Object?> get props => [
    todos,
    nextId,
    isFailureArmed,
    eventStatuses,
  ];
}

@blocEventStatus
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState.initial()) {
    on<TodoLoadRequested>(_onLoadRequested);
    on<TodoAdded>(_onTodoAdded);
    on<TodoToggled>(_onTodoToggled);
    on<TodoDeleted>(_onTodoDeleted);
    on<FailureModeToggled>(_onFailureModeToggled);
  }

  Future<void> _onLoadRequested(
    TodoLoadRequested event,
    Emitter<TodoState> emit,
  ) async {
    emit.loading(event, state);

    try {
      await _simulateLatency(emit, action: 'load todos');
      emit.success(
        event,
        state.copyWith(
          todos: _sampleTodos,
          nextId: _sampleTodos.length + 1,
        ),
        'Loaded ${_sampleTodos.length} sample todos',
      );
    } on Exception catch (error) {
      emit.failure(event, state, error);
    }
  }

  Future<void> _onTodoAdded(
    TodoAdded event,
    Emitter<TodoState> emit,
  ) async {
    final title = event.title.trim();
    if (title.isEmpty) {
      return;
    }

    emit.loading(event, state);

    try {
      await _simulateLatency(emit, action: 'add "$title"');
      final todo = Todo(
        id: '${state.nextId}',
        title: title,
      );

      emit.success(
        event,
        state.copyWith(
          todos: [...state.todos, todo],
          nextId: state.nextId + 1,
        ),
        'Added "${todo.title}"',
      );
    } on Exception catch (error) {
      emit.failure(event, state, error);
    }
  }

  Future<void> _onTodoToggled(
    TodoToggled event,
    Emitter<TodoState> emit,
  ) async {
    final index = state.todos.indexWhere((todo) => todo.id == event.todo.id);
    if (index == -1) {
      return;
    }

    emit.loading(event, state);

    try {
      await _simulateLatency(
        emit,
        action: 'toggle "${event.todo.title}"',
      );
      final updatedTodos = [...state.todos];
      final currentTodo = updatedTodos[index];
      final updatedTodo = currentTodo.copyWith(isDone: !currentTodo.isDone);
      updatedTodos[index] = updatedTodo;

      emit.success(
        event,
        state.copyWith(todos: updatedTodos),
        updatedTodo.isDone
            ? 'Marked "${updatedTodo.title}" as done'
            : 'Marked "${updatedTodo.title}" as open',
      );
    } on Exception catch (error) {
      emit.failure(event, state, error);
    }
  }

  Future<void> _onTodoDeleted(
    TodoDeleted event,
    Emitter<TodoState> emit,
  ) async {
    if (!state.todos.any((todo) => todo.id == event.todo.id)) {
      return;
    }

    emit.loading(event, state);

    try {
      await _simulateLatency(
        emit,
        action: 'delete "${event.todo.title}"',
      );

      emit.success(
        event,
        state.copyWith(
          todos: state.todos.where((todo) => todo.id != event.todo.id).toList(),
        ),
        'Deleted "${event.todo.title}"',
      );
    } on Exception catch (error) {
      emit.failure(event, state, error);
    }
  }

  void _onFailureModeToggled(
    FailureModeToggled event,
    Emitter<TodoState> emit,
  ) {
    emit(state.copyWith(isFailureArmed: event.enabled));
  }

  Future<void> _simulateLatency(
    Emitter<TodoState> emit, {
    required String action,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!state.isFailureArmed) {
      return;
    }

    emit(state.copyWith(isFailureArmed: false));
    throw Exception('Forced failure while trying to $action');
  }
}

String _describeEvent(TodoEvent event) {
  return switch (event) {
    TodoLoadRequested(:final reason) => 'TodoLoadRequested(reason: $reason)',
    TodoAdded(:final title) => 'TodoAdded(title: $title)',
    TodoToggled(:final todo) => 'TodoToggled(todo: ${todo.title})',
    TodoDeleted(:final todo) => 'TodoDeleted(todo: ${todo.title})',
    FailureModeToggled(:final enabled) =>
      'FailureModeToggled(enabled: $enabled)',
  };
}

String _formatException(Exception error) {
  return error.toString().replaceFirst('Exception: ', '');
}

const _sampleTodos = [
  Todo(id: '1', title: 'Read the README'),
  Todo(id: '2', title: 'Generate emit helpers'),
  Todo(id: '3', title: 'Toggle an item to see per-row loading'),
  Todo(id: '4', title: 'Delete an item and retry on failure'),
];
