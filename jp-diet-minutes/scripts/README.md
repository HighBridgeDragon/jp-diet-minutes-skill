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
