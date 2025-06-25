# BlocEventStatus

[![BlocEventStatus CI](https://github.com/Jei-sKappa/bloc_event_status/actions/workflows/bloc_event_status-test.yml/badge.svg)](https://github.com/Jei-sKappa/bloc_event_status/actions/workflows/bloc_event_status-test.yml)
[![codecov](https://codecov.io/github/Jei-sKappa/bloc_event_status/graph/badge.svg?token=LYNF1FJ8YF)](https://codecov.io/github/Jei-sKappa/bloc_event_status)
[![pub package](https://img.shields.io/pub/v/bloc_event_status.svg)](https://pub.dev/packages/bloc_event_status)
![pub points](https://img.shields.io/pub/points/bloc_event_status)
![pub Popularity](https://img.shields.io/pub/popularity/bloc_event_status)
![pub Likes](https://img.shields.io/pub/likes/bloc_event_status)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Track the status of events in a bloc without updating the state.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  bloc_event_status: ^1.1.0
```

and then run:

```bash
flutter pub get
```

Or just install it with flutter cli:

```bash
flutter pub add bloc_event_status
```

## Getting Started

### Update the Bloc

Start by creating a Bloc as usual:

```dart
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState.initial()) {
    on<TodoLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    TodoLoadRequested event,
    Emitter<TodoState> emit,
  ) async {
    try {
      final todos = await loadTodos();

      emit(state.copyWith(todos: todos));
    } on Exception catch (e) {
      addError(e);
      return;
    }
  }
}
```

Add the `BlocEventStatusMixin` to your Bloc class:

```dart
class TodoBloc extends Bloc<TodoEvent, TodoState> with BlocEventStatusMixin<TodoEvent, TodoState> {
  /* ... */
}
```

Now you can use `emitEventStatus` to emit the status of the event:

```dart
/* ... */

Future<void> _onLoadRequested(
  TodoLoadRequested event,
  Emitter<TodoState> emit,
) async {
  emitEventStatus(event, LoadingEventStatus()); // Emit loading status

  try {
    final todos = await loadTodos();

    emit(state.copyWith(todos: todos));

    emitEventStatus(event, SuccessEventStatus()); // Emit success status
  } on Exception catch (e) {
    emitEventStatus(event, FailureEventStatus(e)); // Emit failure status

    addError(e);
    return;
  }
}

/* ... */
```

When using `BlocEventStatusMixin` you also get access to some useful methods:

- `emitLoadingStatus()` - Emit loading status (equivalent to `emitEventStatus(event, LoadingEventStatus())`)
- `emitSuccessStatus(data)` - Emit success status (equivalent to `emitEventStatus(event, SuccessEventStatus(data))`)
- `emitFailureStatus(error)` - Emit failure status (equivalent to `emitEventStatus(event, FailureEventStatus(error))`)

Let's see them in action:

```dart
/* ... */

Future<void> _onLoadRequested(
  TodoLoadRequested event,
  Emitter<TodoState> emit,
) async {
  emitLoadingStatus(event);

  try {
    final todos = await loadTodos();

    emit(state.copyWith(todos: todos));

    emitSuccessStatus(event);
  } on Exception catch (e) {
    emitFailureStatus(event, error: e);

    addError(e);
    return;
  }
}

/* ... */
```

The most powerful method of `BlocEventStatusMixin` is `handleEventStatus`. It allows you to wrap your already existing event handler and automatically emit the statuses of the event for you.
Let's see how to use it:

```dart
class TodoBloc extends Bloc<TodoEvent, TodoState> with BlocEventStatusMixin<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState.initial()) {
    on<TodoLoadRequested>(handleEventStatus(_onLoadRequested)); // Wrap the event handler with handleEventStatus
  }

  Future<void> _onLoadRequested(
    TodoLoadRequested event,
    Emitter<TodoState> emit,
  ) async {
    final todos = await loadTodos();

    emit(state.copyWith(todos: todos));
  }
}
```

### React to Event Statuses

Now that you have your Bloc set up, you can listen to the event statuses in your UI.

#### BlocEventStatusListener

You can use the `BlocEventStatusListener` widget to listen to one event status in your UI.

```dart
BlocEventStatusListener<TodoBloc, TodoEvent, TodoLoadRequested>(
  // optionally filter the events to listen to
  filter: (event) => /* select only the events you want */,
  // optionally select when the listener should be called
  listenWhen: (previous, current) => previous != current && current is FailureEventStatus,
  // The listener function that will be called when a new status is emitted
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
  bloc: subjectBloc,
  child: SomeWidget(),
)
```

#### BlocEventStatusBuilder

You can use the `BlocEventStatusBuilder` widget to build your UI based on the event status.
It's equivalent to `BlocEventStatusListener` but instead of a listener function, it takes a builder function that returns a widget.

```dart
BlocEventStatusBuilder<TodoBloc, TodoEvent, TodoDeleted, TodoState>(
  filter: (event) => event.todo.id == todos[index].id,
  buildWhen: (previous, current) =>
      previous != current &&
      (previous is LoadingEventStatus || current is LoadingEventStatus),
  builder: (context, event, status) {
    if (status is LoadingEventStatus) {
      return CircularProgressIndicator();
    }

    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () {
        context.read<TodoBloc>().add(TodoDeleted(todos[index]));
      },
    );
  },
),
```

#### BlocBuilderWithEventStatus

In case you want to use the `BlocBuilder` widget and listen to the event status at the same time, you can use the `BlocBuilderWithEventStatus` widget.

```dart
BlocBuilderWithEventStatus<TodoBloc, TodoEvent, TodoToggled, TodoState>(
  filter: (event) => event.todo.title == 'Learn Flutter',
  // optionally select when the builder should be called based on the status
  buildWhenStatus: (previous, current) =>
      previous != current &&
      (previous is LoadingEventStatus || current is LoadingEventStatus),
  // optionally select when the builder should be called based on the state
  buildWhenState: (previous, current) =>
      previous.filter != current.filter && current.filter == Filter.done,
  builder: (context, event, status, state) {
    if (status is LoadingEventStatus) {
      return const CircularProgressIndicator();
    }

    return const Text('Flutter is awesome! Here is the state: $state');
  },
  bloc: subjectBloc,
  child: SomeWidget(),
)
```


## Advanced Usage

### React to multiple event types

Every widget that reacts to a specific event type has it corresponding widget that reacts to multiple event types.
For example, `BlocEventStatusListener` has `MultiBlocEventStatusListener`.
The only difference is that you can't specify a specific event type in it's type parameters but you can use the `filter` parameter to filter the events you want to listen to.

```dart
MultiBlocEventStatusListener<TodoBloc, TodoEvent>(
  filter: (event) => event is TodoLoadRequested || event is TodoDeleted,
  listener: (context, event, status) {
    // Handle the event status here
  },
)
```

If you want to listen to all events, you can just ignore the `filter` parameter.

```dart
MultiBlocEventStatusListener<TodoBloc, TodoEvent>(
  listener: (context, event, status) {
    // Handle the event status here
  },
)
```

### Custom Event Statuses

In order to use your own event statuses, you need to use `BlocCustomEventStatusMixin` mixin instead of `BlocEventStatusMixin`.

```dart
enum MyStatus { initial, loading, success, failure }

class TodoBloc extends Bloc<TodoEvent, TodoState> with BlocCustomEventStatusMixin<TodoEvent, TodoState, MyStatus> {
  TodoBloc() : super(const TodoState.initial()) {
    on<TodoLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    TodoLoadRequested event,
    Emitter<TodoState> emit,
  ) async {
    emitEventStatus(event, MyStatus.loading); // Emit loading status

    try {
      final todos = await loadTodos();

      emit(state.copyWith(todos: todos));

      emitEventStatus(event, MyStatus.success); // Emit success status
    } on Exception catch (e) {
      emitEventStatus(event, MyStatus.failure); // Emit failure status

      addError(e);
      return;
    }
  }
}
```

If you use this mixin you need also to change the widgets from `BlocEventStatus*` to `BlocCustomEventStatus*`.
For example, `BlocEventStatusListener` becomes `BlocCustomEventStatusListener` and so on.

## Example

See the [example](/packages/bloc_event_status/example) folder for a complete example of how to use the package.

## Acknowledgments

A special thanks to [LeanCode](https://github.com/leancodepl) for their inspiring work on the [bloc_presentation](https://github.com/leancodepl/bloc_presentation/tree/master/packages/bloc_presentation) package, which served as a foundational reference and inspiration for this project.

## Contributing

We welcome contributions! Please open an issue, submit a pull request or open a discussion on [GitHub](https://github.com/Jei-sKappa/bloc_event_status).

## License

This project is licensed under the [MIT License](LICENSE).
