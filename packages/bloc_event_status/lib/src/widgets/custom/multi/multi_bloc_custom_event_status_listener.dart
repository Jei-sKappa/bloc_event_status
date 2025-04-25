import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:bloc_event_status/helpers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

class MultiBlocCustomEventStatusListener<
    TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
    TEvent,
    TStatus> extends SingleChildStatefulWidget {
  const MultiBlocCustomEventStatusListener({
    super.key,
    // required List<Type> this.events,
    required this.listener,
    this.bloc,
    this.filter,
    this.listenWhen,
    super.child,
  });

  // const MultiBlocCustomEventStatusListener.all({
  //   super.key,
  //   required this.listener,
  //   this.bloc,
  //   this.filter,
  //   this.listenWhen,
  //   super.child,
  // }) : events = null;

  final TBloc? bloc;

  // final List<Type>? events;

  /// A function that defines the behavior when a new event of type [P] is
  /// emitted by the Bloc. It takes the current [BuildContext] and the
  /// event itself as parameters and is responsible for handling the event.
  final BlocCustomEventStatusWidgetListener<TEvent, TStatus> listener;

  final BlocCustomEventFilter<TEvent>? filter;

  final BlocCustomEventStatusListenerCondition<TEvent, TStatus>? listenWhen;

  @override
  SingleChildState<MultiBlocCustomEventStatusListener<TBloc, TEvent, TStatus>>
      createState() =>
          _BloCustomcEventStatusListenerBaseState<TBloc, TEvent, TStatus>();
}

class _BloCustomcEventStatusListenerBaseState<
        TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
        TEvent,
        TStatus>
    extends SingleChildState<
        MultiBlocCustomEventStatusListener<TBloc, TEvent, TStatus>> {
  final Map<
          Type,
          StreamSubscription<
              PreviousValuePair<EventStatusUpdate<TEvent, TStatus>>>>
      _streamSubscriptionMap = {};

  StreamSubscription<PreviousValuePair<EventStatusUpdate<TEvent, TStatus>>>?
      _allEventsStreamSubscription;

  late TBloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = widget.bloc ?? context.read<TBloc>();

    _subscribe();
  }

  @override
  void didUpdateWidget(
    MultiBlocCustomEventStatusListener<TBloc, TEvent, TStatus> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;

    if (oldBloc != currentBloc) {
      if (_streamSubscriptionMap.isNotEmpty ||
          _allEventsStreamSubscription != null) {
        _unsubscribe();
        _bloc = currentBloc;
      }

      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bloc = widget.bloc ?? context.read<TBloc>();

    if (_bloc != bloc) {
      if (_streamSubscriptionMap.isNotEmpty ||
          _allEventsStreamSubscription != null) {
        _unsubscribe();
        _bloc = bloc;
      }

      _subscribe();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return child ?? const SizedBox();
  }

  @override
  void dispose() {
    _unsubscribe();

    super.dispose();
  }

  void _subscribe() {
    _allEventsStreamSubscription = _bloc
        .streamAllEventStatus()
        .where((update) => widget.filter?.call(update.event) ?? true)
        .transform(WithPrevious())
        .listen(
      (data) {
        if (!mounted) return;

        final update = data.current;
        final event = update.event;
        final currentStatus = update.status;
        final previousStatus = data.previous?.status;

        final shouldTrigger =
            widget.listenWhen?.call(previousStatus, currentStatus) ?? true;
        if (shouldTrigger) {
          widget.listener(context, event, currentStatus);
        }
      },
    );
  }

  void _unsubscribe() {
    for (var streamSubscription in _streamSubscriptionMap.values) {
      streamSubscription.cancel();
    }
    _streamSubscriptionMap.clear();
  }
}
