---
name: jp-diet-minutes
description: Search and retrieve Japanese National Diet (国会) meeting minutes via the official NDL Kokkai API (no auth required). Covers all post-WWII Diet sessions, supports keyword search, speaker lookup, meeting-level retrieval, and date/session/issue filtering. Useful for political research, legislative tracking, speech analysis, and any task involving Japanese parliamentary records. 戦後の日本の国会議事録を NDL 国会会議録検索システム API 経由で検索・取得するスキル。発言・会議・キーワード検索および期間/回次/会派による絞り込みに対応。Use this skill when researching Japanese Diet debates, MP statements, or parliamentary records.
license: MIT
metadata:
  version: "0.1.0"
---

# 国会会議録検索スキル

NDL（国立国会図書館）の国会会議録検索システム API 経由で戦後の日本の国会議事録を調査する。認証不要。HTTPS GET でアクセス可能なフェッチツール（`mcp-server-fetch`, Claude Code の `WebFetch`, 他の MCP 対応 fetch ツール）が 1 つあれば動作する。

帝国議会会議録（戦前）は別 API のため対象外。

## 基本ルール

- Base URL: `https://kokkai.ndl.go.jp/api/`
- レスポンス形式: クエリパラメータ `recordPacking=json` 推奨（既定は XML）
- 認証: 不要
- 呼び出し方法: フェッチツールで URL を直接 GET（クエリ文字列で日本語可、自動 URL エンコード）
- レート制限: 公式に「機械的アクセス時は多重リクエスト禁止、数秒間隔を空ける」と明記。並列化禁止、連続呼び出しは 2〜3 秒間隔目安
- クエリ全長 2,000 バイト上限（日本語は URL エンコードで 1 文字 9 バイト換算）

## エンドポイント選択

ユーザーの要求に応じて適切なエンドポイントを選ぶ。**情報量と消費トークンは `meeting_list` < `speech` < `meeting` の順で増える** ため、軽い方から段階的に絞ること。

```text
「○○議員の発言を見せて」「△△に関する発言を探して」
  → GET https://kokkai.ndl.go.jp/api/speech?speaker=○○&recordPacking=json
  → GET https://kokkai.ndl.go.jp/api/speech?any=△△&recordPacking=json
  ※ speech は発言単位。会議メタも各 record にフラット展開される

「○○委員会の会議一覧を見せて」「YYYY 年の本会議を一覧で」
  → GET https://kokkai.ndl.go.jp/api/meeting_list?nameOfMeeting=○○&recordPacking=json
  → GET https://kokkai.ndl.go.jp/api/meeting_list?from=YYYY-01-01&until=YYYY-12-31&recordPacking=json
  ※ 軽量。会議メタのみ返却(発言本文は含まない)

「特定の会議の全発言を見せて」「○○委員会 YYYY-MM-DD の議事録全文」
  → Step 1: meeting_list で対象会議の issueID を特定
  → Step 2: GET https://kokkai.ndl.go.jp/api/meeting?issueID=<21桁ID>&recordPacking=json
  ※ meeting は 1 リクエストで会議全文が返るため大きい。必ず絞ってから呼ぶ

「議案ごとの審議経過を追って」「△△法案の質疑を時系列で」
  → GET https://kokkai.ndl.go.jp/api/speech?any=△△法案&from=YYYY-MM-DD&recordPacking=json
  ※ any は AND 検索(スペース区切り複数語は全て含む条件)

「○○会派の議員の発言を抽出」
  → GET https://kokkai.ndl.go.jp/api/speech?speakerGroup=○○&recordPacking=json
  ※ speakerGroup は正式名称のみ(略称ヒットしない。例: 自由民主党 ✅ / 自民党 ❌)
```

詳細は [api-reference.md](references/api-reference.md), [parameters.md](references/parameters.md), [response-format.md](references/response-format.md) を参照。

## 各エンドポイントの使い方

### 1. `speech` — 発言単位検索（最頻用）

検索条件にヒットした発言のみ返す。トークン効率が最も良い。

