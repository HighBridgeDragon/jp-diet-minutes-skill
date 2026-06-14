---
name: wrapper-scripts-design-plan
description: docs/specs/2026-06-14-wrapper-scripts-design.md の実装計画。5 本の wrapper scripts 追加 + SKILL.md/references の wrapper-first 改訂。
date: 2026-06-14
related_spec: docs/specs/2026-06-14-wrapper-scripts-design.md
---

# wrapper-scripts-design 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` を使ってタスク単位で実装する。各 step はチェックボックス (`- [ ]`) 形式。

**Goal:** jp-diet-minutes skill を wrapper-first 設計に刷新し、`WebFetch` ハルシネーション・ソート順誤読・recipe 散逸の 3 種の UX 問題を構造的に解決する。

**Architecture:** 姉妹 skill `jp-law` の薄ラッパパターンを踏襲。`jp-diet-minutes/scripts/` に 5 本の bash wrapper を追加し、SKILL.md と references 3 ファイルを wrapper-first に書き換える。スクリプトは `set -e` + URL エンコード + `recordPacking=json` 強制 + 1 行 curl のみで、JSON パース等のロジックは持たない。

**Tech Stack:** bash 4+ / curl / POSIX 系ツール（`od`, `tr`, `grep`）。LLM 経由実行を前提とするため Git Bash 環境を最低要件とする。

**Spec:** [`docs/specs/2026-06-14-wrapper-scripts-design.md`](../specs/2026-06-14-wrapper-scripts-design.md)

---

## 共通事項

### NDL API レート制限の遵守

公式 API は「機械的アクセス時は数秒間隔」を要求している。本計画の smoke test は **タスク間で順次実行** し、連続呼び出し時は 2〜3 秒以上の間隔を空ける。並列実行は禁止。

### コミット規約

CLAUDE.md `intent: commit-style` に従い Conventional Commits + 日本語本文。各タスク末尾の `git commit` 例を参照。

### worktree 前提

本計画は worktree `C:\SRC\jp-diet-minutes-skill\.claude\worktrees\claude+20260614+wrapper-scripts-design` ブランチ `claude/20260614/wrapper-scripts-design` で実行する前提。main への直接 commit は CLAUDE.md `dev-workflow` で禁止。

---

## File Structure

新規ファイル:

| パス | 責務 |
|---|---|
| `jp-diet-minutes/scripts/search-by-speaker.sh` | `GET /api/speech?speaker=X` の薄ラッパ |
| `jp-diet-minutes/scripts/search-by-keyword.sh` | `GET /api/speech?any=X` の薄ラッパ |
| `jp-diet-minutes/scripts/search-by-role.sh` | `GET /api/speech?speakerRole=X` の薄ラッパ |
| `jp-diet-minutes/scripts/list-meetings.sh` | `GET /api/meeting_list?nameOfMeeting=X` の薄ラッパ |
| `jp-diet-minutes/scripts/fetch-meeting.sh` | `GET /api/meeting?issueID=X` の薄ラッパ |
| `jp-diet-minutes/scripts/README.md` | スクリプト一覧と使い方 |
| `jp-diet-minutes/references/recipes.md` | scripts では covers できない複合パターン集 |

変更ファイル:

| パス | 変更内容 |
|---|---|
| `jp-diet-minutes/SKILL.md` | wrapper-first 構造に全面改訂、version 0.1.0 → 0.2.0 |
| `jp-diet-minutes/references/api-reference.md` | 「結果の返却順」節を新設 |
| `jp-diet-minutes/references/response-format.md` | 冒頭に「フェッチツール選定」H2 節を新設 |

---

## Task 1: scripts/search-by-speaker.sh

**Files:**

- Create: `jp-diet-minutes/scripts/search-by-speaker.sh`

- [ ] **Step 1: Smoke test 期待値を確認**

スクリプト存在前に手動 curl で期待レスポンス形を確認:

```bash
curl -s 'https://kokkai.ndl.go.jp/api/speech?speaker=%E5%B2%B8%E7%94%B0%E6%96%87%E9%9B%84&maximumRecords=1&recordPacking=json' | head -c 200
```

Expected: `{"numberOfRecords":` で始まる JSON が返る

- [ ] **Step 2: スクリプトを作成**

`jp-diet-minutes/scripts/search-by-speaker.sh` に以下を書く:

```bash
#!/bin/bash
set -e

# 議員名で発言検索 — GET /api/speech
# Usage: bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit]
# Example: bash scripts/search-by-speaker.sh 岸田文雄 2024-01-01 2024-12-31 50

SPEAKER="$1"
FROM="$2"
UNTIL="$3"
LIMIT="${4:-30}"

if [ -z "$SPEAKER" ]; then
  echo "Usage: bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit]" >&2
  exit 1
fi

urlencode() {
  printf '%s' "$1" | od -An -tx1 | tr ' ' '\n' | grep . | while read -r hex; do
    case "$hex" in
      2d|2e|5f|7e|3[0-9]|[46][1-9a-f]|[57][0-9a]) printf "\\x${hex}" ;;
      *) printf "%%%s" "$hex" ;;
    esac
  done
}

ENCODED=$(urlencode "$SPEAKER")
URL="https://kokkai.ndl.go.jp/api/speech?speaker=${ENCODED}&maximumRecords=${LIMIT}&recordPacking=json"
[ -n "$FROM" ] && URL="${URL}&from=${FROM}"
[ -n "$UNTIL" ] && URL="${URL}&until=${UNTIL}"

curl -s "$URL"
```

