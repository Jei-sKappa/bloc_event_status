import 'dart:async';

/// A record that holds the `previous` and `current` value of a stream.
///
/// The `previous` value can be `null` if the stream is emitting its first
/// value.
typedef PreviousValuePair<T> = ({T? previous, T current});

/// {@template with_previous_stream_transformer}
/// A [StreamTransformer] that pairs each value in a stream with its previous
/// value.
///
/// This transformer takes each value from the source stream and emits a record
/// containing
/// both the current value and the previous value. The first emission will have
/// the [initialPrevious] value, if provided, as the previous value.
///
/// The transformed stream emits a [PreviousValuePair], which is a record type
/// containing:
/// * `previous`: The previous value in the stream (or [initialPrevious] for the
/// first emission)
/// * `current`: The current value from the stream
///
/// Example:
/// ```dart
/// final stream = Stream.fromIterable([1, 2, 3]);
/// final withPrevious = stream.transform(WithPrevious(0));
/// // Emits: (previous: 0, current: 1)
/// //        (previous: 1, current: 2)
/// //        (previous: 2, current: 3)
/// ```
/// {@endtemplate}
class WithPrevious<T> extends StreamTransformerBase<T, PreviousValuePair<T>> {
  /// Creates a [WithPrevious] transformer.
  ///
  /// {@macro with_previous_stream_transformer}
  WithPrevious([this.initialPrevious]);

  /// The initial previous value to use for the first emission.
  ///
  /// If `null`, the first emission will have `null` as the previous value.
  final T? initialPrevious;

  @override
  Stream<PreviousValuePair<T>> bind(Stream<T> stream) async* {
    var previous = initialPrevious;
    await for (final element in stream) {
      yield (previous: previous, current: element);
      previous = element;
    }
  }
}
