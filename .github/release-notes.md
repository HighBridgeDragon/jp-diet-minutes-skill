# 導入方法

## Claude Code / Cursor / GitHub Copilot CLI ほか

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

## claude.ai / Claude Desktop

本 Release に添付の `jp-diet-minutes.zip` をダウンロードし、Settings > Features からアップロードします。

## 動作条件

`jp-diet-minutes.zip` を導入しても、以下を満たさない環境では動作しません。

- **プラン**: Pro / Max / Team / Enterprise のいずれかであること。
- **コード実行**: 有効になっていること。本スキルは同梱の bash スクリプトから API を呼び出します。
- **ネットワークアクセス**: Skill のサンドボックスから `kokkai.ndl.go.jp` へ到達できること。claude.ai のネットワークアクセスは user / admin 設定により full / partial / none のいずれかになり、外部へ出られない設定では動作しません。
- **Claude API 経由では動作しません**: API の Skills サンドボックスはネットワークアクセスを持たないため、原理的に国会会議録 API を呼び出せません。

## 利用上の注意

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

Custom Skill は面をまたいで同期しません。Claude Code に導入済みでも、claude.ai では別途アップロードが必要です。

## 出典

- [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [How to create custom Skills](https://support.claude.com/en/articles/12512198-creating-custom-skills)
- [Create and edit files with Claude](https://support.claude.com/en/articles/12111783-create-and-edit-files-with-claude)
- [国会会議録検索システム API](https://kokkai.ndl.go.jp/api.html)
