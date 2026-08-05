---
name: flutter-clean-architecture
description: Flutter / Dart アプリを Clean Architecture、SSOT、SOLID、依存性注入、feature 境界に沿って実装・レビューする。Flutter プロジェクトで機能追加、リファクタリング、不具合修正、ディレクトリ再編、domain、use case、port、adapter、state management、controller、navigation、shared UI、永続化、生成コード、architecture test を追加・変更するときに使う。
---

# Flutter クリーンアーキテクチャ

対象リポジトリの規約と現行実装を確認し、変更理由、依存方向、状態所有者を明示してから実装する。
一般的な Clean Architecture の定型を機械的に追加せず、プロジェクトに必要な境界だけを使う。

## 作業フロー

1. リポジトリの `AGENTS.md`、architecture 文書、対象コード、関連テストを探して読む。
2. `git status --short` で既存変更を確認し、依頼外の差分を保持する。
3. 変更する責務と SSOT を特定し、配置先と依存方向を決める。
4. 下記ルーティングに従って必要な reference を読む。境界を推測しない。
5. リポジトリの互換性方針を守り、最小の責務単位で実装する。
6. 古い経路、重複状態、不要な抽象化を残さず、呼び出し元、テスト、文書を同じ変更で整合させる。
7. 生成、整形、解析、テストを変更範囲に応じて実行する。
8. 最終報告で変更した設計境界、SSOT、検証結果、未検証事項を簡潔に示す。

## 参照資料の選択

- すべての実装・レビューで [layer-boundaries.md](references/layer-boundaries.md) を読む。
- use case、port、adapter、依存注入、bootstrap を変更するときは
  [dependency-injection.md](references/dependency-injection.md) を読む。
- Screen、Widget、Controller、UI state、route を変更するときは
  [presentation.md](references/presentation.md) を読む。
- リファクタリング、状態整理、責務レビューでは [ssot-solid.md](references/ssot-solid.md) を読む。
- 機能追加、外部 I/O、永続化、package 変更では [change-workflows.md](references/change-workflows.md) を読む。
- 実装を完了する前に [validation.md](references/validation.md) を読む。

## 判断の優先順位

矛盾を見つけた場合は次の順で判断する。

1. リポジトリの明示的な指示と機能仕様
2. architecture test などの実行可能な制約
3. architecture 文書
4. Accepted かつ supersede されていない最新 ADR
5. 現在の実装
6. 一般的な設計慣例

意図した境界変更なら、コードだけを例外化せず architecture test、architecture 文書、必要な ADR を
同時に更新する。プロジェクトが ADR を運用している場合、既存 ADR は削除せず新しい ADR で supersede する。

## 実装原則

- 内側のレイヤーから Flutter、状態管理 framework、plugin、具象 I/O を見せない。
- 同じ情報を複数の mutable state、dependency token、永続化 key、route 定義に保持しない。
- 利用者が必要とする最小契約へ依存し、具象選択をプロジェクトの composition root に集約する。
- 将来使うかもしれない interface、service、manager、forwarding layer を追加しない。
- 画面固有の状態と plugin lifecycle は所有 feature に置き、実利用が複数 feature に広がった時だけ
  shared、application、domain の適切な境界へ昇格する。
- 生成物を手編集しない。入力ファイルを修正して正規コマンドで再生成する。
- エラーを握りつぶさず、ユーザーに見える復旧可能な状態とプロジェクトの観測手段の両方を整える。

## 完了条件

- 責務の配置理由と依存方向を説明できる。
- SSOT が一つで、派生値は計算または `select` で取得できる。
- 既存の architecture test を弱める例外を追加していない。存在しなければ変更リスクに応じて導入を検討した。
- 対象 package / app の analyze と test が成功している。
- 生成物、翻訳、文書が変更内容と同期している。
