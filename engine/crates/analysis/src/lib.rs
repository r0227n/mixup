//! Tempo, beat, four-beat bar-grid, and per-bar vocal analysis for music tracks.

mod bars;
mod vocal;

use std::path::Path;

use anyhow::{Context, Result};
use beat_this::{BeatThis, RtenRuntime, calculate_bpm};
use mixup_domain::TrackAnalysis;

use crate::bars::{build_bars, global_beat_confidence};

/// Paths to the beat-tracking inference models required by [`Analyzer`].
#[derive(Debug, Clone, Copy)]
pub struct ModelPaths<'a> {
    pub mel_spectrogram: &'a Path,
    pub beat_tracking: &'a Path,
}

/// Reusable beat and bar analyzer. Construct once and use it for multiple tracks.
pub struct Analyzer {
    beat_tracker: BeatThis<<RtenRuntime as beat_this::Runtime>::Model>,
}

impl Analyzer {
    /// Load the models used for beat and downbeat inference.
    ///
    /// # Errors
    ///
    /// Returns an error when either model cannot be read or parsed by the inference runtime.
    pub fn new(paths: ModelPaths<'_>) -> Result<Self> {
        let beat_tracker = BeatThis::new(&RtenRuntime, paths.mel_spectrogram, paths.beat_tracking)
            .context("failed to load beat-tracking models")?;
        Ok(Self { beat_tracker })
    }

    /// Analyze tempo, beats, and four-beat bars in an MP3, WAV, FLAC, or OGG file.
    ///
    /// Bars are reconstructed from groups of four stable beats. Downbeats select the grid phase
    /// but cannot create short, malformed bars.
    ///
    /// # Errors
    ///
    /// Returns an error when decoding or beat inference fails, or when too few beats are found to
    /// form a complete bar.
    pub fn analyze_file(&mut self, path: &Path) -> Result<TrackAnalysis> {
        let raw = self
            .beat_tracker
            .analyze_file(path)
            .with_context(|| format!("failed to analyze beats: {}", path.display()))?;
        let tempo_bpm = calculate_bpm(&raw).unwrap_or(0.0);
        let beat_confidence = global_beat_confidence(&raw.beats);
        let mut bars = build_bars(&raw.beats, &raw.downbeats, beat_confidence)?;
        let probabilities = vocal::estimate_probabilities(path, &bars)
            .with_context(|| format!("failed to analyze vocal stem: {}", path.display()))?;
        bars::apply_vocal_probabilities(&mut bars, &probabilities);
        let mut warnings = vec![
            "Vocal activity is inferred from source separation and remains a recommendation."
                .to_owned(),
            "Vocal probability includes temporal and four-bar phrase context; acoustic_vocal_probability retains the pre-context value."
                .to_owned(),
        ];
        if beat_confidence < 0.8 {
            warnings.push("Beat-grid confidence is low; bar boundaries need review.".to_owned());
        }

        Ok(TrackAnalysis {
            analyzer_version: env!("CARGO_PKG_VERSION").to_owned(),
            tempo_bpm,
            bars,
            beat_confidence,
            warnings,
        })
    }
}
