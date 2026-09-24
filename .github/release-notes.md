# 導入方法

## Claude Code / Cursor / GitHub Copilot CLI ほか

```bash
npx skills add HighBridgeDragon/jp-diet-minutes-skill
```

## claude.ai / Claude Desktop

本 Release に添付の `jp-diet-minutes.zip` をダウンロードし、Settings > Features からアップロードします。

Custom Skill は面をまたいで同期しません。Claude Code に導入済みでも、claude.ai では別途アップロードが必要です。

## 動作条件

`jp-diet-minutes.zip` を導入しても、以下を満たさない環境では動作しません。

- **プラン**: Pro / Max / Team / Enterprise のいずれかであること。
- **コード実行**: 有効になっていること。本スキルは同梱の bash スクリプトから API を呼び出します。
- **`jq`**: 必須です。`list-meetings.sh` / `search-by-*.sh` はクライアント側ソートに `jq` を使い、無い場合はエラー終了します。
- **ネットワークアクセス**: Skill のサンドボックスから `kokkai.ndl.go.jp` へ到達できること。claude.ai のネットワークアクセスは user / admin 設定により full / partial / none のいずれかになります。
- **Claude API 経由では動作しません**: API の Skills サンドボックスはネットワークアクセスを持たないため、原理的に国会会議録 API を呼び出せません。

## 実測結果（2026-09-24）

zip のアップロードと skill の認識は**成功**しました。一方で、claude.ai のサンドボックスには次の 2 つの制約があり、**現状では API 取得まで到達できません**。

- **`kokkai.ndl.go.jp` への通信がブロックされます**（`host_not_allowed`）。許可ドメインに含まれていないためです。
- **`jq` が導入されていません**。ドメインが許可されても、`--sort` を使うスクリプトはこの時点で失敗します。

claude.ai で実際に利用するには、組織のオーナーまたはユーザーのネットワーク設定で `kokkai.ndl.go.jp` を許可ドメインに追加する必要があります。`jq` 非依存化は別途対応が必要です。

## 利用上の注意

国会会議録検索システム API は、機械的アクセスにあたって多重リクエストを禁じ、数秒の間隔を空けることを求めています。本スキルはこの制約を SKILL.md の記述で守る設計です。スクリプトを直接繰り返し呼び出す場合は、呼び出し間隔にご注意ください。

## 出典

- [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [How to create custom Skills](https://support.claude.com/en/articles/12512198-creating-custom-skills)
- [Create and edit files with Claude](https://support.claude.com/en/articles/12111783-create-and-edit-files-with-claude)
- [国会会議録検索システム API](https://kokkai.ndl.go.jp/api.html)
