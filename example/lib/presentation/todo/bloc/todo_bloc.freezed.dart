// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodoState {
  List<Todo> get todos;
  Filter get selectedFilter;
  String get query;
  EventStatuses<TodoEvent, EventStatus> get eventStatuses;

  /// Create a copy of TodoState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TodoStateCopyWith<TodoState> get copyWith =>
      _$TodoStateCopyWithImpl<TodoState>(this as TodoState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TodoState &&
            const DeepCollectionEquality().equals(other.todos, todos) &&
            (identical(other.selectedFilter, selectedFilter) ||
                other.selectedFilter == selectedFilter) &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.eventStatuses, eventStatuses) ||
                other.eventStatuses == eventStatuses));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(todos),
      selectedFilter,
      query,
      eventStatuses);

  @override
  String toString() {
    return 'TodoState(todos: $todos, selectedFilter: $selectedFilter, query: $query, eventStatuses: $eventStatuses)';
  }
}

/// @nodoc
abstract mixin class $TodoStateCopyWith<$Res> {
  factory $TodoStateCopyWith(TodoState value, $Res Function(TodoState) _then) =
      _$TodoStateCopyWithImpl;
  @useResult
  $Res call(
      {List<Todo> todos,
      Filter selectedFilter,
      String query,
      EventStatuses<TodoEvent, EventStatus> eventStatuses});
}

/// @nodoc
class _$TodoStateCopyWithImpl<$Res> implements $TodoStateCopyWith<$Res> {
  _$TodoStateCopyWithImpl(this._self, this._then);

  final TodoState _self;
  final $Res Function(TodoState) _then;

  /// Create a copy of TodoState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todos = null,
    Object? selectedFilter = null,
    Object? query = null,
    Object? eventStatuses = null,
  }) {
    return _then(TodoState(
      todos: null == todos
          ? _self.todos
          : todos // ignore: cast_nullable_to_non_nullable
              as List<Todo>,
      selectedFilter: null == selectedFilter
          ? _self.selectedFilter
          : selectedFilter // ignore: cast_nullable_to_non_nullable
              as Filter,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      eventStatuses: null == eventStatuses
          ? _self.eventStatuses
          : eventStatuses // ignore: cast_nullable_to_non_nullable
              as EventStatuses<TodoEvent, EventStatus>,
    ));
  }
}

/// Adds pattern-matching-related methods to [TodoState].
extension TodoStatePatterns on TodoState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>() {
    final _that = this;
    switch (_that) {
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>() {
    final _that = this;
    switch (_that) {
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>() {
    final _that = this;
    switch (_that) {
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>() {
    final _that = this;
    switch (_that) {
      case _:
        return null;
    }
  }
}

// dart format on
