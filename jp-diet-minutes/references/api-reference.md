---
name: Kokkai (National Diet) Minutes API Reference
description: 国会会議録検索システム API の3エンドポイント仕様（URL・最大件数・recordPacking・ページネーション・エラー・レート制限）
---

# 国会会議録検索システム API リファレンス

国会会議録検索システム（NDL 提供）が公開する戦後の国会会議録 API の仕様。
帝国議会会議録 API は対象外（別 API）。

- Base URL: `https://kokkai.ndl.go.jp/api/`
- 公式仕様: <https://kokkai.ndl.go.jp/api.html>
- HTTP メソッド: 全エンドポイント `GET`
- 認証: 不要
- 文字エンコード: UTF-8
- 検索パラメータ詳細は [parameters.md](./parameters.md)、レスポンス構造詳細は [response-format.md](./response-format.md) を参照

---

## エンドポイント一覧

| エンドポイント | フル URL | 最大件数 | 用途 |
|---|---|---|---|
| 会議単位簡易出力 | `https://kokkai.ndl.go.jp/api/meeting_list` | 100 | 会議メタ情報のみ（発言本文を含まない） |
| 会議単位出力 | `https://kokkai.ndl.go.jp/api/meeting` | 10 | 会議メタ情報＋当該会議の全発言本文 |
| 発言単位出力 | `https://kokkai.ndl.go.jp/api/speech` | 100 | 検索条件にヒットした発言単位の本文 |

「最大件数」は 1 リクエストあたりの `maximumRecords` の上限。総ヒット件数が上限を超える場合は後述のページネーションで取得する。

### エンドポイント選択指針

トークンと API 負荷を抑えるため、まず情報量の少ない `meeting_list` / `speech` で範囲を絞り、必要な会議に限定して `meeting` で全文取得する流れを推奨する。

| ユースケース | 推奨エンドポイント |
|---|---|
| 会議の一覧・回次や日付の把握 | `meeting_list` |
| 特定の議員・キーワードに該当する発言の抽出 | `speech` |
| 特定会議の議事の全文取得 | `meeting`（件数を絞ってから呼ぶ） |

---

## 1. `GET /api/meeting_list` — 会議単位簡易出力

会議のメタ情報のみを返す。発言本文 (`speechRecord`) は含まれないため、ヒット数の概観や会議一覧の生成に適する。

- 最大件数 (`maximumRecords`): 1〜100、既定 30
- `startRecord` 既定値: 1
- `recordPacking`: `xml`（既定）または `json`

主要レスポンス要素: `numberOfRecords`, `numberOfReturn`, `startRecord`, `nextRecordPosition`, `meetingRecord[]`。`meetingRecord` の構造は [response-format.md](./response-format.md) を参照。

---

## 2. `GET /api/meeting` — 会議単位出力

会議のメタ情報に加え、当該会議の全発言本文 (`speechRecord[]`) を返す。1 件あたりのレスポンスが非常に大きくなるため、最大件数が他エンドポイントの 10 分の 1 に制限されている。

- 最大件数 (`maximumRecords`): 1〜10、既定 3
- `startRecord` 既定値: 1
- `recordPacking`: `xml`（既定）または `json`
- 1 件あたりの応答ボリュームが大きいため、`meeting_list` / `speech` で対象会議を絞ってから呼び出すこと

---

## 3. `GET /api/speech` — 発言単位出力

検索条件にヒットした発言のみを返す。会議全体ではなく発言粒度で結果を返すため、議員名やキーワードでのピンポイント検索に最適。

- 最大件数 (`maximumRecords`): 1〜100、既定 30
- `startRecord` 既定値: 1
- `recordPacking`: `xml`（既定）または `json`

`meeting_list` と異なり、結果単位は会議ではなく `speechRecord`。同一会議内の複数発言にヒットすると、その会議は同数回返る点に注意。

---

## レスポンス形式指定

| パラメータ | 取りうる値 | 既定 |
|---|---|---|
| `recordPacking` | `xml` / `json` | `xml` |

