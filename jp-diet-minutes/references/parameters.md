---
name: Kokkai (National Diet) Minutes API Parameters
description: 国会会議録検索システム API の検索パラメータ仕様（型・既定値・検索方式・組み合わせ例）
---

# 国会会議録検索システム API 検索パラメータ仕様

国会会議録検索システム API の検索パラメータ仕様。エンドポイント・ページネーション・レスポンス形式の概観は [api-reference.md](./api-reference.md)、レスポンス構造の詳細は [response-format.md](./response-format.md) を参照。

公式: <https://kokkai.ndl.go.jp/api.html>

---

## 共通ルール

- 全パラメータは URL クエリ文字列で渡す（HTTP メソッドは `GET`）
- 文字エンコードは UTF-8、値は URL エンコード必須
- **クエリ文字列全体は 2,000 バイト上限**（超過時はエラー）
- 院名・会議名・キーワード・発言者名・期間・回次・号数・各種 ID のいずれかを **最低 1 つ指定する必要がある**（指定なしは `errorCode=19007`）
- 複数のパラメータは `&` で連結（パラメータ間は AND 評価）

---

## パラメータ一覧

### 全文検索

| パラメータ | 型 | 既定値 | 検索方式 | 複数指定 | 備考 |
|---|---|---|---|---|---|
| `any` | 文字列 | （指定なし） | 部分一致・**AND** | 半角スペース区切りで複数指定可 | 発言本文を対象。`searchRange` と併用 |
| `searchRange` | `冒頭` / `本文` / `冒頭・本文` | `冒頭・本文` | N/A | 不可 | `any` 指定時のみ有効 |

`searchRange` は会議録の構造ブロックを指定する。`冒頭` は会議冒頭部分、`本文` は審議本文、`冒頭・本文` は両方（既定）。

### 会議属性

| パラメータ | 型 | 既定値 | 検索方式 | 複数指定 | 備考 |
|---|---|---|---|---|---|
| `nameOfHouse` | `衆議院` / `参議院` / `両院` / `両院協議会` | （指定なし） | 完全一致（列挙） | 不可 | **不正値は無言で無視され、フィルタなしの結果が返る**（HTTP 200） |
| `nameOfMeeting` | 文字列 | （指定なし） | 部分一致・**OR** | 半角スペース区切りで複数指定可 | ひらがな入力可。例: `予算 法務` で予算 OR 法務委員会 |
| `closing` | `true` / `false` | `false` | N/A | 不可 | `true` で閉会中審査の会議録に限定 |

### 発言者属性

| パラメータ | 型 | 既定値 | 検索方式 | 複数指定 | 備考 |
|---|---|---|---|---|---|
| `speaker` | 文字列 | （指定なし） | 部分一致・**OR** | 半角スペース区切りで複数指定可 | ひらがな入力可。表記揺れに注意 |
| `speakerPosition` | 文字列 | （指定なし） | 部分一致 | 不可 | 肩書き（例: `内閣総理大臣`） |
| `speakerGroup` | 文字列 | （指定なし） | 部分一致 | 不可 | 所属会派。データ上は **正式名称のみ**（略称不可。例: `自由民主党` ✅ / `自民党` ❌ ）|
| `speakerRole` | `証人` / `参考人` / `公述人` | （指定なし） | 完全一致（列挙） | 不可 | **不正値はエラー**（`nameOfHouse` と挙動が異なる点に注意）|
| `speechNumber` | 整数（0 以上） | （指定なし） | 完全一致 | 不可 | 会議録内の発言番号 |

### 期間・回次・号数

| パラメータ | 型 | 既定値 | 検索方式 | 複数指定 | 備考 |
|---|---|---|---|---|---|
| `from` | 日付 `YYYY-MM-DD` | `0000-01-01` | 範囲（始点） | 不可 | 開会日付の下限。`from` ≦ `until` 必須 |
| `until` | 日付 `YYYY-MM-DD` | `9999-12-31` | 範囲（終点） | 不可 | 開会日付の上限。`from` と同じ値を指定すると当日のみ抽出 |
| `sessionFrom` | 整数（最大 3 桁） | （指定なし） | 範囲または完全一致 | 不可 | 国会回次の下限。`sessionTo` 併用で範囲、単独指定で完全一致 |
| `sessionTo` | 整数（最大 3 桁） | （指定なし） | 範囲または完全一致 | 不可 | 国会回次の上限 |
| `issueFrom` | 整数（最大 3 桁） | （指定なし） | 範囲または完全一致 | 不可 | 会議録号数の下限。目次・索引・追録・附録は号数 `0` |
| `issueTo` | 整数（最大 3 桁） | （指定なし） | 範囲または完全一致 | 不可 | 会議録号数の上限 |

### 同定 ID

| パラメータ | 型 | 検索方式 | 備考 |
|---|---|---|---|
| `issueID` | 21 桁の英数字 | 完全一致 | 会議録を一意に識別する ID。形式不正はエラー |
| `speechID` | `issueID_発言番号` 形式 | 完全一致 | 例: `100105254X00119470520_000`。形式不正はエラー |

### 補助フラグ

| パラメータ | 型 | 既定値 | 備考 |
|---|---|---|---|
| `supplementAndAppendix` | `true` / `false` | `false` | `true` で追録・附録に限定 |
| `contentsAndIndex` | `true` / `false` | `false` | `true` で目次・索引に限定 |

### ページネーション・出力

| パラメータ | 型 | 既定値 | 備考 |
|---|---|---|---|
| `startRecord` | 整数 | `1` | 取得開始位置（1 始まり）|
| `maximumRecords` | 整数 | `meeting_list`/`speech`: `30`、`meeting`: `3` | 上限は `meeting_list`/`speech` で `100`、`meeting` で `10` |
| `recordPacking` | `xml` / `json` | `xml` | 応答形式。LLM/エージェント連携では `json` を推奨 |

