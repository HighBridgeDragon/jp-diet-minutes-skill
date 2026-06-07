---
name: Kokkai (National Diet) Minutes API Response Format
description: 国会会議録検索システム API のレスポンス構造（meetingRecord / speechRecord / メタ要素 / エンドポイント別差分 / 実データ例）
---

# 国会会議録検索システム API レスポンス構造

国会会議録検索システム API が返す XML / JSON レスポンスの構造仕様と、各エンドポイントの実データ例。エンドポイント概要・ページネーション・エラー形式は [api-reference.md](./api-reference.md)、検索パラメータの詳細は [parameters.md](./parameters.md) を参照。

XML が既定形式（`recordPacking` 省略時）だが、本ドキュメントは LLM 用途を想定し JSON 形式を中心に記載する。XML 形式は要素名と階層が JSON のキーと同一構造になる。

---

## 共通メタ要素

全エンドポイントのレスポンス直下に出現する。

| 要素 | 型 | 出現条件 | 意味 |
|---|---|---|---|
| `numberOfRecords` | 整数 | 常に | 検索条件に該当する総件数 |
| `numberOfReturn` | 整数 | 常に | 今回のレスポンスで返された件数 |
| `startRecord` | 整数 | 常に | 返却された範囲の開始位置（1 始まり）|
| `nextRecordPosition` | 整数 / `null` | 常に（値は条件付き） | 次リクエストの `startRecord` に渡す値。**最終ページでは `null`**（XML では要素自体が欠落する場合あり） |
| `meetingRecord[]` | 配列 | `meeting_list`, `meeting` で常に（ヒット 0 件時は欠落） | 会議単位の結果配列 |
| `speechRecord[]` | 配列 | `speech` で常に（ヒット 0 件時は欠落） | 発言単位の結果配列 |

**ページネーション終端判定（重要）:**

- JSON 形式: `nextRecordPosition === null` で最終ページ
- XML 形式: `<nextRecordPosition>` 要素自体が欠落（パーサ側で存在チェックが必要）
- `numberOfRecords === 0` のヒット 0 件時は `meetingRecord` / `speechRecord` 自体がレスポンスに含まれない

---

## meetingRecord 構造

会議単位の情報を表す。`meeting_list` / `meeting` エンドポイントで返される。

| フィールド | 型 | 出現条件 | 意味 |
|---|---|---|---|
| `issueID` | 文字列（21 桁英数字） | 常に | 会議録一意 ID。`speechID` のプレフィックスにもなる |
| `imageKind` | 文字列 | 常に | 区分: `会議録` / `目次` / `索引` / `附録` / `追録` |
| `searchObject` | 整数 | 常に | 内部識別用の番号（通常 `0`）|
| `session` | 整数 | 常に | 国会回次（例: `214`）|
| `nameOfHouse` | 文字列 | 常に | `衆議院` / `参議院` / `両院` / `両院協議会` |
| `nameOfMeeting` | 文字列 | 常に | 会議名（例: `本会議`, `予算委員会`）|
| `issue` | 文字列 | 常に | 号数（例: `第1号`）。目次・索引・附録・追録は号数 `0` |
| `date` | 文字列 `YYYY-MM-DD` | 常に | 開催日 |
| `closing` | `true` / `null` | 常に | 閉会中フラグ。**`false` ではなく `null` が返る**（API の仕様上の特徴。値の評価時は `=== true` で判定推奨）|
| `speechRecord[]` | 配列 | 常に | 発言の配列。エンドポイントにより内容粒度が異なる（後述）|
| `meetingURL` | URL | 常に | テキスト表示画面の URL |
| `pdfURL` | URL | 存在する場合のみ | PDF 表示画面の URL |

### `meeting_list` の `speechRecord[]` 粒度

`meeting_list` では会議メタ情報のみ返却の建付けだが、配下に `speechRecord[]` も含まれる。ただし各要素は **発言メタの最小集合のみ**:

- `speechID`
- `speechOrder`
- `speaker`
- `speechURL`

発言本文 (`speech`) を含む全フィールドは `meeting` または `speech` エンドポイントで取得する必要がある。

### `meeting` の `speechRecord[]` 粒度

