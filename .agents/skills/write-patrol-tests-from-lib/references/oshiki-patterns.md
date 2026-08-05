# Oshiki Patrol and Marionette patterns

## Source-of-truth paths

- Routes: `app/lib/presentation/navigation/routes.dart`
- Presentation: `app/lib/presentation`
- Marionette wrapper:
  `app/lib/presentation/shared/widgets/marionette_node.dart`
- Tests: `app/patrol_test`
- Test documents: `app/patrol_test/docs`
- Feature modules: `app/patrol_test/modules/modules.dart`
- Test harness: `app/patrol_test/support/test_app.dart`
- Tags: `app/patrol_test/support/test_tags.dart`
- Patrol environment: `app/.patrol.env`
- Patrol configuration: `app/pubspec.yaml`

Read the relevant current files before copying a pattern because these paths
may evolve.

## ID pattern

Keep IDs with their owning screen or shared widget:

```dart
abstract final class SettingsMarionetteIds {
  static const screen = 'settings.screen';
  static const theme = 'settings.theme';

  static String dialogOption(String id, String option) =>
      '$id.option.$option';
}
```

`MarionetteNode` supplies the Patrol key automatically:

```dart
MarionetteNode(
  id: SettingsMarionetteIds.theme,
  interactive: true,
  child: tile,
)
```

Its constructor delegates with:

```dart
super(key: key ?? ValueKey<String>(id))
```

Therefore, do not write both `id:` and an equivalent `key:`. For widgets that
cannot use `MarionetteNode`, attach the shared ID explicitly:

```dart
Scaffold(
  key: const ValueKey<String>(SettingsMarionetteIds.screen),
  // ...
)
```

Patrol consumes the same string:

```dart
await $(
  const ValueKey<String>(SettingsMarionetteIds.theme),
).scrollTo().tap();
```

## Test harness pattern

Pump `OshikiApp` with the real `GoRouter` and a manually owned
`ProviderContainer`. Override application use cases or port providers with
in-memory implementations.

Use a stateful host and dispose both owned resources:

```dart
final class _TestAppHost extends StatefulWidget {
  const _TestAppHost({
    required this.container,
    required this.router,
    super.key,
  });

  final ProviderContainer container;
  final GoRouter router;

  @override
  State<_TestAppHost> createState() => _TestAppHostState();
}

final class _TestAppHostState extends State<_TestAppHost> {
  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: widget.container,
    child: TranslationProvider(child: OshikiApp(router: widget.router)),
  );

  @override
  void dispose() {
    widget.router.dispose();
    widget.container.dispose();
    super.dispose();
  }
}
```

Pump it with `key: UniqueKey()` when a test replaces the app during a scenario.
This ensures that the old state and its resources are disposed.

Represent deterministic negative paths explicitly:

```dart
final class TestFailures {
  const TestFailures({
    this.imageLibrary = false,
    this.layoutRendering = false,
  });

  final bool imageLibrary;
  final bool layoutRendering;
}
```

Throw from the relevant fake port and assert the user-visible error feedback.
Do not make a negative test depend on an actual filesystem, photo library, or
network failure.

## Screen test and module pattern

Keep scenarios together by their owning screen. Use one top-level group and
multiple focused `patrolTest` callbacks:

```dart
import 'package:flutter_test/flutter_test.dart' show group;
import 'package:patrol/patrol.dart';

void main() {
  group('PreviewScreen', () {
    // 画面内の通常操作を、結果ごとに独立したシナリオとして検証する。
    patrolTest(
      '選択した画像を削除し、残った画像を表示する',
      tags: const [PatrolTags.preview, PatrolTags.regression],
      ($) async {
        await testApp(
          $,
          initialLocation: const PreviewRoute().location,
          galleryImageCount: 2,
        );
        final modules = Modules($);

        await modules.preview.selectThumbnail(0);
        await modules.preview.deleteSelectedImage();

        await modules.preview.assertPreviewVisible();
      },
    );

    // 外部I/Oの異常はFakeで固定し、ユーザーに見える状態を検証する。
    patrolTest(
      '画像ライブラリへの保存失敗を通知する',
      tags: const [
        PatrolTags.error,
        PatrolTags.preview,
        PatrolTags.regression,
      ],
      ($) async {
        await testApp(
          $,
          initialLocation: const PreviewRoute().location,
          failures: const TestFailures(imageLibrary: true),
          galleryImageCount: 1,
        );
        final modules = Modules($);

        await modules.preview.saveSelectedImage();

        await modules.preview.assertSaveFailed();
      },
    );
  });
}
```

