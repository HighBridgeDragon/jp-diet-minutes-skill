# インストールガイド / Installation Guide

本スキル（`jp-diet-minutes`）の各種 AI エージェントおよびクライアントへの導入手順と動作条件です。

## CLI / パッケージマネージャ

対応クライアント: Claude Code, Cursor, GitHub Copilot CLI, Gemini CLI ほか

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

上記コマンドでお使いのエージェント環境（プロジェクトの `.agents/skills` やグローバル設定など）に自動インストールされます。

## 各種クライアントへの導入手順（デスクトップ / Web アプリ）

Claude Desktop, claude.ai, OpenAI Codex, Goose, Gemini CLI 等への共通導入手順は、以下の共通ガイドをご確認ください。

👉 [**クライアント別共通インストールガイド (jp-skills-shared)**](https://github.com/HighBridgeDragon/jp-skills-shared/blob/main/docs/install-guide.md)

- Releases 添付の `jp-diet-minutes.zip` を用いた導入手順
- 各クライアントでの配置先および動作要件

## 本スキル固有の動作要件・必須設定

### claude.ai / Claude Desktop の許可ドメイン

claude.ai のコード実行環境から本スキルを利用する場合、以下のドメインへの外部アクセス許可が必要です：

- **許可ドメイン**: `kokkai.ndl.go.jp`

組織管理者による許可ドメインへの追加設定を行ってください（手順詳細は上記共通ガイドの「動作条件」節を参照）。

### 実行環境と依存関係

HTTPS GET でアクセスできるフェッチツールが 1 つあれば動作します。

| エージェント | 代表的なフェッチ手段の例（目安） |
| --- | --- |
| Claude Code | 標準同梱の `WebFetch`（追加セットアップ不要） |
| claude.ai / Claude Desktop | Custom Skills サンドボックスのコード実行（要コード実行および許可ドメイン追加） |
| GitHub Copilot CLI / Cursor / Cline / OpenAI Codex / Goose / Gemini CLI | [`mcp-server-fetch`](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch) またはエージェントのシェル実行機能 |
| その他 | 任意の HTTP クライアント |

#### `jq` コマンドについて（推奨）

スクリプト利用時、`list-meetings.sh` / `search-by-*.sh` の `--sort`（クライアント側ソート）に使います。`jq` が無い環境では `--sort` を省略すると API 既定順（会議開催日降順）の raw JSON をそのまま返し、`--sort` を指定するとエラー終了します。

### 利用上の注意（アクセス間隔）

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

## 出典

- [国会会議録検索システム API 仕様](https://kokkai.ndl.go.jp/api.html)
- クライアント仕様・規格の出典一覧は [共通インストールガイドの出典節](https://github.com/HighBridgeDragon/jp-skills-shared/blob/main/docs/install-guide.md#出典) を参照
