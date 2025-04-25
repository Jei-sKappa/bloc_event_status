part of 'todo_bloc.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object> get props => [];
}

class TodoLoadRequested extends TodoEvent {
  const TodoLoadRequested();

  @override
  List<Object> get props => [];
}

class TodoAdded extends TodoEvent {
  final String title;

  const TodoAdded(this.title);

  @override
  List<Object> get props => [title];
}

class TodoToggled extends TodoEvent {
  final Todo todo;

  const TodoToggled(this.todo);

  @override
  List<Object> get props => [todo];
}

class TodoCompletitionSet extends TodoEvent {
  final Todo todo;
  final bool isDone;

  const TodoCompletitionSet(
    this.todo, {
    required this.isDone,
  });

  @override
  List<Object> get props => [todo, isDone];
}

class TodoDeleted extends TodoEvent {
  final Todo todo;

  const TodoDeleted(this.todo);

  @override
  List<Object> get props => [todo];
}

class FilterSelected extends TodoEvent {
  final Filter filter;

  const FilterSelected(this.filter);

  @override
  List<Object> get props => [filter];
}

class QuerySet extends TodoEvent {
  final String query;

  const QuerySet(this.query);

  @override
  List<Object> get props => [query];
}
