# BlocEventStatus

[BlocEventStatus CI](https://github.com/Jei-sKappa/bloc_event_status/actions/workflows/bloc_event_status-test.yml)
[codecov](https://codecov.io/github/Jei-sKappa/bloc_event_status)
[pub package](https://pub.dev/packages/bloc_event_status)
pub points
pub monthly downloads
pub Likes
[License: MIT](https://opensource.org/licenses/MIT)

Compose event status tracking into your BLoC state.

## Installation

```bash
dart pub add bloc_event_status
```

## Overview

`bloc_event_status` lets you track the status of individual event types (loading, success, failure, or any custom status) directly inside your BLoC state. The status for each event type is stored in an `EventStatuses` field on the state, so you can react to it using standard `flutter_bloc` widgets (`BlocListener`, `BlocBuilder`, `BlocSelector`) without any extra widgets or streams.

## Getting Started

### Step 1: Define your status type

The package is status-agnostic — you define what statuses mean in your app. A sealed class is a natural fit:

```dart
sealed class EventStatus {
  const EventStatus();
}

class LoadingEventStatus extends EventStatus {
  const LoadingEventStatus();
}

class SuccessEventStatus extends EventStatus {
  const SuccessEventStatus();
}

class FailureEventStatus extends EventStatus {
  const FailureEventStatus(this.error);
  final Exception error;
}
```

An enum works just as well for simpler cases.

### Step 2: Add `EventStatuses` to your state

Add an `EventStatuses<TEvent, TStatus>` field to your state class. This is the only required change to your state.

```dart
class TodoState {
  const TodoState({
    required this.todos,
    required this.eventStatuses,
  });

  const TodoState.initial()
      : todos = const [],
        eventStatuses = const EventStatuses();

  final List<Todo> todos;
  final EventStatuses<TodoEvent, EventStatus> eventStatuses;

  TodoState copyWith({
    List<Todo>? todos,
    EventStatuses<TodoEvent, EventStatus>? eventStatuses,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      eventStatuses: eventStatuses ?? this.eventStatuses,
    );
  }
}
```

**Optional: mix in `EventStatusesMixin`** to add convenience accessors directly on your state. This lets you write `state.statusOf<TodoLoadRequested>()` instead of `state.eventStatuses.statusOf<TodoLoadRequested>()`.

```dart
class TodoState with EventStatusesMixin<TodoEvent, EventStatus> {
  // ... same as above ...

  @override
  final EventStatuses<TodoEvent, EventStatus> eventStatuses;
}
```

The examples below use the mixin variant.

### Step 3: Emit statuses in the BLoC

Call `eventStatuses.update<EventType>(event, status)` and emit the resulting state via `copyWith`:

```dart
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState.initial()) {
    on<TodoLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    TodoLoadRequested event,
    Emitter<TodoState> emit,
  ) async {
    emit(state.copyWith(
      eventStatuses: state.eventStatuses.update(event, const LoadingEventStatus()),
    ));

    try {
      final todos = await loadTodos();

      emit(state.copyWith(
        todos: todos,
        eventStatuses: state.eventStatuses.update(event, const SuccessEventStatus()),
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        eventStatuses: state.eventStatuses.update(event, FailureEventStatus(e)),
      ));
    }
  }
}
```

**Tip:** An Emitter extension cleans this up significantly — see [Tips](#tips).

### Step 4: React in the UI

Use standard `flutter_bloc` widgets. The `EventStatusesMixin` methods (`statusOf`, `eventStatusOf`, `eventOf`) slot directly into `listenWhen` / `buildWhen` / `selector`.

#### BlocListener — show a snackbar on failure

```dart
BlocListener<TodoBloc, TodoState>(
  listenWhen: (previous, current) =>
      previous.eventStatusChangedTo<TodoLoadRequested, FailureEventStatus>(current),
  listener: (context, state) {
    final eventStatus = state.eventStatusOf<TodoLoadRequested>()!;
    final error = (eventStatus.status as FailureEventStatus).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading todos: $error'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => context.read<TodoBloc>().add(eventStatus.event),
        ),
      ),
    );
  },
  child: child,
)
```

#### BlocSelector — switch on load status

```dart
BlocSelector<TodoBloc, TodoState, EventStatus?>(
  selector: (state) => state.statusOf<TodoLoadRequested>(),
  builder: (context, status) {
    return switch (status) {
      null => const SizedBox.shrink(),
      LoadingEventStatus() => const CircularProgressIndicator(),
      FailureEventStatus() => const Text('Error loading todos'),
      SuccessEventStatus() => const TodoListView(),
    };
  },
)
```

#### BlocBuilder — show a spinner per-item

```dart
BlocBuilder<TodoBloc, TodoState>(
  buildWhen: (previous, current) =>
      current.eventOf<TodoDeleted>()?.todo.id == todo.id &&
      previous.eventStatusChanged<TodoDeleted>(current) &&
      (previous.statusOf<TodoDeleted>() is LoadingEventStatus ||
          current.statusOf<TodoDeleted>() is LoadingEventStatus),
  builder: (context, state) {
    if (state.statusOf<TodoDeleted>() is LoadingEventStatus) {
      return const CircularProgressIndicator();
    }
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () => context.read<TodoBloc>().add(TodoDeleted(todo)),
    );
  },
)
```

## API Reference

### `EventStatuses<TEvent, TStatus>`

Immutable class (extends `Equatable`) that stores the status of each event type.


| Member                                 | Description                                                                                     |
| -------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `const EventStatuses()`                | Creates an empty instance (use as initial value).                                               |
| `update<TEventSubType>(event, status)` | Returns a **new** `EventStatuses` with the entry for `TEventSubType` updated.                   |
| `statusOf<TEventSubType>()`            | Returns the current `TStatus` for `TEventSubType`, or `null`.                                   |
| `eventOf<TEventSubType>()`             | Returns the last `TEventSubType` instance that was updated, or `null`.                          |
| `eventStatusOf<TEventSubType>()`       | Returns the full `EventStatusUpdate` record `({event, status})` for `TEventSubType`, or `null`. |
| `lastEventStatus`                      | Returns the most recently updated `EventStatusUpdate`, regardless of event type.                |


### `EventStatusesMixin<TEvent, TStatus>`

Optional mixin for your BLoC state. Requires you to implement `EventStatuses<TEvent, TStatus> get eventStatuses`. Delegates all four query methods (`statusOf`, `eventOf`, `eventStatusOf`, `lastEventStatus`) to `eventStatuses`, so you can call them directly on the state.

### `EventStatusConditions` extension

Extension on `EventStatusesMixin` that provides `buildWhen` / `listenWhen` helpers. Call on the **previous** state, passing **current** as the argument.


| Method                                 | Description                                                       |
| -------------------------------------- | ----------------------------------------------------------------- |
| `statusChanged<E>(current)`            | `true` if `statusOf<E>()` differs.                                |
| `eventStatusChanged<E>(current)`       | `true` if `eventStatusOf<E>()` differs (full record).             |
| `statusChangedTo<E, S>(current)`       | `true` if `statusOf<E>()` changed AND current status is `S`.      |
| `eventStatusChangedTo<E, S>(current)`  | `true` if `eventStatusOf<E>()` changed AND current status is `S`. |
| `lastEventStatusChanged(current)`      | `true` if `lastEventStatus` differs.                              |
| `lastEventStatusChangedTo<S>(current)` | `true` if `lastEventStatus` changed AND current status is `S`.    |


### `EventStatusUpdate<TEvent, TStatus>`

A record typedef: `({TEvent event, TStatus status})`. Returned by `eventStatusOf` and `lastEventStatus`.

## Tips

### Emitter extension for cleaner Bloc code

An extension on `Emitter` removes the `copyWith` boilerplate from every handler:

```dart
extension _TodoEmitterX on Emitter<TodoState> {
  void _emit<T extends TodoEvent>(T event, EventStatus status, TodoState state) {
    this(state.copyWith(
      eventStatuses: state.eventStatuses.update(event, status),
    ));
  }

  void loading<T extends TodoEvent>(T event, TodoState state) =>
      _emit(event, const LoadingEventStatus(), state);

  void success<T extends TodoEvent>(T event, TodoState state) =>
      _emit(event, const SuccessEventStatus(), state);

  void failure<T extends TodoEvent>(T event, TodoState state, {required Exception error}) =>
      _emit(event, FailureEventStatus(error), state);
}
```

> **Prefer code generation?** The [bloc_event_status_generator](https://pub.dev/packages/bloc_event_status_generator) package can auto-generate this extension for you. Annotate your Bloc with `@blocEventStatus` and run `build_runner` — see the generator [README](https://pub.dev/packages/bloc_event_status_generator) for setup instructions.

Usage in the handler:

```dart
Future<void> _onLoadRequested(
  TodoLoadRequested event,
  Emitter<TodoState> emit,
) async {
  emit.loading(event, state);
  try {
    final todos = await loadTodos();
    emit.success(event, state.copyWith(todos: todos));
  } on Exception catch (e) {
    emit.failure(event, state, error: e);
  }
}
```

### Access the triggering event for retry

You can access the event instance that produced the last status update for any event. This is useful for retry actions — pass the original event back to the bloc:

```dart
listener: (context, state) {
  final event = state.eventOf<TodoLoadRequested>()!; // Equivalent to `state.eventStatusOf<TodoLoadRequested>()!.event`

  // Re-add the exact same event that failed
  context.read<TodoBloc>().add(event);
},
```

### `buildWhen` / `listenWhen` helpers

The `EventStatusConditions` extension (available on any state that uses `EventStatusesMixin`) provides helpers that replace the verbose comparison patterns commonly written in `buildWhen` and `listenWhen` callbacks.

#### Status changed

Use `statusChanged` to check if a status value changed, ignoring event instance changes.

```dart
// Before:
buildWhen: (previous, current) =>
    previous.statusOf<TodoLoadRequested>() !=
        current.statusOf<TodoLoadRequested>(),

// After:
buildWhen: (previous, current) =>
    previous.statusChanged<TodoLoadRequested>(current),
```

Use `eventStatusChanged` to check if the full record (event + status) changed. Prefer this for `listenWhen` because it reacts to every new emission, even when the status type is unchanged:

```dart
// Before:
listenWhen: (previous, current) =>
    previous.eventStatusOf<TodoToggled>() !=
        current.eventStatusOf<TodoToggled>(),

// After:
listenWhen: (previous, current) =>
    previous.eventStatusChanged<TodoToggled>(current),
```

#### Multiple events — use `||`:

```dart
buildWhen: (previous, current) =>
    previous.statusChanged<TodoLoadRequested>(current) ||
    previous.statusChanged<TodoDeleted>(current),
```

#### Status changed to a specific type

Use `eventStatusChangedTo` to combine change detection with a type check on the current status. This is the most common `listenWhen` pattern:

```dart
// Before:
listenWhen: (previous, current) =>
    previous.eventStatusOf<TodoLoadRequested>() !=
        current.eventStatusOf<TodoLoadRequested>() &&
    current.statusOf<TodoLoadRequested>() is FailureEventStatus,

// After:
listenWhen: (previous, current) =>
    previous.eventStatusChangedTo<TodoLoadRequested, FailureEventStatus>(current),
```

`statusChangedTo` is the equivalent that compares only the status (ignoring event instance changes), suitable for `buildWhen`.

These compose naturally with `&&` / `||` and manual checks:

```dart
listenWhen: (previous, current) =>
    previous.eventStatusChangedTo<TodoToggled, SuccessEventStatus>(current) &&
    current.eventOf<TodoToggled>()!.todo.isDone,
```

#### Last event status

`lastEventStatusChanged` and `lastEventStatusChangedTo` work on `lastEventStatus` instead of a specific event type:

```dart
// React to any status change, regardless of event type:
listenWhen: (previous, current) =>
    previous.lastEventStatusChanged(current),

// React only when the latest status is a failure:
listenWhen: (previous, current) =>
    previous.lastEventStatusChangedTo<FailureEventStatus>(current),
```

### Observe any status change with `lastEventStatus`

`lastEventStatus` returns the most recent update regardless of event type. Use it to drive a global loading indicator or listening for any error in the BLoC.

```dart
BlocSelector<TodoBloc, TodoState, EventStatusUpdate<TodoEvent, EventStatus>?>(
  selector: (state) => state.lastEventStatus,
  builder: (context, lastStatus) {
    if (lastStatus?.status is LoadingEventStatus) {
      return const LinearProgressIndicator();
    }
    return /* your widget tree */;
  },
)
```

## Example

See the [example](https://github.com/Jei-sKappa/bloc_event_status/tree/main/example) folder for a complete working app.

## Acknowledgments

A special thanks to [LeanCode](https://github.com/leancodepl) for their inspiring work on the [bloc_presentation](https://github.com/leancodepl/bloc_presentation/tree/master/packages/bloc_presentation) package, which served as a foundational reference and inspiration for the initial version of this project.

## Contributing

We welcome contributions! Please open an issue, submit a pull request or open a discussion on [GitHub](https://github.com/Jei-sKappa/bloc_event_status).

## License

This project is licensed under the [MIT License](LICENSE).