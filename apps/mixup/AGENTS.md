# AGENTS.md

このファイルは `apps/mixup` のデスクトップ・Web 向け Flutter GUI を開発するためのルールです。
ルートの `AGENTS.md` と併せて適用し、競合する場合はこのアプリ固有の規則を優先します。

## 対象

- UI は Flutter / Dart で実装し、デスクトップと Web の両方で成立する操作・レイアウトを基本とします。
- 機能は `lib/presentation/features/<feature>/` 単位で配置し、画面、状態、操作を機能境界の内側にまとめます。
- アプリ起動、ルーティング、依存の組み立ては機能実装から分離します。
- 音声解析は `packages/mixup_ffi` で実装し、その公開 API を介して利用します。`engine/` や生成 FFI コードを
  アプリから直接参照・編集しません。
- 音声・動画・YouTube などのメディア再生には `packages/mixup_media_player` の公開 API を使用し、
  個別の再生ライブラリへ直接依存しません。

## 設計原則

Rust・Flutterを問わず、**SSOT**と**SOLID原則**に従って実装します。

### SSOT（Single Source of Truth）

- 仕様・型・定数・ビジネスルールは一箇所を正とし、他の場所へ複製しません。
- 共有スキーマは`contracts/`を正とし、Rust・Flutter・CLIはここから生成または参照します。
- 音声解析・MIX推薦の中核ロジックはRust（`engine/crates/`）にのみ置き、FlutterやCLIへ重複実装しません。
- 設定値、単位、エラーコード、UI文言の定義元を明確にし、散在させません。

### SOLID原則

- **S（単一責任）**: モジュール・型・Widgetは一つの変更理由に限定します。解析、推薦、UI表示、入出力を混在させません。
- **O（開放/閉鎖）**: 新しい解析手法や推薦戦略は既存コードの改変ではなく、拡張ポイント（trait、インターフェース）で追加します。
- **L（リスコフ置換）**: 抽象型を利用する側は、具体実装の差し替えで挙動の前提が崩れないようにします。
- **I（インターフェース分離）**: 利用側が使わないAPIを持たせません。trait・抽象クラスは用途ごとに小さく分割します。
- **D（依存性逆転）**: 上位モジュールは下位の具体実装ではなく抽象に依存します。Flutterは解析エンジンの実装詳細ではなく、bridge経由の契約に依存します。

### 破壊的変更

- 本プロジェクトは初期開発段階であり、**後方互換性を維持する必要はありません**。
- 設計やAPIの改善のため、破壊的変更を躊躇せず行って構いません。
- 破壊的変更を行う場合は、影響範囲（Rust・Flutter・CLI・`contracts/`）を揃えて更新し、テストで整合性を確認します。
- 移行期間の互換レイヤーや非推奨警告は、明示的に求められない限り追加しません。

## アーキテクチャ

Clean Architecture を採用し、`lib/` 配下を次の4レイヤーに分けます。

- `domain`: UI や外部パッケージに依存しないエンティティ、値、ビジネスルールを置きます。
- `application`: ユースケースと、外部機能を利用するための最小の port を定義します。
- `infrastructure`: `mixup_ffi`、`mixup_media_player`、`settings.json`、プラットフォーム API などを扱う
  adapter を置き、application の port を実装します。
- `presentation`: 画面、Widget、画面状態、controller、ルーティングを機能単位で置きます。

依存方向は `presentation → application → domain` および
`infrastructure → application → domain` とします。`domain` と `application` は Flutter、外部パッケージ、
具象 I/O に依存させません。具象 adapter の選択と依存の組み立ては composition root に集約します。

## Flutter GUI の実装

- Widget は表示と入力の受け渡しに専念させ、業務ルール、解析、ファイル I/O を `build` 内に置きません。
- 画面状態の所有者を一つにし、同じ値を複数の Widget や controller に保持しません。
- 非同期処理は待機中、成功、空結果、失敗を区別し、失敗時の再試行や次の操作を表示します。
- 可変幅、キーボード・マウス操作、文字サイズ変更、意味のあるラベル、十分なコントラストを考慮します。
- 表示文言はローカライズ可能な定義元で管理し、Widget に重複して埋め込みません。
- プラットフォーム固有 API は adapter に閉じ込め、UI とビジネスルールから直接呼びません。

## データ保存の段階方針

- 開発前半は `assets/settings.json` をアプリデータの保存先かつ SSOT とします。初期値や固定データを
  Dart コードや Widget に重複して定義しません。
- JSON の読み込み、変換、検証は infrastructure の adapter に閉じ込めます。presentation と domain は
  `settings.json`、asset path、JSON key を直接参照せず、application が定義する最小の port を利用します。
- `settings.json` は Flutter asset であり、配布後の実行環境から直接更新できる永続ストレージとは
  みなしません。開発前半のデータ更新は原則としてファイル自体の編集で行います。
- 開発後半では、composition root で adapter を差し替え、設定・ユーザーデータはデータ永続化
  パッケージへ、音源などのファイル選択・参照はファイル参照パッケージへ移行します。
- 移行時に UI、domain、use case の変更を不要にするため、保存方式固有の型、key、path、例外を
  application の内側へ漏らしません。互換用の二重保存は明示的に求められない限り追加しません。

## テストと完了条件

- 機能追加とバグ修正には、主要な正常系と失敗系の unit / Widget test を追加します。
- `settings.json` の adapter は正常値、欠損、壊れた JSON、既定値の扱いをテストします。
- 変更後は対象範囲で `dart format --output=none --set-exit-if-changed`、`flutter analyze`、
  `flutter test` を実行します。プラットフォーム固有の変更では対象環境でビルドまたは起動も確認します。
- 未コミットの既存変更を戻さず、依頼外の整形、依存更新、生成物の手編集を行いません。
- 実行できなかった検証がある場合は、理由と残るリスクを報告します。
