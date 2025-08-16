# Ubuntu 24.04（amd64/arm64 両対応）
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 基本ツール & ffmpeg & venv（pipはvenvで使う）
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git build-essential cmake pkg-config \
      python3 python3-pip python3-venv ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# ---- yt-dlp はシステムPythonに直書きせず venv に入れる（PEP 668 回避）----
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir -U pip yt-dlp \
 && ln -s /opt/venv/bin/yt-dlp /usr/local/bin/yt-dlp

# ---- whisper.cpp ビルド（CPU版）----
WORKDIR /opt
RUN git clone --depth=1 https://github.com/ggerganov/whisper.cpp.git \
 && cd whisper.cpp \
 && make -j"$(nproc)"

# 実行用パス
ENV PATH="/opt/whisper.cpp/build/bin:${PATH}"

# 作業ディレクトリ（ホストの外付けSSDをマウント予定の場所）
WORKDIR /work

# 便利スクリプト置き場
RUN mkdir -p /work/scripts

# デフォルトはシェル
CMD ["bash"]
