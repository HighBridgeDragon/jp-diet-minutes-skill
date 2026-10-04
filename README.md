# jp-diet-minutes

[![skills.sh](https://skills.sh/b/HighBridgeDragon/jp-diet-minutes-skill)](https://skills.sh/HighBridgeDragon/jp-diet-minutes-skill)

**Search and retrieve Japanese National Diet (国会) meeting minutes from the official NDL Kokkai API.** An [Agent Skill](https://agentskills.io) for compatible AI agents (Claude, Codex, Cursor, GitHub Copilot, Goose, Gemini, and more). No authentication required.

国会発足（1947 年）以降の日本の国会議事録を国会会議録検索システム API 経由で調査するスキル（AI エージェント向け）。議員別の発言抽出、法案審議の追跡、会議全文取得、会派・期間・回次での絞り込みを AI エージェントから直接実行できます。

姉妹スキル: 法令本文の調査は [jp-law-skill](https://github.com/HighBridgeDragon/jp-law-skill) を併用すると、法令と国会審議を行き来する調査が可能になります。

## Install

### CLI / パッケージマネージャ

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

### デスクトップ / Web アプリ（zip 導入）

[Releases](https://github.com/HighBridgeDragon/jp-diet-minutes-skill/releases) から `jp-diet-minutes.zip` をダウンロードして導入します。

- **claude.ai / Claude Desktop**: Skills 設定からアップロード（コード実行の有効化および許可ドメインへの追加が必要。設定手順や条件は [docs/install.md](docs/install.md) を参照。追加できない環境では Claude Code 経由をご利用ください）
- **OpenAI Codex**: `~/.agents/skills/` 直下に展開後の `jp-diet-minutes` フォルダを配置

各クライアント別の詳細な導入手順や動作条件（ネットワーク設定・フェッチ環境等）は [docs/install.md](docs/install.md) を参照してください。なお、Web 版 Gemini（gemini.google.com）はスクリプト実行機構を持たないため非対応です（Gemini CLI / Google Antigravity 推奨）。

## What it does / 機能

インストール後、エージェントに以下のように依頼できます:

- "Show me speeches by Prime Minister Ishiba in October 2024" / 「2024 年 10 月の石破首相の発言を見せて」
- "Track Diet debates on the My Number Law" / 「マイナンバー法案の国会審議を追って」
- "Get the full transcript of the House of Representatives Budget Committee on 2024-03-04" / 「2024 年 3 月 4 日の衆議院予算委員会の議事録全文を取得して」
- "Find statements about ChatGPT in the Diet, chronologically" / 「国会での ChatGPT に関する発言を時系列で」
- "List all witness testimonies in 2024" / 「2024 年の参考人質疑を一覧で」

代表的なユースケース: 政治・政策研究、法案審議の経過追跡、議員別発言分析、報道・メディアでのファクトチェック、学術調査。

## Capabilities / 提供機能

| Capability | Endpoint | 用途 |
| --- | --- | --- |
| Speech-level search / 発言単位検索 | `GET /api/speech` | 議員名・キーワード・会派・期間で発言を抽出（最大 100 件/req） |
| Meeting list / 会議一覧 | `GET /api/meeting_list` | 会議メタのみの軽量索引（最大 100 件/req） |
| Meeting full transcript / 会議全文 | `GET /api/meeting` | 会議全発言の取得（最大 10 件/req、サイズ大） |

Supported agents / 対応エージェント: [Claude Code](https://docs.anthropic.com/en/docs/claude-code), GitHub Copilot (Copilot CLI), Cursor, Cline, claude.ai / Claude Desktop (Custom Skills), OpenAI Codex, Goose, Gemini CLI, Google Antigravity, and any other [Agent Skills](https://agentskills.io)-compatible runtime.

## 依存

HTTPS GET でアクセスできるフェッチツール（Claude Code の `WebFetch`、公式 MCP サーバ `mcp-server-fetch`、curl 等）が 1 つあれば動作します。各エージェントでの推奨フェッチ手段や Windows での設定例は [docs/install.md#実行環境と依存関係](docs/install.md#実行環境と依存関係) を参照してください。

## 国会会議録 API

- [公式仕様](https://kokkai.ndl.go.jp/api.html)
- [トップページ](https://kokkai.ndl.go.jp/)
- [国立国会図書館（NDL）](https://www.ndl.go.jp/)

### 対象範囲

- ✅ **国会会議録**（1947 年〜現在、国会発足以降）: 衆議院・参議院・両院・両院協議会の会議録
- ❌ **帝国議会会議録**（1890-11-29〜1947-03-31、第 1〜92 回帝国議会（貴族院を含む））: 別 API のため対象外。帝国議会期の議事録は姉妹スキル [jp-imperial-diet-minutes-skill](https://github.com/HighBridgeDragon/jp-imperial-diet-minutes-skill) を利用してください。

## 関連スキル

- [jp-imperial-diet-minutes-skill](https://github.com/HighBridgeDragon/jp-imperial-diet-minutes-skill) — 帝国議会会議録の検索・発言取得（NDL 帝国議会会議録検索システム API）
- [jp-law-skill](https://github.com/HighBridgeDragon/jp-law-skill) — 日本法令の検索・条文取得（e-Gov 法令 API V2）

## ライセンス

[MIT](LICENSE)
