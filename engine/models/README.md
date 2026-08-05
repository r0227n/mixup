# Analysis models

The engine uses the MIT-licensed small model from
[`beat-this-rs`](https://github.com/danigb/beat-this-rs) for beat and downbeat tracking.
Model binaries are intentionally not committed to Git.

From the repository root, download and checksum-verify them with:

```sh
./engine/scripts/download-models.sh
```

By default, the script stores the models in `engine/models/`. An explicit destination may be
passed as its first argument.

| File | SHA-256 |
|---|---|
| `mel_spectrogram.onnx` | `fdd59e65c515331308e4c8841edf99972deca646bdf6197744c2a5b7755e3de9` |
| `beat_this_small.onnx` | `a5f8d39d989f31859454ba27afe61c5317ca95e4d9373e6853e5361b8937172f` |

## Vocal source-separation model

Per-bar vocal activity uses `HTDemucs-ORT 0.1.0`, downloaded and checksum-verified by
`stem-splitter-core` in the operating system's application cache. It is not committed here.

SHA-256: `09dc165512d8ef7480bcb2cacea9dda82d571f8dbf421d8c44a2ca5568bec729`

The model repository does not publish explicit license metadata. Do not redistribute the model
until its weight license has been confirmed with the publisher.
