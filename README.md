# jp-diet-minutes

[![skills.sh](https://skills.sh/b/HighBridgeDragon/jp-diet-minutes-skill)](https://skills.sh/HighBridgeDragon/jp-diet-minutes-skill)

**Search and retrieve Japanese National Diet (国会) meeting minutes from the official NDL Kokkai API.** An [Agent Skill](https://agentskills.io) for Claude Code, Cursor, GitHub Copilot, and other compatible AI agents. No authentication required.

戦後の日本の国会議事録を国会会議録検索システム API 経由で調査するスキル（Claude Code / AI Agent 向け）。議員別の発言抽出、法案審議の追跡、会議全文取得、会派・期間・回次での絞り込みを AI エージェントから直接実行できます。

姉妹スキル: 法令本文の調査は [jp-law-skill](https://github.com/HighBridgeDragon/jp-law-skill) を併用すると、法令と国会審議を行き来する調査が可能になります。

## Install

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

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
|---|---|---|
| Speech-level search / 発言単位検索 | `GET /api/speech` | 議員名・キーワード・会派・期間で発言を抽出（最大 100 件/req）|
| Meeting list / 会議一覧 | `GET /api/meeting_list` | 会議メタのみの軽量索引（最大 100 件/req）|
| Meeting full transcript / 会議全文 | `GET /api/meeting` | 会議全発言の取得（最大 10 件/req、サイズ大）|

Supported agents / 対応エージェント: [Claude Code](https://docs.anthropic.com/en/docs/claude-code), GitHub Copilot (Copilot CLI), Cursor, Cline, Claude Desktop, and any other [Agent Skills](https://agentskills.io)-compatible runtime.

## 依存

HTTPS GET でアクセスできるフェッチツールが 1 つあれば動作します。代表的な構成:

| エージェント | 推奨フェッチ手段 |
|---|---|
| Claude Code | 標準同梱の `WebFetch`（追加セットアップ不要） |
| Claude Desktop / Cursor / Cline | [`mcp-server-fetch`](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch)（公式 MCP サーバ）|
| その他 | 任意の HTTP クライアント |

### Windows ユーザー向け注意

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

## 国会会議録 API

- [公式仕様](https://kokkai.ndl.go.jp/api.html)
- [トップページ](https://kokkai.ndl.go.jp/)
- [国立国会図書館（NDL）](https://www.ndl.go.jp/)

### 対象範囲

- ✅ **戦後の国会**（1947 年〜現在）: 衆議院・参議院・両院・両院協議会の会議録
- ❌ **帝国議会会議録**（1890 年〜1947 年）: 別 API（[帝国議会会議録検索システム](https://teikokugikai-i.ndl.go.jp/)）のため対象外

戦前の議事録が必要な場合は帝国議会会議録検索システムを直接利用してください。

## 関連スキル

- [jp-law-skill](https://github.com/HighBridgeDragon/jp-law-skill) — 日本法令の検索・条文取得（e-Gov 法令 API V2）

## ライセンス

[MIT](LICENSE)
