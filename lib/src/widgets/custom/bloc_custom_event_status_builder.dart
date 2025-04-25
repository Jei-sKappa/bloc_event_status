import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocCustomEventStatusWidgetBuilder<TEvent, TStatus> = Widget Function(
  BuildContext context,
  TEvent? event,
  TStatus? status,
);

typedef BlocCustomEventStatusBuilderCondition<TEvent, TStatus> = bool Function(
  TStatus? previous,
  TStatus current,
);

class BlocCustomEventStatusBuilder<
    TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TEventSubType extends TEvent,
    TState,
    TStatus> extends StatefulWidget {
  /// {@macro bloc_builder_base}
  const BlocCustomEventStatusBuilder({
    required this.builder,
    super.key,
    this.bloc,
    this.event,
    this.filter,
    this.buildWhen,
  });

  final TBloc? bloc;

  /// TODO: Add a description
  final TEventSubType? event;

  final BlocCustomEventFilter<TEventSubType>? filter;

  final BlocCustomEventStatusBuilderCondition<TEventSubType, TStatus>?
      buildWhen;

  /// The event can be null ony during the first build
  final BlocCustomEventStatusWidgetBuilder<TEventSubType, TStatus> builder;

  @override
  State<
      BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState,
          TStatus>> createState() => _BloCustomcEventStatusBuilderState<TBloc,
      TEvent, TEventSubType, TState, TStatus>();
}

class _BloCustomcEventStatusBuilderState<
        TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
        TEvent,
        TEventSubType extends TEvent,
        TState,
        TStatus>
    extends State<
        BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState,
            TStatus>> {
  late TBloc _bloc;
  late TEventSubType? _event;
  late TStatus? _status;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<TBloc>();
    _event = widget.event;
    _status = _bloc.statusOf<TEventSubType>(widget.event);
  }

  @override
  void didUpdateWidget(
      BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState,
              TStatus>
          oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _event = widget.event;
      _status = _bloc.statusOf(widget.event);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<TBloc>();
    if (_bloc != bloc) {
      _bloc = bloc;
      _event = widget.event;
      _status = _bloc.statusOf(widget.event);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bloc == null) {
      // Trigger a rebuild if the bloc reference has changed.
      // See https://github.com/felangel/bloc/issues/2127.
      context.select<TBloc, bool>((bloc) => identical(_bloc, bloc));
    }
    return BlocCustomEventStatusListener<TBloc, TEvent, TEventSubType, TStatus>(
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
