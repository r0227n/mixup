use std::path::Path;

use anyhow::{Context, Result, ensure};
use hound::{SampleFormat, WavReader};
use mixup_domain::BarAnalysis;
use stem_splitter_core::{SplitOptions, split_file};

const MODEL_NAME: &str = "htdemucs_ort_v1";
const EDGE_MARGIN_SECONDS: f32 = 0.08;

pub(crate) fn estimate_probabilities(
    path: &Path,
    bar_timeline: &[BarAnalysis],
) -> Result<Vec<f32>> {
    let output = tempfile::tempdir().context("failed to create temporary stem directory")?;
    let input = path.to_str().context("audio path is not valid UTF-8")?;
    let result = split_file(
        input,
        SplitOptions {
            output_dir: output.path().to_string_lossy().into_owned(),
            model_name: MODEL_NAME.to_owned(),
            manifest_url_override: None,
        },
    )
    .map_err(|error| anyhow::anyhow!(error.to_string()))?;

    let vocal_powers = bar_powers(Path::new(&result.vocals_path), bar_timeline)?;
    let mut total_powers = vocal_powers.clone();
    for stem_path in [&result.drums_path, &result.bass_path, &result.other_path] {
        let powers = bar_powers(Path::new(stem_path), bar_timeline)?;
        for (total, power) in total_powers.iter_mut().zip(powers) {
            *total += power;
        }
    }
    let ratios_db = vocal_powers
        .iter()
        .zip(total_powers)
        .map(|(vocal, total)| 10.0 * (*vocal / total.max(1.0e-12)).max(1.0e-8).log10())
        .collect::<Vec<_>>();
    Ok(cluster_probabilities(&ratios_db))
}

fn bar_powers(path: &Path, bar_timeline: &[BarAnalysis]) -> Result<Vec<f32>> {
    let audio = read_wav(path)?;
    Ok(bar_timeline
        .iter()
        .map(|bar| audio.power(bar.start_seconds, bar.end_seconds))
        .collect())
}

struct WavAudio {
    mono_samples: Vec<f32>,
    sample_rate: u32,
}

impl WavAudio {
    #[allow(
        clippy::cast_possible_truncation,
        clippy::cast_precision_loss,
        clippy::cast_sign_loss
    )]
    fn power(&self, start_seconds: f32, end_seconds: f32) -> f32 {
        let start_seconds = start_seconds + EDGE_MARGIN_SECONDS;
        let end_seconds = (end_seconds - EDGE_MARGIN_SECONDS).max(start_seconds);
        let start = (start_seconds.max(0.0) * self.sample_rate as f32) as usize;
        let end = (end_seconds.max(0.0) * self.sample_rate as f32) as usize;
        let slice = self
            .mono_samples
            .get(start.min(self.mono_samples.len())..end.min(self.mono_samples.len()))
            .unwrap_or_default();
        if slice.is_empty() {
            return 0.0;
        }
        #[allow(clippy::cast_precision_loss)]
        let mean_square =
            slice.iter().map(|sample| sample * sample).sum::<f32>() / slice.len() as f32;
        mean_square
    }
}

#[allow(clippy::cast_precision_loss)]
fn read_wav(path: &Path) -> Result<WavAudio> {
    let mut reader = WavReader::open(path)
        .with_context(|| format!("failed to open separated stem: {}", path.display()))?;
    let spec = reader.spec();
    let channels = usize::from(spec.channels);
    ensure!(channels > 0, "separated stem has no channels");
    let interleaved = match spec.sample_format {
        SampleFormat::Float => reader
            .samples::<f32>()
            .collect::<std::result::Result<Vec<_>, _>>()?,
        SampleFormat::Int => {
            let scale = 2.0_f32.powi(i32::from(spec.bits_per_sample) - 1);
            reader
                .samples::<i32>()
                .map(|sample| sample.map(|value| value as f32 / scale))
                .collect::<std::result::Result<Vec<_>, _>>()?
        }
    };
    let mono_samples = interleaved
        .chunks(channels)
        .map(|frame| frame.iter().sum::<f32>() / channels as f32)
        .collect();
    Ok(WavAudio {
        mono_samples,
        sample_rate: spec.sample_rate,
    })
}

fn cluster_probabilities(levels_db: &[f32]) -> Vec<f32> {
    if levels_db.is_empty() {
        return Vec::new();
    }
    let mut sorted = levels_db.to_vec();
    sorted.sort_by(f32::total_cmp);
    let mut quiet = sorted[sorted.len() / 4];
    let mut vocal = sorted[sorted.len() * 3 / 4];
    for _ in 0..20 {
        let midpoint = f32::midpoint(quiet, vocal);
        let (quiet_values, vocal_values): (Vec<_>, Vec<_>) = levels_db
            .iter()
            .copied()
            .partition(|level| *level < midpoint);
        if !quiet_values.is_empty() {
            quiet = mean(&quiet_values);
        }
        if !vocal_values.is_empty() {
            vocal = mean(&vocal_values);
        }
    }
    let midpoint = f32::midpoint(quiet, vocal);
    let scale = ((vocal - quiet).abs() / 6.0).max(0.75);
    levels_db
        .iter()
        .map(|level| 1.0 / (1.0 + (-(level - midpoint) / scale).exp()))
        .collect()
}

#[allow(clippy::cast_precision_loss)]
fn mean(values: &[f32]) -> f32 {
    values.iter().sum::<f32>() / values.len() as f32
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn separated_level_clusters_map_to_probability_extremes() {
        let probabilities =
            cluster_probabilities(&[-42.0, -40.0, -39.0, -38.0, -18.0, -17.0, -16.0, -15.0]);
        assert!(probabilities[..4].iter().all(|value| *value < 0.2));
        assert!(probabilities[4..].iter().all(|value| *value > 0.8));
    }
}
