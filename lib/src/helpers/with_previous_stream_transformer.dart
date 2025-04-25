import 'dart:async';

typedef PreviousValuePair<T> = ({T? previous, T current});

class WithPrevious<T> extends StreamTransformerBase<T, PreviousValuePair<T>> {
  final T? initialPrevious;
  WithPrevious([this.initialPrevious]);

  @override
  Stream<PreviousValuePair<T>> bind(Stream<T> stream) async* {
    var previous = initialPrevious;
    await for (final element in stream) {
      yield (previous: previous, current: element);
      previous = element;
    }
  }
}