- [ ] **Step 3: 実行権限を付与**

```bash
chmod +x jp-diet-minutes/scripts/search-by-speaker.sh
ls -la jp-diet-minutes/scripts/search-by-speaker.sh
```

Expected: `-rwxr-xr-x` が出力される

- [ ] **Step 4: Smoke test 1: 引数欠落時の Usage 表示**

```bash
bash jp-diet-minutes/scripts/search-by-speaker.sh 2>&1; echo "exit=$?"
```

Expected: `Usage: bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit]` と `exit=1`

- [ ] **Step 5: Smoke test 2: 実 API への 1 リクエスト**

```bash
bash jp-diet-minutes/scripts/search-by-speaker.sh 岸田文雄 2024-01-01 2024-01-31 3 | python -c "import json, sys; d = json.load(sys.stdin); print('numberOfRecords=', d['numberOfRecords']); print('numberOfReturn=', d['numberOfReturn']); print('first speaker=', d['speechRecord'][0]['speaker'])"
```

Expected: `numberOfRecords` が 0 以上の整数、`numberOfReturn` が 1〜3、`first speaker` が文字列を出力

- [ ] **Step 6: Commit**

```bash
git add jp-diet-minutes/scripts/search-by-speaker.sh
git commit -m "feat: 議員名で発言検索する wrapper script を追加"
```

---

## Task 2: scripts/search-by-keyword.sh

**Files:**

- Create: `jp-diet-minutes/scripts/search-by-keyword.sh`

- [ ] **Step 1: スクリプトを作成**

`jp-diet-minutes/scripts/search-by-keyword.sh` に以下を書く:

```bash
#!/bin/bash
set -e

# キーワードで発言検索 — GET /api/speech (any 検索, AND)
# Usage: bash scripts/search-by-keyword.sh <keyword> [from] [until] [limit]
# Example: bash scripts/search-by-keyword.sh マイナンバー 2024-01-01 2024-12-31 50

KEYWORD="$1"
FROM="$2"
UNTIL="$3"
LIMIT="${4:-30}"

if [ -z "$KEYWORD" ]; then
  echo "Usage: bash scripts/search-by-keyword.sh <keyword> [from] [until] [limit]" >&2
  exit 1
fi

urlencode() {
  printf '%s' "$1" | od -An -tx1 | tr ' ' '\n' | grep . | while read -r hex; do
    case "$hex" in
      2d|2e|5f|7e|3[0-9]|[46][1-9a-f]|[57][0-9a]) printf "\\x${hex}" ;;
      *) printf "%%%s" "$hex" ;;
    esac
  done
}

ENCODED=$(urlencode "$KEYWORD")
URL="https://kokkai.ndl.go.jp/api/speech?any=${ENCODED}&maximumRecords=${LIMIT}&recordPacking=json"
[ -n "$FROM" ] && URL="${URL}&from=${FROM}"
[ -n "$UNTIL" ] && URL="${URL}&until=${UNTIL}"

curl -s "$URL"
```

- [ ] **Step 2: 実行権限を付与**

```bash
chmod +x jp-diet-minutes/scripts/search-by-keyword.sh
```

- [ ] **Step 3: Smoke test 1: Usage 表示**

```bash
bash jp-diet-minutes/scripts/search-by-keyword.sh 2>&1; echo "exit=$?"
```

Expected: Usage と `exit=1`

- [ ] **Step 4: Smoke test 2: 実 API への 1 リクエスト（前回呼び出しから 2 秒以上空ける）**

```bash
sleep 3 && bash jp-diet-minutes/scripts/search-by-keyword.sh マイナンバー 2024-01-01 2024-01-31 3 | python -c "import json, sys; d = json.load(sys.stdin); print('numberOfRecords=', d['numberOfRecords'])"
```

Expected: `numberOfRecords` が 0 以上の整数を出力

- [ ] **Step 5: Commit**

```bash
git add jp-diet-minutes/scripts/search-by-keyword.sh
git commit -m "feat: キーワードで発言検索する wrapper script を追加"
```

---

## Task 3: scripts/search-by-role.sh

**Files:**

- Create: `jp-diet-minutes/scripts/search-by-role.sh`

- [ ] **Step 1: スクリプトを作成**

`jp-diet-minutes/scripts/search-by-role.sh` に以下を書く:

