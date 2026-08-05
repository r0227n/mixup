# 生成・テスト・完了確認

## 生成物

`*.g.dart`、`*.freezed.dart` など、ヘッダーや設定から生成物と判断できるファイルを手編集しない。

生成設定を確認し、annotation、serialization、immutable model、localization、typed route などの入力を
変更したら、対象 Flutter package で正規の generator を実行する。build_runner 採用時の例:

```shell
flutter pub get
flutter pub run build_runner build
```

生成後は意図しない package の生成物が変わっていないか差分を確認する。

## 最小検証

Dart / Flutter コードを変更したら、少なくとも対象 package / app の format check、analyze、test を行う。
設計境界を変更し architecture test がある場合は先に実行する。

```shell
cd <flutter-package-or-app>
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

小さい変更では対象 test を先に実行し、共通契約、DI、navigation、plugin lifecycle、永続化、domain を
変更した場合は影響 package / app の全 test まで広げる。純 Dart package では `dart analyze` と `dart test`
を使う。

Dart は `dart format` を使う。文書や設定はリポジトリが指定する formatter を使う。

```shell
dart format --output=none --set-exit-if-changed <changed-dart-paths>
git diff --check
```

既存の無関係な差分まで一括整形しない。対象ファイルだけの整形で十分な場合は範囲を限定する。

## テストの配置

- domain rule: `test/domain`
- application use case / model: `test/application`
- infrastructure adapter / codec: `test/infrastructure`
- controller / route / Widget: `test/presentation`
- 依存方向と directory constraint: `test/architecture`
- local package: 各 package の `test`

振る舞い test と architecture test を代替関係にしない。前者で結果、後者で依存・配置を固定する。

## 完了前チェック

- `git status --short` と `git diff --check` を確認する。
- 未コミットの既存変更を戻していないことを確認する。
- 生成物が入力と同期していることを確認する。
- 新しい表示文言が localization の SSOT にあることを確認する。
- 新しい具象 adapter が composition root だけで選択されていることを確認する。
- presentation / infrastructure が application の内部 path を import していないことを確認する。
- dependency token、state、key、route の重複 SSOT がないことを確認する。
- async resource の dispose と await 後の lifecycle check を確認する。
- 実行できなかった検証と理由を最終報告へ記載する。

## 最終報告

最初に結果を示し、次に次の内容だけを簡潔に報告する。

1. 変更した責務と設計判断
2. SSOT / SOLID 上の改善点
3. 主要ファイル
4. 実行した生成、解析、テストと結果
5. 残るリスクまたは未検証事項
