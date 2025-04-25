import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:example/domain/todo.dart';
import 'package:example/presentation/programmed_failure/components/components.dart';
import 'package:example/presentation/todo/bloc/todo_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoBloc(
        programmedFailureCubit: context.read(),
      )..add(const TodoLoadRequested()),
      child: HomeView(),
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
    String newTodoTitle = '';
    final todoBloc = BlocProvider.of<TodoBloc>(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: todoBloc,
          child: Builder(builder: (context) {
            return AlertDialog(
              title: Text('Add Todo'),
              content: TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: 'Todo title'),
                onChanged: (value) {
                  newTodoTitle = value;
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Add'),
                  onPressed: () {
                    if (newTodoTitle.trim().isNotEmpty) {
                      context.read<TodoBloc>().add(TodoAdded(newTodoTitle));
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo App'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ProgrammedFailureCheckbox(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110.0),
          child: Padding(
            padding: EdgeInsets.all(8.0),
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
          BlocEventStatusListener<TodoBloc, TodoEvent, TodoLoadRequested>(
            listenWhen: (previous, current) =>
                previous != current && current is FailureEventStatus,
            listener: (context, event, status) {
              final error = (status as FailureEventStatus).error;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error loading todos: $error',
                    ),
                    action: SnackBarAction(
                      label: "Retry",
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context.read<TodoBloc>().add(event);
                      },
                    ),
                  ),
                );
            },
          ),
          BlocEventStatusListener<TodoBloc, TodoEvent, TodoToggled>(
            // Togged a [Todo] that is already done: notify the user if he is
            // sure
            filter: (event) => event.todo.isDone,
            listenWhen: (previous, current) =>
                previous != current && current is SuccessEventStatus,
            listener: (context, event, status) {
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '\'${event.todo.title}\' was already done, are you sure you want remove it from the done list?',
                    ),
                    action: SnackBarAction(
                      label: "Oops",
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
          BlocEventStatusListener<TodoBloc, TodoEvent, TodoToggled>(
            listenWhen: (previous, current) =>
                previous != current && current is FailureEventStatus,
            listener: (context, event, status) {
              final error = (status as FailureEventStatus).error;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error while toggling todo \'${event.todo.title}\': $error',
                    ),
                    action: SnackBarAction(
                      label: "Retry",
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context.read<TodoBloc>().add(event);
                      },
                    ),
                  ),
                );
            },
          ),
          BlocEventStatusListener<TodoBloc, TodoEvent, TodoDeleted>(
            listenWhen: (previous, current) =>
                previous != current && current is FailureEventStatus,
            listener: (context, event, status) {
              final error = (status as FailureEventStatus).error;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error while deleting todo \'Buy groceries\': $error',
                    ),
                    action: SnackBarAction(
                      label: "Retry",
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context.read<TodoBloc>().add(event);
                      },
                    ),
                  ),
                );
            },
          ),
        ],
        child: _TodoList(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          FloatingActionButton(
            onPressed: () {
              context.read<TodoBloc>().add(const TodoLoadRequested());
            },
            child: Icon(Icons.refresh),
          ),
          FloatingActionButton(
            onPressed: _showAddTodoDialog,
            child: Icon(Icons.add),
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
    return BlocEventStatusBuilder<TodoBloc, TodoEvent, TodoLoadRequested,
        TodoState>(
      builder: (context, event, status) {
        switch (status) {
          case null:
            return SizedBox.shrink();
          case LoadingEventStatus():
            return Center(
              child: CircularProgressIndicator(),
            );
          case FailureEventStatus():
            return Center(
              child: Text(
                'Error loading todos',
                style: TextStyle(fontSize: 20),
              ),
            );
          case SuccessEventStatus():
            return BlocSelector<TodoBloc, TodoState, List<Todo>>(
              selector: (state) => state.filteredTodos,
              builder: (context, filteredTodos) {
                if (filteredTodos.isEmpty) {
                  return Center(
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

  static const _circularProgressIndicatorPadding =
      (_actionSize - _circularProgressIndicatorSize) / 2;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        "${todo.id} - ${todo.title}",
        style: TextStyle(
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
          color: todo.isDeleted
              ? Colors.red
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      leading: SizedBox.square(
        dimension: _actionSize,
        child:
            //   BlocEventStatusBuilder<TodoBloc, TodoEvent, TodoToggled, TodoState>(
            // filter: (event) => event.todo.id == todo.id,
            MultiBlocEventStatusBuilder<TodoBloc, TodoEvent, TodoState>(
          filter: (event) =>
              (event is TodoToggled && event.todo.id == todo.id) ||
              (event is TodoCompletitionSet && event.todo.id == todo.id),
          buildWhen: (previous, current) =>
              previous != current &&
              (previous is LoadingEventStatus || current is LoadingEventStatus),
          builder: (context, event, status) {
            if (status is LoadingEventStatus) {
              return Padding(
                padding: const EdgeInsets.all(
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
        child:
            BlocEventStatusBuilder<TodoBloc, TodoEvent, TodoDeleted, TodoState>(
          filter: (event) => event.todo.id == todo.id,
          buildWhen: (previous, current) =>
              previous != current &&
              (previous is LoadingEventStatus || current is LoadingEventStatus),
          builder: (context, event, status) {
            if (status is LoadingEventStatus) {
              return Padding(
                padding: const EdgeInsets.all(
                  _circularProgressIndicatorPadding,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            }

            return IconButton(
              icon: Icon(Icons.delete),
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
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        suffixIcon: Icon(Icons.search),
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
            segments: [
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
            onSelectionChanged: (Set<Filter> newSelected) {
              context.read<TodoBloc>().add(FilterSelected(newSelected.first));
            });
      },
    );
  }
}
