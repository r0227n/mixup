---
name: write-patrol-tests-from-lib
description: Derive executable, screen-organized Patrol E2E coverage and matching Japanese test documentation from Oshiki's Flutter lib implementation using Marionette IDs, real routes, Riverpod test seams, feature modules, and Patrol tags. Use when adding, updating, consolidating, or documenting Patrol tests for a screen hierarchy, covering normal and error flows, instrumenting widgets, or proving that app/patrol_test passes.
---

# Write Patrol Tests From Lib

Build the coverage model from the current `app/lib` code, not from an assumed
screen specification. Preserve unrelated uncommitted work and follow the
repository `AGENTS.md`.

Read [references/oshiki-patterns.md](references/oshiki-patterns.md) before
editing. It contains the current project paths, ID conventions, harness pattern,
tags, and commands.

## 1. Derive the test matrix from lib

1. Read `app/lib/presentation/navigation/routes.dart`.
2. Read each requested root screen and follow every user-reachable callback,
   typed route, dialog, sheet, and fullscreen child.
3. Read the controllers/providers and application ports used by those screens.
   Identify observable failures at external boundaries such as load, save,
   render, or permission operations.
4. Inspect existing `app/patrol_test` coverage and reuse valid harness,
   modules, IDs, and failure fakes.
5. Record a private coverage matrix with:
   - root and descendant screen;
   - action that reaches it;
   - success outcome;
   - reachable error outcome;
   - required Marionette ID;
   - owning `*_screen_test.dart` file;
   - matching documentation file and tag set.

Cover all reachable screens in the requested hierarchy. Do not invent error
flows that the UI cannot expose. Keep materially different failures in separate
tests so each failure cause is deterministic.

## 2. Instrument only the required UI

Prefer existing `xxx_marionette_ids.dart` files as the shared selector source
for both Marionette and Patrol. Do not introduce `keys.dart`.

- Define IDs in the feature or shared widget directory that owns the element.
- Use `abstract final class XxxMarionetteIds`.
- Use stable, unique ASCII values with dot-separated hierarchy.
- Use parameterized static methods for list rows and dynamic options.
- Keep IDs independent of localized display text.
- Add an ID only when a test or runtime Marionette interaction uses it.

Wrap an interactive region with `MarionetteNode(id: ..., interactive: true)`
when Marionette metadata is needed. `MarionetteNode` already falls back to
`ValueKey<String>(id)`; do not also pass the same `key:` property.

Use an explicit `ValueKey<String>(XxxMarionetteIds.value)` only when the target
is not represented by a `MarionetteNode`, such as a root `Scaffold`, an error
card, a retry button, a transient feedback widget, or a framework-owned page.

In Patrol, locate app widgets only through the shared ID:

```dart
await $(
  const ValueKey<String>(SettingsMarionetteIds.screen),
).waitUntilVisible();
```

Do not change a widget signature or restructure production UI merely to attach
a selector.

## 3. Build deterministic app-level scenarios

Use the real app router and real presentation/controllers. Replace external
application ports with deterministic in-memory implementations through
Riverpod overrides.

- Model each failure with an explicit switch or dedicated fake behavior.
- Seed the minimum domain state needed to reach the screen.
- Keep production infrastructure, device storage, and network out of
  deterministic widget-level Patrol scenarios.
- Surface failures through the same UI path users see; do not assert fake
  internals.
- Make the harness own and dispose every `ProviderContainer` and `GoRouter`.
- Give a repumped host a distinct identity so the prior host is disposed.

Use native Patrol APIs for flows that genuinely cross into OS UI. Handle native
dialogs immediately after the triggering action.

## 4. Organize tests by screen

Use the production screen as the file boundary. Convert `preview_screen.dart`
and `PreviewScreen`, for example, into
`app/patrol_test/preview_screen_test.dart` with these rules:

- Keep one top-level `group` named after the screen class.
- Put every scenario primarily owned by that screen in the group as an
  independent `patrolTest`.
