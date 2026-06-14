---
name: oldest-speech-by-speaker
description: API の降順固定下で from/until を狭めて最古発言を探すレシピ
---

# 議員の特定期間における最古発言の特定

## 目的

`maximumRecords` で部分取得した結果は会議開催日の **降順** で返るため、最古発言を確定するには `from`/`until` で範囲を狭めて 1 件取得するパターンが必要。API のソート順仕様は [api-reference.md「結果の返却順」](../api-reference.md#結果の返却順) を参照。

## スニペット

```powershell
# Step 1: 議員の全ヒット件数を確認
$probeJson = bash scripts/search-by-speaker.sh 松岡克由 1971-01-01 1975-12-31 1
$total = ($probeJson | ConvertFrom-Json).numberOfRecords
Write-Host "Total records: $total"

# Step 2: 1 年単位で from/until を狭めて最古を探す（降順なので末尾ページに最古がある）
# 簡便な方法: until を毎回過去側にずらして 1 件取得 → 該当年範囲に当たれば最新側からの 1 件 = その範囲の最新
# 最古を確定するには until を段階的に下げる
Start-Sleep -Seconds 3
$oldestProbe = bash scripts/search-by-speaker.sh 松岡克由 1971-01-01 1973-12-31 1
$oldestDate = ($oldestProbe | ConvertFrom-Json).speechRecord[0].date
Write-Host "1971-1973 range, newest record date: $oldestDate"
# 結果が 1973-07-17 などなら、その年以前にはヒットなし → 1973-07-17 が最古候補
```

## 補足

- 完全な最古確定にはページネーションで末尾まで取得する手もある（`startRecord` を `numberOfRecords - limit + 1` に設定）
- 上記スニペットは「年単位での絞り込み + 1 件取得」で実用的に最古に近い値を得る発想

## 関連

- [recipes 索引](../recipes.md)
- [api-reference.md「結果の返却順」](../api-reference.md#結果の返却順)
- [scripts/README.md](../../scripts/README.md)
