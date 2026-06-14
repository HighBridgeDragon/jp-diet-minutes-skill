---
name: meeting-speaker-keyword-filter
description: 特定会議の speechRecord[] を議員名と発言本文キーワードでクライアント側絞り込みするレシピ
---

# 会議内の議員 × キーワード絞り込み

## 目的

特定の会議（`issueID` 確定済み）の `speechRecord[]` に対し、議員名と発言本文のキーワードでクライアント側絞り込みを行う。`speech` エンドポイントの `any` 検索で発言が大量にヒットする時の二次絞り込みや、過去質疑の引用元特定に有用。

## スニペット

```powershell
# Step 1: 対象会議の issueID を特定（事前に確定済みの場合は省略可）
$listJson = bash scripts/list-meetings.sh 逓信委員会 1974-03-26 1974-03-26
$issueID = ($listJson | ConvertFrom-Json).meetingRecord[0].issueID

# Step 2: 会議全文取得
Start-Sleep -Seconds 3
$meetingJson = bash scripts/fetch-meeting.sh $issueID
$m = ($meetingJson | ConvertFrom-Json).meetingRecord[0]

# Step 3: クライアント側絞り込み（議員 × キーワード）
$m.speechRecord |
  Where-Object { $_.speaker -eq '松岡克由' -and $_.speech -match '前田|値上げ|甘い' } |
  Select-Object speechOrder, @{n='excerpt';e={$_.speech.Substring(0,200)}}
```

## 補足

- `speech -match` は PowerShell の正規表現マッチ。OR 検索は `|` で連結
- `meeting` の `speechRecord[]` は `speech` / `speaker` / `speechOrder` 等の全フィールドを持つ
- bash 版は `jq` で同等の絞り込みが可能（`jq '.meetingRecord[0].speechRecord[] | select(.speaker=="X" and (.speech | test("Y")))'`）

## 関連

- [recipes 索引](../recipes.md)
- [api-reference.md](../api-reference.md)
- [scripts/README.md](../../scripts/README.md)