- Keep materially different normal and error outcomes in separate
  `patrolTest` callbacks so failures remain diagnosable.
- Split a scenario that resets the app or validates unrelated destinations;
  do not combine several independent journeys into one long test.
- Keep tests for a different screen in that screen's own `*_screen_test.dart`.
- Keep a genuinely cross-screen critical journey in a separately named flow
  test only when assigning it to one screen would obscure its purpose.

Import `package:flutter_test/flutter_test.dart` with `show group` only because
Patrol does not export the grouping API. Continue to use
`package:patrol/patrol.dart` for `patrolTest` and all Patrol interactions.

Pump every scenario through the shared `testApp` wrapper and create a `Modules`
aggregate from its tester.

During development, write a short action sequence directly in the test. Run it,
then move stable user-facing actions and assertions into the appropriate
feature module. The finished test file should describe the scenario through
module methods rather than raw finders.

Keep module methods at user-intent level. After navigation, verify the
destination screen before repumping or replacing the app; otherwise the test
can pass without proving that the descendant screen rendered. Keep the final
business outcome assertion at the end of the scenario.

Use Patrol APIs only in files importing `package:patrol/patrol.dart`. Other than
the narrow `show group` import above, do not use `flutter_test` APIs. Do not add
handwritten setup/teardown wrappers, arbitrary delays, or catch-and-ignore
blocks.

Use descriptive Japanese scenario names. Add comments only for non-obvious
grouping decisions, deterministic Fake behavior, or native boundaries; do not
narrate every action already expressed by module method names.

## 5. Document each screen test

Create exactly one Japanese Markdown document for every top-level Patrol test
file under `app/patrol_test/docs/`. Match the basename:

```text
app/patrol_test/preview_screen_test.dart
app/patrol_test/docs/preview_screen_test.md
```

Keep all scenarios from the Dart file in that one document. Include:

- the screen or flow purpose;
- shared prerequisites and deterministic Fake assumptions;
- separate normal and error sections when both exist;
- numbered operations with observable expected results for every scenario;
- the tags used by the file.

Explain why a setup or boundary exists instead of restating implementation
details. Do not create one Markdown file per `patrolTest`. Format and check the
documents with dprint.

## 6. Apply tags consistently

Use constants from `app/patrol_test/support/test_tags.dart`.

- Add the feature tag to every scenario.
- Add `smoke` only to short, stable, critical normal paths.
- Add `error` to negative scenarios.
- Add `regression` to the maintained hierarchy suite.
- Keep tag lists in alphabetical order.

Use expressions such as `settings && error` to run intersections. Do not encode
the same classification separately in filenames and ad hoc string literals.

## 7. Run and diagnose

1. Run a single new test after each logical group of actions with Patrol MCP
   when available.
2. On failure, inspect Patrol output and a screenshot. Inspect the native tree
   only for native or cross-app UI.
3. Confirm the selector is attached and scroll when the element is outside the
   viewport; do not add arbitrary waits.
4. Rerun after moving actions into modules.
5. Run changed non-native screen tests together with
   `mise run patrol-test-changed`. Pass explicit tags and a device when testing
   native scenarios.
6. Run feature/tag groups and then the complete affected Patrol suite with
   `patrol test` when the change affects shared harness or module code.
7. Run Dart formatting, dprint for test documents, the app analyzer, and
   `git diff --check`.

Never use `flutter test` to execute Patrol tests.

## Completion criteria

Finish only when:

- every requested lib-derived screen is exercised;
- normal and reachable error outcomes are covered;
- scenarios are consolidated into the owning `*_screen_test.dart` group;
- every Patrol test file has one same-basename Japanese document under
  `app/patrol_test/docs/`;
- every selector resolves from a shared Marionette ID;
- every newly added or changed Patrol test passes on the target device;
- the affected tagged groups and full affected suite pass;
- Dart formatting, test-document dprint, and analysis pass;
- no generated `patrol_test/test_bundle.dart` is tracked;
- the final report lists scenario counts, commands, device, and any genuinely
  untestable boundary.