Name the file `preview_screen_test.dart`, following the production
`preview_screen.dart`. Even a screen with one scenario keeps the group so the
suite remains structurally consistent.

Use modules for reusable user-facing actions:

```dart
Future<void> openAndSaveTwoImageLayoutPreset() async {
  await $(
    const ValueKey<String>(SettingsMarionetteIds.layoutPresets),
  ).scrollTo().tap();
  await $(ValueKey<String>(LayoutPresetsMarionetteIds.row(2))).tap();
  await $(
    const ValueKey<String>(LayoutPresetEditorMarionetteIds.screen),
  ).waitUntilVisible();
  await $(
    const ValueKey<String>(LayoutPresetEditorMarionetteIds.save),
  ).scrollTo().tap();
  await $(
    const ValueKey<String>(LayoutPresetsMarionetteIds.screen),
  ).waitUntilVisible();
}
```

The destination checks are important when the scenario later calls `testApp`
again. Without them, replacing the widget tree could hide a broken navigation.

## Test documentation pattern

For `app/patrol_test/preview_screen_test.dart`, create
`app/patrol_test/docs/preview_screen_test.md`. Use one document for every
scenario in the screen group:

```markdown
# プレビュー画面

## 目的

プレビュー画面の主要操作と、失敗時のフィードバックを確認する。

## 正常系

### 選択画像の削除

1. 先頭画像を選択する。
2. 選択中の画像を削除する。
3. 残った画像が表示されることを確認する。

## 異常系

外部I/Oの失敗を再現するFakeを使用する。

### 画像保存の失敗

1. 保存処理が失敗する状態で保存する。
2. 保存失敗のメッセージが表示されることを確認する。

タグ: `error`, `preview`, `regression`
```

Use Japanese headings and expected results. Explain deterministic setup where
it matters. Do not split the document per scenario.

## Tags

Define tags once:

```dart
abstract final class PatrolTags {
  static const error = 'error';
  static const gallery = 'gallery';
  static const regression = 'regression';
  static const settings = 'settings';
  static const smoke = 'smoke';
}
```

Common CLI filters:

```shell
patrol test --tags smoke
patrol test --tags error
patrol test --tags 'settings && error'
patrol test --exclude-tags error
```

When the app requires its configured flavor and device, preserve those
arguments:

```shell
patrol test -d <device-id> --flavor dev --tags smoke
```

## Validation

Run single files with Patrol MCP when available:

```text
patrol-run({"testFile":"patrol_test/<name>_test.dart"})
```

Use Patrol CLI for tag groups and the complete suite. From `app`, run:

```shell
patrol test -d <device-id> --flavor dev --tags smoke
patrol test -d <device-id> --flavor dev --tags error
patrol test -d <device-id> --flavor dev
```

From the repository root, also run:

```shell
mise run patrol-test-changed
dart format app/patrol_test app/lib/presentation
dprint check --incremental=false app/patrol_test/docs/*.md
melos exec --scope=app -- "dart analyze --fatal-infos"
git diff --check
```

`mise run patrol-test-changed` bundles changed Patrol files once, selects an
available simulator or emulator, and excludes `native` by default. Run native
coverage explicitly:

```shell
mise run patrol-test-changed -- --tags native --device <device-id>
```

Before finishing, verify that the basenames of top-level `*_test.dart` files
and `docs/*.md` files match one-to-one.

Do not run Patrol files through `flutter test`. Keep generated
`app/patrol_test/test_bundle.dart` ignored.
