use anyhow::{Result, ensure};
use mixup_domain::{BarAnalysis, VocalState};

const BEATS_PER_BAR: usize = 4;
const DOWNBEAT_TOLERANCE_SECONDS: f32 = 0.075;
const VOCAL_THRESHOLD: f32 = 0.65;
const STATE_TRANSITION_PENALTY: f32 = 3.0;
const BARS_PER_PHRASE: usize = 4;
const INSTRUMENTAL_CORE_MEAN: f32 = 0.15;
const INSTRUMENTAL_NEIGHBOR_MEAN: f32 = 0.90;
const CONTEXTUAL_INSTRUMENTAL_SCALE: f32 = 0.35;

pub(crate) fn build_bars(
    beats: &[f32],
    downbeats: &[f32],
    global_confidence: f32,
) -> Result<Vec<BarAnalysis>> {
    ensure!(
        beats.len() > BEATS_PER_BAR,
        "fewer than five beats were detected"
    );
    let phase = best_downbeat_phase(beats, downbeats);
    let starts = (phase..beats.len())
        .step_by(BEATS_PER_BAR)
        .collect::<Vec<_>>();
    let mut bars = Vec::with_capacity(starts.len().saturating_sub(1));

    for (number, pair) in starts.windows(2).enumerate() {
        let start_index = pair[0];
        let end_index = pair[1];
        let bar_beats = beats[start_index..end_index].to_vec();
        let regularity = interval_regularity(&bar_beats);
        bars.push(BarAnalysis {
            number: number + 1,
            start_seconds: beats[start_index],
            end_seconds: beats[end_index],
            beats_seconds: bar_beats,
            beat_confidence: (global_confidence * regularity).clamp(0.0, 1.0),
            vocal_probability: 0.5,
            acoustic_vocal_probability: 0.5,
            vocal_state: VocalState::Uncertain,
        });
    }

    ensure!(!bars.is_empty(), "no complete four-beat bars were detected");
    Ok(bars)
}

fn best_downbeat_phase(beats: &[f32], downbeats: &[f32]) -> usize {
    let mut scores = [0.0_f32; BEATS_PER_BAR];
    for downbeat in downbeats {
        if let Some((index, distance)) = nearest_beat(beats, *downbeat)
            && distance <= DOWNBEAT_TOLERANCE_SECONDS
        {
            let weight = 1.0 - distance / DOWNBEAT_TOLERANCE_SECONDS;
            scores[index % BEATS_PER_BAR] += weight;
        }
    }
    scores
        .iter()
        .enumerate()
        .max_by(|left, right| left.1.total_cmp(right.1))
        .map_or(0, |(phase, _)| phase)
}

fn nearest_beat(beats: &[f32], target: f32) -> Option<(usize, f32)> {
    let insertion = beats.partition_point(|beat| *beat < target);
    [insertion.saturating_sub(1), insertion]
        .into_iter()
        .filter(|index| *index < beats.len())
        .map(|index| (index, (beats[index] - target).abs()))
        .min_by(|left, right| left.1.total_cmp(&right.1))
}

fn interval_regularity(beats: &[f32]) -> f32 {
    if beats.len() < 3 {
        return 0.0;
    }
    let intervals = beats
        .windows(2)
        .map(|pair| pair[1] - pair[0])
        .collect::<Vec<_>>();
    let mean = intervals.iter().sum::<f32>() / len_as_f32(intervals.len());
    let maximum_deviation = intervals
        .iter()
        .map(|interval| (interval - mean).abs())
        .fold(0.0, f32::max);
    (1.0 - maximum_deviation / mean.max(0.001)).clamp(0.0, 1.0)
}

pub(crate) fn global_beat_confidence(beats: &[f32]) -> f32 {
    if beats.len() < 3 {
        return 0.0;
    }
    let intervals = beats
        .windows(2)
        .map(|pair| pair[1] - pair[0])
        .filter(|interval| *interval > 0.0)
        .collect::<Vec<_>>();
    let mean = intervals.iter().sum::<f32>() / len_as_f32(intervals.len());
    let variance = intervals
        .iter()
        .map(|interval| (interval - mean).powi(2))
        .sum::<f32>()
        / len_as_f32(intervals.len());
    (1.0 - variance.sqrt() / mean.max(0.001)).clamp(0.0, 1.0)
}

pub(crate) fn apply_vocal_probabilities(bars: &mut [BarAnalysis], probabilities: &[f32]) {
    let states = stable_vocal_states(probabilities);
    for ((bar, probability), is_vocal) in bars
        .iter_mut()
        .zip(probabilities.iter().copied())
        .zip(states)
    {
        let acoustic_probability = probability.clamp(0.0, 1.0);
        let contextual_probability = if is_vocal {
            acoustic_probability
        } else {
            acoustic_probability * CONTEXTUAL_INSTRUMENTAL_SCALE
        };
        bar.acoustic_vocal_probability = acoustic_probability;
        bar.vocal_probability = contextual_probability;
        bar.vocal_state = if contextual_probability <= 1.0 - VOCAL_THRESHOLD {
            VocalState::Instrumental
        } else if contextual_probability >= VOCAL_THRESHOLD {
            VocalState::Vocal
        } else {
            VocalState::Uncertain
        };
    }
}

