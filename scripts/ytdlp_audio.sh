#!/usr/bin/env bash
set -euo pipefail
URL="${1:?YouTube URL required}"
OUT="${2:-audio.m4a}"
cd /work/data
# SABR回避のためHLS優先、フォーマットは音声または360p混在の18/140等を柔軟に
yt-dlp -N 8 --hls-prefer-ffmpeg -f "bestaudio[ext=m4a]/140/18" -o "$OUT" "$URL"
echo "OK: data/$OUT"
