# SSOT と SOLID のレビュー基準

## SSOT

変更前に「誰が値を所有し、誰が派生させ、誰が永続化するか」を一文で定義する。

次の対象について、リポジトリ内の canonical owner を特定する。固定のファイル名を仮定せず、見つからなければ
今回の変更範囲で最も狭い適切な所有者を一つ定める。

| 対象 | canonical owner の例 |
| --- | --- |
| SDK、workspace、開発 command | ルート設定と各 `pubspec.yaml` |
| route | navigation の route 定義 |
| 翻訳文言 | localization の入力ファイル |
| package 公開 API | `lib/<package_name>.dart` |
| 具象依存の選択と結線 | composition root |
| 永続化 key と codec | infrastructure の persistence adapter |
| 画面状態 | 所有 feature の controller / notifier state |
| 依存制約 | architecture test |

次を重複状態として検出する。

- 同じ bool / enum / id / list を controller field と immutable state の両方で持つ。
- dependency token を別名 token へ転送する。
- 設定値を listener で別 controller へコピーする。
- 保存値、draft、表示値の区別なしに同じ情報を複数 state へ保持する。
- route、永続化 key、default 値、変換規則を複数ファイルに直書きする。
- index を identity として使い、並び替えや更新で対象がずれる。

コピーを削除し、必要な時点で canonical owner から読む。状態管理 framework が提供する `select` などで
購読範囲を絞る。表示最適化が必要なら
identity と revision を持つ安定した cache key を使う。

## SRP

class、file、directory の変更理由を一つにする。Controller が UI state と操作変換、use case が共有する
業務手順、adapter が plugin / codec、composition root が具象選択を担当する。名前に `Manager`、`Service`、
`Utils` を付ける前に、所有する変更理由を具体化する。

## OCP

新機能を既存の巨大 switch、capability bundle、共通 controller の肥大化で追加しない。新しい feature、
use case、adapter を既存境界へ接続する。一方、拡張点が一つしかない段階で plugin registry や抽象 factory を
先回りして追加しない。

## LSP

interface 実装は成功、失敗、nullability、順序、永続化の意味を保つ。テスト fake だけが満たせる契約や、
実装ごとに前提条件が異なる広すぎる interface を避ける。subtype が不要なら継承階層を作らない。

## ISP

利用者が必要な操作だけを契約に含める。無関係な load / save / render / navigate を一つの capability class に
まとめない。ただし同じユーザー目的の設定 load / update / reset は、一貫した use case としてまとめてよい。

## DIP

内側は Flutter、状態管理 framework、具象 plugin、永続化・観測 SDK に依存しない。application が port を所有し、
infrastructure が実装し、app が選択する。presentation は application use case token と observability token を
参照する。

## 不要な抽象化

次の形を原則として削除または追加しない。

- application input boundary として必要な use case を除く、一度だけ転送する interface + implementation + DI token
- typed route を呼ぶだけの navigator abstraction
- 元の state / dependency token を返すだけの forwarding layer
- 実利用のない shared Widget / shared model
- 互換性のためだけの re-export、別名型、別名 token

リポジトリが後方互換性を要求するなら移行計画を示す。破壊的変更が許可されている場合は、互換 shim で
古い正を残さず、全 call site、test、document を同じ変更で更新する。
