---
name: kokkai-minutes-recipes-index
description: 国会会議録検索システム API V2 wrapper scripts では covers できない複合パターンのスニペット集（索引）
---

# 国会会議録検索 recipe 集

`jp-diet-minutes/scripts/` の wrapper では covers できない複合パターンのスニペット集。各 recipe は wrapper を呼び出す前提で書かれている。

実行環境は Claude Code の Bash / PowerShell tool を想定。レート制限の都合上、API 呼び出しは 2〜3 秒以上の間隔を空けること。

## recipe 一覧

- [meeting-speaker-keyword-filter.md](recipes/meeting-speaker-keyword-filter.md): 会議内の議員 × キーワード絞り込み。`speech` エンドポイントの `any` 検索で大量ヒット時の二次絞り込みや、過去質疑の引用元特定に有用
- [oldest-speech-by-speaker.md](recipes/oldest-speech-by-speaker.md): 議員の特定期間における最古発言の特定。降順固定の API 仕様下で `from`/`until` を狭めて最古を探すパターン
- [qa-pair-extraction.md](recipes/qa-pair-extraction.md): 同一会議内の質問者 → 答弁者ペア抽出。`speakerPosition` を識別子に Q&A 構造を可視化

## 関連リソース

- [SKILL.md](../SKILL.md): skill 全体の使い方
- [api-reference.md](api-reference.md): API 仕様（ソート順、ページネーション等）
- [parameters.md](parameters.md): パラメータ詳細
- [response-format.md](response-format.md): レスポンス構造
- [scripts/README.md](../scripts/README.md): wrapper script 一覧