```bash
#!/bin/bash
set -e

# 役割で発言検索 — GET /api/speech (speakerRole 検索)
# Usage: bash scripts/search-by-role.sh <role> [from] [until] [limit]
# Example: bash scripts/search-by-role.sh 参考人 2024-01-01 2024-12-31 50
# role は 証人 / 参考人 / 公述人 のいずれか（それ以外は API 側で HTTP 400）

ROLE="$1"
FROM="$2"
UNTIL="$3"
LIMIT="${4:-30}"

if [ -z "$ROLE" ]; then
  echo "Usage: bash scripts/search-by-role.sh <role> [from] [until] [limit]" >&2
  echo "  role: 証人 / 参考人 / 公述人" >&2
  exit 1
fi

urlencode() {
  printf '%s' "$1" | od -An -tx1 | tr ' ' '\n' | grep . | while read -r hex; do
    case "$hex" in
      2d|2e|5f|7e|3[0-9]|[46][1-9a-f]|[57][0-9a]) printf "\\x${hex}" ;;
      *) printf "%%%s" "$hex" ;;
    esac
  done
}

ENCODED=$(urlencode "$ROLE")
URL="https://kokkai.ndl.go.jp/api/speech?speakerRole=${ENCODED}&maximumRecords=${LIMIT}&recordPacking=json"
[ -n "$FROM" ] && URL="${URL}&from=${FROM}"
[ -n "$UNTIL" ] && URL="${URL}&until=${UNTIL}"

curl -s "$URL"
```

- [ ] **Step 2: 実行権限を付与**

```bash
chmod +x jp-diet-minutes/scripts/search-by-role.sh
```

- [ ] **Step 3: Smoke test 1: Usage 表示**

```bash
bash jp-diet-minutes/scripts/search-by-role.sh 2>&1; echo "exit=$?"
```

Expected: Usage（role 候補 3 つ含む）と `exit=1`

- [ ] **Step 4: Smoke test 2: 正常系（参考人）**

```bash
sleep 3 && bash jp-diet-minutes/scripts/search-by-role.sh 参考人 2024-01-01 2024-01-31 3 | python -c "import json, sys; d = json.load(sys.stdin); print('numberOfRecords=', d['numberOfRecords'])"
```

Expected: `numberOfRecords` が 0 以上の整数

- [ ] **Step 5: Smoke test 3: 異常系（不正 role）の API 透過**

```bash
sleep 3 && bash jp-diet-minutes/scripts/search-by-role.sh 不正役割 2>&1 | head -c 200
```

Expected: `{"message":"(19011)検索条件の入力に誤りがあります。"` で始まる JSON が返る（API のエラーをそのまま透過）

- [ ] **Step 6: Commit**

```bash
git add jp-diet-minutes/scripts/search-by-role.sh
git commit -m "feat: 役割で発言検索する wrapper script を追加"
```

---

## Task 4: scripts/list-meetings.sh

**Files:**

- Create: `jp-diet-minutes/scripts/list-meetings.sh`

- [ ] **Step 1: スクリプトを作成**

`jp-diet-minutes/scripts/list-meetings.sh` に以下を書く:

```bash
#!/bin/bash
set -e

# 会議一覧 — GET /api/meeting_list
# Usage: bash scripts/list-meetings.sh <meeting_name> [from] [until] [limit]
# Example: bash scripts/list-meetings.sh 予算委員会 2024-03-01 2024-03-31 50

MEETING="$1"
FROM="$2"
UNTIL="$3"
LIMIT="${4:-30}"

if [ -z "$MEETING" ]; then
  echo "Usage: bash scripts/list-meetings.sh <meeting_name> [from] [until] [limit]" >&2
  exit 1
fi

urlencode() {
  printf '%s' "$1" | od -An -tx1 | tr ' ' '\n' | grep . | while read -r hex; do
    case "$hex" in
      2d|2e|5f|7e|3[0-9]|[46][1-9a-f]|[57][0-9a]) printf "\\x${hex}" ;;
      *) printf "%%%s" "$hex" ;;
    esac
  done
}

ENCODED=$(urlencode "$MEETING")
URL="https://kokkai.ndl.go.jp/api/meeting_list?nameOfMeeting=${ENCODED}&maximumRecords=${LIMIT}&recordPacking=json"
[ -n "$FROM" ] && URL="${URL}&from=${FROM}"
[ -n "$UNTIL" ] && URL="${URL}&until=${UNTIL}"

curl -s "$URL"
```

- [ ] **Step 2: 実行権限を付与**

```bash
chmod +x jp-diet-minutes/scripts/list-meetings.sh
```

- [ ] **Step 3: Smoke test 1: Usage 表示**

```bash
bash jp-diet-minutes/scripts/list-meetings.sh 2>&1; echo "exit=$?"
```

Expected: Usage と `exit=1`

- [ ] **Step 4: Smoke test 2: 実 API への 1 リクエスト**