```text
# 議員名で発言抽出(部分一致 OR)
GET https://kokkai.ndl.go.jp/api/speech?speaker=岸田文雄&from=2024-01-01&until=2024-12-31&maximumRecords=100&recordPacking=json

# キーワード AND 検索(空白区切りは `+` または `%20` でエンコード)
GET https://kokkai.ndl.go.jp/api/speech?any=マイナンバー+個人情報&nameOfHouse=参議院&recordPacking=json

# 会派指定(正式名称のみ)
GET https://kokkai.ndl.go.jp/api/speech?speakerGroup=自由民主党&from=2024-01-01&recordPacking=json
```

主要パラメータ: `speaker`（発言者・OR 部分一致）, `any`（全文・AND 部分一致）, `speakerGroup`（会派・部分一致 ※DB 上は正式名称で格納されているため、部分一致でも略称ではヒットしない）, `from`/`until`（YYYY-MM-DD 範囲）, `nameOfHouse`（列挙: 衆議院/参議院/両院/両院協議会）, `maximumRecords`（1〜100、既定 30）。

レスポンスは `speechRecord[]` 配列。各要素に会議メタ（`issueID`, `session`, `nameOfHouse`, `nameOfMeeting`, `date` 等）がフラット展開されている。

### 2. `meeting_list` — 会議一覧（軽量索引）

会議メタ情報のみ返す。発言本文は含まれないため一覧生成・絞り込みに向く。

```text
# 特定会期の予算委員会一覧
GET https://kokkai.ndl.go.jp/api/meeting_list?sessionFrom=213&sessionTo=213&nameOfMeeting=予算委員会&recordPacking=json

# 特定日の全会議
GET https://kokkai.ndl.go.jp/api/meeting_list?from=2024-10-04&until=2024-10-04&recordPacking=json
```

主要パラメータ: `nameOfMeeting`（会議名・OR 部分一致）, `sessionFrom`/`sessionTo`（回次範囲）, `from`/`until`（日付範囲）, `maximumRecords`（1〜100、既定 30）。

レスポンスは `meetingRecord[]`。各要素配下の `speechRecord[]` は **発言メタの最小集合のみ**（`speechID`, `speechOrder`, `speaker`, `speechURL`）。本文取得には `speech` または `meeting` を呼ぶ。

### 3. `meeting` — 会議全文（最終手段）

会議全文を返す。1 リクエストで全発言が返るため重い。`maximumRecords` 上限が他より小さい（1〜10、既定 3）のはこの理由。

```text
# issueID で会議全文取得(推奨)
GET https://kokkai.ndl.go.jp/api/meeting?issueID=121405254X00220241004&recordPacking=json
```

`meeting_list` または `speech` で `issueID` を特定してから呼ぶこと。`meeting` の `speechRecord[]` は全フィールド完備（`speech`, `speakerYomi`, `speakerGroup`, `speakerPosition`, `speakerRole`, `startPage`, `createTime`/`updateTime`）。

## トークン節約ガイダンス

`meeting` は 1 会議で数百 KB〜MB 規模になる。順守事項:

1. **`speech` を優先する**: 発言単位なら必要な部分だけ取れる。`meeting` はユーザーが明示的に「会議全文」を要求した場合のみ
2. **`recordPacking=json` を必ず指定**: XML より構造が扱いやすい上、データ量も若干小さい
3. **`maximumRecords` を明示**: 既定 30 で十分な場合は省略可。多数取得時は上限（speech/meeting_list: 100、meeting: 10）まで上げてリクエスト総数を減らす
4. **2 段階検索を使う**: まず `meeting_list` または `speech` で対象を絞り込み、`issueID` を取得 → 必要に応じて `meeting` で全文。最初から `meeting` を打たない
5. **ヒット 0 件時のリトライは表記揺れを試す**: 議員名は `福島 みずほ` / `福島瑞穂` / ひらがなを順に試す。会派名は **必ず正式名称**（`自民党` ❌ / `自由民主党` ✅）

## 結果フィルタリングの落とし穴

レスポンス取得後、以下の点に注意:

