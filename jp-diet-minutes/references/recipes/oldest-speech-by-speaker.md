---
name: oldest-speech-by-speaker
description: 議員の最古発言を 1 コマンドで確定するレシピ。同日内 speechOrder 昇順の二次ソート (実測ベース) を考慮した手順
---

# 議員の最古発言の特定（1 コマンド確定パターン）

## 目的

API のソート順は会議開催日の降順固定で、`maximumRecords` 部分取得は新しい側 N 件のみが返る。加えて **同日内（同一会議内）は `speechOrder` 昇順** で返る（実測ベース、公式仕様未掲載）。期間を絞らず `startRecord=<numberOfRecords>&maximumRecords=1` で末尾を直撃する従来手法は、降順固定により期間内最古日付の **同日最終発言** (`speechOrder` 最大) を返し、真の初発言を逃す。

本 recipe は wrapper script の `--sort date-asc,speech-order-asc`（`jq` 経由のクライアント側ソート）を活用して、1 コマンドで真の最古発言を確定するパターン。API のソート順仕様と同日内二次ソートの実測根拠は [api-reference.md「結果の返却順」](../api-reference.md#結果の返却順) を参照。

## 手順

### Step 1: 議員の総ヒット件数を確認

```bash
bash scripts/search-by-speaker.sh 松岡克由 '' '' 1 --sort date-desc | jq '.numberOfRecords'
```

### Step 2: `from`/`until` を狭めて `numberOfRecords ≤ 100` まで絞る

`maximumRecords` の上限は 100。期間内全件を 1 リクエストで取得するために、`from`/`until` を年単位等で狭めて `numberOfRecords ≤ 100` まで絞る:

```bash
# 1970 年代に絞る
bash scripts/search-by-speaker.sh 松岡克由 1970-01-01 1979-12-31 1 --sort date-desc | jq '.numberOfRecords'
# まだ 100 を超えるなら年単位でさらに狭める
bash scripts/search-by-speaker.sh 松岡克由 1972-01-01 1972-12-31 1 --sort date-desc | jq '.numberOfRecords'
```

### Step 3: 全件取得 + `--sort date-asc,speech-order-asc` で真の最古を 1 コマンド確定

`maximumRecords` を `numberOfRecords` 以上（最大 100）に設定して全件取得し、wrapper の `--sort date-asc,speech-order-asc` で **日付昇順 + 同日内 `speechOrder` 昇順** の二重キーソート。先頭 1 件が真の最古発言:

```bash
bash scripts/search-by-speaker.sh 松岡克由 1972-01-01 1972-12-31 100 --sort date-asc,speech-order-asc \
  | jq '.speechRecord[0] | {date, speechOrder, nameOfMeeting, speaker}'
```

実測結果 (松岡克由の 1972 年最古発言):

```json
{
  "date": "1972-06-08",
  "speechOrder": 32,
  "nameOfMeeting": "逓信委員会",
  "speaker": "松岡克由"
}
```

## なぜ `--sort date-asc,speech-order-asc` が必要か

API は会議開催日の降順固定で、同日内は `speechOrder` 昇順（実測）。期間を絞らず `startRecord=<numberOfRecords>&maximumRecords=1` で末尾を直撃する従来手法では:

- API 降順固定により末尾 = 期間内最古日付の **最終発言**（同日 `speechOrder` 最大）を取得 ← 真の初発言ではない

実証: 松岡克由 (全期間) で `numberOfRecords=N` だった場合、`startRecord=N&maximumRecords=1` は期間内最古日付 1972-06-08 の `speechOrder=51` (同日最終発言) を返す。`--sort date-asc,speech-order-asc` でクライアント側ソートをかけることで、`speechOrder=32` の真の初発言が先頭に来る。

なお、最古日付を別途確定して `from=oldest-date&until=oldest-date&maximumRecords=1` で 1 日に絞れば、API 降順は同日内の二次キー (昇順) に影響しないため `speechOrder=32` の真の初発言が取れる。ただし最古日付の事前確定が別途必要で、本 recipe の `--sort date-asc,speech-order-asc` の方が手数が少ない。

## 補足

- `--sort` は本 skill の wrapper が必須化しているクライアント側ソート（`jq` 経由、`search-by-*.sh` / `list-meetings.sh` で必須）。詳細は [scripts/README.md](../../scripts/README.md) を参照
- `numberOfRecords > 100` の期間で最古を確定したい場合は `from`/`until` を狭めるのが基本。どうしても狭められない場合は raw curl で `startRecord=<numberOfRecords>` を打って末尾 1 件を取得する方法もあるが、その場合も同日内 `speechOrder` 最大の最終発言を取得することになる点に注意（その日の全件を別途取得して `speechOrder` 最小を採用する追加クエリが必要）

## 関連

- [recipes 索引](../recipes.md)
- [api-reference.md「結果の返却順」](../api-reference.md#結果の返却順)
- [SKILL.md 結果フィルタリングの落とし穴](../../SKILL.md#結果フィルタリングの落とし穴)
- [scripts/README.md](../../scripts/README.md)
