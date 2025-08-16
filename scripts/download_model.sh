#!/usr/bin/env bash
set -euo pipefail
MODEL="${1:-medium}"   # tiny/base/small/medium/large-v3 など
mkdir -p models
cd /opt/whisper.cpp/models
./download-ggml-model.sh "$MODEL"
# 取得したモデルをワーク側にも見えるよう symlink
cd /work/models
if [ ! -e "ggml-${MODEL}.bin" ] && [ -e "/opt/whisper.cpp/models/ggml-${MODEL}.bin" ]; then
  ln -s /opt/whisper.cpp/models/ggml-${MODEL}.bin "ggml-${MODEL}.bin"
fi
echo "OK: models/ggml-${MODEL}.bin"
