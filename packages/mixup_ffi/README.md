# mixup_ffi

MixupのRust engineをDart / Flutterから呼び出すパッケージです。CLIと同じモデルの
インストールおよび楽曲解析を、型付きAPIとして提供します。

## ネイティブライブラリのビルド

リポジトリルートで次を実行します。

```sh
cargo build --release --manifest-path engine/Cargo.toml --package mixup-ffi
```

生成物はmacOSでは `engine/target/release/libmixup_ffi.dylib`、Linuxでは
`libmixup_ffi.so`、Windowsでは `mixup_ffi.dll` です。デスクトップから直接使う場合は
`MixupFfi.load(libraryPath: ...)` に生成物のパスを渡します。Flutterアプリへ組み込む場合は、
対象プラットフォームのRunnerへこのライブラリをリンクしてください。

## 使用例

```dart
import 'package:mixup_ffi/mixup_ffi.dart';

final mixup = await MixupFfi.load(
  libraryPath: 'engine/target/release/libmixup_ffi.dylib',
);

final installed = await mixup.install(modelsDirectory: 'engine/models');
final analysis = await mixup.analyze(
  'path/to/audio.mp3',
  modelsDirectory: 'engine/models',
);
print('${analysis.tempoBpm} BPM, ${analysis.bars.length} bars');
```

実ライブラリを使って `install` / `analyze` を実行するDart CLIは
[`apps/mixup_cli`](../../apps/mixup_cli/) にあります。

`install` のモデル省略時・保存先既定値と、`analyze` のモデルディレクトリ既定値はCLIと
同じです。非同期処理とネイティブスレッドへのディスパッチは `flutter_rust_bridge` が
管理するため、呼び出し中にUI isolateをブロックしません。

## bridgeコードの生成

Rust側の `engine/crates/bridge/src/api.rs` を変更した場合は、リポジトリルートで安定版の
コード生成器を実行します。`lib/src/rust/` と `frb_generated.rs` は生成物なので手動編集
しません。

```sh
flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge.yaml
```

## テスト

```sh
cd packages/mixup_ffi
dart pub get
dart test
```

実際のRustライブラリとの結合テストも実行する場合は、先にライブラリをビルドしてから
次の環境変数を設定します。

```sh
MIXUP_FFI_TEST_LIBRARY=../../engine/target/debug/libmixup_ffi.dylib dart test
```
