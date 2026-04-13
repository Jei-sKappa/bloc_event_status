import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:example/core/bloc/bloc.dart';
import 'package:example/domain/todo.dart';
import 'package:example/presentation/programmed_failure/components/components.dart';
import 'package:example/presentation/todo/bloc/todo_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoBloc(
        programmedFailureCubit: context.read(),
      )..add(const TodoLoadRequested()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Show a dialog with a form to add a new todo.
  void _showAddTodoDialog() {
    var newTodoTitle = '';
    final todoBloc = BlocProvider.of<TodoBloc>(context);
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return BlocProvider.value(
            value: todoBloc,
            child: Builder(
              builder: (context) {
                return AlertDialog(
                  title: const Text('Add Todo'),
                  content: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Todo title'),
                    onChanged: (value) {
                      newTodoTitle = value;
                    },
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Add'),
                      onPressed: () {
                        if (newTodoTitle.trim().isNotEmpty) {
                          context.read<TodoBloc>().add(TodoAdded(newTodoTitle));
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo App'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ProgrammedFailureCheckbox(),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              spacing: 12,
              children: [
                _FilterSelector(),
                _SearchBox(),
              ],
            ),
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TodoBloc, TodoState>(
            listenWhen: (previous, current) => previous.eventStatusChangedTo<
                TodoLoadRequested, FailureEventStatus>(current),
            listener: (context, state) {
              final eventStatus = state.eventStatusOf<TodoLoadRequested>();

              final error = (eventStatus!.status as FailureEventStatus).error;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error loading todos: $error',
                    ),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context.read<TodoBloc>().add(eventStatus.event);
                      },
                    ),
                  ),
                );
            },
          ),
          BlocListener<TodoBloc, TodoState>(
            // Togged a [Todo] that is already done: notify the user if he is
            // sure
            // filter: (event) => event.todo.isDone,
            // listenWhen: (previous, current) =>
            //     previous != current && current is SuccessEventStatus,
            listenWhen: (previous, current) =>
                previous.eventStatusChangedTo<TodoToggled,
                    SuccessEventStatus<dynamic>>(current) &&
                current.eventOf<TodoToggled>()!.todo.isDone,
            listener: (context, state) {
              final event = state.eventOf<TodoToggled>()!;

              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      "'${event.todo.title}' was already done, are you sure "
                      'you want remove it from the done list?',
                    ),
                    action: SnackBarAction(
                      label: 'Oops',
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context
                            .read<TodoBloc>()
                            .add(TodoCompletitionSet(event.todo, isDone: true));
                      },
                    ),
                  ),
                );
            },
          ),
          BlocListener<TodoBloc, TodoState>(
            listenWhen: (previous, current) => previous
                .eventStatusChangedTo<TodoToggled, FailureEventStatus>(current),
            listener: (context, state) {
              final eventStatus = state.eventStatusOf<TodoToggled>()!;

              final error = (eventStatus.status as FailureEventStatus).error;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error while toggling todo '
                      "'${eventStatus.event.todo.title}': $error",
                    ),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context.read<TodoBloc>().add(eventStatus.event);
                      },
                    ),
                  ),
                );
            },
          ),
          BlocListener<TodoBloc, TodoState>(
            listenWhen: (previous, current) => previous
                .eventStatusChangedTo<TodoDeleted, FailureEventStatus>(current),
            listener: (context, state) {
              final eventStatus = state.eventStatusOf<TodoDeleted>()!;
              final error = (eventStatus.status as FailureEventStatus).error;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error while deleting todo '
                      "'${eventStatus.event.todo.title}': $error",
                    ),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context.read<TodoBloc>().add(eventStatus.event);
                      },
                    ),
                  ),
                );
            },
          ),
        ],
        child: const _TodoList(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          FloatingActionButton(
            onPressed: () {
              context.read<TodoBloc>().add(const TodoLoadRequested());
            },
            child: const Icon(Icons.refresh),
          ),
          FloatingActionButton(
            onPressed: _showAddTodoDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoState, EventStatus?>(
      selector: (state) => state.statusOf<TodoLoadRequested>(),
      builder: (context, status) {
        switch (status) {
          case null:
            return const SizedBox.shrink();
          case LoadingEventStatus():
            return const Center(
              child: CircularProgressIndicator(),
            );
          case FailureEventStatus():
            return const Center(
              child: Text(
                'Error loading todos',
                style: TextStyle(fontSize: 20),
              ),
            );
          case SuccessEventStatus():
            return BlocBuilder<TodoBloc, TodoState>(
              buildWhen: (previous, current) =>
                  previous.filteredTodos.map((todo) => todo.id).join(',') !=
                  current.filteredTodos.map((todo) => todo.id).join(','),
              builder: (context, state) {
                final filteredTodos = state.filteredTodos;
                if (filteredTodos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No todos found',
                      style: TextStyle(fontSize: 20),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = filteredTodos[index];
                    return _TodoTile(todo: todo);
                  },
                );
              },
            );
        }
      },
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.todo,
  });

  final Todo todo;

  static const _actionSize = 40.0;

  static const _circularProgressIndicatorSize = 18.0;

  static const double _circularProgressIndicatorPadding =
      (_actionSize - _circularProgressIndicatorSize) / 2;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '${todo.id} - ${todo.title}',
        style: TextStyle(
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
          color: todo.isDeleted
              ? Colors.red
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      leading: SizedBox.square(
        dimension: _actionSize,
        child: BlocBuilder<TodoBloc, TodoState>(
          buildWhen: (previous, current) {
            if (current.eventOf<TodoToggled>()?.todo.id == todo.id &&
                previous.eventStatusChanged<TodoToggled>(current) &&
                (previous.statusOf<TodoToggled>() is LoadingEventStatus ||
                    current.statusOf<TodoToggled>() is LoadingEventStatus)) {
              return true;
            }

            if (current.eventOf<TodoCompletitionSet>()?.todo.id == todo.id &&
                previous.eventStatusChanged<TodoCompletitionSet>(current) &&
                (previous.statusOf<TodoCompletitionSet>()
                        is TodoCompletitionSet ||
                    current.statusOf<TodoCompletitionSet>()
                        is TodoCompletitionSet)) {
              return true;
            }

            return false;
          },
          builder: (context, state) {
            final completitionSetStatus = state.statusOf<TodoCompletitionSet>();
            final toggledStatus = state.statusOf<TodoToggled>();

            if (toggledStatus is LoadingEventStatus ||
                completitionSetStatus is LoadingEventStatus) {
              return const Padding(
                padding: EdgeInsets.all(
                  _circularProgressIndicatorPadding,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            }

            return Checkbox(
              value: todo.isDone,
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              onChanged: (_) {
                context.read<TodoBloc>().add(TodoToggled(todo));
              },
            );
          },
        ),
      ),
      trailing: SizedBox.square(
        dimension: _actionSize,
        child: BlocBuilder<TodoBloc, TodoState>(
          buildWhen: (previous, current) =>
              current.eventOf<TodoDeleted>()?.todo.id == todo.id &&
              previous.eventStatusChanged<TodoDeleted>(current) &&
              (previous.statusOf<TodoDeleted>() is LoadingEventStatus ||
                  current.statusOf<TodoDeleted>() is LoadingEventStatus),
          builder: (context, state) {
            final status = state.statusOf<TodoDeleted>();

            if (status is LoadingEventStatus) {
              return const Padding(
                padding: EdgeInsets.all(
                  _circularProgressIndicatorPadding,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            }

            return IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                context.read<TodoBloc>().add(TodoDeleted(todo));
              },
            );
          },
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search todos',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.grey,
          ),
        ),
        suffixIcon: const Icon(Icons.search),
      ),
      onChanged: (value) {
        context.read<TodoBloc>().add(QuerySet(value));
      },
    );
  }
}

class _FilterSelector extends StatelessWidget {
  const _FilterSelector();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoState, Filter>(
      selector: (state) => state.selectedFilter,
      builder: (context, selectedFilter) {
        return SegmentedButton(
          showSelectedIcon: false,
          selected: {selectedFilter},
          segments: const [
            ButtonSegment<Filter>(
              value: Filter.all,
              label: Text('All'),
            ),
            ButtonSegment<Filter>(
              value: Filter.done,
              label: Text('Done'),
            ),
            ButtonSegment<Filter>(
              value: Filter.notDone,
              label: Text('Not Done'),
            ),
            ButtonSegment<Filter>(
              value: Filter.deleted,
              label: Text('Deleted'),
            ),
          ],
          onSelectionChanged: (newSelected) {
            context.read<TodoBloc>().add(FilterSelected(newSelected.first));
          },
        );
      },
    );
  }
}
