/// {@template bloc_event_status_annotation}
/// Annotation that marks a Bloc class for event status extension generation.
///
/// When applied to a class extending `Bloc<TEvent, TState>` where `TState`
/// uses `EventStatusesMixin`, the `bloc_event_status_generator` package will
/// generate an `Emitter<TState>` extension with convenience methods for each
/// concrete status subtype.
///
/// Example:
/// ```dart
/// @blocEventStatus
/// class TodoBloc extends Bloc<TodoEvent, TodoState> {
///   // ...
/// }
/// ```
/// {@endtemplate}
class BlocEventStatus {
  /// {@macro bloc_event_status_annotation}
  const BlocEventStatus();
}

/// {@macro bloc_event_status_annotation}
const blocEventStatus = BlocEventStatus();
