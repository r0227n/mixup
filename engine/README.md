# mixup engine

楽曲を解析し、アイドルライブのMIXを入れやすい区間の判定に利用するRustワークスペースです。現在は、テンポ、拍、4拍単位の小節、および小節ごとのボーカル活動を解析するライブラリとFlutter向けFFIを提供しています。

解析結果は正解を断定するものではありません。信頼度と警告を含むデータとして返し、利用側でユーザーが確認・修正できることを前提としています。

## 構成

```text
engine/
├── crates/
│   ├── analysis/     # 拍・小節・ボーカル活動の解析
│   ├── bridge/       # Flutter/DartとのFFI境界
│   └── domain/       # 解析結果の共通ドメイン型
├── assets/           # 開発用のローカル音源（Git管理外）
├── models/           # モデルの取得情報とローカル配置先
└── tools/            # 解析結果を確認する開発用ツール
```

依存関係は次の方向に限定します。

```text
bridge -> analysis -> domain
```

- [`crates/analysis/`](crates/analysis/README.md): 解析機能とRust APIの使用方法
- [`crates/bridge/`](crates/bridge/): Flutter/Dart向けFFI
- [`crates/domain/`](crates/domain/README.md): 解析結果の型と値の扱い
- [`models/`](models/README.md): モデルの取得元、チェックサム、ライセンス上の注意事項

## 必要な環境

- Rust 1.92.0
- `rustfmt` と `clippy`
- モデルや依存クレートの初回取得に利用できるネットワーク接続

Rustのバージョンとコンポーネントは `rust-toolchain.toml` に固定されています。Rustupを利用している場合、このディレクトリの設定が自動的に適用されます。

## セットアップ

リポジトリルートで、Dart CLIをビルドして拍解析用モデルをダウンロードします。

```sh
cd apps/mixup_cli
dart pub get
dart run bin/mixup_cli.dart build-native
dart run bin/mixup_cli.dart install --path ../../engine/models
```

CLIはモデルのSHA-256チェックサムを検証します。ボーカル分離用モデルは初回解析時にOSのアプリケーションキャッシュへ自動的にダウンロードされます。詳しい使用方法は [`../apps/mixup_cli/README.md`](../apps/mixup_cli/README.md) を参照してください。

著作権上、再配布できない楽曲をリポジトリへ追加しないでください。ローカルの開発用音源は `engine/assets/` に置き、Gitでは管理しません。

## CLIで解析する

`apps/mixup_cli/` から、解析する音声ファイルとモデルディレクトリを指定します。

```sh
dart run bin/mixup_cli.dart \
  analyze path/to/audio.mp3 \
  --models ../../engine/models
```

対応形式はMP3、WAV、FLAC、OGGです。解析結果のJSONは標準出力へ、進行メッセージとエラーは標準エラー出力へ出力されます。

## 開発時の確認

リポジトリルートから、ワークスペース全体を確認します。

```sh
cargo fmt --manifest-path engine/Cargo.toml --all --check
cargo check --manifest-path engine/Cargo.toml --workspace
cargo clippy \
  --manifest-path engine/Cargo.toml \
  --workspace \
  --all-targets \
  --all-features \
  -- \
  -D warnings
cargo test --manifest-path engine/Cargo.toml --workspace
```

クレートを限定して確認する場合は、パッケージ名を指定します。

```sh
cargo test --manifest-path engine/Cargo.toml --package mixup-analysis
cargo test --manifest-path engine/Cargo.toml --package mixup-domain
```

## 実装時の原則

- 解析と推薦の中核ロジックは再利用可能な `crates/` に置き、Dart CLIやFlutterへ重複実装しません。
- 共通のデータ型とその意味は `mixup-domain` を正とします。
- 時刻の単位、値域、信頼度をAPI上で明確にします。
- 解析失敗と、解析には成功したものの信頼度が低い結果を区別します。
- モデルや大きな音声ファイル、秘密情報をGitへ追加しません。

プロジェクト全体のアーキテクチャ、実装方針、完了条件は、リポジトリルートの `AGENTS.md` を参照してください。
