#!/usr/bin/env bash
set -euo pipefail
IN="${1:?input .m4a}"
OUT="${2:-audio.wav}"
cd /work/data
ffmpeg -y -i "$IN" -ar 16000 -ac 1 "$OUT"
echo "OK: data/$OUT"
