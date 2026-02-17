# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.
Remember to update this file when you make significant changes that needs to be remembered across session.

## Project Overview

`bloc_event_status` is a Dart/Flutter package that enables event status tracking in BLoC state management without modifying the main state. Published on pub.dev at version 2.0.0.

## Repository Structure

Monorepo with two packages:
- `packages/bloc_event_status/` — main library package
  - `lib/src/event_statuses.dart` — core `EventStatuses<TEvent, TStatus>` immutable class
  - `lib/src/event_statuses_mixin.dart` — `EventStatusesMixin` convenience accessor mixin
  - `test/` — unit tests (Dart `test` package)
  - `example/` — Flutter example app demonstrating real-world usage
- `packages/bloc_event_status_generator/` — code generator package
  - `lib/generator.dart` — builder factory (`blocEventStatusGenerator`)
  - `lib/src/bloc_event_status_generator.dart` — `BlocEventStatusGenerator` implementation
  - `test/bloc_event_status_generator_test.dart` — generator tests (uses `build_test`)

## Flutter Version

Uses FVM (Flutter Version Manager). Flutter version is `3.38.6` (configured in `.fvmrc`). Use `fvm flutter` or set Flutter SDK path to `.fvm/versions/3.38.6`.

## Commands

### `bloc_event_status` (run from `packages/bloc_event_status/`)

```bash
fvm flutter pub get       # Install dependencies
fvm flutter test          # Run tests
fvm flutter test --coverage
fvm flutter analyze       # Lint / analyze
fvm dart format .         # Format
```

### `bloc_event_status_generator` (run from `packages/bloc_event_status_generator/`)

```bash
fvm dart pub get          # Install dependencies
fvm dart test             # Run tests
fvm dart analyze          # Lint / analyze
fvm dart format .         # Format
```

### Example app (run from `example/`)

```bash
fvm flutter pub get
fvm flutter run -d macos
fvm dart run build_runner build --delete-conflicting-outputs  # Regenerate freezed models
```

## API Reference

### `EventStatuses<TEvent, TStatus>`

Immutable class (extends `Equatable`) that stores the status of each event type.

| Member | Description |
|---|---|
| `const EventStatuses()` | Creates an empty instance (use as initial value). |
| `update<TEventSubType>(event, status)` | Returns a **new** `EventStatuses` with the entry for `TEventSubType` updated. |
| `statusOf<TEventSubType>()` | Returns the current `TStatus` for `TEventSubType`, or `null`. |
| `eventOf<TEventSubType>()` | Returns the last `TEventSubType` instance that was updated, or `null`. |
| `eventStatusOf<TEventSubType>()` | Returns the full `EventStatusUpdate` record `({event, status})` for `TEventSubType`, or `null`. |
| `lastEventStatus` | Returns the most recently updated `EventStatusUpdate`, regardless of event type. |

### `EventStatusesMixin<TEvent, TStatus>`

Optional mixin for your BLoC state. Requires you to implement `EventStatuses<TEvent, TStatus> get eventStatuses`. Delegates all four query methods (`statusOf`, `eventOf`, `eventStatusOf`, `lastEventStatus`) to `eventStatuses`, so you can call them directly on the state.

### `EventStatusUpdate<TEvent, TStatus>`

A record typedef: `({TEvent event, TStatus status})`. Returned by `eventStatusOf` and `lastEventStatus`.

## Example app

### Pattern used

- BLoC state extends `Equatable` and uses `EventStatusesMixin`
- Emitter extension or manual `emit(state.copyWith(...))` propagates status updates
- UI uses `BlocListener`, `BlocSelector`, or `BlocBuilder` to react to specific event statuses

## Generator — How It Works

`BlocEventStatusGenerator` is a `GeneratorForAnnotation<BlocEventStatus>` (from `source_gen`). Given a `@blocEventStatus`-annotated `Bloc` subclass it:

1. Resolves the `Bloc<TEvent, TState>` supertype to get the event and state types.
2. Finds `EventStatusesMixin<TEvent, TStatus>` on the state to get the status base type.
3. Collects all concrete (non-abstract) subclasses of the status type declared in the same library.
4. Generates an `extension $<BlocName>EmitterX on Emitter<TState>` with:
   - A private `_emitEventStatus` helper that calls `state.copyWith(eventStatuses: ...)`.
   - One public convenience method per concrete status subtype.

### Testing the generator

Tests use `resolveSources()` from `build_test` with `readAllSourcesFromFilesystem: true` (required to resolve external types like `Bloc`). `generateForAnnotatedElement` is called directly on the class element found via `LibraryReader.classes`, bypassing annotation resolution.

## Commit Scopes

Conventional commits with scopes: `bes` (bloc_event_status package), `generator` (bloc_event_status_generator package), `example` (example app).
