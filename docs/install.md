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
2. Customize > Skills を開き、「+」→「+ Create skill」→「Upload a skill」の順に選んで `jp-diet-minutes.zip` をアップロードします。

> [!IMPORTANT]
> アップロードできるのは **Releases に添付された `jp-diet-minutes.zip`** だけです。GitHub リポジトリ画面の **Code > Download ZIP** や Releases の **Source code (zip)** で取得した zip は、展開時のルートが `jp-diet-minutes-skill-<ref>/`（直下に `jp-diet-minutes/`）になり `SKILL.md` が直下に来ないため、skill として認識されません。

Custom Skill は claude.ai・Claude API・Claude Code の間で同期しません。Claude Code に導入済みでも、claude.ai では別途アップロードが必要です。

#### 動作条件（claude.ai / Claude Desktop）

zip を導入しても、以下を満たさない環境では動作しません。

- **プラン**: Free / Pro / Max / Team / Enterprise のいずれかであること（スキルのアップロード自体は全プランで可能ですが、国会会議録 API の利用には後述のとおり Team / Enterprise の組織オーナーによる許可ドメイン追加が必要です）。
- **コード実行**: 有効になっていること。本スキルは同梱の bash スクリプトから API を呼び出します。
- **ネットワークアクセス**: サンドボックスから `kokkai.ndl.go.jp` へ到達できること。claude.ai の既定の許可ドメインはパッケージマネージャー等に限られ、`kokkai.ndl.go.jp` は含まれません（公式ヘルプ [Create and edit files with Claude](https://support.claude.com/en/articles/12111783-create-and-edit-files-with-claude) の「Approved network domains」節）。Team / Enterprise では、組織オーナーが Organization settings > Capabilities で許可ドメインに `kokkai.ndl.go.jp` を追加する必要があります。個人プラン（Free / Pro / Max）には許可ドメインを追加する設定が無いため、Claude Code 経由をご利用ください。
- **Claude API 経由**: API の Skills サンドボックスはネットワークアクセスを持たないため、原理的に国会会議録 API を呼び出せません。

### OpenAI Codex

[OpenAI Codex のスキル仕様](https://developers.openai.com/codex/skills/) に準拠した配置手順です。

1. [Releases](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/releases) から `jp-diet-minutes.zip` をダウンロードして展開します。
2. 展開された `jp-diet-minutes` フォルダ（直下に `SKILL.md` があるフォルダ）を、ユーザー共通スキルディレクトリ（`~/.agents/skills/` 直下）またはプロジェクトの `.agents/skills/` 直下に配置します（配置後のパス: `~/.agents/skills/jp-diet-minutes/SKILL.md`。二重フォルダ `jp-diet-minutes/jp-diet-minutes/` にならないようご注意ください）。

> [!NOTE]
> 上記の配置パスは OpenAI Codex 公式ドキュメントに基づく仕様です。ChatGPT Desktop 等におけるローカルスキルの読み込み仕様や対応状況については、OpenAI の公式アナウンスをご確認ください。

### Goose

Block 主導のオープンソースエージェント Goose は [Agent Skills オープン標準](https://agentskills.io/clients) に対応しています。

1. [Releases](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/releases) から `jp-diet-minutes.zip` をダウンロードして展開します。
2. スキルの配置先や読み込み方法については、[Goose 公式ドキュメント](https://block.github.io/goose/) の指示に従ってください。なお、同梱スクリプトを実行できるシェル環境が必要です。

### Google Gemini についての注意

- **Gemini CLI / Google Antigravity**: Agent Skills（`SKILL.md`）仕様に準拠しており、ローカル端末上で正常に動作します。
- **Web 版 Gemini（gemini.google.com）**: Gemini Web の Skills はプロンプト・指示ベースの拡張であり、サンドボックス内でのシェルスクリプト実行機構を持ちません。そのため、本スキルは Web 版 Gemini では動作しません。Gemini CLI または Google Antigravity をご利用ください。

## 実行環境と依存関係

HTTPS GET でアクセスできるフェッチツールが 1 つあれば動作します。

| エージェント | 代表的なフェッチ手段の例（目安） |
| --- | --- |
| Claude Code | 標準同梱の `WebFetch`（追加セットアップ不要） |
| claude.ai / Claude Desktop | Custom Skills サンドボックスのコード実行（コード実行の有効化が必要。`kokkai.ndl.go.jp` は既定の許可ドメインに含まれないため Team / Enterprise の組織オーナーによる追加が必要） |
| GitHub Copilot CLI / Cursor / Cline / OpenAI Codex / Goose / Gemini CLI | [`mcp-server-fetch`](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch)（公式 MCP サーバ）またはエージェントのシェル実行機能 |
| その他 | 任意の HTTP クライアント |

### `jq` コマンドについて（推奨）

スクリプト利用時、`list-meetings.sh` / `search-by-*.sh` の `--sort`（クライアント側ソート）に使います。`jq` が無い環境では `--sort` を省略すると API 既定順（会議開催日降順）の raw JSON をそのまま返し、`--sort` を指定するとエラー終了します。

### Windows 環境での利用注意（mcp-server-fetch）

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

また、同梱の bash スクリプトを Windows 環境で直接実行する場合は、Git for Windows 付属の Git Bash や WSL 等の bash 実行環境をご利用ください。

## 利用上の注意

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

## 出典

- [Agent Skills (agentskills.io)](https://agentskills.io)
- [Agent Skills Overview (Anthropic)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [How to create custom Skills (Claude Help)](https://support.claude.com/en/articles/12512198-creating-custom-skills)
- [Using Skills in Claude (Claude Help)](https://support.claude.com/en/articles/12512180-using-skills-in-claude)
- [Create and edit files with Claude (Claude Help)](https://support.claude.com/en/articles/12111783-create-and-edit-files-with-claude)
- [Build skills (OpenAI Codex)](https://developers.openai.com/codex/skills/)
- [Goose (Block)](https://block.github.io/goose/)
- [国会会議録検索システム API 仕様](https://kokkai.ndl.go.jp/api.html)
