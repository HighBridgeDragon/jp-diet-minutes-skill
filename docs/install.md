# インストールガイド / Installation Guide

本スキル（`jp-diet-minutes`）の各種 AI エージェントおよびクライアントへの導入手順と動作条件です。

## CLI / パッケージマネージャ

対応クライアント: Claude Code, Cursor, GitHub Copilot CLI, Gemini CLI ほか

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

上記コマンドでお使いのエージェント環境（プロジェクトの `.agents/skills` やグローバル設定など）に自動インストールされます。

## デスクトップ / Web アプリ

[Releases](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/releases) に添付されている `jp-diet-minutes.zip` をダウンロードして利用します。

### claude.ai / Claude Desktop

1. [Releases](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/releases) から `jp-diet-minutes.zip` をダウンロードします。
2. Settings > Features（または Capabilities）を開き、`jp-diet-minutes.zip` をアップロードします。

> [!IMPORTANT]
> アップロードできるのは **Releases に添付された `jp-diet-minutes.zip`** だけです。GitHub リポジトリ画面の **Code > Download ZIP** で取得した zip は、展開時のルートが `jp-diet-minutes-skill-main/` になり `SKILL.md` が直下に来ないため、skill として認識されません。

Custom Skill は面をまたいで同期しません。Claude Code に導入済みでも、claude.ai では別途アップロードが必要です。

#### 動作条件（claude.ai / Claude Desktop）

zip を導入しても、以下を満たさない環境では動作しません。

- **プラン**: Pro / Max / Team / Enterprise のいずれかであること。
- **コード実行**: 有効になっていること。本スキルは同梱の bash スクリプトから API を呼び出します。
- **`jq`**: 推奨です。`list-meetings.sh` / `search-by-*.sh` の `--sort`（クライアント側ソート）に使います。`jq` が無い環境では `--sort` を省略すると API 既定順（会議開催日降順）の raw JSON をそのまま返し、`--sort` を指定するとエラー終了します。
- **ネットワークアクセス**: サンドボックスから `kokkai.ndl.go.jp` へ到達できること。claude.ai のネットワーク設定でブロックされる場合は、許可ドメインに `kokkai.ndl.go.jp` を追加する必要があります（これを満たせない環境では Claude Code 経由をご利用ください）。
- **Claude API 経由**: API の Skills サンドボックスはネットワークアクセスを持たないため、原理的に国会会議録 API を呼び出せません。

### ChatGPT Desktop

1. [Releases](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/releases) から `jp-diet-minutes.zip` をダウンロードして展開します。
2. 展開したフォルダを、ユーザー共通スキルディレクトリ（`~/.agents/skills/jp-diet-minutes`）または作業プロジェクトの `.agents/skills/jp-diet-minutes` に配置します。
3. ChatGPT Desktop アプリのサイドバーにある「Skills」から本スキルが認識され、チャット上で利用可能になります。

### Goose Desktop

1. [Releases](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/releases) から `jp-diet-minutes.zip` をダウンロードして展開します。
2. `~/.agents/skills/jp-diet-minutes` に配置します。
3. Goose Desktop を起動すると自動認識されます。

### Google Gemini についての注意

- **Gemini CLI / Google Antigravity**: Agent Skills（`SKILL.md`）仕様に準拠しており、ローカル端末上で正常に動作します。
- **Web 版 Gemini（gemini.google.com）**: Gemini Web の Skills はプロンプト・指示ベースの拡張であり、サンドボックス内でのシェルスクリプト実行機構を持ちません。そのため、本スキルは Web 版 Gemini では動作しません。Gemini CLI または Google Antigravity をご利用ください。

## 実行環境と依存関係

HTTPS GET でアクセスできるフェッチツールが 1 つあれば動作します。

| エージェント | 推奨フェッチ手段 |
| --- | --- |
| Claude Code | 標準同梱の `WebFetch`（追加セットアップ不要） |
| Claude Desktop / Cursor / Cline / ChatGPT Desktop | [`mcp-server-fetch`](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch)（公式 MCP サーバ）またはシェル実行 |
| その他 | 任意の HTTP クライアント |

### Windows ユーザー向け注意（`mcp-server-fetch`）

`mcp-server-fetch` を Windows で使う場合、文字化け対策に `PYTHONIOENCODING=utf-8` の設定が必要です。設定例:

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "env": {
        "PYTHONIOENCODING": "utf-8"
      }
    }
  }
}
```

## 利用上の注意

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

## 出典

- [Agent Skills (agentskills.io)](https://agentskills.io)
- [Agent Skills Overview (Anthropic)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [How to create custom Skills (Claude Help)](https://support.claude.com/en/articles/12512198-creating-custom-skills)
- [Build skills (OpenAI ChatGPT & Codex)](https://learn.chatgpt.com/docs/build-skills)
- [国会会議録検索システム API 仕様](https://kokkai.ndl.go.jp/api.html)
