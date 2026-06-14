---
name: wrapper-scripts-design
description: jp-diet-minutes skill を wrapper-script ベースに刷新する設計仕様。jp-law skill の薄ラッパパターンを踏襲し、WebFetch ハルシネーション・ソート順誤読・recipe 散逸の 3 種の UX 問題を構造的に解決する。
date: 2026-06-14
status: approved
related_issues:
  - https://github.com/HighBridgeDragon/jp-diet-minutes-skill/issues/37
  - https://github.com/HighBridgeDragon/jp-diet-minutes-skill/issues/38
  - https://github.com/HighBridgeDragon/jp-diet-minutes-skill/issues/39
---

# jp-diet-minutes wrapper-scripts 設計

## 1. 背景と動機

### 1.1 観測された UX 問題

実セッション（2026-06-14「松岡克由」調査）で、本 skill が議事録調査用途を達成する過程で 3 種の UX 失敗が観測された:

1. **擬装フィールド hallucination**: `WebFetch` 経由で `speech` / `meeting` を呼び出した際、API 仕様に存在しない `summary` / `sampleSpeeches` / `notableSpeechCharacteristics` 等のフィールドが内部要約モデルにより生成され、あたかも API レスポンスのように返った（issue #37）
2. **レスポンス切り捨て**: `meeting` エンドポイント（数百 KB）を `WebFetch` で取得した際、`speechOrder=122` 付近で切り捨てられ、それ以降の発言を「該当なし」と誤判定した
3. **ソート順誤読による最古発言判定誤り**: `maximumRecords=10` の部分取得結果から「最古発言は 1975-03-27」と判定したが、API は会議開催日の **降順固定** で返すため、部分取得 10 件は期間内の **最新側 10 件** だった。実際には 1973-07-17 まで遡れた（issue #38）

### 1.2 根本原因

- (1) (2) は **`WebFetch` の選定ミス**（生データ取得に summarizing fetcher を使った）
- (3) は **公式仕様「検索結果のソート順は、会議開催日の新しい順となっています」をスキル本文が強調していなかった**

### 1.3 姉妹リポジトリの先行設計

`~/.claude/skills/jp-law/` の構成を確認したところ、本 skill と姉妹関係にある e-Gov 法令 skill は wrapper-script 設計を採用している:

- `scripts/` 配下に 6 スクリプト（API ラッパ 4 + ユーティリティ 2）
- 各スクリプトは 23〜27 行、`set -e` + URL エンコード + `recordPacking=json` 強制 + 1 行 curl
- 業務ロジック・JSON パース・ページネーション等の「賢さ」は持たず、徹底して薄い
- SKILL.md は `bash scripts/<name>.sh` 呼び出しを軸に書かれ、raw curl は corner case 1 箇所のみ
- 依存: `bash` + `curl` + `grep`/`sed`/`od`/`tr`（POSIX 系）

本設計は jp-law パターンに揃え、skill ファミリーの一貫性を保つ。

## 2. ゴール / 非ゴール

### 2.1 ゴール

- SKILL.md / references の構成を wrapper-first に書き換え、`WebFetch` の優先選定を構造的に抑制する
- 5 本の薄ラッパスクリプトを `jp-diet-minutes/scripts/` に追加し、議事録調査の主用途 5 種を 1 行で発行可能にする
- ソート順（降順固定）の挙動を SKILL.md と `references/api-reference.md` の双方に明記し、部分取得の解釈ミスを再発防止する
- 会議内の議員 × キーワード絞り込みなど、scripts では covers できない複合パターンを `references/recipes.md`（新規）に集約する

### 2.2 非ゴール

- 自動ページネーション（jp-law も実装しておらず、本 skill も `nextRecordPosition` の処理はドキュメントに留める）
- JSON パース / ビジネスロジックを wrapper に持たせる（薄ラッパ原則の堅持）
- `nameOfHouse` / `closing` / `contentsAndIndex` / `sessionFrom` 等の二次パラメータの wrapper 対応（必要時は raw curl で対応）
- skill のコード化（マークダウン中心 skill としての性質は維持）

## 3. 設計

### 3.1 スクリプト構成

`jp-diet-minutes/scripts/` 配下に 5 本の wrapper を新規追加する。

| スクリプト | エンドポイント | Usage | 既定 limit |
|---|---|---|---|
| `search-by-speaker.sh` | `GET /api/speech` | `<speaker_name> [from] [until] [limit]` | 30 |
| `search-by-keyword.sh` | `GET /api/speech` | `<keyword> [from] [until] [limit]` | 30 |
| `search-by-role.sh` | `GET /api/speech` | `<role> [from] [until] [limit]` | 30 |
| `list-meetings.sh` | `GET /api/meeting_list` | `<meeting_name> [from] [until] [limit]` | 30 |
| `fetch-meeting.sh` | `GET /api/meeting` | `<issueID>` | 1 |

#### 3.1.1 共通実装方針

