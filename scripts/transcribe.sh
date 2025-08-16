#!/usr/bin/env bash
set -euo pipefail
WAV="${1:-/work/data/audio.wav}"
MODEL="${2:-/work/models/ggml-medium.bin}"  # フルパス or symlink
OUTBASE="${3:-/work/data/subtitle}"

# 速度調整は -t (threads), -bs (beam-size) など
/opt/whisper.cpp/build/bin/whisper-cli \
  -m "$MODEL" \
  -f "$WAV" \
  -otxt -osrt -of "$OUTBASE" \
  -l auto \
  -t "$(nproc)" \
  -bs 5

echo "OK: ${OUTBASE}.srt / .txt"
