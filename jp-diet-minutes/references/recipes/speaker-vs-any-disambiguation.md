---
name: speaker-vs-any-disambiguation
description: any（発言本文）と speaker（発言者属性）を意図別に使い分けるレシピ。両者を併用すると積集合になる相互作用の回避と意図的活用
---

# `speaker` / `any` の使い分け — 議員 A をどう検索するか

## 目的

「議員 A」を起点にした検索には、検索対象軸が異なる 3 つの典型意図がある。`speaker`（発言者属性）と `any`（発言本文）はそれぞれ別の軸を絞り込むため、**両者を併用すると積集合（intersection）** になり、件数が大幅に減る（実測: `speaker=石原慎太郎` 単独 2,098 件 → 両者併用 647 件）。

意図ごとに片方だけを使うのが原則。両者の併用は 3 番目の自己言及パターンでのみ意図的に活用する。

公式仕様（<https://kokkai.ndl.go.jp/api.html>）には `any` 単独・`speaker` 単独の挙動のみ明示されており、両者の併用挙動は記載がない。本相互作用は実測ベース。

## 3 つの使い分けパターン

### 1. 議員 A の **全発言** を取得

A 本人が話したすべての発言が対象。第三者が A について言及した発言は含めない。

→ `speaker=A` 単独（`any` を併用しない）

```bash
# 例: 石原慎太郎の全発言
bash scripts/search-by-speaker.sh 石原慎太郎 '' '' 100 --sort date-desc
```

実測ベースライン: `numberOfRecords` = 2,098 件（2026-06-16 観測）。

### 2. 議員 A への **言及** を取得（第三者の発言を含む）

「A について誰が・どう発言したか」を調べたい場合。A 本人の発言と、第三者が A について語った発言の両方が対象。

→ `any=A` 単独（`speaker` を併用しない）

```bash
# 例: 石原慎太郎への言及（自他問わず）
bash scripts/search-by-keyword.sh 石原慎太郎 '' '' 100 --sort date-desc
```

実測ベースライン: `numberOfRecords` = 2,143 件（2026-06-16 観測）。パターン 1 とパターン 2 はおおむね同程度の件数になりがちだが、**両者は別母集団**（パターン 1 は本人発言の集合、パターン 2 は名前を含む全発言の集合）であることに注意。

### 3. 議員 A 本人の **自己言及** に限定

A 本人が、自分の名前を発言本文に含めて話した発言。所信表明・自己紹介・反論時の自己引用などの場面の抽出に有用。

→ `speaker=A&any=A` の積集合を意図的に活用（wrapper 非対応のため raw curl）

```bash
# 例: 石原慎太郎本人が「石原慎太郎」を発言したケース
curl -s 'https://kokkai.ndl.go.jp/api/speech?speaker=%E7%9F%B3%E5%8E%9F%E6%85%8E%E5%A4%AA%E9%83%8E&any=%E7%9F%B3%E5%8E%9F%E6%85%8E%E5%A4%AA%E9%83%8E&maximumRecords=100&recordPacking=json'
```

実測: `numberOfRecords` = 647 件（2026-06-16 観測）。パターン 1（2,098 件）の約 31% に絞られる。

## 補足

- wrapper script は `search-by-speaker.sh`（`speaker` パラメータ）と `search-by-keyword.sh`（`any` パラメータ）が分離されており、片方の wrapper を呼ぶ限りパターン 1 / 2 の取り違えは起こらない設計
- パターン 3 のみ wrapper が covers しないため raw curl が必要。URL エンコードは `python -c "import urllib.parse; print(urllib.parse.quote('石原慎太郎'))"` などで生成する
- 「議員 A の発言で B について語ったもの」（A が発言者、B が本文）を取得したい場合は `speaker=A&any=B` の併用が正しい。これも積集合だが、軸が異なるため意図通りの絞り込みになる

## 関連

- [parameters.md#複数パラメータの併用と相互作用](../parameters.md#複数パラメータの併用と相互作用)
- [recipes 索引](../recipes.md)
- [SKILL.md 結果フィルタリングの落とし穴](../../SKILL.md#結果フィルタリングの落とし穴)
- [scripts/README.md](../../scripts/README.md)
