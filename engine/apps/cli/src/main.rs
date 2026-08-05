mod installer;

use std::path::PathBuf;

use anyhow::Result;
use clap::{Args, Parser, Subcommand};
use installer::ModelName;
use mixup_analysis::{Analyzer, ModelPaths};

#[derive(Debug, Parser)]
#[command(about = "Analyze songs and manage the models used by Mixup")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Analyze tempo, four-beat bars, and per-bar vocal activity.
    Analyze(AnalyzeArgs),
    /// Download and checksum-verify analysis models.
    Install(InstallArgs),
}

#[derive(Debug, Args)]
struct AnalyzeArgs {
    /// Audio file to analyze.
    input: PathBuf,
    /// Directory containing `mel_spectrogram.onnx` and `beat_this_small.onnx`.
    #[arg(long, default_value = "models")]
    models: PathBuf,
}

#[derive(Debug, Args)]
struct InstallArgs {
    /// Model to install. If omitted, all models are installed.
    #[arg(value_enum)]
    model: Option<ModelName>,
    /// Directory in which to install the model files.
    #[arg(long, short = 'p', default_value = "models", value_name = "DIR")]
    path: PathBuf,
}

fn main() -> Result<()> {
    match Cli::parse().command {
        Command::Analyze(args) => analyze(&args),
        Command::Install(args) => install(&args),
    }
}

fn analyze(args: &AnalyzeArgs) -> Result<()> {
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

fn install(args: &InstallArgs) -> Result<()> {
    let models = args.model.map_or_else(ModelName::all, |model| vec![model]);

    for model in models {
        eprintln!("Installing {}", model.file_name());
        let installed = installer::install(model, &args.path)?;
        println!("{}", installed.display());
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::error::ErrorKind;

    #[test]
    fn parses_install_model_and_path() -> Result<()> {
        let cli = Cli::try_parse_from([
            "mixup",
            "install",
            "beat-this-small",
            "--path",
            "/tmp/models",
        ])?;

        let Command::Install(args) = cli.command else {
            anyhow::bail!("expected install command");
        };
        assert_eq!(args.model, Some(ModelName::BeatThisSmall));
        assert_eq!(args.path, PathBuf::from("/tmp/models"));
        Ok(())
    }

    #[test]
    fn rejects_unknown_model() -> Result<()> {
        let Err(error) = Cli::try_parse_from(["mixup", "install", "unknown"]) else {
            anyhow::bail!("unknown model should be rejected");
        };

        assert_eq!(error.kind(), ErrorKind::InvalidValue);
        Ok(())
    }
}
