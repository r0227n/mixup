#!/bin/sh
set -eu

script_directory="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
engine_directory="$(dirname -- "$script_directory")"
destination="${1:-$engine_directory/models}"
mkdir -p "$destination"

download() {
    name="$1"
    expected="$2"
    url="https://raw.githubusercontent.com/danigb/beat-this-rs/main/models/$name"
    target="$destination/$name"
    curl -fL "$url" -o "$target"
    actual="$(shasum -a 256 "$target" | awk '{print $1}')"
    if [ "$actual" != "$expected" ]; then
        rm -f "$target"
        echo "Checksum mismatch for $name" >&2
        exit 1
    fi
}

download "mel_spectrogram.onnx" "fdd59e65c515331308e4c8841edf99972deca646bdf6197744c2a5b7755e3de9"
download "beat_this_small.onnx" "a5f8d39d989f31859454ba27afe61c5317ca95e4d9373e6853e5361b8937172f"
