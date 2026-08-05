# mixup

音声ファイルを解析し、テンポ、4拍単位の小節、および小節ごとのボーカル活動をJSONで出力するCLIです。

## 事前準備

Rustツールチェーンと、解析対象の音声ファイルを用意してください。対応する音声形式はMP3、WAV、FLAC、OGGです。

拍解析用モデルはGitで管理していないため、CLIの `install` コマンドでダウンロードします。

```sh
cargo run --manifest-path engine/Cargo.toml \
  --package mixup \
  -- \
  install --path engine/models
```

モデル名を省略すると、解析に必要なモデルをすべて取得します。個別に取得する場合は `mel-spectrogram` または `beat-this-small` を指定できます。

```sh
cargo run --manifest-path engine/Cargo.toml \
  --package mixup \
  -- \
  install beat-this-small --path engine/models
```

保存先を省略した場合は、カレントディレクトリの `models/` に保存されます。ダウンロードしたモデルは、利用前にSHA-256チェックサムが検証されます。ボーカル分離用モデルは、初回解析時にOSのアプリケーションキャッシュへ自動的にダウンロードされます。

## 実行方法

リポジトリルートから次のように実行します。

```sh
cargo run --manifest-path engine/Cargo.toml \
  --package mixup \
  -- \
  analyze \
  path/to/audio.mp3 \
  --models engine/models
```

`path/to/audio.mp3` は解析する音声ファイルのパスへ置き換えてください。

解析結果のJSONは標準出力へ、進行メッセージとエラーは標準エラー出力へ出力されます。JSONをファイルへ保存する場合は、次のようにリダイレクトします。

```sh
cargo run --quiet --manifest-path engine/Cargo.toml \
  --package mixup \
  -- \
  analyze \
  path/to/audio.mp3 \
  --models engine/models \
  > analysis.json
```

## 出力結果

標準出力には、次のようなJSONが出力されます。数値は説明用の例であり、実際の解析結果は音源によって異なります。

```json
{
  "analyzer_version": "0.1.0",
  "tempo_bpm": 120.0,
  "bars": [
    {
      "number": 1,
      "start_seconds": 0.0,
      "end_seconds": 2.0,
      "beats_seconds": [0.0, 0.5, 1.0, 1.5],
      "beat_confidence": 0.96,
      "vocal_probability": 0.82,
      "acoustic_vocal_probability": 0.78,
      "vocal_state": "vocal"
    },
    {
      "number": 2,
      "start_seconds": 2.0,
      "end_seconds": 4.0,
      "beats_seconds": [2.0, 2.5, 3.0, 3.5],
      "beat_confidence": 0.94,
      "vocal_probability": 0.31,
      "acoustic_vocal_probability": 0.28,
      "vocal_state": "uncertain"
    }
  ],
  "beat_confidence": 0.95,
  "warnings": [
    "Vocal activity is inferred from source separation and remains a recommendation."
  ]
}
```

### トップレベルのプロパティ

| プロパティ | JSON型 | 単位・範囲 | 説明 |
|---|---|---|---|
| `analyzer_version` | string | - | 結果を生成した解析パイプラインのバージョンです。アルゴリズム変更前後の結果を識別するために使用します。 |
| `tempo_bpm` | number | BPM | 楽曲全体の推定テンポです。テンポを算出できない場合は `0.0` になります。 |
| `bars` | array | - | 4拍単位で構築された小節の配列です。各要素の構造は次の表を参照してください。 |
| `beat_confidence` | number | `0.0..=1.0` | 楽曲全体の拍グリッドに対する信頼度です。値が大きいほど信頼度が高いことを表します。 |
| `warnings` | string[] | - | 解析結果の制約や、確認が必要な事項を表す致命的ではない警告です。空の場合もあります。 |

### `bars` の各要素

| プロパティ | JSON型 | 単位・範囲 | 説明 |
|---|---|---|---|
| `number` | number | 1以上 | 1から始まる小節番号です。 |
| `start_seconds` | number | 秒 | 小節の開始時刻です。 |
| `end_seconds` | number | 秒 | 小節の終了時刻です。次の小節がある場合は、その小節の先頭拍と一致します。 |
| `beats_seconds` | number[] | 秒 | 小節内にある4つの拍の時刻です。音源全体の先頭を `0.0` 秒とする絶対時刻で表します。 |
| `beat_confidence` | number | `0.0..=1.0` | 小節内の拍の規則性に対する信頼度です。 |
| `vocal_probability` | number | `0.0..=1.0` | 時間方向と4小節フレーズの文脈を反映した、最終的なボーカル確率です。 |
| `acoustic_vocal_probability` | number | `0.0..=1.0` | 音源分離後の音響エネルギーから直接求めた、文脈補正前のボーカル確率です。 |
| `vocal_state` | string | 下表を参照 | `vocal_probability` から導出した大まかなボーカル状態です。 |

### `vocal_state` の値

| 値 | 説明 |
|---|---|
| `vocal` | ボーカル区間と推定されています。 |
| `instrumental` | インストゥルメンタル区間と推定されています。 |
| `uncertain` | どちらかを明確に判断できない区間です。 |

時刻、テンポ、確率、状態はすべて自動解析による推定値です。特に信頼度が低い結果や `warnings` がある結果は、音源を確認したうえで利用してください。

## オプション

```text
mixup analyze [OPTIONS] <INPUT>
mixup install [OPTIONS] [MODEL]
```

- `analyze --models <DIR>`: 解析に使うモデルのディレクトリ。既定値は `models` です。
- `install [MODEL]`: 指定モデルを取得します。省略時は全モデルを取得します。
- `install --path <DIR>` / `-p <DIR>`: モデルの保存先。既定値は `models` です。

## ビルド済みバイナリを使う

リリースビルドを作成します。

```sh
cargo build --release \
  --manifest-path engine/Cargo.toml \
  --package mixup
```

リポジトリルートから、生成されたバイナリを次のように実行できます。

```sh
./engine/target/release/mixup \
  analyze \
  path/to/audio.mp3 \
  --models engine/models
```

## 補足

- 解析時間は音源の長さや実行環境により変わります。
- 自動解析の結果は推定値です。出力される信頼度と警告も確認してください。
- モデルの取得元、チェックサム、ライセンス上の注意事項は [`../../models/README.md`](../../models/README.md) を参照してください。
