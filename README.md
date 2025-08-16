# Local ASR Stack (yt-dlp + ffmpeg + whisper.cpp)

外付けSSD上に Docker で構築する、オフライン音声文字起こし用スタック。  
YouTube等から音声取得 → WAVへ変換 → whisper.cpp で文字起こし（SRT/TXT出力）。

---

## 構成

- **Dockerfile**: Ubuntu 24.04 / ffmpeg / yt-dlp(venv) / whisper.cpp(CPU)
- **docker-compose.yml**: ホストの外付けSSDを `/work` にマウント
- **/work**: 入出力用の共有フォルダ（音源や生成物はここに置く）

> Apple Silicon (M1/M2/M3/M4) 対応。GPUは使わずCPU版をビルド。

---

## 1. 前提

- macOS に Docker / Docker Compose がインストール済み
- 外付けSSDにこのプロジェクト一式を配置  
  例: `/Volumes/EXT/whisper-stack`

---

## 2. セットアップ

### 2.1 Dockerfile

プロジェクト直下に `Dockerfile` を配置してください。（例は別ファイルを参照）

### 2.2 docker-compose.yml（例）

```yaml
services:
  whisper:
    build:
      context: .
      dockerfile: Dockerfile
      # Apple Silicon を明示したい場合:
      # platform: linux/arm64
    container_name: whisper
    tty: true
    stdin_open: true
    working_dir: /work
    volumes:
      - /Volumes/EXT/whisper-stack:/work   # ←外付けSSDの実パスに変更
```

### 2.3 ビルド & 起動

```bash
# プロジェクト直下（外付けSSD）で
docker compose build --no-cache
docker compose up -d

# コンテナに入る
docker compose exec whisper bash
```

---

## 3. モデルのダウンロード

`whisper.cpp` 付属スクリプトで GGML モデルを取得します。

```bash
cd /opt/whisper.cpp
bash ./models/download-ggml-model.sh base      # 軽量版
# 他候補:
# bash ./models/download-ggml-model.sh small
# bash ./models/download-ggml-model.sh medium
# bash ./models/download-ggml-model.sh large-v2
```

- モデルは `/opt/whisper.cpp/models/ggml-*.bin` に保存されます。
- サイズ目安: base ~140MB / small ~460MB / medium ~1.5GB / large-v2 ~3GB

---

## 4. 音声ファイルの置き場所

- ホスト(mac) → 外付けSSDに置く  
- コンテナ内では `/work` にマウントされて見える  

例:  
ホスト `/Volumes/EXT/whisper-stack/input.mp4`  
コンテナ `/work/input.mp4`

---

## 5. ワークフロー

### 5.1 YouTubeから音声DL

利用可能フォーマット一覧:

```bash
yt-dlp -F "https://www.youtube.com/watch?v=XXXXXXXXXXX"
```

最高音質を自動抽出して WAV 保存:

```bash
yt-dlp -x --audio-format wav --audio-quality 0   -o "%(id)s.%(ext)s"   "https://www.youtube.com/watch?v=XXXXXXXXXXX"
```

### 5.2 ffmpegで整形（例）

```bash
ffmpeg -i input.m4a -ar 16000 -ac 1 input.wav
```

### 5.3 whisper.cppで文字起こし

```bash
/opt/whisper.cpp/main   -m /opt/whisper.cpp/models/ggml-base.bin   -f input.wav   -l auto   -otxt -osrt   -of output
```

- `-l auto`: 言語自動判定
- `-otxt -osrt`: TXT + SRT出力
- `-of output`: 出力ファイル接頭辞 → `output.txt` / `output.srt`

---

## 6. よく使うコマンド

```bash
# コンテナに入る / 出る
docker compose exec whisper bash
exit

# ログ確認
docker compose logs -f whisper

# コンテナ停止 / 削除
docker compose down
```

---

## 7. モデル選びの目安（CPU）

| モデル      | 速度 | 精度 | サイズ |
|-------------|------|------|--------|
| base        | ◎    | △    | ~140MB |
| small       | ○    | ○    | ~460MB |
| medium      | △    | ◎    | ~1.5GB |
| large-v2    | ×    | ★    | ~3GB   |

---

## 8. トラブルシューティング

- **PEP 668 エラー** → venv経由でインストール済み
- **Apple Siliconでビルド失敗** → `platform: linux/arm64` をcomposeに追加
- **YouTube SABR問題** → `--hls-prefer-ffmpeg` を併用
- **実行ファイル見つからない** → `/opt/whisper.cpp/main` をフルパス指定

---

## 9. ワンライナーまとめ

```bash
# 1) YouTube音声DL
yt-dlp -x --audio-format wav -o "%(id)s.%(ext)s" "https://www.youtube.com/watch?v=XXXXXXXXXXX"

# 2) WAV整形
ffmpeg -i XXXXXXXXXXX.wav -ar 16000 -ac 1 audio_16k.wav

# 3) 文字起こし
/opt/whisper.cpp/main   -m /opt/whisper.cpp/models/ggml-small.bin   -f audio_16k.wav   -l auto   -otxt -osrt -of transcript
```

---

## 10. クリーンアップ

```bash
# コンテナ停止/削除
docker compose down

# イメージ削除
docker rmi $(docker images -q)
```
# whisper-stack
