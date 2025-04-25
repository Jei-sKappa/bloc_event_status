part of 'todo_bloc.dart';

enum Filter { all, done, notDone, deleted }

final initialTodos = [
  Todo(id: "1", title: 'Buy groceries'),
  Todo(id: "2", title: 'Walk the dog', isDone: true),
  Todo(id: "3", title: 'Read a book', isDone: true, isDeleted: true),
  Todo(id: "4", title: 'Write some code', isDeleted: true),
  Todo(id: "5", title: 'Go to the gym'),
  Todo(id: "6", title: 'Clean the house'),
  Todo(id: "7", title: 'Cook dinner'),
  Todo(id: "8", title: 'Call mom'),
  Todo(id: "9", title: 'Finish project'),
  Todo(id: "10", title: 'Watch a movie'),
  Todo(id: "11", title: 'Play video games'),
  Todo(id: "12", title: 'Learn Flutter'),
  Todo(id: "13", title: 'Go shopping'),
  Todo(id: "14", title: 'Visit a friend'),
  Todo(id: "15", title: 'Take a nap'),
  Todo(id: "16", title: 'Go for a run'),
  Todo(id: "17", title: 'Do laundry'),
  Todo(id: "18", title: 'Write a blog post'),
  Todo(id: "19", title: 'Practice guitar'),
  Todo(id: "20", title: 'Plan a trip'),
  Todo(id: "21", title: 'Organize workspace'),
  Todo(id: "22", title: 'Attend a workshop'),
];

@freezed
class TodoState with _$TodoState {
  @override
  final List<Todo> todos;
  @override
  final Filter selectedFilter;
  @override
  final String query;

  const TodoState({
    required this.todos,
    required this.selectedFilter,
    required this.query,
  });

  const TodoState.initial()
      : todos = const [],
        selectedFilter = Filter.all,
        query = '';

  List<Todo> get filteredTodos {
    late final List<Todo> matchingTodos;
    if (query.isNotEmpty) {
      matchingTodos = todos
          .where(
              (todo) => todo.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      matchingTodos = todos;
    }

    switch (selectedFilter) {
      case Filter.done:
        return matchingTodos
            .where((todo) => todo.isDone && !todo.isDeleted)
            .toList();
      case Filter.notDone:
        return matchingTodos
            .where((todo) => !todo.isDone && !todo.isDeleted)
            .toList();
      case Filter.deleted:
        return matchingTodos.where((todo) => todo.isDeleted).toList();
      case Filter.all:
        return matchingTodos;
    }
  }
}