```bash
sleep 3 && bash jp-diet-minutes/scripts/list-meetings.sh 予算委員会 2024-03-01 2024-03-31 3 | python -c "import json, sys; d = json.load(sys.stdin); print('numberOfRecords=', d['numberOfRecords']); print('first issueID=', d['meetingRecord'][0]['issueID']); print('first nameOfMeeting=', d['meetingRecord'][0]['nameOfMeeting'])"
```

Expected: `numberOfRecords` が 1 以上、`first issueID` が 21 桁の英数字、`first nameOfMeeting` に「予算委員会」を含む

- [ ] **Step 5: Commit**

```bash
git add jp-diet-minutes/scripts/list-meetings.sh
git commit -m "feat: 会議一覧を取得する wrapper script を追加"
```

---

## Task 5: scripts/fetch-meeting.sh

**Files:**

- Create: `jp-diet-minutes/scripts/fetch-meeting.sh`

- [ ] **Step 1: スクリプトを作成**

`jp-diet-minutes/scripts/fetch-meeting.sh` に以下を書く:

```bash
#!/bin/bash
set -e

# 会議全文取得 — GET /api/meeting
# Usage: bash scripts/fetch-meeting.sh <issueID>
# Example: bash scripts/fetch-meeting.sh 121405254X00220241004
# issueID は会議録を一意に識別する 21 桁。list-meetings.sh で取得する

ISSUE_ID="$1"

if [ -z "$ISSUE_ID" ]; then
  echo "Usage: bash scripts/fetch-meeting.sh <issueID>" >&2
  exit 1
fi

curl -s "https://kokkai.ndl.go.jp/api/meeting?issueID=${ISSUE_ID}&maximumRecords=1&recordPacking=json"
```

- [ ] **Step 2: 実行権限を付与**

```bash
chmod +x jp-diet-minutes/scripts/fetch-meeting.sh
```

- [ ] **Step 3: Smoke test 1: Usage 表示**

```bash
bash jp-diet-minutes/scripts/fetch-meeting.sh 2>&1; echo "exit=$?"
```

Expected: Usage と `exit=1`

- [ ] **Step 4: Smoke test 2: 実 API への 1 リクエスト（既知の issueID）**

```bash
sleep 3 && bash jp-diet-minutes/scripts/fetch-meeting.sh 121405254X00220241004 | python -c "import json, sys; d = json.load(sys.stdin); m = d['meetingRecord'][0]; print('issueID=', m['issueID']); print('nameOfMeeting=', m['nameOfMeeting']); print('speechRecord len=', len(m['speechRecord']))"
```

Expected: `issueID=121405254X00220241004`、`nameOfMeeting=本会議`、`speechRecord len` が 1 以上

- [ ] **Step 5: Commit**

```bash
git add jp-diet-minutes/scripts/fetch-meeting.sh
git commit -m "feat: 会議全文を取得する wrapper script を追加"
```

---

## Task 6: scripts/README.md

**Files:**

- Create: `jp-diet-minutes/scripts/README.md`

- [ ] **Step 1: README を作成**

`jp-diet-minutes/scripts/README.md` に以下を書く:

````markdown
# スクリプト一覧

このディレクトリには、国会会議録検索システム API V2 を呼び出すための bash wrapper スクリプトを格納する。

各スクリプトは姉妹 skill `jp-law` と同じく「薄ラッパ」設計で、`recordPacking=json` を強制する以外のロジック（JSON パース・ページネーション・エラー解析）は持たない。複合的な処理は SKILL.md と `references/recipes.md` の用例を参照すること。

## 共通仕様

- shebang `#!/bin/bash`
- `set -e` で異常時即終了
- 引数未指定時は `Usage:` を stderr に出力して `exit 1`
- 出力は curl の生レスポンス body のみ（HTTP ステータスは body 内 `message` から判定）
- `from` / `until` / `limit` は positional 引数。順序固定（互換性のため将来も変更しない）
- 全スクリプトで `recordPacking=json` を強制

## API スクリプト

### search-by-speaker.sh

議員名で発言を検索する（`GET /api/speech?speaker=X`）。

```bash
bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit]
```

| 引数 | 必須 | 既定値 | 説明 |
|---|---|---|---|
| `speaker_name` | ✅ | — | 議員名（部分一致 OR、半角スペース区切りで複数指定可） |
| `from` | | （指定なし） | 開会日付の下限 `YYYY-MM-DD` |
| `until` | | （指定なし） | 開会日付の上限 `YYYY-MM-DD` |
| `limit` | | 30 | `maximumRecords`（1〜100） |

例:

```bash
# 岸田文雄の 2024 年の発言を 50 件取得
bash scripts/search-by-speaker.sh 岸田文雄 2024-01-01 2024-12-31 50
```

### search-by-keyword.sh

キーワードで発言本文を検索する（`GET /api/speech?any=X`、AND 部分一致）。

```bash
bash scripts/search-by-keyword.sh <keyword> [from] [until] [limit]
```

例:

```bash
# 「マイナンバー 個人情報」を両方含む発言を取得（AND 検索）
bash scripts/search-by-keyword.sh 'マイナンバー 個人情報' 2024-01-01 2024-12-31 50
```

