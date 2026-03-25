## [2.0.0]

### Breaking Changes
- Removed `flutter_bloc`, `flutter`, and `nested` dependencies. The package is now pure Dart and depends on `bloc` directly.
- Removed all custom Flutter widgets (`BlocEventStatusBuilder`, `BlocEventStatusListener`, etc.) and the stream-based event status delivery. Use standard `flutter_bloc` widgets (`BlocListener`, `BlocBuilder`, `BlocSelector`) instead.
- Removed `BlocEventStatusContainer` and associated mixins. Event statuses are now stored as an `EventStatuses` field on the BLoC state.

### Added
- `EventStatuses<TEvent, TStatus>` — immutable, `Equatable` container that tracks event statuses by type.
- `EventStatusesMixin<TEvent, TStatus>` — convenience mixin for direct state-level access to `statusOf`, `eventOf`, `eventStatusOf`, and `lastEventStatus`.
- `EventStatusUpdate<TEvent, TStatus>` — record typedef returned by query methods.
- `BlocEventStatus` annotation and `blocEventStatus` constant for use with the `bloc_event_status_generator` code generator.

## [1.1.1] – 2025-07-06

### Changed
- Widened `flutter_bloc` dependency to support both 8.x and 9.x: `flutter_bloc: ">=8.0.0 <10.0.0"`

## [1.1.0]

### Changed
- Lowered dependency on `flutter_bloc` to `8.0.0`.


## [1.0.0]

- Initial release of `bloc_event_status` package.
