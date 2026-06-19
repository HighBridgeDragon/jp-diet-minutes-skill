---
name: Kokkai (National Diet) Minutes API Reference
description: 国会会議録検索システム API の3エンドポイント仕様（URL・最大件数・recordPacking・ページネーション・エラー・レート制限）
---

# 国会会議録検索システム API リファレンス

国会会議録検索システム（NDL 提供）が公開する国会発足（1947 年）以降の国会会議録 API の仕様。
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

会議のメタ情報を返す。`speechRecord[]` は含まれるが各要素は `speechID` / `speechOrder` / `speaker` / `speechURL` の最小集合のみで、発言本文 (`speech` フィールド) は含まれないため、ヒット数の概観や会議一覧の生成に適する。発言本文や肩書きまで取得するには `meeting` または `speech` を呼ぶ。

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

## 結果の返却順

公式仕様（<https://kokkai.ndl.go.jp/api.html> 「2. 概要」）に以下が明記されている:

> 検索結果のソート順は、会議開催日の新しい順となっています。

- `speech` / `meeting_list` / `meeting` 全エンドポイントで会議開催日の降順固定
- ソート指定パラメータ（`sort` / `order` / `orderBy` 等）は存在しない
- `maximumRecords` 部分取得は常に「期間内で最新側 N 件」を返すため、最古発言判定にはページネーション末尾まで取得するか `from`/`until` で範囲を狭める必要がある