- shebang `#!/bin/bash`、先頭で `set -e`
- 引数未指定時は `Usage:` を stderr に出して exit 1
- URL エンコード関数は jp-law の `urlencode()` をそのまま流用（`od`/`tr`/`grep` ベース、外部依存なし）
- 全スクリプトで `recordPacking=json` を強制クエリパラメータに含める（XML 既定値の事故防止）
- `from` / `until` / `limit` などの省略可能引数は positional、`[]` で囲んで Usage に明記
- `curl -s` でレスポンス body のみを stdout に出力（HTTP ステータスは body 内 `message` から判定）

#### 3.1.2 `search-by-role.sh` の引数バリデーション

`speakerRole` は API 側で `証人` / `参考人` / `公述人` 以外を HTTP 400 で弾く（`nameOfHouse` と異なる）。Skill 側で事前バリデーションは行わず、API のエラーメッセージをそのまま透過する（薄ラッパ原則）。

#### 3.1.3 `fetch-meeting.sh` の既定値

`issueID` は会議録を一意に識別するため、`maximumRecords` 既定値は 1 とする（API 既定の 3 だと帯域の無駄）。

### 3.2 SKILL.md 改訂方針

既存 SKILL.md（197 行）を以下の構造に書き換える。

#### 3.2.1 「基本ルール」の wrapper-first 化

`呼び出し方法` 項目を以下に書き換え:

> 呼び出し方法: `bash scripts/<script>.sh` を使う。`WebFetch` / `Invoke-RestMethod` 等の直接利用は、wrapper が covers しない corner case（後述「raw curl が必要なケース」参照）のみ。

#### 3.2.2 「エンドポイント選択」の再構成

3 エンドポイント軸 → スクリプト 5 本の用途別マッピングに書き換え。ユーザー要求の例文 → スクリプト呼び出し例の対応表を維持する。

#### 3.2.3 「結果フィルタリングの落とし穴」項目 7 の追加

issue #38 で訂正された内容を追記（SKILL.md へ追加するテキスト原案）:

```text
7. **API のソート順は「会議開催日の降順」で固定**: 公式仕様（https://kokkai.ndl.go.jp/api.html
   「2. 概要」）で並び順が降順保証されており、ソート指定パラメータは存在しない（speech /
   meeting_list / meeting いずれも同様）。便利な反面、maximumRecords で部分取得すると
   新しい側 N 件のみが返る。
   - 最新発言判定: 部分取得の先頭で OK（maximumRecords=1 で十分）
   - 最古発言判定: 部分取得結果から最古を断定しない。numberOfRecords 全件をページネーション
     末尾まで取得するか、from / until で年単位等に区切ってヒット件数 ≤ maximumRecords まで
     狭めてから判定する
```

#### 3.2.4 「raw curl が必要なケース」セクション新設

末尾に追加し、wrapper が covers しない以下を列挙:

- `sessionFrom` / `sessionTo`（回次絞り込み）
- `contentsAndIndex` / `supplementAndAppendix`（目次・索引・附録）
- `closing=true`（閉会中審査限定）
- `nameOfHouse` / `nameOfMeeting` 等の二次フィルタ（wrapper の引数に含めていない）
- ページネーション（`startRecord` + `nextRecordPosition` の連続呼び出し）

サンプルとして `sessionFrom` を使った 1 例を掲載。

### 3.3 references 更新

#### 3.3.1 `references/api-reference.md` 加筆

「ページネーション」節の直後に「結果の返却順」節を新設（api-reference.md へ追加するテキスト原案）:

```text
## 結果の返却順

公式仕様（https://kokkai.ndl.go.jp/api.html 「2. 概要」）に以下が明記されている:

> 検索結果のソート順は、会議開催日の新しい順となっています。

- speech / meeting_list / meeting 全エンドポイントで会議開催日の降順固定
- ソート指定パラメータ（sort / order / orderBy 等）は存在しない
- maximumRecords 部分取得は常に「期間内で最新側 N 件」を返すため、最古発言判定には
  ページネーション末尾まで取得するか from / until で範囲を狭める必要がある
```

#### 3.3.2 `references/response-format.md` 加筆

文書冒頭（H1 直後、最初の H2 として）に新規 H2 セクションを追加（response-format.md へ追加するテキスト原案）:

```text
## 注意: フェッチツール選定

WebFetch 等の内部要約モデルを介在させるツールで API を呼ぶと、レスポンスに存在しない
フィールド（summary / sampleSpeeches / notableSpeechCharacteristics 等）が hallucination
として混入する事象が観測されている。生データ取得は必ず bash scripts/<script>.sh、
または同等の生 HTTP 呼び出し（curl / Invoke-RestMethod）を用いること。
```

#### 3.3.3 `references/recipes.md`（新規）

`jp-diet-minutes/references/recipes.md` を新規追加。初版コンテンツ:

- 「会議内の議員 × キーワード絞り込み」（issue #39 の PowerShell スニペットを移植）
- 「議員の特定期間における最古発言の特定」（`from`/`until` を狭めて部分取得 1 件で判定するパターン）
- 「同一会議内の質問者 → 答弁者ペア抽出」（`speakerPosition` 併用例）

