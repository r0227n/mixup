# mixup-domain

mixupエンジンで共有する解析結果のドメイン型を定義するRustクレートです。解析処理や入出力処理には依存せず、`analysis`、CLI、Flutterとの境界で共通の意味を持つデータ表現を提供します。

## 定義している型

### `TrackAnalysis`

1曲分の解析結果です。

- 解析器のバージョン
- 推定テンポ（BPM）
- 4拍単位の小節一覧
- 曲全体の拍グリッド信頼度（`0.0..=1.0`）
- 致命的ではない制約や注意事項

### `BarAnalysis`

1小節分の解析結果です。

- 1始まりの小節番号
- 小節の開始・終了時刻（秒）
- 小節内の4つの拍位置（秒）
- 拍の規則性に対する信頼度（`0.0..=1.0`）
- 文脈補正後と音響解析直後のボーカル確率
- 大まかなボーカル状態

### `VocalState`

小節のボーカル状態を `Vocal`、`Instrumental`、`Uncertain` のいずれかで表します。JSONではそれぞれ `vocal`、`instrumental`、`uncertain` へシリアライズされます。

## 使用方法

ワークスペース内のRustクレートから利用する場合は、対象クレートの `Cargo.toml` に依存関係を追加します。

```toml
[dependencies]
mixup-domain = { path = "../../crates/domain" }
```

```rust
use mixup_domain::{BarAnalysis, TrackAnalysis, VocalState};

let result = TrackAnalysis {
    analyzer_version: "0.1.0".to_owned(),
    tempo_bpm: 120.0,
    bars: vec![BarAnalysis {
        number: 1,
        start_seconds: 0.0,
        end_seconds: 2.0,
        beats_seconds: vec![0.0, 0.5, 1.0, 1.5],
        beat_confidence: 0.95,
        vocal_probability: 0.8,
        acoustic_vocal_probability: 0.75,
        vocal_state: VocalState::Vocal,
    }],
    beat_confidence: 0.95,
    warnings: Vec::new(),
};
```

すべての公開型は `Serialize` と `Deserialize` を実装しているため、境界でJSONなどへ変換できます。シリアライズ処理そのものは、このクレートではなくCLIやbridgeなどの境界側で行います。

## 値を扱う際の注意

- 時刻の単位は秒、テンポの単位はBPMです。
- 小節番号は1から始まります。
- 信頼度と確率は `0.0..=1.0` の範囲を前提とします。
- 浮動小数点の時刻や確率を完全一致で比較せず、用途に応じた許容誤差を使用してください。
- `Uncertain` や低い信頼度は解析失敗ではありません。解析失敗は `analysis` クレートのエラーとして別に扱います。
- 型や値の意味はこのクレートを正とし、利用側に同じ定義を重複させないでください。

## テスト

リポジトリルートから、このクレートのテストを実行します。

```sh
cargo test \
  --manifest-path engine/Cargo.toml \
  --package mixup-domain
```

ワークスペース共通の確認方法は、リポジトリルートの `AGENTS.md` を参照してください。