`Accept` ヘッダではなくクエリパラメータで指定する。LLM/エージェント連携では `json` を明示することを推奨する。

---

## ページネーション

全エンドポイント共通。

| パラメータ | 範囲 | 既定値 |
|---|---|---|
| `startRecord` | 1 〜 総ヒット件数 | 1 |
| `maximumRecords`（`meeting_list` / `speech`） | 1 〜 100 | 30 |
| `maximumRecords`（`meeting`） | 1 〜 10 | 3 |

ページ送りの基本パターン:

1. 初回リクエストは `startRecord=1`、必要に応じて `maximumRecords` を指定
2. レスポンスの `nextRecordPosition` を次回リクエストの `startRecord` に渡す
3. 最終ページの判定はレスポンス形式で異なる:
   - **JSON 形式**: `nextRecordPosition` が `null` で返る → `!nextRecordPosition` の真偽値評価で判定可能
   - **XML 形式**: `<nextRecordPosition>` 要素自体が欠落 → パーサ側で要素の存在チェックが必要

`numberOfRecords`（総ヒット件数）、`numberOfReturn`（今回返却件数）と合わせて進捗を判断する。

---

## エラーレスポンス

リクエスト不正時はエンドポイント共通でエラーを返す。形式は `recordPacking` で切り替わる。

### XML 形式（既定）

`<diagnostics>` 要素配下に `<diagnostic>` を含み、`<message>` がエラーメッセージ、`<details>` が詳細情報。

```xml
<data>
  <diagnostics>
    <diagnostic>
      <message>検索条件の入力に誤りがあります。</message>
      <details>... 詳細 ...</details>
    </diagnostic>
  </diagnostics>
</data>
```

### JSON 形式

`message` フィールドにエラーメッセージ、`details` 配列に詳細情報。

```json
{
  "message": "検索条件の入力に誤りがあります。",
  "details": ["..."]
}
```

### 不正入力の挙動の使い分け

実測によると、NDL 実装は不正入力の種類で挙動が分かれる。

| 不正入力の種類 | HTTP ステータス | 挙動 |
|---|---|---|
| 構文不正（不正日付、上限超過、範囲外、必須欠落 等） | 400 | `message` / `details`（JSON）または `<diagnostics>`（XML）にエラー本文を返す |
| 列挙値の不正（例: `nameOfHouse=invalid_house_xyz`） | 200 | **そのパラメータは無言で無視され、フィルタ未適用の結果が返る** |

**重要:** 列挙値不正は HTTP 200 で返るため、エラーとして検知されない。意図したフィルタが効いているかを `numberOfRecords` の妥当性で必ず確認すること（無視された場合は全件規模の `numberOfRecords` が返る）。

代表的なエラー要因（いずれも HTTP 400）:

- 日付フォーマットの誤り（`from` / `until` は `YYYY-MM-DD`）
- `maximumRecords` がエンドポイントの上限を超過
- `startRecord` が総件数を超える値
- 必須パラメータの欠落

代表的な silently 無視されるケース（HTTP 200）:

- `nameOfHouse` などの列挙値が許可された値以外

---

## レート制限・推奨呼び出し間隔

公式の文言は以下のとおり（<https://kokkai.ndl.go.jp/api.html> より）。

> 機械的なアクセスを行う場合、多重リクエストは避けてください。
> また、データを取得し終えてから数秒程度空けて次のリクエストを行うようにしてください。

具体的な閾値（毎秒上限値など）は公開されていない。スキル運用時は以下を遵守する。

- 並列リクエストを発行しない（1 リクエスト完了 → 数秒待機 → 次リクエスト）
- バックオフ目安: 連続呼び出し時は最低 2〜3 秒、ヒット件数が大きい一覧取得後は 5 秒程度を目安に間隔をあける
- 短時間に大量取得が必要な場合は、`maximumRecords` を上限近くまで上げてリクエスト総数を減らす
- HTTP 429 や 5xx を受けたら指数バックオフでリトライする
