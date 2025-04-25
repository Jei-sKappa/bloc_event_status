import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MultiBlocCustomEventStatusBuilder<
    TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TState,
    TStatus> extends StatefulWidget {
  /// {@macro bloc_builder_base}
  const MultiBlocCustomEventStatusBuilder({
    required this.builder,
    super.key,
    this.bloc,
    this.filter,
    this.buildWhen,
  });

  final TBloc? bloc;

  final BlocCustomEventFilter<TEvent>? filter;

  final BlocCustomEventStatusBuilderCondition<TEvent, TStatus>? buildWhen;

  /// The event can be null ony during the first build
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
    _status = _bloc.statusOfAllEvents();
  }

  @override
  void didUpdateWidget(
      MultiBlocCustomEventStatusBuilder<TBloc, TEvent, TState, TStatus>
          oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _event = null;
      // TODO: This should be filterd by the event filter otherwise it will return the status of the last event that was triggered and maybe not the one that was requested by the user
      _status = _bloc.statusOfAllEvents();
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
      _status = _bloc.statusOfAllEvents();
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
