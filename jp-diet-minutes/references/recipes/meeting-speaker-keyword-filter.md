---
name: meeting-speaker-keyword-filter
description: 特定会議の speechRecord[] を議員名と発言本文キーワードでクライアント側絞り込みするレシピ
---

# 会議内の議員 × キーワード絞り込み

## 目的

特定の会議（`issueID` 確定済み）の `speechRecord[]` に対し、議員名と発言本文のキーワードでクライアント側絞り込みを行う。`speech` エンドポイントの `any` 検索で発言が大量にヒットする時の二次絞り込みや、過去質疑の引用元特定に有用。

## スニペット

```bash
# Step 1: 対象会議の issueID を特定（事前に確定済みの場合は省略可）
issueID=$(bash scripts/list-meetings.sh 逓信委員会 1974-03-26 1974-03-26 1 --sort date-desc \
  | jq -r '.meetingRecord[0].issueID')

# Step 2: 会議全文取得
sleep 3
meetingJson=$(bash scripts/fetch-meeting.sh "$issueID")

# Step 3: クライアント側絞り込み（議員 × キーワード）
echo "$meetingJson" \
  | jq '.meetingRecord[0].speechRecord[]
        | select(.speaker == "松岡克由" and (.speech | test("前田|値上げ|甘い")))
        | {speechOrder, excerpt: .speech[0:200]}'
```

## 補足

- `.speech | test("前田|値上げ|甘い")` は `jq` の正規表現マッチ。OR 検索は `|` で連結
- `.speech[0:200]` は `jq` の文字列スライス。本文が 200 文字未満でも安全に切り出せる（末尾まで返る）
- `meeting` の `speechRecord[]` は `speech` / `speaker` / `speechOrder` 等の全フィールドを持つ
- `list-meetings.sh` は `--sort` 必須。単一会議の `issueID` 特定では順序は結果に影響しないため `date-desc` を指定している

## 関連

- [recipes 索引](../recipes.md)
- [api-reference.md](../api-reference.md)
- [scripts/README.md](../../scripts/README.md)