1. **`speechOrder` が `0` の行は会議録情報ヘッダ**: 議事日程・付議案件などの構造情報で、実発言ではない。`speaker` は固定で `会議録情報`。発言集計時は `speechOrder` が `0` の行を除外する
2. **`imageKind` の値**: 既定では `会議録` のほかに `目次` / `索引` / `附録` / `追録` も混入する。発言抽出時は `imageKind` の値が `会議録` の行のみに絞り込む（リクエストパラメータ `contentsAndIndex` / `supplementAndAppendix` はいずれも既定 `false` のため通常は省略可。明示的に混入させたい場合のみ `true` を指定する）
3. **`closing` は `false` ではなく `null` を返す**: 閉会中フラグが立っていない通常会議では `null`。閉会中審査の判定は `closing` の値が `true` の場合のみで行う（`false` との比較ではなく `true` との比較を使うこと）
4. **`nameOfHouse` の不正値は silently 無視される**: HTTP 200 でフィルタ未適用の結果が返る。意図が反映されているか `numberOfRecords` の妥当性で確認すること
5. **発言本文の改行は CRLF (`\r\n`)**: LF のみではない。テキスト処理時は正規化が必要な場合あり
6. **`speech` のレスポンス構造はフラット**: `meeting` のような `meetingRecord` ラッパは持たない。共通パーサを書くなら分岐が必要

## よく使う検索パターン例

### 議員の特定期間の発言

```text
GET https://kokkai.ndl.go.jp/api/speech?speaker=石破茂&from=2024-10-01&until=2024-10-31&maximumRecords=100&recordPacking=json
```

### 法案審議の追跡（時系列）

```text
GET https://kokkai.ndl.go.jp/api/speech?any=マイナンバー法&from=2023-01-01&recordPacking=json&maximumRecords=100
```

### 内閣総理大臣演説の抽出

```text
GET https://kokkai.ndl.go.jp/api/speech?speakerPosition=内閣総理大臣&nameOfMeeting=本会議&from=2024-01-01&recordPacking=json
```

### 参考人質疑

```text
GET https://kokkai.ndl.go.jp/api/speech?speakerRole=参考人&from=2024-01-01&recordPacking=json
```

### 特定会議の議事全文（2 段階）

```text
# Step 1: issueID 特定
GET https://kokkai.ndl.go.jp/api/meeting_list?nameOfMeeting=予算委員会&nameOfHouse=衆議院&from=2024-03-01&until=2024-03-01&recordPacking=json

# Step 2: 全文取得
GET https://kokkai.ndl.go.jp/api/meeting?issueID=<上記で取得した21桁ID>&recordPacking=json
```

## ページネーション

全エンドポイント共通。

- レスポンスの `nextRecordPosition` を次回リクエストの `startRecord` に渡す
- 最終ページの判定:
  - JSON: `nextRecordPosition` の値が `null`
  - XML: `<nextRecordPosition>` 要素自体が欠落
- 連続取得時は数秒間隔を空ける（レート制限）

## 出力フォーマット

ユーザーに発言を提示する際の推奨フォーマット:

```text
【発言者】○○○○（所属会派・肩書き）
【会議】第XXX回国会 衆議院 ○○委員会 第X号（YYYY-MM-DD）
【発言】
発言本文の引用(CRLF を改行に正規化)

【出典】国会会議録検索システム https://kokkai.ndl.go.jp/txt/<issueID>/<speechOrder>
```

会議一覧を提示する際:

```text
【会議一覧】N 件
- YYYY-MM-DD: 第XXX回国会 衆議院 ○○委員会 第X号
  https://kokkai.ndl.go.jp/txt/<issueID>
- ...
```

## 詳細リファレンス

- [api-reference.md](references/api-reference.md): エンドポイント仕様・ページネーション・エラーレスポンス
- [parameters.md](references/parameters.md): 検索パラメータの完全な仕様・検索方式・組み合わせ例
- [response-format.md](references/response-format.md): レスポンス構造・実 JSON サンプル・実測ベースの落とし穴
