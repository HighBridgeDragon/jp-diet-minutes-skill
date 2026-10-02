# 導入方法

## Claude Code / Cursor / GitHub Copilot CLI ほか

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

## claude.ai / Claude Desktop

本 Release に添付の `jp-diet-minutes.zip` をダウンロードし、Settings > Features からアップロードします。

> [!IMPORTANT]
> アップロードするのは本 Release に添付の `jp-diet-minutes.zip` です。下の Assets にある **Source code (zip)** や、リポジトリ画面の **Code > Download ZIP** で取得した zip は展開時のトップが `jp-diet-minutes-skill-<ref>/` になり、`SKILL.md` が直下に来ないため skill として認識されません。

Custom Skill は面をまたいで同期しません。Claude Code に導入済みでも、claude.ai では別途アップロードが必要です。

## 動作条件

`jp-diet-minutes.zip` を導入しても、以下を満たさない環境では動作しません。

- **プラン**: Pro / Max / Team / Enterprise のいずれかであること。
- **コード実行**: 有効になっていること。本スキルは同梱の bash スクリプトから API を呼び出します。
- **`jq`**: 推奨です。`list-meetings.sh` / `search-by-*.sh` の `--sort`（クライアント側ソート）に使います。`jq` が無い環境では `--sort` を省略すると API 既定順（会議開催日降順）の raw JSON をそのまま返し、`--sort` を指定するとエラー終了します。
- **ネットワークアクセス**: Skill のサンドボックスから `kokkai.ndl.go.jp` へ到達できること。claude.ai のネットワークアクセス設定で通信がブロックされる場合は、許可ドメインに `kokkai.ndl.go.jp` を追加する必要があります（これを満たせない環境では Claude Code 経由をご利用ください）。
- **Claude API 経由では動作しません**: API の Skills サンドボックスはネットワークアクセスを持たないため、原理的に国会会議録 API を呼び出せません。

## 利用上の注意

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

## 出典

- [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [How to create custom Skills](https://support.claude.com/en/articles/12512198-creating-custom-skills)
- [Create and edit files with Claude](https://support.claude.com/en/articles/12111783-create-and-edit-files-with-claude)
- [国会会議録検索システム API](https://kokkai.ndl.go.jp/api.html)