### search-by-role.sh

役割で発言を検索する（`GET /api/speech?speakerRole=X`）。

```bash
bash scripts/search-by-role.sh <role> [from] [until] [limit]
```

`role` は `証人` / `参考人` / `公述人` のいずれか。それ以外を指定すると API が HTTP 400 で弾く。

例:

```bash
# 2024 年の参考人質疑を 50 件取得
bash scripts/search-by-role.sh 参考人 2024-01-01 2024-12-31 50
```

### list-meetings.sh

会議一覧を取得する（`GET /api/meeting_list`）。`issueID` 特定に使う。

```bash
bash scripts/list-meetings.sh <meeting_name> [from] [until] [limit]
```

例:

```bash
# 2024-03 の予算委員会一覧を取得
bash scripts/list-meetings.sh 予算委員会 2024-03-01 2024-03-31 50
```

### fetch-meeting.sh

会議全文を取得する（`GET /api/meeting?issueID=X`）。`maximumRecords` は 1 固定。

```bash
bash scripts/fetch-meeting.sh <issueID>
```

例:

```bash
# 2024-10-04 衆議院本会議 第2号の全文取得
bash scripts/fetch-meeting.sh 121405254X00220241004
```

## raw curl が必要なケース

以下のパラメータは wrapper が covers しない。SKILL.md「raw curl が必要なケース」節を参照:

- `sessionFrom` / `sessionTo`（回次絞り込み）
- `contentsAndIndex` / `supplementAndAppendix`（目次・索引・附録）
- `closing=true`（閉会中審査限定）
- `nameOfHouse` / `nameOfMeeting` 等の二次フィルタ
- ページネーション（`startRecord` + `nextRecordPosition` の連続呼び出し）

## 前提条件

- `bash` 4 以上
- `curl`
- `od` / `tr` / `grep`（URL エンコード用、POSIX 系で標準搭載）
- インターネット接続

## レート制限

NDL は「機械的アクセス時は数秒間隔」を要求している。連続呼び出し時は 2〜3 秒以上の間隔を空けること。並列実行は禁止。

## 関連ドキュメント

- [SKILL.md](../SKILL.md): skill 全体の使い方
- [api-reference.md](../references/api-reference.md): API 仕様
- [response-format.md](../references/response-format.md): レスポンス構造
- [recipes.md](../references/recipes.md): 複合パターン集
````

- [ ] **Step 2: markdownlint で検証**

```bash
npx --yes markdownlint-cli jp-diet-minutes/scripts/README.md 2>&1 | grep -v MD060; echo "non-MD060 errors above"
```

Expected: MD060 以外のエラーゼロ

- [ ] **Step 3: Commit**

```bash
git add jp-diet-minutes/scripts/README.md
git commit -m "docs: scripts/README.md でスクリプト一覧と使い方を記載"
```

---

## Task 7: jp-diet-minutes/SKILL.md 全面改訂

**Files:**

- Modify: `jp-diet-minutes/SKILL.md` (197 行)

このタスクは SKILL.md を section 単位で順次書き換える。各 step は独立した編集で、step 単位での部分コミットはせず、全 step 完了後にまとめてコミットする（SKILL.md は一貫性が崩れていると LLM が誤読するため、中間状態を残さない）。

- [ ] **Step 1: frontmatter の version を 0.2.0 に bump**

`jp-diet-minutes/SKILL.md` の frontmatter `metadata.version` を `"0.1.0"` → `"0.2.0"` に変更。

```yaml
metadata:
  version: "0.2.0"
```

- [ ] **Step 2: 「## 基本ルール」の `呼び出し方法` 行を書き換え**

該当の行を以下に置換:

```text
- 呼び出し方法: `bash scripts/<script>.sh` を使う。`WebFetch` / `Invoke-RestMethod` 等の直接利用は、wrapper が covers しない corner case（後述「raw curl が必要なケース」参照）のみ
```

- [ ] **Step 3: 「## エンドポイント選択」セクションを書き換え**

既存の 3 エンドポイント例を、スクリプト 5 本の用途別マッピングに置換する。書き換える内容（SKILL.md に書き込むテキスト）:

````text
## エンドポイント選択

ユーザーの要求に応じて適切な wrapper script を選ぶ。**情報量と消費トークンは `list-meetings.sh` < `search-by-*.sh` < `fetch-meeting.sh` の順で増える** ため、軽い方から段階的に絞ること。

