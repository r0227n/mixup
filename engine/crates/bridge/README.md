# mixup-ffi bridge

MixupのRust解析エンジンをDart / Flutterから呼び出すためのFFI境界クレートです。
`flutter_rust_bridge`を使用し、Rustのドメイン型とエラーを、FFIで扱いやすい単純な型へ
変換します。音声解析やモデル管理の中核ロジックはこのクレートへ実装せず、
`mixup-analysis`と`mixup-domain`を呼び出します。

## 構成

- `src/api.rs`: Dartへ公開する関数、列挙型、データ型、およびドメイン型からの変換
- `src/lib.rs`: クレートのエントリーポイント
- `src/frb_generated.rs`: `flutter_rust_bridge`によるRust側の生成コード

対応するDartパッケージは
[`packages/mixup_ffi`](../../../packages/mixup_ffi/README.md)、engineの動作確認用CLIは
[`apps/mixup_cli`](../../../apps/mixup_cli/README.md)にあります。

## 公開API

`src/api.rs`では次の操作を公開しています。

- `install`: 必要な解析モデルをダウンロードし、SHA-256チェックサムを検証する
- `analyze`: 音源を解析し、テンポ、4拍単位の小節、拍信頼度、ボーカル活動、警告を返す

境界を越えるパスと時刻は、それぞれ文字列と秒単位の`f32`で表現します。エラーは
`anyhow::Result`として境界へ渡し、Dart側では例外として扱います。解析失敗と、解析に
成功した低信頼度の結果は区別し、後者は信頼度と`warnings`に保持します。

## ネイティブライブラリのビルド

リポジトリルートで実行します。

```sh
cargo build --release \
  --manifest-path engine/Cargo.toml \
  --package mixup-ffi
```

主な生成物は、macOSでは`engine/target/release/libmixup_ffi.dylib`、Linuxでは
`libmixup_ffi.so`、Windowsでは`mixup_ffi.dll`です。Dart側からのロード方法は
[`packages/mixup_ffi/README.md`](../../../packages/mixup_ffi/README.md)を参照してください。

## bridgeコードの生成

`src/api.rs`の公開関数または境界型を変更した場合は、リポジトリルートで次を実行します。

```sh
flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge.yaml
```

生成設定の正は`flutter_rust_bridge.yaml`です。次の生成物は手動編集しないでください。

- `engine/crates/bridge/src/frb_generated.rs`
- `packages/mixup_ffi/lib/src/rust/`以下

生成後はRust側とDart側の両方で整合性を確認します。

## テスト

リポジトリルートから、このクレートのフォーマット、静的解析、テストを実行します。

```sh
cargo fmt --manifest-path engine/Cargo.toml --all --check
cargo clippy \
  --manifest-path engine/Cargo.toml \
  --package mixup-ffi \
  --all-targets \
  --all-features \
  -- \
  -D warnings
cargo test \
  --manifest-path engine/Cargo.toml \
  --package mixup-ffi
```

Dartラッパーを含むテスト方法は
[`packages/mixup_ffi/README.md`](../../../packages/mixup_ffi/README.md)を参照してください。
