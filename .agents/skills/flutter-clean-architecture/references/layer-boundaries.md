# レイヤー境界と配置規則

## 依存方向

アプリの `lib` 配下ではコンパイル時依存を原則として次の向きに限定する。既存構成の名称が異なる場合は、
ディレクトリ名ではなく責務を対応付ける。

```text
presentation ──> application ──> domain
presentation ──────────────────> domain
infrastructure ─> application ─> domain
composition root ─> presentation / infrastructure / application
```

`domain` と `application` から Flutter、状態管理 framework、plugin、具象 I/O を参照しない。
`infrastructure` から `presentation` と composition root を参照しない。
`presentation` から `infrastructure` と composition root を参照しない。

## 配置判断

次の順で最初に該当する所有者へ置く。

1. UI や端末なしでも成立する業務の不変条件: `lib/domain/<business-area>`
2. ユーザー目的の業務手順: `lib/application/use_cases`
3. application が必要とする差し替え可能な外部能力: `lib/application/ports`
4. application 境界の入力・出力モデルと失敗分類: `lib/application/models`、`lib/application/errors`
5. 永続化、通信、platform API の具象 adapter: `lib/infrastructure`
6. 画面入力、表示、UI state、lifecycle、単一 feature の plugin: `lib/presentation/features/<feature>`
7. 複数 feature が実際に共有する UI state または Widget: `lib/presentation/shared`
8. route 定義: `lib/presentation/navigation`
9. 起動、外部 instance、具象選択、DI override: `lib/app` などの composition root

型の種類ではなく、業務領域と変更理由でまとめる。単一利用のコードを「共通化候補」という理由だけで
shared、core、application へ昇格しない。

## 公開境界

package 間では `lib/<package_name>.dart` など既存の公開入口を使い、外部 package から `lib/src/` を
import しない。アプリ内の layer barrel は既存規約がある場合だけ使い、巨大な barrel を新設しない。

## ディレクトリ規則

- `application/`: `errors`、`models`、`ports`、`use_cases` と公開入口だけを置く。
- `domain/`: 技術種別ではなく業務領域で分ける。
- `infrastructure/`: 必要に応じて `persistence`、`network`、`platform` など外部技術で分ける。
- `presentation/`: `dependencies`、`features`、`navigation`、`shared` をトップレベルとする。
- feature は必要な `screens`、`controllers`、`models`、`widgets` だけを持つ。
- feature は別 feature を import しない。`shared` は feature を import しない。

## 境界を守る正

既存の architecture test があれば依存規則の実行可能な仕様として扱う。なければ、境界変更の頻度と
回帰リスクに見合う場合に追加する。allowlist を広げる前に配置または依存方向を見直す。