```text
「○○議員の発言を見せて」
  → bash scripts/search-by-speaker.sh ○○ [from] [until] [limit]

「△△に関する発言を探して」
  → bash scripts/search-by-keyword.sh △△ [from] [until] [limit]
  ※ any 検索（AND）。複数キーワードは半角スペース区切り

「参考人質疑（証人喚問・公述人含む）を抽出」
  → bash scripts/search-by-role.sh 参考人 [from] [until] [limit]
  ※ role は 証人 / 参考人 / 公述人 のいずれか

「○○委員会の会議一覧を見せて」
  → bash scripts/list-meetings.sh ○○ [from] [until] [limit]
  ※ 軽量。会議メタのみ返却（発言本文は含まない）

「特定の会議の全発言を見せて」「○○委員会 YYYY-MM-DD の議事録全文」
  → Step 1: bash scripts/list-meetings.sh で対象会議の issueID を特定
  → Step 2: bash scripts/fetch-meeting.sh <issueID>
  ※ 1 リクエストで会議全文が返るため大きい。必ず絞ってから呼ぶ
```

詳細は [api-reference.md](references/api-reference.md), [parameters.md](references/parameters.md), [response-format.md](references/response-format.md), [recipes.md](references/recipes.md) を参照。
````

（注: 外側を 4 バックティック ````` ````` `````、内側を 3 バックティック ` ``` ` で書く）

- [ ] **Step 4: 「## 各エンドポイントの使い方」セクションを書き換え**

既存の 3 サブセクション（speech / meeting_list / meeting）を、5 サブセクション構成（5 スクリプト各 1）に書き換える。各サブセクションは以下フォーマット:

````text
### 1. `search-by-speaker.sh` — 議員名で発言検索（最頻用）

検索条件にヒットした発言のみ返す。トークン効率が最も良い。

```bash
# 議員名で発言抽出（部分一致 OR）
bash scripts/search-by-speaker.sh 岸田文雄 2024-01-01 2024-12-31 100
```

主要引数: `speaker_name`（部分一致 OR、半角スペース区切りで複数指定可）, `from`/`until`（YYYY-MM-DD 範囲）, `limit`（1〜100、既定 30）。

レスポンスは `speechRecord[]` 配列。各要素に会議メタ（`issueID`, `session`, `nameOfHouse`, `nameOfMeeting`, `date` 等）がフラット展開されている。
````

同様のフォーマットで以下を作成（各サブセクションの本文は spec §3.1 と既存 SKILL.md「## 各エンドポイントの使い方」を参考に書く）:

- `### 2. search-by-keyword.sh — キーワード検索（any 検索、AND）`
- `### 3. search-by-role.sh — 役割で発言検索（参考人質疑など）`
- `### 4. list-meetings.sh — 会議一覧（軽量索引）`
- `### 5. fetch-meeting.sh — 会議全文（最終手段）`

- [ ] **Step 5: 「## トークン節約ガイダンス」セクションの軽微な修正**

`meeting` を直接呼ぶ言及を `bash scripts/fetch-meeting.sh` に書き換え。`recordPacking=json` の指定は wrapper が常に強制するため、「`recordPacking=json` を必ず指定」の項目は削除する。

- [ ] **Step 6: 「## 結果フィルタリングの落とし穴」に項目 7 を追加**

既存の 6 項目の末尾（項目 6 の後）に以下を追加:

```text
7. **API のソート順は「会議開催日の降順」で固定**: 公式仕様で並び順が降順保証されており、ソート指定パラメータは存在しない（speech / meeting_list / meeting いずれも同様）。便利な反面、`maximumRecords` で部分取得すると **新しい側 N 件のみ** が返る。
    - 最新発言判定: 部分取得の先頭で OK（`maximumRecords=1` で十分）
    - 最古発言判定: 部分取得結果から最古を断定しない。`numberOfRecords` 全件をページネーション末尾まで取得するか、`from` / `until` で年単位等に区切ってヒット件数 ≤ `maximumRecords` まで狭めてから判定する
```

- [ ] **Step 7: 「## よく使う検索パターン例」のコードブロックを scripts 呼び出しに書き換え**

既存の 5 サブセクション（議員の特定期間／法案審議／総理大臣演説／参考人質疑／特定会議）の `GET https://...` を `bash scripts/<script>.sh <args>` に置換。`speakerPosition=内閣総理大臣` などスクリプト引数で対応できない条件は raw curl のサンプル例として残す（その旨をコメントで明記）。

- [ ] **Step 8: 末尾に「## raw curl が必要なケース」セクションを新設**

「## 詳細リファレンス」の直前に追加（SKILL.md に書き込むテキスト）:

````text
## raw curl が必要なケース

以下のパラメータは wrapper script が covers しない。必要時は `curl` / `Invoke-RestMethod` で直接 API を叩く:

- `sessionFrom` / `sessionTo`（回次絞り込み）
- `contentsAndIndex` / `supplementAndAppendix`（目次・索引・附録）
- `closing=true`（閉会中審査限定）
- `nameOfHouse` / `nameOfMeeting` 等の二次フィルタ（wrapper の引数に含めていない）
- ページネーション（`startRecord` + `nextRecordPosition` の連続呼び出し）

例: 第 213 回国会の予算委員会のみを抽出する場合（`sessionFrom`/`sessionTo` 必要、wrapper 非対応）

