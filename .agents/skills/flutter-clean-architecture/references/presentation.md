# Presentation 実装規則

## Feature-first

変更対象を `presentation/features/<feature>` から探索する。Screen、Controller、feature 固有 Widget と
補助 model を同じ feature に置く。技術種別のトップレベル `pages`、`notifiers`、`providers` を作らない。

複数 feature で実利用される UI state は `shared/controllers`、表示規則は `shared/widgets` へ置く。
一つの feature しか使わない型を先回りして shared へ置かない。feature 間 import で共有せず、所有権を
見直して shared、application、domain の適切な境界へ昇格する。

## Controller と状態

- プロジェクトが採用する状態管理手法に従い、controller / notifier と state の所有関係を明確にする。
- feature 専用の immutable state、補助 enum、派生 getter は controller と近接させてよい。
- mutable state の所有者を一つにし、画面は `watch` / `select` で読む。
- 派生値は state の getter、domain service、Provider の `select` で求め、別 Provider や field にコピーしない。
- 永続設定の更新は controller → application use case の順に行い、保存結果と UX 要件に沿って UI state を更新する。
- ビジネス不変条件を controller に複製せず domain の value object / service を使う。

非同期処理では dispose 後の完了を考慮する。await 後に state、ref、controller、timer、isolate を扱う前に
`context.mounted`、`ref.mounted` など採用 API の lifecycle を確認する。開始した timer、subscription、
stream、isolate、plugin resource は同じ所有者で解放する。多重実行防止状態も canonical state に含める。

## Screen と Widget

- Screen は状態の購読、イベント接続、画面構成を担当する。
- I/O、非同期開始、重い計算を `build` で実行しない。
- feature 固有の表示部品は feature の `widgets` に置く。
- 複数 feature が同じ表示規則を実際に共有するときだけ `shared/widgets` に昇格する。
- theme、色、余白、文字、角丸、寸法はプロジェクトの theme / design token を優先する。
- 表示文言を直書きせず、プロジェクトのローカライズ SSOT を更新する。
- `const` は自然な場所で使い、可読性を損なう機械的変更を行わない。

## Plugin の扱い

画面 lifecycle や単一画面の表示処理と密接な UI plugin は、presentation の framework API として所有
feature に置ける。

複数箇所で共有する端末 I/O、統一した権限・失敗変換が必要な処理、永続化 key と codec は application
port と infrastructure adapter を経由する。presentation から永続化・通信の具象 plugin を直接呼ばない。

## Navigation

route 定義の SSOT を一箇所に定める。採用 router が typed route を提供するならそれを直接利用し、単に
route 呼び出しを転送する navigator interface、Provider、callback bundle を作らない。

生成型 router を採用している場合は route 変更後に正規コマンドで再生成する。router の observer と初期
location は bootstrap / app router composition で組み立て、別の `MaterialApp` へ分岐させない。

## エラー

端末依存処理の例外を握りつぶさない。ユーザーが再試行または判断できる UI state / feedback を用意し、
同時に既存の観測境界へ error と stack trace を渡す。application で分類すべき外部境界エラーは
application error に変換し、具象 plugin 例外を画面全体へ拡散させない。
