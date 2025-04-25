import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:bloc_event_status/helpers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

typedef BlocCustomEventStatusWidgetListener<TEventSubType, TStatus> = void
    Function(
  BuildContext context,
  TEventSubType event,
  TStatus status,
);

typedef BlocCustomEventFilter<TEventSubType> = bool Function(
  TEventSubType event,
);

typedef BlocCustomEventStatusListenerCondition<TEventSubType, TStatus> = bool
    Function(
  TStatus? previous,
  TStatus current,
);

/// A widget that listens to events from a bloc or cubit and invokes a listener
/// function in response to new events.
///
/// This widget is used to interact with [BlocCustomEventStatusMixin] and listen
/// to events of type [P]. When a new event of type [P] is emitted by the Bloc,
/// the provided [listener] function is called with the current [BuildContext]
/// and the event itself.
///
/// Example:
/// ```dart
/// BlocCustomEventStatusListener<MyBloc, MyEvent>(
///   listener: (context, event) {
///     // Handle the event here
///   },
///   bloc: myBloc, // You don't have to pass it if you provided it in context
///   child: SomeWidget(),
/// )
/// ```
class BlocCustomEventStatusListener<
    TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
    TEvent,
    TEventSubType extends TEvent,
    TStatus> extends SingleChildStatefulWidget {
  /// Creates a [BlocCustomEventStatusListener].
  ///
  /// The [listener] function is required and will be called with the
  /// current [BuildContext] and the event of type [P] when new events are
  /// emitted by the Bloc.
  ///
  /// The [bloc] parameter is optional and can be used to specify the
  /// Bloc to listen to. If not provided, the nearest ancestor Bloc of
  /// type [TBloc] in the widget tree will be used.
  const BlocCustomEventStatusListener({
    super.key,
    required this.listener,
    this.bloc,
    this.filter,
    this.listenWhen,
    super.child,
  });

  /// The Bloc from which to listen to events of type [P]. If not provided,
  /// the nearest ancestor Bloc of type [TBloc] in the widget tree will be used.
  final TBloc? bloc;

  /// A function that defines the behavior when a new event of type [P] is
  /// emitted by the Bloc. It takes the current [BuildContext] and the
  /// event itself as parameters and is responsible for handling the event.
  final BlocCustomEventStatusWidgetListener<TEventSubType, TStatus> listener;

  final BlocCustomEventFilter<TEventSubType>? filter;

  final BlocCustomEventStatusListenerCondition<TEventSubType, TStatus>?
      listenWhen;

  @override
  SingleChildState<
          BlocCustomEventStatusListener<TBloc, TEvent, TEventSubType, TStatus>>
      createState() => _BloCustomEventStatusListenerBaseState<TBloc, TEvent,
          TEventSubType, TStatus>();
}

class _BloCustomEventStatusListenerBaseState<
        TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
        TEvent,
        TEventSubType extends TEvent,
        TStatus>
    extends SingleChildState<
        BlocCustomEventStatusListener<TBloc, TEvent, TEventSubType, TStatus>> {
  StreamSubscription<PreviousValuePair<EventStatusUpdate<TEvent, TStatus>>>?
      _streamSubscription;
  late TBloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = widget.bloc ?? context.read<TBloc>();

    _subscribe();
  }

  @override
  void didUpdateWidget(
    BlocCustomEventStatusListener<TBloc, TEvent, TEventSubType, TStatus>
        oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;

    if (oldBloc != currentBloc) {
      if (_streamSubscription != null) {
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
      if (_streamSubscription != null) {
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
    _streamSubscription = _bloc
        .streamStatusOf<TEventSubType>()
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
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
