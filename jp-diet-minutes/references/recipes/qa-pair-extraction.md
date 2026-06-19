---
name: qa-pair-extraction
description: meeting 全文の speechRecord[] から speakerPosition を識別子に Q&A ペアを抽出するレシピ
---

# 同一会議内の質問者 → 答弁者ペア抽出

## 目的

`meeting` 全文から、質問者（議員）→ 答弁者（大臣等、`speakerPosition` で識別）の隣接ペアを抽出する。委員会審議の Q&A 構造を可視化するときに有用。

## スニペット

```bash
# Step 1: 会議全文取得
meetingJson=$(bash scripts/fetch-meeting.sh 121405254X00220241004)

# Step 2: speakerPosition が空でない発言（答弁者）を探し、直前の発言（質問者）とペア化
echo "$meetingJson" \
  | jq -r '.meetingRecord[0].speechRecord as $r
      | range(1; $r | length) as $i
      | select($r[$i].speakerPosition != null and $r[$i-1].speakerPosition == null)
      | {
          speechOrder: $r[$i-1].speechOrder,
          questioner: $r[$i-1].speaker,
          respondent: "\($r[$i].speaker)(\($r[$i].speakerPosition))",
          qExcerpt: ($r[$i-1].speech[0:100])
        }'
```

## 補足

- `speakerPosition` は答弁者（内閣総理大臣・各省大臣・参考人等）に設定される
- 議員（質問者）の `speakerPosition` は通常 `null`（API の実測値。空文字 `""` ではなく `null` が返る）。上記 `jq` は `== ""` ではなく `== null` で判定している（空文字判定では取りこぼす）
- `.speech[0:100]` は `jq` の文字列スライス。本文が 100 文字未満でも安全に切り出せる（末尾まで返る）
- 「直前の発言が議員、現在の発言が答弁者」を Q→A ペアの近似として扱う簡易ヒューリスティック

## 関連

- [recipes 索引](../recipes.md)
- [response-format.md](../response-format.md)
- [scripts/README.md](../../scripts/README.md)
