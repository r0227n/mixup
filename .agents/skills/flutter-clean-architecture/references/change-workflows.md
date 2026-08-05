# 変更種別ごとの実装手順

## ドメインルールの追加・変更

1. UI、plugin、保存方式に依存しない不変条件か確認する。
2. `domain/<business-area>` に entity、value object、純粋 service を置く。
3. 不正値の扱い、境界値、正規化を unit test で固定する。
4. 外側から必要な型だけ `domain/domain.dart` で公開する。
5. UI 表示都合や永続化 DTO を domain に混ぜない。

## 共有 use case / 外部 I/O の追加

1. 複数の所有元で共有するユーザー目的か、統一すべき外部能力か確認する。
2. 必要なら application model / error / port を最小契約で定義する。
3. use case に処理順序、正規化、失敗分類を置く。
4. infrastructure adapter に plugin、codec、key の知識を閉じ込める。
5. application / infrastructure の公開入口を更新する。
6. 状態管理 token と composition root の生成・注入を追加する。
7. use case、adapter、DI override の各テストを追加する。

単一画面だけが利用し、画面 lifecycle と密接な plugin 操作なら presentation に留める。抽象化するためだけに
use case と port を追加しない。

## 機能・画面の追加

1. `presentation/features/<feature>` の所有範囲を定義する。
2. UI state と操作を controller、表示を screen / widget に分ける。
3. domain rule と application use case を公開入口および必須 token 経由で利用する。
4. 別 feature を import せず、共有状態・表示規則の真の所有者を判断する。
5. プロジェクトの route SSOT に route を追加し、必要なら生成する。
6. 表示文言をローカライズの入力ファイルに追加し、必要なら生成する。
7. controller test、必要な Widget / router test、architecture test を追加する。

## 永続設定の追加

1. 設定値の意味と default の所有者を決める。
2. application model と repository port / use case を更新する。
3. infrastructure 内の canonical owner に key を一度だけ定義する。
4. adapter に codec、後方読み込み方針、書き込み失敗の検出を置く。
5. 一つの canonical UI owner から更新する。
6. 他 controller へ値をコピーせず、必要な時点で owner を読む。
7. load、save、clear、壊れた値、default をテストする。

永続化 key や enum の保存表現を変える場合は仕様と移行方針を更新する。互換性を破る許可がなければ既存
利用者を壊さない。

## リファクタリング

1. 変更前の canonical owner と全 call site を `rg` で特定する。
2. 重複 state、転送層、使われない型、境界違反を分類する。
3. 新しい正へ call site をまとめて移し、古い正を削除する。
4. 公開境界を変更するならリポジトリの互換性方針を確認し、関連文書を更新する。
5. 差分に無関係な整形、依存更新、別機能の改善を混ぜない。
6. architecture test と回帰 test で構造と振る舞いを固定する。

## アーキテクチャ変更

1. 現行規則では解けない具体的な変更理由を示す。
2. ADR を運用している場合は採用案、代替案、結果を新しい ADR に記録する。
3. supersede 対象を新 ADR から明示し、旧 ADR を削除しない。
4. プロジェクトの architecture 文書、architecture test、実装を同時に更新する。
5. 一時的な allowlist や互換 shim を恒久設計として残さない。

## ローカルパッケージの変更

各 package の公開責務を `pubspec.yaml`、公開入口、文書、既存利用から確認する。純 Dart package へ Flutter
依存を持ち込まず、design system package へアプリ機能や navigation を持ち込まない。package 外から `src/`
を import せず、公開入口と影響する package test を更新する。
