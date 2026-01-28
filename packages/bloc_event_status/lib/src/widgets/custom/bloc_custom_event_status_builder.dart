import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for the `builder` function which takes the [context] along with
/// the [event] and [status] as parameters.
///
/// It is called whenever the [BlocCustomEventStatusBuilder] receives
/// an event that matches the `filter` and the `listenWhen` condition specified.
typedef BlocCustomEventStatusWidgetBuilder<TEvent, TStatus> = Widget Function(
  BuildContext context,
  TEvent? event,
  TStatus? status,
);

/// Signature for the `filter` function which takes an event of type
/// [TEventSubType] and returns a boolean value.
///
/// It is called every time a new status is emitted from the bloc in order to
/// filter out the events that should not trigger `buildWhen` and the
/// `builder`.
typedef BlocEventFilterBuilder<TEventSubType> = bool Function(
  TEventSubType event,
);

/// Signature for the `buildWhen` function which takes the previous and current
/// status of type [TStatus] and returns a boolean value.
///
/// It is called every time a new status is emitted from the bloc in order to
/// determine whether the `builder` should be triggered or not.
typedef BlocCustomEventStatusBuilderCondition<TStatus> = bool Function(
  TStatus? previous,
  TStatus current,
);

/// {@template bloc_custom_event_status_builder}
/// A widget that listens to event statuses from a bloc and invokes a builder
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocCustomEventStatusMixin] and listen
/// to events of type [TEventSubType]. When a new event of type [TEventSubType]
/// is emitted by the Bloc, the provided [builder] function is called with the
/// current `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// BlocCustomEventStatusBuilder<SubjectBloc, SubjectEvent, MySubjectEvent, SubjectState, MyStatus>(
///   // optionally filter the events to listen to
///   filter: (event) => event.subject == 'Flutter',
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
class BlocCustomEventStatusBuilder<
    TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
    TEvent,
    TEventSubType extends TEvent,
    TStatus> extends StatefulWidget {
  /// {@macro bloc_custom_event_status_builder}
  const BlocCustomEventStatusBuilder({
    required this.builder,
    super.key,
    this.bloc,
    this.filter,
    this.buildWhen,
  });

  /// {@macro bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@macro bloc_custom_event_status_listener.filter}
  final BlocEventFilterBuilder<TEventSubType>? filter;

  /// {@template bloc_custom_event_status_builder.buildWhen}
  /// A function that determines when the `builder` should be called.
  /// It takes the previous and current status of type [TStatus] and returns a
  /// boolean value.
  /// {@endtemplate}
  final BlocCustomEventStatusBuilderCondition<TStatus>? buildWhen;

  /// {@template bloc_custom_event_status_builder.builder}
  /// A function that renders the widget based on the current event and status.
  /// It takes the `context`, the `event` of type [TEventSubType], and the
  /// `status` of type [TStatus] as parameters.
  ///
  /// The event can be null ony during the first build.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetBuilder<TEventSubType, TStatus> builder;

  @override
  State<BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TStatus>>
      createState() => _BloCustomEventStatusBuilderState<TBloc, TEvent,
          TEventSubType, TStatus>();
}

class _BloCustomEventStatusBuilderState<
        TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
        TEvent,
        TEventSubType extends TEvent,
        TStatus>
    extends State<
        BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TStatus>> {
  late TBloc _bloc;
  late EventStatusUpdate<TEventSubType, TStatus>? _eventStatus;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<TBloc>();
    _eventStatus = _bloc.eventStatusOf<TEventSubType>();
    if (_eventStatus != null &&
        widget.filter != null &&
        !widget.filter!(_eventStatus!.event)) {
      _eventStatus = null;
    }
  }

  @override
  void didUpdateWidget(
    BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TStatus>
        oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _eventStatus = _bloc.eventStatusOf<TEventSubType>();
      if (_eventStatus != null &&
          widget.filter != null &&
          !widget.filter!(_eventStatus!.event)) {
        _eventStatus = null;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<TBloc>();
    if (_bloc != bloc) {
      _bloc = bloc;
      _eventStatus = _bloc.eventStatusOf<TEventSubType>();
      if (_eventStatus != null &&
          widget.filter != null &&
          !widget.filter!(_eventStatus!.event)) {
        _eventStatus = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocCustomEventStatusListener<TBloc, TEvent, TEventSubType, TStatus>(
      bloc: _bloc,
      filter: widget.filter,
      listenWhen: widget.buildWhen,
      listener: (context, event, status) => setState(() {
        _eventStatus = (event: event, status: status);
      }),
      child: widget.builder(context, _eventStatus?.event, _eventStatus?.status),
    );
  }
}
