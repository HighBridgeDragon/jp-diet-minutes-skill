# 導入方法

## CLI / パッケージマネージャ

対応クライアント: Claude Code, Cursor, GitHub Copilot CLI, Gemini CLI ほか

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

## デスクトップ / Web アプリ（zip 導入）

本 Release に添付の `jp-diet-minutes.zip` をダウンロードして導入します。

- **claude.ai / Claude Desktop**: Settings > Features から `jp-diet-minutes.zip` をアップロードします（アップロードできるのは本 Release 添付の zip のみです）。
- **ChatGPT Desktop / Goose Desktop ほか**: `~/.agents/skills/jp-diet-minutes`（またはプロジェクトの `.agents/skills/jp-diet-minutes`）に展開して配置します。

各クライアント別の詳細な導入手順や動作条件（ネットワーク設定・フェッチ環境等）は [インストールガイド (docs/install.md)](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/blob/main/docs/install.md) を参照してください。

## 主な動作条件

- **スクリプト・フェッチ実行**: 本スキルは `WebFetch`、`mcp-server-fetch`、または同梱の bash スクリプトから API を呼び出すため、各環境で適切なフェッチ/スクリプト実行手段が必要です。
- **`jq`（推奨）**: `list-meetings.sh` / `search-by-*.sh` のクライアント側ソート（`--sort`）に利用します。
- **ネットワークアクセス**: サンドボックスや実行環境から `kokkai.ndl.go.jp` へ到達できる必要があります。
- **Web 版 Gemini / Claude API**: シェル実行サンドボックスやネットワークアクセスを持たないため、原理的に動作しません（CLI やデスクトップ版をご利用ください）。

## 利用上の注意

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

## 出典

- [Agent Skills (agentskills.io)](https://agentskills.io)
- [Agent Skills (Anthropic)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [How to create custom Skills (Claude)](https://support.claude.com/en/articles/12512198-creating-custom-skills)
- [Build skills (OpenAI ChatGPT & Codex)](https://learn.chatgpt.com/docs/build-skills)
- [国会会議録検索システム API](https://kokkai.ndl.go.jp/api.html)