fn stable_vocal_states(probabilities: &[f32]) -> Vec<bool> {
    if probabilities.is_empty() {
        return Vec::new();
    }
    let mut scores = vec![[f32::NEG_INFINITY; 2]; probabilities.len()];
    let mut previous = vec![[0_usize; 2]; probabilities.len()];
    scores[0] = emission_scores(probabilities[0]);

    for index in 1..probabilities.len() {
        let emissions = emission_scores(probabilities[index]);
        for state in 0..2 {
            let candidates = [
                scores[index - 1][0]
                    - if state == 0 {
                        0.0
                    } else {
                        STATE_TRANSITION_PENALTY
                    },
                scores[index - 1][1]
                    - if state == 1 {
                        0.0
                    } else {
                        STATE_TRANSITION_PENALTY
                    },
            ];
            let best_previous = usize::from(candidates[1] > candidates[0]);
            previous[index][state] = best_previous;
            scores[index][state] = candidates[best_previous] + emissions[state];
        }
    }

    let last = probabilities.len() - 1;
    let mut state = usize::from(scores[last][1] > scores[last][0]);
    let mut result = vec![false; probabilities.len()];
    for index in (0..probabilities.len()).rev() {
        result[index] = state == 1;
        if index > 0 {
            state = previous[index][state];
        }
    }
    for (state, phrase_is_instrumental) in result
        .iter_mut()
        .zip(instrumental_phrase_mask(probabilities))
    {
        if phrase_is_instrumental {
            *state = false;
        }
    }
    result
}

fn instrumental_phrase_mask(probabilities: &[f32]) -> Vec<bool> {
    let mut mask = vec![false; probabilities.len()];
    if probabilities.len() < BARS_PER_PHRASE {
        return mask;
    }
    let phase = best_phrase_phase(probabilities);
    let starts = (phase..probabilities.len().saturating_sub(BARS_PER_PHRASE - 1))
        .step_by(BARS_PER_PHRASE)
        .collect::<Vec<_>>();
    let means = starts
        .iter()
        .map(|start| mean(&probabilities[*start..*start + BARS_PER_PHRASE]))
        .collect::<Vec<_>>();

    for core in means
        .iter()
        .enumerate()
        .filter_map(|(index, value)| (*value <= INSTRUMENTAL_CORE_MEAN).then_some(index))
    {
        let mut first = core;
        while first > 0 && means[first - 1] <= INSTRUMENTAL_NEIGHBOR_MEAN {
            first -= 1;
        }
        let mut last = core;
        while last + 1 < means.len() && means[last + 1] <= INSTRUMENTAL_NEIGHBOR_MEAN {
            last += 1;
        }
        for start in &starts[first..=last] {
            mask[*start..*start + BARS_PER_PHRASE].fill(true);
        }
    }
    mask
}

fn best_phrase_phase(probabilities: &[f32]) -> usize {
    (0..BARS_PER_PHRASE)
        .min_by(|left, right| {
            minimum_phrase_mean(probabilities, *left)
                .total_cmp(&minimum_phrase_mean(probabilities, *right))
        })
        .unwrap_or(0)
}

fn minimum_phrase_mean(probabilities: &[f32], phase: usize) -> f32 {
    (phase..probabilities.len().saturating_sub(BARS_PER_PHRASE - 1))
        .step_by(BARS_PER_PHRASE)
        .map(|start| mean(&probabilities[start..start + BARS_PER_PHRASE]))
        .min_by(f32::total_cmp)
        .unwrap_or(1.0)
}

fn mean(values: &[f32]) -> f32 {
    values.iter().sum::<f32>() / len_as_f32(values.len())
}

fn emission_scores(probability: f32) -> [f32; 2] {
    let probability = probability.clamp(0.001, 0.999);
    [(1.0 - probability).ln(), probability.ln()]
}

#[allow(clippy::cast_precision_loss)]
fn len_as_f32(length: usize) -> f32 {
    length as f32
}

#[cfg(test)]
#[allow(clippy::cast_precision_loss, clippy::expect_used, clippy::float_cmp)]
mod tests {
    use super::*;

    #[test]
    fn malformed_downbeats_cannot_create_short_bars() {
        let beats = (0..13).map(|index| index as f32 * 0.5).collect::<Vec<_>>();
        let downbeats = vec![0.0, 0.5, 1.0, 2.0, 4.0, 6.0];
        let bars = build_bars(&beats, &downbeats, 1.0).expect("valid beat grid");
        assert_eq!(bars.len(), 3);
        assert!(bars.iter().all(|bar| bar.beats_seconds.len() == 4));
        assert_eq!(bars[0].start_seconds, 0.0);
        assert_eq!(bars[0].end_seconds, 2.0);
    }

    #[test]
    fn phase_uses_consistent_downbeats_instead_of_first_event() {
        let beats = (0..14).map(|index| index as f32 * 0.5).collect::<Vec<_>>();
        let downbeats = vec![0.0, 0.5, 2.5, 4.5, 6.5];
        let bars = build_bars(&beats, &downbeats, 1.0).expect("valid beat grid");
        assert_eq!(bars[0].start_seconds, 0.5);
    }

    #[test]
    fn temporal_model_bridges_short_vocal_leak_inside_instrumental_section() {
        let probabilities = [
            0.98, 0.98, 0.05, 0.84, 0.04, 0.03, 0.8, 0.59, 0.07, 0.98, 0.98,
        ];
        let states = stable_vocal_states(&probabilities);
        assert!(states[..2].iter().all(|state| *state));
        assert!(states[2..9].iter().all(|state| !state));
        assert!(states[9..].iter().all(|state| *state));
    }

    #[test]
    fn phrase_mask_expands_from_strong_four_bar_core() {
        let probabilities = [
            0.98, 0.98, 0.98, 0.98, 0.8, 0.8, 0.8, 0.8, 0.05, 0.05, 0.05, 0.05, 0.98, 0.98, 0.98,
            0.98,
        ];
        let mask = instrumental_phrase_mask(&probabilities);
        assert!(mask[4..12].iter().all(|value| *value));
        assert!(mask[..4].iter().all(|value| !value));
        assert!(mask[12..].iter().all(|value| !value));
    }
}