ページネーションの詳細（`nextRecordPosition` の終端判定など）は [api-reference.md](./api-reference.md) 参照。

---

## 検索方式の使い分けまとめ

| 検索方式 | 該当パラメータ |
|---|---|
| 部分一致・AND（スペース区切り） | `any` |
| 部分一致・OR（スペース区切り） | `nameOfMeeting`, `speaker` |
| 部分一致（単一値） | `speakerPosition`, `speakerGroup` |
| 完全一致（列挙） | `nameOfHouse`, `speakerRole` |
| 完全一致（数値・ID） | `speechNumber`, `issueID`, `speechID` |
| 範囲または完全一致 | `sessionFrom`/`sessionTo`, `issueFrom`/`issueTo` |
| 範囲 | `from`/`until` |
| フラグ | `closing`, `supplementAndAppendix`, `contentsAndIndex` |

**重要な非対称性:** 同じ「列挙型の完全一致」でも、不正値時の挙動は異なる。

| パラメータ | 不正値時の挙動 |
|---|---|
| `nameOfHouse` | **HTTP 200 で silently 無視**（フィルタが効いていない結果が返る） |
| `speakerRole` | **HTTP 400 エラー** |

`nameOfHouse` 側は、誤値を投げてもエラーで弾かれないため、`numberOfRecords` が想定より大きい場合は **値の綴り** を疑うこと。

---

## エンドポイント別の有効パラメータ差異

ほぼ全パラメータは 3 エンドポイント共通だが、`maximumRecords` の上限・既定値だけはエンドポイントで異なる（前掲）。

`speech`（発言単位出力）で発言者・発言内容関連のパラメータを使うと、最も粒度の細かいヒットが返る。`meeting_list` で同じパラメータを使うと、ヒットした発言を含む **会議単位** で返る（同一会議内の複数ヒットは 1 件にまとまる）。

---

## よく使う組み合わせ例

### 1. 特定議員の特定期間の発言を抽出

```text
GET /api/speech?speaker=岸田文雄&from=2024-01-01&until=2024-12-31&recordPacking=json&maximumRecords=100
```

- `speaker` は部分一致のため `岸田` だけでも該当するが、表記揺れ回避のためフルネーム推奨

### 2. 特定キーワードを含む参議院の審議を時系列で取得

```text
GET /api/speech?any=マイナンバー&nameOfHouse=参議院&from=2023-01-01&recordPacking=json&maximumRecords=100
```

- `any` は **AND 検索**。`any=マイナンバー 個人情報` とすると両方を含む発言のみヒット

### 3. 特定会期の予算委員会の会議一覧

```text
GET /api/meeting_list?sessionFrom=213&sessionTo=213&nameOfMeeting=予算委員会&recordPacking=json
```

- `nameOfMeeting` は OR 検索。委員会名の指定で十分な絞り込みが効く

### 4. 特定政党会派の発言抽出

```text
GET /api/speech?speakerGroup=自由民主党&from=2024-01-01&recordPacking=json
```

- `speakerGroup` は **正式名称のみ**。`自民党` などの略称ではヒット 0

### 5. 特定会議の全発言取得（ID 経由）

```text
# Step 1: meeting_list で issueID を特定
GET /api/meeting_list?nameOfMeeting=予算委員会&from=2024-03-01&until=2024-03-01&recordPacking=json

# Step 2: 取得した issueID で meeting を呼び全文取得
GET /api/meeting?issueID=<取得した21桁ID>&recordPacking=json
```

- 1 件あたりの応答が大きいため、対象会議を絞ってから `meeting` を呼ぶこと

### 6. 証人喚問・参考人質疑の抽出

```text
GET /api/speech?speakerRole=参考人&from=2024-01-01&recordPacking=json
```

- `speakerRole` は完全一致。`参考人質疑` などの長い文字列はヒットしない

---

## 主要エラーコード（抜粋）

公式仕様より、API が返す `errorCode` の主要例。詳細なエラーレスポンス形式は [api-reference.md](./api-reference.md#エラーレスポンス) を参照。

| コード | 内容 |
|---|---|
| `19004` | `startRecord` が範囲外 |
| `19005` | `maximumRecords` が `meeting_list` / `speech` の上限（100）を超過 |
| `19006` | `maximumRecords` が `meeting` の上限（10）を超過 |
| `19007` | 検索条件が 1 件も指定されていない |
| `19011` | 入力誤り（型不一致など総合的なエラー） |
| `19012`〜`19020` | 日付形式・値の妥当性、入力文字数超過などの個別エラー |

---

## 注意点

- **クエリ全長 2,000 バイト上限**: 日本語パラメータは URL エンコードで 1 文字あたり 9 バイト（`%E3%81%82` 等）になりやすく、長文の `any` や複数の `speaker` で容易に上限に達する。長文時は文字数を試算する
- **議員名の表記揺れ**: 同一人物が `福島 みずほ` / `福島瑞穂` のように複数表記で登録される場合がある。漢字とひらがな双方の `speaker` クエリで結果件数を比較すると良い
- **会派名は正式名称のみ**: 党名の改称履歴も追う必要あり（例: 立憲民主党は結党時期で別法人）
- **日付未指定時の既定値が極端**: `from` 既定 `0000-01-01` / `until` 既定 `9999-12-31`。意図せず全期間検索になりがちなので、絞りたい場合は明示する
- **`closing` 既定 `false` の意味**: 既定では閉会中審査も検索対象に**含まれる**。`true` を指定すると逆に閉会中審査に**限定**される（包含・除外ではなく限定）
