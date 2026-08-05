//! Shared domain types for the mixup engine.

use serde::{Deserialize, Serialize};

/// Complete, versioned bar-grid and per-bar vocal analysis of one audio track.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TrackAnalysis {
    /// Version of the analysis pipeline that produced this result.
    pub analyzer_version: String,
    /// Estimated tempo in beats per minute.
    pub tempo_bpm: f32,
    /// Four-beat bar timeline.
    pub bars: Vec<BarAnalysis>,
    /// Confidence in the global beat grid in the range `0.0..=1.0`.
    pub beat_confidence: f32,
    /// Non-fatal limitations or suspicious properties of the result.
    pub warnings: Vec<String>,
}

/// Analysis values for a single four-beat musical bar.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BarAnalysis {
    /// One-based bar number.
    pub number: usize,
    /// Start time in seconds.
    pub start_seconds: f32,
    /// End time in seconds, equal to the next bar's first beat.
    pub end_seconds: f32,
    /// Four beat positions in seconds within this bar.
    pub beats_seconds: Vec<f32>,
    /// Confidence in this bar's beat regularity in the range `0.0..=1.0`.
    pub beat_confidence: f32,
    /// Final vocal probability after temporal and phrase context in the range `0.0..=1.0`.
    pub vocal_probability: f32,
    /// Vocal probability derived directly from source-separated acoustic energy.
    pub acoustic_vocal_probability: f32,
    /// Coarse state derived from [`Self::vocal_probability`].
    pub vocal_state: VocalState,
}

/// Coarse per-bar vocal classification.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum VocalState {
    Vocal,
    Instrumental,
    Uncertain,
}
