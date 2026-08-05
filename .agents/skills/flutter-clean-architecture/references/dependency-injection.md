# 依存注入と Provider 規則

## 所有者

- application は純粋な use case と output port を所有する。
- infrastructure は constructor injection 可能な具象 adapter を所有する。
- presentation は application input boundary に依存する。状態管理用 token は presentation 側に置く。
- composition root は external instance、adapter、use case、状態管理 override の結線を所有する。

具象選択と結線の SSOT をアプリの composition root に限定する。ファイル名は既存規約に従う。

## framework からの分離

Riverpod、Provider、Bloc、GetIt などを採用している場合も、use case や adapter 自体を DI framework に
依存させない。状態管理 token は presentation または composition root の既存方針に従って配置する。

同居させない理由は次のとおり。

- application を Flutter と状態管理 framework から独立させる。
- infrastructure を DI framework と composition lifecycle から独立させる。
- application が infrastructure の具象 provider を選ぶ循環依存を防ぐ。
- アプリ全体の具象選択を一箇所でレビュー可能にする。
- DI token を外側の実装詳細として扱う。

## 必須 token の例

Riverpod を採用している場合、必須 token は具象実装へ fallback せず未注入なら即座に失敗させる。

```dart
@riverpod
ExampleUseCase exampleUseCase(Ref _) =>
    throw UnimplementedError('ExampleUseCase must be injected.');
```

composition root で `overrideWithValue` など採用 framework の仕組みを使って注入する。テストでも必要な
token を明示的に差し替え、production の既定実装を token 側へ埋め込まない。

## 新しい共有外部能力の追加順

1. application に利用者が必要とする最小の port を定義する。
2. application にユーザー目的単位の use case を定義し、constructor で port を受ける。
3. application 公開入口から必要な型だけ export する。
4. infrastructure に具象 adapter を実装し、公開入口から export する。
5. 状態管理 framework を使う場合は presentation 側に必須 use case token を追加する。
6. composition root で external instance → adapter → use case の順に生成して注入する。
7. unit test、DI override test、architecture test を追加または更新する。

## 抽象化の判断

port を追加するのは、外部能力を複数の所有元で共有する、失敗変換を統一する、または内側の業務手順を
I/O から隔離する場合に限定する。単一画面だけが使う UI plugin は所有 feature から直接利用する。
単一メソッドを転送するだけの service、manager、repository、Provider を自動的に追加しない。

use case はユーザー目的でまとめる。同じ設定の load / save / reset は同じ use case に置けるが、無関係な
操作を capability bundle に集約しない。利用者が不要なメソッドへ依存する場合は契約を分割する。

## Observability

presentation はプロジェクトの抽象的な error reporter / logger 境界に依存する。Crashlytics などの具象型を
内側へ漏らさず、具象 logger と observer は bootstrap または composition root で組み立てる。
