import 'dart:async';

/// {@template cached_stream_controller}
/// A wrapper around a [StreamController] that caches the last event.
/// {@endtemplate}
class CachedStreamController<T> implements StreamController<T> {
  /// {@macro cached_stream_controller}
  CachedStreamController(StreamController<T> innerStreamController)
      : _innerStreamController = innerStreamController;

  final StreamController<T> _innerStreamController;

  T? _lastEvent;

  /// The last event that was added to the stream. Returns `null` if no event
  /// has been added yet.
  T? get lastEvent => _lastEvent;

  @override
  FutureOr<void> Function()? get onCancel => _innerStreamController.onCancel;

  @override
  void Function()? get onListen => _innerStreamController.onListen;

  @override
  void Function()? get onPause => _innerStreamController.onPause;

  @override
  void Function()? get onResume => _innerStreamController.onResume;

  @override
  set onCancel(FutureOr<void> Function()? onCancel) =>
      _innerStreamController.onCancel = onCancel;
  @override
  set onListen(void Function()? onListen) =>
      _innerStreamController.onListen = onListen;
  @override
  set onPause(void Function()? onPause) =>
      _innerStreamController.onPause = onPause;

  @override
  set onResume(void Function()? onResume) =>
      _innerStreamController.onResume = onResume;

  @override
  void add(T event) {
    _innerStreamController.add(event);

    // Update the last value
    _lastEvent = event;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _innerStreamController.addError(error, stackTrace);

  @override
  Future<dynamic> addStream(Stream<T> source, {bool? cancelOnError}) =>
      _innerStreamController.addStream(source, cancelOnError: cancelOnError);

  @override
  Future<dynamic> close() async {
    await _innerStreamController.close();
    _lastEvent = null;
  }

  @override
  Future<dynamic> get done => _innerStreamController.done;

  @override
  bool get hasListener => _innerStreamController.hasListener;

  @override
  bool get isClosed => _innerStreamController.isClosed;

  @override
  bool get isPaused => _innerStreamController.isPaused;

  @override
  StreamSink<T> get sink => _innerStreamController.sink;

  @override
  Stream<T> get stream => _innerStreamController.stream;
}