各 recipe フォーマット:

- `## 用途タイトル`
- `### 目的`（1〜2 文）
- `### スニペット`（PowerShell or bash コードブロック）
- `### 補足`（必要な場合のみ）

### 3.4 issues との対応関係

| Issue | 提案内容 | 本設計での対応 | 提案からの変更 |
|---|---|---|---|
| #37 | SKILL.md「クライアント実装の注意点」セクション追加 + response-format.md 注意書き | SKILL.md「基本ルール」で wrapper-first 規定により根本対処、response-format.md 注意書きはそのまま採用 | 「専用セクション追加」→「基本ルールに統合 + scripts による行動誘導」に格上げ |
| #38 | SKILL.md 落とし穴項目 7 追加 | そのまま採用 + api-reference.md に「結果の返却順」節新設 | issue body 訂正版（「順序保証なし」→「降順固定」）を採用、api-reference.md 加筆を追加 |
| #39 | SKILL.md 末尾の実装パターン例 or references/recipes.md 新規 | references/recipes.md 新規を採用 | issue 提案そのまま |

### 3.5 テスト戦略

- 各スクリプトに対し、実装 PR 内で smoke test を 1 リクエスト/スクリプト手動実施
- jp-law の `validate-law-ids.sh` 相当の自動テストは、jp-diet に対応する固定 ID テーブルがないため見送り
- CI の `markdown-lint.yml` は既存設定をそのまま使用（`filter_mode: added` により新規違反のみ検知）

### 3.6 配布

- skills marketplace 経由配布で `jp-diet-minutes/scripts/` 配下も同梱される（既存 jp-law と同様の取り扱い）
- `scripts/` には実行権限 (`+x`) を git に登録する

## 4. 実装順序

1. **スクリプト 5 本実装 + 各 smoke test**（合計 ~150 行のシェル）
2. **SKILL.md 改訂**（スクリプト確定後の方が例が固まる）
3. **references 更新**（`api-reference.md` 加筆 / `response-format.md` 加筆 / `recipes.md` 新規）

各ステップは独立に実装可能で、PR 単位で分割するか、wrapper-scripts-design 全体を 1 PR にまとめるかは実装計画フェーズで判断する。

## 5. 影響範囲

### 5.1 ファイル

新規:

- `jp-diet-minutes/scripts/search-by-speaker.sh`
- `jp-diet-minutes/scripts/search-by-keyword.sh`
- `jp-diet-minutes/scripts/search-by-role.sh`
- `jp-diet-minutes/scripts/list-meetings.sh`
- `jp-diet-minutes/scripts/fetch-meeting.sh`
- `jp-diet-minutes/scripts/README.md`
- `jp-diet-minutes/references/recipes.md`
- `docs/specs/2026-06-14-wrapper-scripts-design.md`（本ファイル）

変更:

- `jp-diet-minutes/SKILL.md`（全面改訂）
- `jp-diet-minutes/references/api-reference.md`（「結果の返却順」節追加）
- `jp-diet-minutes/references/response-format.md`（フェッチツール選定注意書き追加）

### 5.2 後方互換性

- 既存ユーザーの呼び出しコード（あれば）は raw curl を直接書いている前提で影響なし
- skill バージョンは `0.1.0` → `0.2.0` に bump する（wrapper 導入による振る舞いの拡大）

## 6. 想定リスク

| リスク | 影響 | 緩和策 |
|---|---|---|
| Bash が未導入の Windows ユーザーへの skill 不適用拡大 | スクリプト実行不可ユーザー発生 | Claude Code の Bash tool は Git Bash 経由で動作するため、Claude Code/Cursor/Copilot のいずれかで使う前提なら問題ない。skill description にも「Use this skill when researching ...」と記述があり、エージェント前提が明示されている |
| jp-law からの URL エンコード関数の流用ライセンス問題 | 法的リスク | jp-law も同じユーザー（HighBridgeDragon）所有・MIT ライセンス。流用は問題なし |
| wrapper 引数の positional order を将来変更したくなった場合の互換性 | breaking change | 初版で `[from] [until] [limit]` の順序を固定し、以降変更しない方針を README に明記 |

## 7. オープン質問

- `scripts/README.md` の粒度を jp-law と同等（172 行、各スクリプト用途と前提条件を網羅）に揃えるか、minimal（Usage のみ）に留めるかは実装フェーズで判断する
- `recipes.md` の初版掲載 recipe 数は 3 件案だが、実装フェーズで適切な範囲を見直す

## 8. 関連リソース

- jp-law 先行設計: `~/.claude/skills/jp-law/SKILL.md`、`~/.claude/skills/jp-law/scripts/`
- 公式 API 仕様: <https://kokkai.ndl.go.jp/api.html>
- 前セッション調査ログ（issue #37 / #38 / #39 のコメント参照）
