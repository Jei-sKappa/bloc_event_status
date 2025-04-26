import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:bloc_event_status/helpers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

/// Signature for the `listener` function which takes the [context] along with
/// the [event] and [status] as parameters.
///
/// It is called whenever the [BlocCustomEventStatusListener] receives
/// an event that matches the `filter` and the `listenWhen` condition specified.
typedef BlocCustomEventStatusWidgetListener<TEventSubType, TStatus> = void
    Function(
  BuildContext context,
  TEventSubType event,
  TStatus status,
);

/// Signature for the `filter` function which takes an event of type
/// [TEventSubType] and returns a boolean value.
///
/// It is called every time a new status is emitted from the bloc in order to
/// filter out the events that should not trigger `listenWhen` and the
/// `listener`.
typedef BlocEventFilterListener<TEventSubType> = bool Function(
  TEventSubType event,
);

/// Signature for the `listenWhen` function which takes the previous and current
/// status of type [TStatus] and returns a boolean value.
///
/// It is called every time a new status is emitted from the bloc in order to
/// determine whether the `listener` should be triggered or not.
typedef BlocCustomEventStatusListenerCondition<TStatus> = bool Function(
  TStatus? previous,
  TStatus current,
);

/// {@template bloc_custom_event_status_listener}
/// A widget that listens to event statuses from a bloc and invokes a listener
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocCustomEventStatusMixin] and listen
/// to events of type [TEventSubType]. When a new event of type [TEventSubType]
/// is emitted by the Bloc, the provided [listener] function is called with the
/// current `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// BlocCustomEventStatusListener<SubjectBloc, SubjectEvent, MySubjectEvent, MyStatus>(
///   // optionally filter the events to listen to
///   filter: (event) => event.subject == 'Flutter',
///   // optionally select when the listener should be called
///   listenWhen: (previous, current) => previous != current && current is MyFailureStatus,
///   // The listener function that will be called when a new status is emitted
///   listener: (context, event, status) {
///     print('Oops! Something went wrong with the Flutter subject: ${event.error}');
///   },
///   bloc: subjectBloc, // You don't have to pass it if you provided it in context
///   child: SomeWidget(),
/// )
/// ```
/// {@endtemplate}
class BlocCustomEventStatusListener<
    TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
    TEvent,
    TEventSubType extends TEvent,
    TStatus> extends SingleChildStatefulWidget {
  /// {@macro bloc_custom_event_status_listener}
  const BlocCustomEventStatusListener({
    super.key,
    required this.listener,
    this.bloc,
    this.filter,
    this.listenWhen,
    super.child,
  });

  /// {@template bloc_custom_event_status_listener.bloc}
  /// The Bloc from which to listen to events of type [TEventSubType]. If not
  /// provided, the nearest ancestor Bloc of type [TBloc] in the widget tree
  /// will be used.
  /// {@endtemplate}
  final TBloc? bloc;

  /// {@template bloc_custom_event_status_listener.listener}
  /// A function that defines the action to be taken when a new event status is
  /// emitted.
  /// It takes the `context`, the `event` of type [TEventSubType], and the
  /// `status` of type [TStatus] as parameters.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetListener<TEventSubType, TStatus> listener;

  /// {@template bloc_custom_event_status_listener.filter}
  /// A function that filters the events to listen to.
  /// It takes an event of type [TEventSubType] and returns a boolean value.
  /// {@endtemplate}
  final BlocEventFilterListener<TEventSubType>? filter;

  /// {@template bloc_custom_event_status_listener.listenWhen}
  /// A function that determines when the `listener` should be called.
  /// It takes the previous and current status of type [TStatus] and returns a
  /// boolean value.
  /// {@endtemplate}
  final BlocCustomEventStatusListenerCondition<TStatus>? listenWhen;

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