全フィールド完備（後述の speechRecord 構造を参照）。1 会議あたり数十〜数百の発言を含むため、レスポンスは数百 KB〜 MB 規模になりやすい。

---

## speechRecord 構造

発言単位の情報を表す。`meeting` / `speech` の両エンドポイントで返されるが、`speech` ではフラット構造、`meeting` では `meetingRecord` 配下にネストされる。

| フィールド | 型 | `meeting_list` | `meeting` | `speech` | 意味 |
|---|---|---|---|---|---|
| `speechID` | 文字列 | ✓ | ✓ | ✓ | 発言一意 ID（`issueID_<speechOrder 3 桁>`）|
| `issueID` | 文字列 | – | – | ✓ | 親会議録 ID（`speech` ではフラット化のため speechRecord 直下に出現）|
| `imageKind` | 文字列 | – | – | ✓ | 区分（`speech` でのみ speechRecord 直下に出現）|
| `searchObject` | 整数 | – | – | ✓ | `searchRange` のヒット位置。発言冒頭ヒットなら 0、本文ヒットなら該当 `speechOrder` |
| `session` | 整数 | – | – | ✓ | 国会回次（`speech` のフラット展開）|
| `nameOfHouse` | 文字列 | – | – | ✓ | 院名（`speech` のフラット展開）|
| `nameOfMeeting` | 文字列 | – | – | ✓ | 会議名（`speech` のフラット展開）|
| `issue` | 文字列 | – | – | ✓ | 号数（`speech` のフラット展開）|
| `date` | 文字列 | – | – | ✓ | 開催日（`speech` のフラット展開）|
| `closing` | `true`/`null` | – | – | ✓ | 閉会中フラグ（`speech` のフラット展開）|
| `speechOrder` | 整数 | ✓ | ✓ | ✓ | 会議内の発言順（0 始まり。0 番は **会議録情報ヘッダ**）|
| `speaker` | 文字列 | ✓ | ✓ | ✓ | 発言者名（speechOrder=0 では `会議録情報`）|
| `speakerYomi` | 文字列 / `null` | – | ✓ | ✓ | 発言者よみがな |
| `speakerGroup` | 文字列 / `null` | – | ✓ | ✓ | 所属会派の正式名称 |
| `speakerPosition` | 文字列 / `null` | – | ✓ | ✓ | 肩書き |
| `speakerRole` | 文字列 / `null` | – | ✓ | ✓ | 役割（`証人` / `参考人` / `公述人`、通常は `null`）|
| `speech` | 文字列 | – | ✓ | ✓ | 発言本文。改行は **CRLF (`\r\n`)** |
| `startPage` | 整数 | – | ✓ | ✓ | 掲載開始ページ番号 |
| `createTime` | 文字列 `YYYY-MM-DD HH:MM:SS` | – | ✓ | – | レコード登録日時（`meeting` のみ）|
| `updateTime` | 文字列 `YYYY-MM-DD HH:MM:SS` | – | ✓ | – | レコード更新日時（`meeting` のみ）|
| `speechURL` | URL | ✓ | ✓ | ✓ | 発言テキスト表示画面の URL |
| `meetingURL` | URL | – | – | ✓ | 会議のテキスト表示画面 URL |
| `pdfURL` | URL / 欠落 | – | – | ✓ | 会議の PDF 表示画面 URL（該当ページ付き）|

**重要な構造差:**

- `meeting` エンドポイントは `meetingRecord[].speechRecord[]` の **2 階層ネスト**
- `speech` エンドポイントは `speechRecord[]` のみ。会議メタ情報は各 speechRecord 配下に **フラット展開** される（`meetingRecord` ラッパは存在しない）
- 同一会議内に複数ヒットがあると、`speech` では同じ `issueID` の speechRecord が複数返る

**`speechOrder = 0` の `会議録情報`:**

会議録の各セッションには順に 0 から発言が並ぶが、0 番目は実際の発言ではなく **議事日程・付議案件などのメタヘッダ**。`speaker` は固定で `会議録情報`、`speech` には議事日程の整形済みテキストが入る。集計時は `speechOrder > 0` でフィルタすると実発言だけを取れる。

---

## エンドポイント別レスポンス完全例（JSON）

すべて `recordPacking=json` で取得。発言本文の長文は `…` で省略表示している。

