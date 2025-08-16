# whisper-stack

ローカルで**音声 → テキスト**をすばやく回すための最小スタック。  
Whisper（公式/CLI）を中心に、録音・変換・文字起こし・（任意で）要約までを一気通貫で実行できます。  
※ 本READMEは汎用的な構成です。プロジェクト構成に合わせて、そのまま使うか必要に応じて調整してください。

---

## 主な特徴

- **ローカル実行**（インターネット不要 / モデルはローカルにキャッシュ）
- **Whisper公式CLI**ベース（`openai/whisper`）
- **日本語対応**（自動 or 指定）
- **複数出力**：`txt` / `srt` / `vtt` / `json`
- **長時間音源対応**：`ffmpeg` で自動変換
- **任意機能**：
  - `yt-dlp` 連携で権利のある音源を取得して文字起こし
  - LLMによる要約/見出し生成（OpenAI/Claude/ローカルLLMなどお好みで）

---

## 依存関係

- Python **3.10+**
- `ffmpeg`（音声/動画の取り扱いに必要）
- pip パッケージ
  ```bash
  pip install -U openai-whisper faster-whisper torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
  pip install yt-dlp ffmpeg-python pydub rich
  ```
  > CUDA を使わない場合は PyTorch のインストール行を省略してOKです。

> **補足**: 公式Whisperは `whisper` コマンドが入ります。高速化したい場合は `faster-whisper` の導入/置き換えをご検討ください（コマンドは別実装になります）。

---

## クイックスタート

### 1) 手元の音声ファイルを文字起こし
```bash
# 例: sample.m4a を日本語として transcribe、各種フォーマットで出力
whisper sample.m4a \
  --model small \
  --language ja \
  --task transcribe \
  --output_format txt,srt,vtt,json \
  --output_dir outputs
```

### 2) 言語自動検出 / 翻訳モード
```bash
# 言語自動検出（--language を外す）
whisper sample.m4a --model medium --task transcribe --output_dir outputs

# 日本語→英語に翻訳（字幕作成に便利）
whisper sample.m4a --model medium --task translate --output_format srt --output_dir outputs
```

### 3) 動画ファイル（mp4, mov, mkv など）でもOK
```bash
# ffmpeg が音声を抽出して処理されます
whisper meeting.mp4 --model small --language ja --task transcribe --output_dir outputs
```

### 4) （任意）権利のあるコンテンツを `yt-dlp` で取得してから文字起こし
> **重要**: YouTube等のコンテンツは **権利者の許可があるものに限り** 取得してください。  
> 各プラットフォームの**利用規約**にも必ず従ってください。

```bash
# 例: 自分のチャンネルの自作動画（または権利者が明示許可）の音声のみを取得
yt-dlp -x --audio-format m4a -o "inputs/%(title)s.%(ext)s" "https://www.youtube.com/watch?v=VIDEO_ID"

# 取得したファイルを文字起こし
whisper "inputs/タイトル.m4a" --model small --language ja --output_dir outputs
```

---

## 要約・見出しの自動生成（任意）

文字起こし結果 (`outputs/*.txt` など) を LLM で要約する簡易スクリプト例（擬似コード）：
```python
# summarize.py (例)
from pathlib import Path

text = Path("outputs/sample.txt").read_text(encoding="utf-8")

# ここにお好みのLLMを呼び出す処理を書く（OpenAI/Claude/ローカルLLM等）
# prompt: 会議の要点/決定事項/アクションを3〜5点で箇条書きに、など

print("## Summary")
print("- ...")
```

> APIキーの扱いに注意（環境変数で管理: `OPENAI_API_KEY` など）。  
> 機密情報を含むデータは、ローカルLLM（例: llama.cpp、Ollama）利用も検討してください。

---

## ディレクトリ構成（例）

```
whisper-stack/
├─ inputs/        # 音源を入れる（m4a, mp3, wav, mp4...）
├─ outputs/       # 文字起こし結果（txt/srt/vtt/jsonなど）
├─ scripts/       # 任意の補助スクリプト（要約、分割、整形など）
└─ README.md
```

---

## よくあるTips

- **精度を上げたい**: `--model base → small → medium → large` と上げる（計算コストも増）
- **処理が重い**: `--model small`以下にする / GPU（CUDA）を使う / `faster-whisper`を検討
- **長時間ファイル**: まず `ffmpeg -i in.mp3 -ar 16000 -ac 1 out.wav` などで軽量化
- **字幕の時間ずれ**: `--word_timestamps True`（実験的）や、外部ツールで微調整
- **日本語表記ゆれ**: 校正・整形は別ステップ（句読点補正、固有表現統一）で後処理

---

## 法令・規約・利用上の注意（重要）

- 本スタックは**自分の音声データ**（会議録音・講義録音・自作コンテンツなど）の文字起こしを主用途としています。  
- YouTube等の第三者コンテンツを**権利者の許可なく**ダウンロード/文字起こし/配布することは、
  **著作権侵害**や各サービスの**利用規約違反**となる可能性があります。  
- `yt-dlp` の使用可否は**各プラットフォームの規約**に従ってください。無断ダウンロードは禁止されている場合があります。
- 機密情報・個人情報を含む音声の取り扱いには十分ご注意ください。**プライバシー法令**（個人情報保護法、GDPR等）を順守し、
  LLM要約等で外部APIを使う場合は**送信内容と保存ポリシー**を必ず確認してください。
- 本ソフトウェアの利用により生じたいかなる損害についても、作者は責任を負いません。**自己責任**でご利用ください。

---

## ライセンス

このリポジトリのライセンスに従います（`LICENSE` を参照）。

---

## 謝辞 / Credits

- [OpenAI Whisper](https://github.com/openai/whisper)
- [faster-whisper](https://github.com/guillaumekln/faster-whisper)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [ffmpeg](https://ffmpeg.org/)

---

## 更新履歴（テンプレ）

- 2025-08-16: 初版のREADMEを整備（合法的な利用ガイド/注意事項を追記）
