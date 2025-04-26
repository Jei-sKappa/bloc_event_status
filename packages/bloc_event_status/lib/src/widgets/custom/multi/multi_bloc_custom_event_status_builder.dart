import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// {@template multi_bloc_custom_event_status_builder}
/// A widget that listens to event statuses from a bloc and invokes a builder
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocCustomEventStatusMixin] and listen
/// to events of type [TEvent]. When a new event of type [TEvent] is emitted by
/// the Bloc, the provided [builder] function is called with the current
/// `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// MultiBlocCustomEventStatusBuilder<SubjectBloc, SubjectEvent, SubjectState, MyStatus>(
///   // optionally filter the events to listen to
///   filter: (event) =>
///       (event is MySubjectEvent && event.subject == "Flutter") ||
///       (event is MyOtherSubjectEvent && event.otherSubject == "Dart"),
///   // optionally select when the builder should be called
///   buildWhen: (previous, current) =>
///       previous != current &&
///       (previous is MyLoadingStatus || current is MyLoadingStatus),
///   // The builder function that will be called when a new status is emitted
///   builder: (context, event, status) {
///     if (status is MyLoadingStatus) {
///       return const CircularProgressIndicator();
///     }
///
///     return const Text('Flutter is awesome!');
///   },
///   bloc: subjectBloc, // You don't have to pass it if you provided it in context
///   child: SomeWidget(),
/// )
/// ```
/// {@endtemplate}
class MultiBlocCustomEventStatusBuilder<
    TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TState,
    TStatus> extends StatefulWidget {
  /// {@macro multi_bloc_custom_event_status_builder}
  const MultiBlocCustomEventStatusBuilder({
    required this.builder,
    super.key,
    this.bloc,
    this.filter,
    this.buildWhen,
  });

  /// {@macro multi_bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@macro multi_bloc_custom_event_status_listener.filter}
  final BlocEventFilterBuilder<TEvent>? filter;

  /// {@macro bloc_custom_event_status_builder.buildWhen}
  final BlocCustomEventStatusBuilderCondition<TStatus>? buildWhen;

  /// {@template multi_bloc_custom_event_status_builder.builder}
  /// A function that renders the widget based on the current event and status.
  /// It takes the `context`, the `event` of type [TEvent], and the `status` of
  /// type [TStatus] as parameters.
  ///
  /// The event can be null ony during the first build.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetBuilder<TEvent, TStatus> builder;

  @override
  State<MultiBlocCustomEventStatusBuilder<TBloc, TEvent, TState, TStatus>>
      createState() =>
          _BloCustomEventStatusBuilderState<TBloc, TEvent, TState, TStatus>();
}

class _BloCustomEventStatusBuilderState<
        TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
        TEvent,
        TState,
        TStatus>
    extends State<
        MultiBlocCustomEventStatusBuilder<TBloc, TEvent, TState, TStatus>> {
  late TBloc _bloc;
  late TEvent? _event;
  late TStatus? _status;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<TBloc>();
    _event = null;
    // TODO: This should be filterd by the event filter otherwise it will return the status of the last event that was triggered and maybe not the one that was requested by the user
    // _status = _bloc.statusOfAllEvents();
    _status = null; // Temp fix
  }

  @override
  void didUpdateWidget(
    MultiBlocCustomEventStatusBuilder<TBloc, TEvent, TState, TStatus> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _event = null;
      // TODO: This should be filterd by the event filter otherwise it will return the status of the last event that was triggered and maybe not the one that was requested by the user
      // _status = _bloc.statusOfAllEvents();
      _status = null; // Temp fix
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<TBloc>();
    if (_bloc != bloc) {
      _bloc = bloc;
      _event = null;
      // TODO: This should be filterd by the event filter otherwise it will return the status of the last event that was triggered and maybe not the one that was requested by the user
      // _status = _bloc.statusOfAllEvents();
      _status = null; // Temp fix
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bloc == null) {
      // Trigger a rebuild if the bloc reference has changed.
      // See https://github.com/felangel/bloc/issues/2127.
      context.select<TBloc, bool>((bloc) => identical(_bloc, bloc));
    }
    return MultiBlocCustomEventStatusListener<TBloc, TEvent, TStatus>(
      bloc: _bloc,
      filter: widget.filter,
      listenWhen: widget.buildWhen,
      listener: (context, event, state) => setState(() {
        _event = event;
        _status = state;
      }),
      child: widget.builder(context, _event, _status),
    );
  }
}
