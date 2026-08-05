//! Installation of the inference models required by the analyzer.

use std::{
    fs::{self, File},
    io::{Read, Write},
    path::{Path, PathBuf},
};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

const MODEL_BASE_URL: &str = "https://raw.githubusercontent.com/danigb/beat-this-rs/main/models";

/// An inference model that can be installed for [`crate::Analyzer`].
#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ModelName {
    /// Converts decoded audio into the mel spectrogram consumed by the beat model.
    MelSpectrogram,
    /// The small Beat This beat- and downbeat-tracking model.
    BeatThisSmall,
}

impl ModelName {
    /// All models required by the analyzer, in installation order.
    #[must_use]
    pub const fn all() -> [Self; 2] {
        [Self::MelSpectrogram, Self::BeatThisSmall]
    }

    /// File name used both by the remote model repository and the local analyzer.
    #[must_use]
    pub const fn file_name(self) -> &'static str {
        match self {
            Self::MelSpectrogram => "mel_spectrogram.onnx",
            Self::BeatThisSmall => "beat_this_small.onnx",
        }
    }

    const fn sha256(self) -> &'static str {
        match self {
            Self::MelSpectrogram => {
                "fdd59e65c515331308e4c8841edf99972deca646bdf6197744c2a5b7755e3de9"
            }
            Self::BeatThisSmall => {
                "a5f8d39d989f31859454ba27afe61c5317ca95e4d9373e6853e5361b8937172f"
            }
        }
    }
}

/// Download and checksum-verify one analyzer model into `destination`.
///
/// An existing complete model is only replaced after the new download passes verification.
///
/// # Errors
///
/// Returns an error when the directory cannot be created, the download fails, the model cannot be
/// written, or its SHA-256 checksum differs from the pinned checksum.
pub fn install_model(model: ModelName, destination: &Path) -> Result<PathBuf> {
    let url = format!("{MODEL_BASE_URL}/{}", model.file_name());
    let response = ureq::get(&url)
        .call()
        .with_context(|| format!("failed to download model from {url}"))?;
    install_from_reader(model, destination, response.into_body().as_reader())
}

fn install_from_reader(
    model: ModelName,
    destination: &Path,
    mut reader: impl Read,
) -> Result<PathBuf> {
    fs::create_dir_all(destination)
        .with_context(|| format!("failed to create model directory {}", destination.display()))?;

    let target = destination.join(model.file_name());
    let partial = destination.join(format!("{}.part", model.file_name()));
    let result = write_and_verify(&mut reader, &partial, model.sha256())
        .and_then(|()| fs::rename(&partial, &target).context("failed to finalize model file"));

    if result.is_err() {
        let _ = fs::remove_file(&partial);
    }
    result?;
    Ok(target)
}

fn write_and_verify(reader: &mut impl Read, partial: &Path, expected_sha256: &str) -> Result<()> {
    let mut file =
        File::create(partial).with_context(|| format!("failed to create {}", partial.display()))?;
    let mut hasher = Sha256::new();
    let mut buffer = vec![0_u8; 64 * 1024];

    loop {
        let count = reader
            .read(&mut buffer)
            .context("failed to read download")?;
        if count == 0 {
            break;
        }
        file.write_all(&buffer[..count])
            .context("failed to write model")?;
        hasher.update(&buffer[..count]);
    }
    file.flush().context("failed to flush model file")?;

    let actual = format!("{:x}", hasher.finalize());
    if actual != expected_sha256 {
        bail!("checksum mismatch: expected {expected_sha256}, got {actual}");
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io;

    #[test]
    fn checksum_failure_removes_partial_and_preserves_existing_model() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let target = directory.path().join(ModelName::MelSpectrogram.file_name());
        fs::write(&target, b"existing")?;

        let Err(error) = install_from_reader(
            ModelName::MelSpectrogram,
            directory.path(),
            io::Cursor::new(b"invalid model"),
        ) else {
            bail!("invalid checksum should fail");
        };

        assert!(error.to_string().contains("checksum mismatch"));
        assert_eq!(fs::read(target)?, b"existing");
        assert!(!directory.path().join("mel_spectrogram.onnx.part").exists());
        Ok(())
    }
}
