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
  const TodoAdded(this.title);
  final String title;

  @override
  List<Object> get props => [title];
}

class TodoToggled extends TodoEvent {
  const TodoToggled(this.todo);
  final Todo todo;

  @override
  List<Object> get props => [todo];
}

class TodoCompletitionSet extends TodoEvent {
  const TodoCompletitionSet(
    this.todo, {
    required this.isDone,
  });
  final Todo todo;
  final bool isDone;

  @override
  List<Object> get props => [todo, isDone];
}

class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.todo);
  final Todo todo;

  @override
  List<Object> get props => [todo];
}

class FilterSelected extends TodoEvent {
  const FilterSelected(this.filter);
  final Filter filter;

  @override
  List<Object> get props => [filter];
}

class QuerySet extends TodoEvent {
  const QuerySet(this.query);
  final String query;

  @override
  List<Object> get props => [query];
}
