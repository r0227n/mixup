# mixup_cli

`mixup_ffi` の `install` と `analyze` をDartから実行するCLIアプリです。コマンドライン
引数の定義と解析には `package:args` を使用しています。

最初に `build-native` を実行します。releaseビルドとコピーが行われ、example直下に
`libmixup_ffi.dylib` が作成されます。

```sh
cd apps/mixup_cli
dart pub get
dart run bin/mixup_cli.dart build-native
```

macOSでモデルをインストールする例:

```sh
dart run bin/mixup_cli.dart \
  install --path ../../engine/models
```

楽曲を解析する例:

```sh
dart run bin/mixup_cli.dart \
  analyze path/to/audio.mp3 --models ../../engine/models
```

通常はアプリ直下の `libmixup_ffi.dylib` が自動的に使われます。別のライブラリを検証
する場合だけ `--library` または `MIXUP_FFI_LIBRARY` で上書きできます。