### 1. `meeting_list` — 会議一覧（メタのみ）

```text
GET /api/meeting_list?from=2024-10-01&until=2024-10-01&maximumRecords=2&recordPacking=json
```

```json
{
  "numberOfRecords": 11,
  "numberOfReturn": 2,
  "startRecord": 1,
  "nextRecordPosition": 3,
  "meetingRecord": [
    {
      "issueID": "121405254X00120241001",
      "imageKind": "会議録",
      "searchObject": 0,
      "session": 214,
      "nameOfHouse": "衆議院",
      "nameOfMeeting": "本会議",
      "issue": "第1号",
      "date": "2024-10-01",
      "closing": null,
      "speechRecord": [
        {
          "speechID": "121405254X00120241001_000",
          "speechOrder": 0,
          "speaker": "会議録情報",
          "speechURL": "https://kokkai.ndl.go.jp/txt/121405254X00120241001/0"
        },
        {
          "speechID": "121405254X00120241001_001",
          "speechOrder": 1,
          "speaker": "額賀福志郎",
          "speechURL": "https://kokkai.ndl.go.jp/txt/121405254X00120241001/1"
        }
      ],
      "meetingURL": "https://kokkai.ndl.go.jp/txt/121405254X00120241001",
      "pdfURL": "https://kokkai.ndl.go.jp/img/121405254X00120241001"
    }
  ]
}
```

ポイント: `speechRecord` 配下の各要素は `speechID` / `speechOrder` / `speaker` / `speechURL` の **4 フィールドのみ**（発言本文や肩書きを取るには `meeting` / `speech` を呼ぶ）。

### 2. `meeting` — 会議全文

```text
GET /api/meeting?nameOfMeeting=本会議&nameOfHouse=衆議院&from=2024-10-04&until=2024-10-04&maximumRecords=1&recordPacking=json
```

```json
{
  "numberOfRecords": 1,
  "numberOfReturn": 1,
  "startRecord": 1,
  "nextRecordPosition": null,
  "meetingRecord": [
    {
      "issueID": "121405254X00220241004",
      "imageKind": "会議録",
      "searchObject": 0,
      "session": 214,
      "nameOfHouse": "衆議院",
      "nameOfMeeting": "本会議",
      "issue": "第2号",
      "date": "2024-10-04",
      "closing": null,
      "speechRecord": [
        {
          "speechID": "121405254X00220241004_000",
          "speechOrder": 0,
          "speaker": "会議録情報",
          "speakerYomi": null,
          "speakerGroup": null,
          "speakerPosition": null,
          "speakerRole": null,
          "speech": "令和六年十月四日（金曜日）\r\n　　　　―――――――――――――\r\n　議事日程　第二号\r\n …",
          "startPage": 1,
          "createTime": "2025-01-27 19:07:25",
          "updateTime": "2025-01-28 09:41:38",
          "speechURL": "https://kokkai.ndl.go.jp/txt/121405254X00220241004/0"
        },
        {
          "speechID": "121405254X00220241004_001",
          "speechOrder": 1,
          "speaker": "額賀福志郎",
          "speakerYomi": "ぬかがふくしろう",
          "speakerGroup": "無所属",
          "speakerPosition": "議長",
          "speakerRole": null,
          "speech": "○議長（額賀福志郎君）　これより会議を開きます。\r\n …",
          "startPage": 1,
          "createTime": "2025-01-27 19:07:25",
          "updateTime": "2025-01-28 09:41:38",
          "speechURL": "https://kokkai.ndl.go.jp/txt/121405254X00220241004/1"
        }
      ]
    }
  ]
}
```

ポイント: `speechRecord` 配下に全フィールド出現。`speakerYomi` / `speakerGroup` / `speakerPosition` / `speakerRole` は値がない場合 `null`。`createTime` / `updateTime` はこのエンドポイントのみ。

### 3. `speech` — 発言単位（フラット構造）

```text
GET /api/speech?speaker=石破茂&from=2024-10-04&until=2024-10-04&maximumRecords=1&recordPacking=json
```

