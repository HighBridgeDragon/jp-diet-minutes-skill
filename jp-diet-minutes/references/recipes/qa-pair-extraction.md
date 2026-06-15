---
name: qa-pair-extraction
description: meeting 全文の speechRecord[] から speakerPosition を識別子に Q&A ペアを抽出するレシピ
---

# 同一会議内の質問者 → 答弁者ペア抽出

## 目的

`meeting` 全文から、質問者（議員）→ 答弁者（大臣等、`speakerPosition` で識別）の隣接ペアを抽出する。委員会審議の Q&A 構造を可視化するときに有用。

## スニペット

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

## 補足

- `speakerPosition` は答弁者（内閣総理大臣・各省大臣・参考人等）に設定される
- 議員（質問者）の `speakerPosition` は通常 `null`（API の実測値。空文字 `""` ではなく `null` が返る）。bash/jq で同等処理を書く場合は `== ""` ではなく `== null` で判定すること
- 「直前の発言が議員、現在の発言が答弁者」を Q→A ペアの近似として扱う簡易ヒューリスティック

## 関連

- [recipes 索引](../recipes.md)
- [response-format.md](../response-format.md)
- [scripts/README.md](../../scripts/README.md)