```bash
curl -s 'https://kokkai.ndl.go.jp/api/meeting_list?sessionFrom=213&sessionTo=213&nameOfMeeting=%E4%BA%88%E7%AE%97%E5%A7%94%E5%93%A1%E4%BC%9A&maximumRecords=30&recordPacking=json'
```

`WebFetch` 等の内部要約モデルを介在させるツールは、レスポンスに存在しないフィールドを hallucination として混入させる事象が観測されているため、生データ取得には使わないこと（詳細は [response-format.md](references/response-format.md) 参照）。
````

- [ ] **Step 9: 「## 詳細リファレンス」の参照に recipes.md を追加**

末尾のリファレンス一覧に以下を追加:

```text
- [recipes.md](references/recipes.md): 複合パターン集（議員 × キーワード絞り込み等、scripts では covers できないケース）
```

- [ ] **Step 10: markdownlint で検証**

```bash
npx --yes markdownlint-cli jp-diet-minutes/SKILL.md 2>&1 | grep -v MD060 | head -20; echo "non-MD060 errors above"
```

Expected: MD060 以外のエラーゼロ。エラーがあれば修正。

- [ ] **Step 11: 視覚的に最終確認**

```bash
head -50 jp-diet-minutes/SKILL.md
```

Expected: frontmatter の version が 0.2.0、基本ルールに wrapper-first 規定が入っている

- [ ] **Step 12: Commit**

```bash
git add jp-diet-minutes/SKILL.md
git commit -m "$(cat <<'EOF'
docs: SKILL.md を wrapper-first 設計に全面改訂 (#37 #38)

- 基本ルールに「bash scripts/<script>.sh を使う、WebFetch 等の直接利用は corner case のみ」を明文化
- エンドポイント選択を 5 wrapper スクリプトの用途別マッピングに書き換え
- 各エンドポイントの使い方を scripts 呼び出しに書き換え
- 結果フィルタリングの落とし穴に項目 7「ソート順は会議開催日の降順固定」を追加 (#38 訂正版)
- 末尾に「raw curl が必要なケース」セクションを新設
- skill version を 0.1.0 → 0.2.0 に bump
EOF
)"
```

---

## Task 8: jp-diet-minutes/references/api-reference.md に「結果の返却順」節を追加

**Files:**

- Modify: `jp-diet-minutes/references/api-reference.md`

- [ ] **Step 1: 該当箇所を特定**

```bash
grep -n '^## ' jp-diet-minutes/references/api-reference.md
```

Expected: 「## ページネーション」の行番号と、その次の H2 セクションの行番号を確認

- [ ] **Step 2: 「## ページネーション」セクションの末尾に新セクションを挿入**

「## ページネーション」の最後の段落の直後（次の H2 の前）に以下を追加:

```text
---

## 結果の返却順

公式仕様（<https://kokkai.ndl.go.jp/api.html> 「2. 概要」）に以下が明記されている:

> 検索結果のソート順は、会議開催日の新しい順となっています。

- `speech` / `meeting_list` / `meeting` 全エンドポイントで会議開催日の降順固定
- ソート指定パラメータ（`sort` / `order` / `orderBy` 等）は存在しない
- `maximumRecords` 部分取得は常に「期間内で最新側 N 件」を返すため、最古発言判定にはページネーション末尾まで取得するか `from`/`until` で範囲を狭める必要がある

実証例: `speaker=松岡克由&from=1971-01-01&until=1975-12-31&maximumRecords=10` の結果は `numberOfRecords=578` のうち最新側 10 件（1975-05-07 → 1975-03-27 ×9）。期間内最古の 1973-07-17 は未取得のまま残る。
```

- [ ] **Step 3: markdownlint で検証**

```bash
npx --yes markdownlint-cli jp-diet-minutes/references/api-reference.md 2>&1 | grep -v MD060 | head -10; echo "non-MD060 errors above"
```

Expected: MD060 以外で新規エラーゼロ

- [ ] **Step 4: Commit**

```bash
git add jp-diet-minutes/references/api-reference.md
git commit -m "docs: api-reference.md に「結果の返却順」節を追加 (#38)"
```

---

## Task 9: jp-diet-minutes/references/response-format.md に「フェッチツール選定」注意書きを追加

**Files:**

- Modify: `jp-diet-minutes/references/response-format.md`

- [ ] **Step 1: ファイル冒頭の構造を確認**

```bash
head -30 jp-diet-minutes/references/response-format.md
```

Expected: frontmatter + H1 タイトル + 最初の H2 セクションの位置を把握

- [ ] **Step 2: H1 直後、最初の H2 として「## 注意: フェッチツール選定」を挿入**

H1（`# ...`）の直後（既存の最初の H2 セクションの前）に以下を追加:

