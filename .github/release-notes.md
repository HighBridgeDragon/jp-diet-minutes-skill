# 導入方法

## CLI / パッケージマネージャ

対応クライアント: Claude Code, Cursor, GitHub Copilot CLI, Gemini CLI ほか

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

## デスクトップ / Web アプリ（zip 導入）

本 Release に添付の `jp-diet-minutes.zip` をダウンロードして導入します。

- **claude.ai / Claude Desktop**: Customize > Skills の「+」→「+ Create skill」→「Upload a skill」から `jp-diet-minutes.zip` をアップロードします（アップロードできるのは本 Release 添付の zip のみです。Source code (zip) や Code > Download ZIP の zip はリポジトリ全体を含み `SKILL.md` が直下に来ないため使えません。また、Custom Skill は claude.ai・Claude API・Claude Code の間で同期しません。claude.ai では個別にアップロードが必要です）。
- **OpenAI Codex**: `~/.agents/skills/`（またはプロジェクトの `.agents/skills/`）直下に展開後の `jp-diet-minutes` フォルダを配置します（配置後のパス: `~/.agents/skills/jp-diet-minutes/SKILL.md`）。二重フォルダ（`jp-diet-minutes/jp-diet-minutes/`）にならないようご注意ください。
- **Goose ほか対応クライアント**: 各ツールの設定手順に従って配置します（詳細は下記インストールガイドを参照）。

各クライアント別の詳細な導入手順や動作条件（ネットワーク設定・フェッチ環境等）は [インストールガイド (docs/install.md)](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/blob/main/docs/install.md) を参照してください。

## 主な動作条件

- **スクリプト・フェッチ実行**: 本スキルは `WebFetch`、`mcp-server-fetch`、または同梱の bash スクリプトから API を呼び出すため、各環境で適切なフェッチ/スクリプト実行手段が必要です。
- **`jq`（推奨）**: `list-meetings.sh` / `search-by-*.sh` のクライアント側ソート（`--sort`）に利用します（非対応時の挙動詳細は [インストールガイド](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/blob/main/docs/install.md#jq-コマンドについて推奨) を参照）。
- **ネットワークアクセス**: サンドボックスや実行環境から `kokkai.ndl.go.jp` へ到達できる必要があります。claude.ai の既定の許可ドメインには含まれないため、Team / Enterprise では組織オーナーが許可ドメインへ `kokkai.ndl.go.jp` を追加する必要があります。個人プラン（Free / Pro / Max）には追加の設定が無いため、Claude Code 経由をご利用ください。
- **claude.ai / Claude Desktop 利用時の要件**: コード実行の有効化が必要です（Free / Pro / Max / Team / Enterprise の各プランで利用できます）。
- **Web 版 Gemini / Claude API**: シェル実行サンドボックスやネットワークアクセスを持たないため、原理的に動作しません（CLI やデスクトップ版をご利用ください）。

## 利用上の注意

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

## 出典

- [Agent Skills (agentskills.io)](https://agentskills.io)
- [Agent Skills (Anthropic)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [How to create custom Skills (Claude)](https://support.claude.com/en/articles/12512198-creating-custom-skills)
- [Using Skills in Claude (Claude Help)](https://support.claude.com/en/articles/12512180-using-skills-in-claude)
- [Create and edit files with Claude (Claude Help)](https://support.claude.com/en/articles/12111783-create-and-edit-files-with-claude)
- [Build skills (OpenAI Codex)](https://developers.openai.com/codex/skills/)
- [Goose (Block)](https://block.github.io/goose/)
- [国会会議録検索システム API](https://kokkai.ndl.go.jp/api.html)