```json
{
  "numberOfRecords": 2,
  "numberOfReturn": 1,
  "startRecord": 1,
  "nextRecordPosition": 2,
  "speechRecord": [
    {
      "speechID": "121405254X00220241004_016",
      "issueID": "121405254X00220241004",
      "imageKind": "会議録",
      "searchObject": 16,
      "session": 214,
      "nameOfHouse": "衆議院",
      "nameOfMeeting": "本会議",
      "issue": "第2号",
      "date": "2024-10-04",
      "closing": null,
      "speechOrder": 16,
      "speaker": "石破茂",
      "speakerYomi": "いしばしげる",
      "speakerGroup": "自由民主党・無所属の会",
      "speakerPosition": "内閣総理大臣",
      "speakerRole": null,
      "speech": "○内閣総理大臣（石破茂君）　この度、第百二代内閣総理大臣に就任いたしました。\r\n　すべての人に安心と安全を。\r\n …",
      "startPage": 2,
      "speechURL": "https://kokkai.ndl.go.jp/txt/121405254X00220241004/16",
      "meetingURL": "https://kokkai.ndl.go.jp/txt/121405254X00220241004",
      "pdfURL": "https://kokkai.ndl.go.jp/img/121405254X00220241004/2"
    }
  ]
}
```

ポイント: 会議メタ（`issueID`, `session`, `nameOfHouse` など）が **`speechRecord` の直下にフラット展開**される。`meetingRecord` ラッパは存在しない。`searchObject` には該当発言の `speechOrder` が入る。

---

## テキスト本文の改行・特殊文字

`speech` フィールドの本文は会議録のオリジナル整形に近い形で返却される。

| 要素 | 内容 |
|---|---|
| 改行コード | **CRLF (`\r\n`)** が使われる（LF のみではない） |
| 段落先頭の字下げ | 全角スペース `　`（U+3000）が 1〜2 字 |
| 発言の冒頭 | `○` 記号 + 発言者の肩書きまたは氏名 + 全角スペース（例: `○議長（額賀福志郎君）` の直後に `　` が続く）|
| 議事日程の区切り | 罫線記号 `―――――` や `…………` の連続 |
| 全角・半角混在 | 数値は漢数字（`第百二代`）と算用数字（`2`）が混在 |
| HTML エンティティ | JSON では生の Unicode 文字、XML では `&lt;` `&gt;` `&amp;` 等のエスケープ |

集計・テキストマイニングの前処理時は以下に注意:

- 改行を `\n` に正規化したい場合は `\r\n` → `\n` 置換
- 発言冒頭の `○` + 肩書き + 全角スペースのパターンは正規表現 <code>^○[^　]+　</code> で除去可能（末尾は全角空白 U+3000）
- 字下げの `　` を削除する場合は意味のある段落構造が崩れないか確認

---

## 落とし穴と実用上の注意

### 1. `closing` は `false` を返さず `null` を返す

API は閉会中以外の会議に対して `closing: null` を返す。`false` を期待した条件式は誤動作するため、`closing === true` で判定する。

### 2. `speechOrder = 0` は実発言ではない

最初の `speechRecord` (`speechOrder: 0`, `speaker: 会議録情報`) は議事日程・付議案件のメタヘッダ。`speech` 本文には議事順序が入っており、実際の議論ではない。発言集計時は `speechOrder > 0` でフィルタする。

### 3. `meeting_list` の `speechRecord` は最小フィールドのみ

`speech`, `speakerGroup`, `speakerPosition`, `speakerYomi`, `speakerRole` などは **そもそも返らない**（`null` ですらない、キーが存在しない）。本文取得には `meeting` または `speech` を呼ぶ。

### 4. `speech` エンドポイントは meetingRecord ラッパを持たない

JSON / XML 構造が `meeting` と異なる。共通のパース関数を書くなら `meetingRecord` の有無で分岐する必要がある。

### 5. `imageKind` の値で本会議録以外が混じる

`目次` / `索引` / `附録` / `追録` も同じ検索クエリでヒットする。発言本文の調査時は `imageKind === "会議録"` でフィルタする、または `supplementAndAppendix=false` / `contentsAndIndex=false`（既定）を明示して除外する。

### 6. JSON のフィールド順序は安定しない可能性

`recordPacking=json` のレスポンスはオブジェクトキー順が将来変わる可能性がある。キー順に依存したパースは避ける（標準的な JSON パーサ利用で問題なし）。
