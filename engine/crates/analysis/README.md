# mixup-analysis

楽曲のテンポ、拍、小節、および小節ごとのボーカル活動を解析するRustクレートです。CLIやFlutterとの境界から再利用する解析ロジックを提供し、解析結果は `mixup-domain` の型で返します。

## 主な機能

- MP3、WAV、FLAC、OGG音源の読み込み
- テンポ、拍、ダウンビートの推定
- 4拍単位の小節グリッドの構築
- 音源分離に基づく小節ごとのボーカル確率の推定
- 拍グリッドの信頼度と、確認が必要な事項の警告

## 事前準備

拍解析には `mel_spectrogram.onnx` と `beat_this_small.onnx` が必要です。リポジトリルートで次のコマンドを実行すると、チェックサムを検証して `engine/models/` へダウンロードします。

```sh
./engine/scripts/download-models.sh
```

ボーカル分離用モデルは、初回解析時に `stem-splitter-core` によってOSのアプリケーションキャッシュへダウンロードされます。モデルの詳細とライセンス上の注意事項は [`../../models/README.md`](../../models/README.md) を参照してください。

## 使用方法

ワークスペース内のRustクレートから利用する場合は、対象クレートの `Cargo.toml` に依存関係を追加します。

```toml
[dependencies]
mixup-analysis = { path = "../../crates/analysis" }
```

解析器の生成時にモデルファイルを指定し、`analyze_file` に音声ファイルのパスを渡します。`Analyzer` は複数の音源で再利用できます。

```rust
use std::path::Path;

use anyhow::Result;
use mixup_analysis::{Analyzer, ModelPaths};

fn main() -> Result<()> {
    let models = Path::new("engine/models");
    let mel_spectrogram = models.join("mel_spectrogram.onnx");
    let beat_tracking = models.join("beat_this_small.onnx");
    let mut analyzer = Analyzer::new(ModelPaths {
        mel_spectrogram: &mel_spectrogram,
        beat_tracking: &beat_tracking,
    })?;

    let result = analyzer.analyze_file(Path::new("path/to/audio.mp3"))?;
    println!("tempo: {:.1} BPM", result.tempo_bpm);
    println!("bars: {}", result.bars.len());
    println!("beat confidence: {:.2}", result.beat_confidence);
    Ok(())
}
```

モデルや音声ファイルのパスは、プロセスのカレントディレクトリを基準に解決されます。

## 出力とエラー

`analyze_file` は [`mixup-domain`](../domain/README.md) の `TrackAnalysis` を返します。テンポ、小節、拍とボーカルの信頼度、および致命的ではない注意事項が含まれます。

次の場合などは `Err` を返します。

- モデルファイルを読み込めない、またはモデルが不正
- 音声ファイルをデコードできない
- 完全な小節を構成できるだけの拍が検出されない
- 拍解析またはボーカル分離に失敗する

低信頼度の解析結果は失敗とはせず、信頼度や `warnings` で表現します。自動解析の値を正解として断定せず、利用側でこれらも提示してください。

## テスト

リポジトリルートから、このクレートのテストを実行します。

```sh
cargo test \
  --manifest-path engine/Cargo.toml \
  --package mixup-analysis
```

ワークスペース共通の確認方法は、リポジトリルートの `AGENTS.md` を参照してください。
