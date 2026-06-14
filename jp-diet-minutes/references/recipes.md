---
name: Kokkai (National Diet) Minutes Recipes
description: 国会会議録検索システム API V2 wrapper scripts では covers できない複合パターンのスニペット集
---

# 国会会議録検索 recipe 集

`jp-diet-minutes/scripts/` の wrapper では covers できない複合パターン（会議内の議員 × キーワード絞り込み、最古発言の特定、答弁ペア抽出など）のスニペット集。各 recipe は wrapper を呼び出す前提で書かれている。

実行環境は Claude Code の Bash / PowerShell tool を想定。レート制限の都合上、API 呼び出しは 2〜3 秒以上の間隔を空けること。

---

## 会議内の議員 × キーワード絞り込み

### 目的

特定の会議（`issueID` 確定済み）の `speechRecord[]` に対し、議員名と発言本文のキーワードでクライアント側絞り込みを行う。`speech` エンドポイントの `any` 検索で発言が大量にヒットする時の二次絞り込みや、過去質疑の引用元特定に有用。

### スニペット

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

### 補足

- `speech -match` は PowerShell の正規表現マッチ。OR 検索は `|` で連結
- `meeting` の `speechRecord[]` は `speech` / `speaker` / `speechOrder` 等の全フィールドを持つ
- bash 版は `jq` で同等の絞り込みが可能（`jq '.meetingRecord[0].speechRecord[] | select(.speaker=="X" and (.speech | test("Y")))'`）

---

## 議員の特定期間における最古発言の特定

### 最古発言: 目的

`maximumRecords` で部分取得した結果は会議開催日の **降順** で返るため、最古発言を確定するには `from`/`until` で範囲を狭めて 1 件取得するパターンが必要。API のソート順仕様は [api-reference.md「結果の返却順」](api-reference.md#結果の返却順) を参照。

### 最古発言: スニペット

```powershell
# Step 1: 議員の全ヒット件数を確認
$probeJson = bash scripts/search-by-speaker.sh 松岡克由 1971-01-01 1975-12-31 1
$total = ($probeJson | ConvertFrom-Json).numberOfRecords
Write-Host "Total records: $total"

# Step 2: 1 年単位で from/until を狭めて最古を探す（降順なので末尾ページに最古がある）
# 簡便な方法: until を毎回過去側にずらして 1 件取得 → 該当年範囲に当たれば最新側からの 1 件 = その範囲の最新
# 最古を確定するには untilを段階的に下げる
Start-Sleep -Seconds 3
$oldestProbe = bash scripts/search-by-speaker.sh 松岡克由 1971-01-01 1973-12-31 1
$oldestDate = ($oldestProbe | ConvertFrom-Json).speechRecord[0].date
Write-Host "1971-1973 range, newest record date: $oldestDate"
# 結果が 1973-07-17 などなら、その年以前にはヒットなし → 1973-07-17 が最古候補
```

### 最古発言: 補足

- 完全な最古確定にはページネーションで末尾まで取得する手もある（`startRecord` を `numberOfRecords - limit + 1` に設定）
- 上記スニペットは「年単位での絞り込み + 1 件取得」で実用的に最古に近い値を得る発想

---

## 同一会議内の質問者 → 答弁者ペア抽出

### 答弁ペア: 目的

`meeting` 全文から、質問者（議員）→ 答弁者（大臣等、`speakerPosition` で識別）の隣接ペアを抽出する。委員会審議の Q&A 構造を可視化するときに有用。

### 答弁ペア: スニペット

```powershell
# Step 1: 会議全文取得
$meetingJson = bash scripts/fetch-meeting.sh 121405254X00220241004
$records = ($meetingJson | ConvertFrom-Json).meetingRecord[0].speechRecord

# Step 2: speakerPosition が空でない発言（答弁者）を探し、直前の発言（質問者）とペア化
for ($i = 1; $i -lt $records.Count; $i++) {
  if ($records[$i].speakerPosition -and -not $records[$i-1].speakerPosition) {
    [PSCustomObject]@{
      speechOrder = $records[$i-1].speechOrder
      questioner = $records[$i-1].speaker
      respondent = "$($records[$i].speaker)($($records[$i].speakerPosition))"
      qExcerpt = $records[$i-1].speech.Substring(0, [Math]::Min(100, $records[$i-1].speech.Length))
    }
  }
}
```

### 答弁ペア: 補足

- `speakerPosition` は答弁者（内閣総理大臣・各省大臣・参考人等）に設定される
- 議員（質問者）の `speakerPosition` は通常空文字
- 「直前の発言が議員、現在の発言が答弁者」を Q→A ペアの近似として扱う簡易ヒューリスティック

---

## 関連リソース

- [SKILL.md](../SKILL.md): skill 全体の使い方
- [api-reference.md](./api-reference.md): API 仕様（ソート順、ページネーション等）
- [parameters.md](./parameters.md): パラメータ詳細
- [response-format.md](./response-format.md): レスポンス構造
- [scripts/README.md](../scripts/README.md): wrapper script 一覧