実証例: `speaker=松岡克由&from=1971-01-01&until=1975-12-31&maximumRecords=10` の結果は `numberOfRecords=578` のうち最新側 10 件（1975-05-07 → 1975-03-27 ×9）。期間内最古の 1972-06-08（参議院 逓信委員会、第 68 回国会）は未取得のまま残る。最古を 1 リクエストで特定するには `startRecord=<numberOfRecords>` で末尾を直撃する方法もある（ただし末尾は同日最終発言になる。詳細は [後述の同日内二次ソート節](#同日内の二次ソートspeechorder-昇順実測ベース)）。

### 同日内の二次ソート（`speechOrder` 昇順、実測ベース）

公式仕様で明記されているのは「会議開催日の新しい順」までで、**同日内（同一会議内）の二次ソートについては記載なし**。実測では同日内は `speechOrder` 昇順で返る（小さい方が先頭）。本挙動は `19028` / `19004` と同様、実測でのみ確認できる（公式仕様には明示なし）。

実証データ: `speaker=松岡克由&from=1972-06-08&until=1972-06-08&maximumRecords=100` の結果は 10 件で、同一会議（1972-06-08 参議院 逓信委員会、第 68 回国会）内で `speechOrder=32〜51` が昇順で並ぶ。期間を広げた `speaker=松岡克由&from=1971-01-01&until=1975-12-31&maximumRecords=100&startRecord=656` でも同じ 10 件 (`speechOrder=32〜51` 昇順) が返り、`startRecord=665` で `speechOrder=51` の最終発言、`startRecord=656` で `speechOrder=32` の初発言となる。

最古発言判定への影響: 期間を絞らず `startRecord=<numberOfRecords>&maximumRecords=1` で末尾を直撃すると、API 降順固定により期間内最古日付の **同日最終発言** (`speechOrder` 最大) を取得し、真の初発言 (`speechOrder` 最小) を逃す。期間を最古日付の 1 日まで絞れば `from=oldest&until=oldest&maximumRecords=1` で同日内昇順の先頭 = 真の初発言が取れるが、最古日付の事前確定が必要。複数日にまたがる期間を 1 リクエストで確定するには wrapper script の `--sort date-asc,speech-order-asc`（`jq` 経由のクライアント側ソート）を使う。詳細は [recipes/oldest-speech-by-speaker.md](recipes/oldest-speech-by-speaker.md) を参照。

---

## エラーレスポンス

リクエスト不正時はエンドポイント共通でエラーを返す。形式は `recordPacking` で切り替わる。

### XML 形式（既定）

`<diagnostics>` 要素配下に `<diagnostic>` を含み、`<message>` がエラーメッセージ、`<details>` が詳細情報。**`<details>` 要素はエラー種別により省略される**（実測: `19007`（必須欠落）では `<details>` 要素自体が欠落、`19011`（入力誤り）では存在）。パーサ側で `<details>` の存在チェックを行うこと。

`<details>` ありの例（`19011` / speakerRole 不正、HTTP 400）:

```xml
<data>
  <diagnostics>
    <diagnostic>
      <message>(19011)検索条件の入力に誤りがあります。</message>
      <details>(0) (19028)speakerRole:発言者役割を証人/参考人/公述人で入力してください。</details>
    </diagnostic>
  </diagnostics>
</data>
```

`<details>` なしの例（`19007` / 必須欠落、HTTP 400）:

```xml
<data>
  <diagnostics>
    <diagnostic>
      <message>(19007)検索条件を指定してください。</message>
    </diagnostic>
  </diagnostics>
</data>
```

### JSON 形式

`message` フィールドにエラーメッセージ、`details` 配列に詳細情報。**`details` フィールドはエラー種別により省略される**（実測: `19007`（必須欠落）では `details` キー自体が存在しない、`19011`（入力誤り）では存在）。`body.details[0]` のような無条件アクセスは `19007` 等で `undefined` / `KeyError` 系の例外を踏むため、`details` の有無を条件分岐し、`message` のみで判定できる構造にすること。

`details` ありの例（`19011` / speakerRole 不正、HTTP 400）:

```json
{
  "message": "(19011)検索条件の入力に誤りがあります。",
  "details": ["(0) (19028)speakerRole:発言者役割を証人/参考人/公述人で入力してください。"]
}
```

`details` なしの例（`19007` / 必須欠落、HTTP 400）:

```json
{
  "message": "(19007)検索条件を指定してください。"
}
```

### 不正入力の挙動の使い分け

実測によると、NDL 実装は不正入力の種類で挙動が分かれる。**列挙値パラメータでも `nameOfHouse` と `speakerRole` で挙動が非対称** な点に注意（詳細は [`parameters.md` の「検索方式の使い分けまとめ」](parameters.md#検索方式の使い分けまとめ)を参照）。

| 不正入力の種類 | HTTP ステータス | 挙動 |
|---|---|---|
| 構文不正（不正日付、上限超過、範囲外、必須欠落 等） | 400 | `message`（必須）+ `details`（JSON 配列・任意）または `<message>` + `<details>`（XML・任意）にエラー本文を返す。`details` / `<details>` はエラー種別により省略される（例: `19007` では欠落） |
| 列挙値の不正 — `nameOfHouse`（例: `nameOfHouse=invalid_house_xyz`） | 200 | **そのパラメータは無言で無視され、フィルタ未適用の結果が返る** |
| 列挙値の不正 — `speakerRole`（`証人` / `参考人` / `公述人` 以外） | 400 | エラー本文を返す（`message` フィールドにコード `19011`、`details` 配列にコード `19028` を内包。`19028` は[公式仕様](https://kokkai.ndl.go.jp/api.html)の「表 2：エラーメッセージ」未掲載・実測のみ） |

**重要:** `nameOfHouse` の列挙値不正は HTTP 200 で返るため、エラーとして検知されない。意図したフィルタが効いているかを `numberOfRecords` の妥当性で必ず確認すること（無視された場合は全件規模の `numberOfRecords` が返る）。一方 `speakerRole` の列挙値不正は HTTP 400 で弾かれるため、挙動が異なる点に留意。

代表的なエラー要因（いずれも HTTP 400）:

- 日付フォーマットの誤り（`from` / `until` は `YYYY-MM-DD`）
- `maximumRecords` がエンドポイントの上限を超過
- `startRecord` が総件数を超える値（`19004`、「検索件数」の解釈は[後述の専用節](#19004startrecord-範囲外の検索件数の解釈)参照）
- 必須パラメータの欠落
- `speakerRole` の列挙値が許可された値（`証人` / `参考人` / `公述人`）以外

代表的な silently 無視されるケース（HTTP 200）:

- `nameOfHouse` の列挙値が許可された値（`衆議院` / `参議院` / `両院` / `両院協議会`）以外

注: `両院` と `両院協議会` はいずれも有効な列挙値であり、同義（エイリアス）として扱われる。どちらを指定しても両院協議会の会議録が返り、レスポンスの `nameOfHouse` フィールドは常に `両院` で返る（実測ベース）。

### `19004`（`startRecord` 範囲外）の「検索件数」の解釈

`19004` のエラーメッセージは以下の形式で返る（HTTP 400）:

> (19004)startRecord には 1 から検索件数までの値を指定してください。

ここで言う「検索件数」は **同一クエリでの `numberOfRecords`** を指す（実測ベース）。公式仕様（<https://kokkai.ndl.go.jp/api.html>）の「表 2：エラーメッセージ」には「1 から検索件数まで」の文言のみが記載されており、「検索件数」がどのクエリの `numberOfRecords` を参照するかについての明示はない（`19028` と同様に、本挙動は実測でのみ確認できる）。

別クエリで取得した `numberOfRecords` の値を流用して `startRecord` を決めると、絞り込み条件で件数が縮んだ同一クエリ側では範囲外となり 19004 を踏む。典型ケース:

- 単純検索（例: `speaker=A` 単独）で得た `numberOfRecords` を、後続の絞り込み付きクエリ（例: `speaker=A&from=2024-01-01&until=2024-12-31`）の `startRecord` に流用
- `any` と `speaker` の併用で件数が大幅減するケース（[SKILL.md 落とし穴節項目 8](../SKILL.md#結果フィルタリングの落とし穴) 参照）
- wrapper script 経由で取得した件数を、raw curl の別パラメータ組合せに流用

原因切り分け手順（実用上有効）:

1. 19004 を踏んだクエリと **完全に同一の検索条件** で `startRecord=1&maximumRecords=1` を 1 リクエスト発行
2. レスポンスの `numberOfRecords` を確認
3. その値が「検索件数」の上限。`startRecord` は `1` から `numberOfRecords` までの範囲で指定する

別経路で取得した件数（過去取得した古いキャッシュ、別パラメータ組合せの結果、wrapper script の結果）を信用しないこと。

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
