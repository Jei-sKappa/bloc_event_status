# Changelog

## 1.0.1

### Fixed
- Fixed method name derivation when subtype and base class share only a common suffix with different prefixes (e.g. `LoadingEventStatus` / `CounterEventStatus` now correctly derives `loading` instead of `loadingEventStatus`).

### Changed
- Widened `analyzer` dependency to `>=6.0.0 <13.0.0`.
- Widened SDK constraint from `^3.6.1` to `>=3.5.0 <4.0.0`.

## 1.0.0

- Initial release of `bloc_event_status_generator`.
- Generates `Emitter<TState>` extensions from `@blocEventStatus`-annotated Bloc classes.
- Auto-derives method names by stripping the shared prefix and suffix from concrete status subtypes.
- Supports positional, named, required, and optional constructor parameters.
- Supports generic type parameters on status subtypes.
