use std::path::PathBuf;

use anyhow::Result;
use clap::Parser;
use mixup_analysis::{Analyzer, ModelPaths};

#[derive(Debug, Parser)]
#[command(about = "Analyze tempo, four-beat bars, and per-bar vocal activity")]
struct Args {
    /// Audio file to analyze.
    input: PathBuf,
    /// Directory containing `mel_spectrogram.onnx` and `beat_this_small.onnx`.
    #[arg(long, default_value = "models")]
    models: PathBuf,
}

fn main() -> Result<()> {
    let args = Args::parse();
    eprintln!("Analyzing {}", args.input.display());
    let mut analyzer = Analyzer::new(ModelPaths {
        mel_spectrogram: &args.models.join("mel_spectrogram.onnx"),
        beat_tracking: &args.models.join("beat_this_small.onnx"),
    })?;
    let result = analyzer.analyze_file(&args.input)?;
    serde_json::to_writer_pretty(std::io::stdout().lock(), &result)?;
    println!();
    Ok(())
}
