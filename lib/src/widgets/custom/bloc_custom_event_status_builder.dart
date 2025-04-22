import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for the `builder` function which takes the `BuildContext` and
/// [state] and is responsible for returning a widget which is to be rendered.
/// This is analogous to the `builder` function in [StreamBuilder].
typedef BlocCustomEventStatusWidgetBuilder<TStatus> = Widget Function(
    BuildContext context, TStatus? status);

/// Signature for the `buildWhen` function which takes the previous `state` and
/// the current `state` and is responsible for returning a [bool] which
/// determines whether to rebuild [BlocBuilder] with the current `state`.
typedef BlocCustomEventStatusBuilderCondition<TStatus> = bool Function(
    TStatus? previous, TStatus current);

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
    this.buildWhen,
  });

  /// The [bloc] that the [BlocCustomEventStatusBuilder] will interact with.
  /// If omitted, [BlocCustomEventStatusBuilder] will automatically perform a lookup using
  /// [BlocProvider] and the current `BuildContext`.
  final TBloc? bloc;

  /// TODO: Add a description
  final TEventSubType? event;

  /// {@macro bloc_builder_build_when}
  final BlocCustomEventStatusBuilderCondition<TStatus>? buildWhen;

  /// The [builder] function which will be invoked on each widget build.
  /// The [builder] takes the `BuildContext` and current `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [StreamBuilder].
  final BlocCustomEventStatusWidgetBuilder<TStatus> builder;

  @override
  State<BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState, TStatus>>
      createState() => _BloCustomcEventStatusBuilderState<TBloc, TEvent,
          TEventSubType, TState, TStatus>();
}

class _BloCustomcEventStatusBuilderState<
        TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
        TEvent,
        TEventSubType extends TEvent,
        TState,
        TStatus>
    extends State<
        BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState, TStatus>> {
  late TBloc _bloc;
  late TStatus? _status;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<TBloc>();
    _status = _bloc.statusOf(widget.event);
  }

  @override
  void didUpdateWidget(
      BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState, TStatus> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _status = _bloc.statusOf(widget.event);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<TBloc>();
    if (_bloc != bloc) {
      _bloc = bloc;
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
      listenWhen: widget.buildWhen,
      listener: (context, state) => setState(() => _status = state),
      child: widget.builder(context, _status),
    );
  }
}
