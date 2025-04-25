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
    this.filter,
    this.buildWhen,
  });

  final TBloc? bloc;

  final BlocCustomEventFilter<TEventSubType>? filter;

  final BlocCustomEventStatusBuilderCondition<TEventSubType, TStatus>?
      buildWhen;

  /// The event can be null ony during the first build
  final BlocCustomEventStatusWidgetBuilder<TEventSubType, TStatus> builder;

  @override
  State<
      BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState,
          TStatus>> createState() => _BloCustomEventStatusBuilderState<TBloc,
      TEvent, TEventSubType, TState, TStatus>();
}

class _BloCustomEventStatusBuilderState<
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
    _event = null;
    // TODO: This should be filterd by the event filter otherwise it will return the status of the last event that was triggered and maybe not the one that was requested by the user
    // _status = _bloc.statusOf<TEventSubType>();
    _status = null; // Temp fix
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
      _event = null;
      // TODO: This should be filterd by the event filter otherwise it will return the status of the last event that was triggered and maybe not the one that was requested by the user
      // _status = _bloc.statusOf<TEventSubType>();
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
      // _status = _bloc.statusOf<TEventSubType>();
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
