//! Dart-facing operations and simple serializable boundary types.

use std::path::Path;

use anyhow::{Context, Result};
use mixup_analysis::{
    Analyzer, ModelPaths,
    models::{self, ModelName},
};
use mixup_domain::{BarAnalysis as DomainBarAnalysis, TrackAnalysis as DomainTrackAnalysis};

/// Analyzer model that can be installed independently.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MixupModel {
    /// Mel-spectrogram preprocessing model.
    MelSpectrogram,
    /// Small Beat This beat-tracking model.
    BeatThisSmall,
}

impl From<MixupModel> for ModelName {
    fn from(value: MixupModel) -> Self {
        match value {
            MixupModel::MelSpectrogram => Self::MelSpectrogram,
            MixupModel::BeatThisSmall => Self::BeatThisSmall,
        }
    }
}

/// Coarse vocal classification for a four-beat bar.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum VocalState {
    Vocal,
    Instrumental,
    Uncertain,
}

/// Complete analysis returned by the Mixup engine.
#[derive(Clone, Debug, PartialEq)]
pub struct TrackAnalysis {
    pub analyzer_version: String,
    pub tempo_bpm: f32,
    pub bars: Vec<BarAnalysis>,
    pub beat_confidence: f32,
    pub warnings: Vec<String>,
}

/// Analysis values for one four-beat musical bar.
#[derive(Clone, Debug, PartialEq)]
pub struct BarAnalysis {
    pub number: usize,
    pub start_seconds: f32,
    pub end_seconds: f32,
    pub beats_seconds: Vec<f32>,
    pub beat_confidence: f32,
    pub vocal_probability: f32,
    pub acoustic_vocal_probability: f32,
    pub vocal_state: VocalState,
}

impl From<DomainTrackAnalysis> for TrackAnalysis {
    fn from(value: DomainTrackAnalysis) -> Self {
        Self {
            analyzer_version: value.analyzer_version,
            tempo_bpm: value.tempo_bpm,
            bars: value.bars.into_iter().map(Into::into).collect(),
            beat_confidence: value.beat_confidence,
            warnings: value.warnings,
        }
    }
}

impl From<DomainBarAnalysis> for BarAnalysis {
    fn from(value: DomainBarAnalysis) -> Self {
        Self {
            number: value.number,
            start_seconds: value.start_seconds,
            end_seconds: value.end_seconds,
            beats_seconds: value.beats_seconds,
            beat_confidence: value.beat_confidence,
            vocal_probability: value.vocal_probability,
            acoustic_vocal_probability: value.acoustic_vocal_probability,
            vocal_state: match value.vocal_state {
                mixup_domain::VocalState::Vocal => VocalState::Vocal,
                mixup_domain::VocalState::Instrumental => VocalState::Instrumental,
                mixup_domain::VocalState::Uncertain => VocalState::Uncertain,
            },
        }
    }
}

/// Download and checksum-verify one model, or every required model when `model` is `None`.
///
/// # Errors
///
/// Returns an error if a download, write, or checksum verification fails.
pub fn install(model: Option<MixupModel>, path: &str) -> Result<Vec<String>> {
    let selected = model.map_or_else(|| ModelName::all().to_vec(), |value| vec![value.into()]);
    selected
        .into_iter()
        .map(|model| {
            models::install_model(model, Path::new(path))
                .with_context(|| format!("failed to install {}", model.file_name()))
                .map(|installed| installed.to_string_lossy().into_owned())
        })
        .collect()
}

/// Analyze tempo, four-beat bars, and per-bar vocal activity in `input`.
///
/// # Errors
///
/// Returns an error when models cannot be loaded or the audio cannot be decoded and analyzed.
pub fn analyze(input: &str, models: &str) -> Result<TrackAnalysis> {
    let models = Path::new(models);
    let mut analyzer = Analyzer::new(ModelPaths {
        mel_spectrogram: &models.join("mel_spectrogram.onnx"),
        beat_tracking: &models.join("beat_this_small.onnx"),
    })?;
    analyzer
        .analyze_file(Path::new(input))
        .map(TrackAnalysis::from)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reports_model_loading_failure() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let input = directory.path().join("missing.wav").display().to_string();
        let models = directory.path().join("models").display().to_string();
        let result = analyze(&input, &models);

        assert!(result.is_err());
        Ok(())
    }
}