```text
## 注意: フェッチツール選定

`WebFetch` 等の内部要約モデルを介在させるツールで API を呼ぶと、レスポンスに存在しないフィールド（`summary` / `sampleSpeeches` / `notableSpeechCharacteristics` 等）が hallucination として混入する事象が観測されている。生データ取得は必ず `bash scripts/<script>.sh`、または同等の生 HTTP 呼び出し（`curl` / `Invoke-RestMethod`）を用いること。

txt ページ（`https://kokkai.ndl.go.jp/txt/<issueID>/<speechOrder>`）は SPA（Single Page Application）であり、静的 HTML には本文がない（`<div id=app></div>` のみ）。発言全文取得は必ず API 経由で行い、txt URL はユーザー提示用の引用リンクとしてのみ使用すること。

---
```

- [ ] **Step 3: markdownlint で検証**

```bash
npx --yes markdownlint-cli jp-diet-minutes/references/response-format.md 2>&1 | grep -v MD060 | head -10; echo "non-MD060 errors above"
```

Expected: MD060 以外で新規エラーゼロ

- [ ] **Step 4: Commit**

```bash
git add jp-diet-minutes/references/response-format.md
git commit -m "docs: response-format.md にフェッチツール選定注意書きを追加 (#37)"
```

---

## Task 10: jp-diet-minutes/references/recipes.md 新規追加

**Files:**

- Create: `jp-diet-minutes/references/recipes.md`

- [ ] **Step 1: ファイルを作成**

`jp-diet-minutes/references/recipes.md` に以下を書く:

````markdown
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

### 目的

`maximumRecords` で部分取得した結果は会議開催日の **降順** で返るため、最古発言を確定するには `from`/`until` で範囲を狭めて 1 件取得するパターンが必要。API のソート順仕様は [api-reference.md「結果の返却順」](api-reference.md#結果の返却順) を参照。

### スニペット

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

### 補足

- 完全な最古確定にはページネーションで末尾まで取得する手もある（`startRecord` を `numberOfRecords - limit + 1` に設定）
- 上記スニペットは「年単位での絞り込み + 1 件取得」で実用的に最古に近い値を得る発想

---

## 同一会議内の質問者 → 答弁者ペア抽出

### 目的

`meeting` 全文から、質問者（議員）→ 答弁者（大臣等、`speakerPosition` で識別）の隣接ペアを抽出する。委員会審議の Q&A 構造を可視化するときに有用。

### スニペット

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

### 補足

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
````

- [ ] **Step 2: markdownlint で検証**

```bash
npx --yes markdownlint-cli jp-diet-minutes/references/recipes.md 2>&1 | grep -v MD060 | head -20; echo "non-MD060 errors above"
```

Expected: MD060 以外で新規エラーゼロ

- [ ] **Step 3: Commit**

```bash
git add jp-diet-minutes/references/recipes.md
git commit -m "docs: references/recipes.md を新規追加（複合パターン集）(#39)"
```

---

## 最終確認

- [ ] **Step 1: 全 commit を一覧で確認**

```bash
git log --oneline main..HEAD
```

Expected: 11 個の commit（spec commit 1 + plan commit 1 + scripts 5 + scripts README 1 + SKILL.md 1 + references 3）が並ぶ

- [ ] **Step 2: 全 markdown ファイルを lint 再確認**

```bash
npx --yes markdownlint-cli "jp-diet-minutes/**/*.md" 2>&1 | grep -v MD060 | head -20; echo "non-MD060 errors above"
```

Expected: MD060 以外のエラーゼロ

- [ ] **Step 3: スクリプト 5 本に実行権限が付与されているか確認**

```bash
ls -la jp-diet-minutes/scripts/*.sh
```

Expected: 全 5 ファイルに `-rwxr-xr-x` が出る

- [ ] **Step 4: skill version が 0.2.0 になっているか確認**

```bash
grep version jp-diet-minutes/SKILL.md
```

Expected: 出力に `version: "0.2.0"` が含まれる

- [ ] **Step 5: 関連 issues に進捗コメントを投稿（任意、PR 作成時にまとめてもよい）**

実装完了後、PR を起こした時点で issue #37 / #38 / #39 のいずれにも PR リンクを添えてコメントする。

---

## Self-Review チェック結果

- ✅ spec §3.1 (5 スクリプト): Task 1-5 でカバー
- ✅ spec §3.2 (SKILL.md 改訂 4 サブセクション): Task 7 step 2/3/6/8 でカバー
- ✅ spec §3.3.1 (api-reference.md): Task 8 でカバー
- ✅ spec §3.3.2 (response-format.md): Task 9 でカバー
- ✅ spec §3.3.3 (recipes.md): Task 10 でカバー
- ✅ spec §3.4 (issues との対応): commit message に `(#37)` `(#38)` `(#39)` を含めることで紐付け
- ✅ spec §3.6 (実行権限): Task 1-5 step 3 で chmod +x、最終確認 step 3 で全件検証
- ✅ spec §5.2 (version bump): Task 7 step 1 でカバー
- ✅ placeholder scan: TBD/TODO なし。全 step がコード/コマンド/期待出力を具体化
- ✅ type consistency: スクリプト引数名（`speaker_name`/`keyword`/`role`/`meeting_name`/`issueID`）は spec §3.1 と一致
