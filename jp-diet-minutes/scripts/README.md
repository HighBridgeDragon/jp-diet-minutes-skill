# スクリプト一覧

このディレクトリには、国会会議録検索システム API V2 を呼び出すための bash wrapper スクリプトを格納する。

各スクリプトは姉妹 skill `jp-law` と同じく「薄ラッパ」設計で、`recordPacking=json` を強制する以外のロジック（JSON パース・ページネーション・エラー解析）は持たない。複合的な処理は SKILL.md と `references/recipes.md` の用例を参照すること。

## 共通仕様

- shebang `#!/bin/bash`
- `set -e` で異常時即終了
- 引数未指定時は `Usage:` を stderr に出力して `exit 1`
- 出力は curl の生レスポンス body（`--sort` 指定スクリプトは下記の `jq` 経由のソート後）
- `from` / `until` / `limit` は positional 引数。順序固定（互換性のため将来も変更しない）
- 全スクリプトで `recordPacking=json` を強制
- 全スクリプトに `-h` / `--help` を実装。引数仕様の詳細は `bash scripts/<name>.sh -h` で確認できる
- `search-by-*.sh` / `list-meetings.sh` の 4 本は **`--sort <keys>` が必須引数**。`jq` 経由でクライアント側ソートを行う。利用者が API ソート順仕様（会議開催日降順 + 同日 speechOrder 昇順）を意識せざるを得ない構造的ガード
- 取りうる sort key: `date-asc` / `date-desc` / `speech-order-asc` / `speech-order-desc`（`list-meetings.sh` は `date-*` のみ）。カンマ区切りで複合指定可
- Exit code: 0 (成功) / 1 (引数不足 or jq 不在) / 2 (不正 option or sort key)

### urlencode 関数の意図的な複製

`search-by-speaker.sh` / `search-by-keyword.sh` / `search-by-role.sh` / `list-meetings.sh` の 4 スクリプトには同一の `urlencode()` 関数が複製されている（`fetch-meeting.sh` は `issueID` が 21 桁英数字のみのためエンコード不要）。これは **意図的な設計判断** で、姉妹 skill `jp-law` と同じく「各スクリプトを単一ファイルで自己完結させる」ことを優先している。共有ライブラリ化（`_urlencode.sh` 等）は採用しない。

理由:

- skill 配布時に `bash scripts/<name>.sh` 単体で動作する状態を維持したい
- POSIX 系 `od`/`tr`/`grep` ベースの安定したコードで、将来の修正頻度が極めて低い
- 4 スクリプト共通の場合は `git grep urlencode jp-diet-minutes/scripts/` で一括検索 → 同時編集できる

将来 urlencode 内のバイト範囲扱いを変更する場合は、4 ファイル同時に編集すること。

## API スクリプト

### search-by-speaker.sh

議員名で発言を検索する（`GET /api/speech?speaker=X`）。

```bash
bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit] --sort <keys>
```

| 引数 | 必須 | 既定値 | 説明 |
|---|---|---|---|
| `speaker_name` | ✅ | — | 議員名（部分一致 OR、半角スペース区切りで複数指定可） |
| `from` | | （指定なし） | 開会日付の下限 `YYYY-MM-DD` |
| `until` | | （指定なし） | 開会日付の上限 `YYYY-MM-DD` |
| `limit` | | 30 | `maximumRecords`（1〜100） |
| `--sort` | ✅ | — | sort key（`date-asc` / `date-desc` / `speech-order-asc` / `speech-order-desc`、カンマ区切り複合可） |

全引数仕様（取りうる値・複合キー指定例等）は `bash scripts/search-by-speaker.sh -h` を参照。

例:

```bash
# 岸田文雄の 2024 年の発言を 50 件、日付降順で取得
bash scripts/search-by-speaker.sh 岸田文雄 2024-01-01 2024-12-31 50 --sort date-desc

# 松岡克由の 1972-06-08 の発言を speechOrder 昇順で取得（最古発言確定用）
bash scripts/search-by-speaker.sh 松岡克由 1972-06-08 1972-06-08 100 --sort date-asc,speech-order-asc
```

### search-by-keyword.sh

キーワードで発言本文を検索する（`GET /api/speech?any=X`、AND 部分一致）。

```bash
bash scripts/search-by-keyword.sh <keyword> [from] [until] [limit] --sort <keys>
```

`--sort` 必須。詳細は `bash scripts/search-by-keyword.sh -h` を参照。

例:

```bash
# 「マイナンバー 個人情報」を両方含む発言を日付降順で取得（AND 検索）
bash scripts/search-by-keyword.sh 'マイナンバー 個人情報' 2024-01-01 2024-12-31 50 --sort date-desc
```

### search-by-role.sh

役割で発言を検索する（`GET /api/speech?speakerRole=X`）。

```bash
bash scripts/search-by-role.sh <role> [from] [until] [limit] --sort <keys>
```

`role` は `証人` / `参考人` / `公述人` のいずれか。それ以外を指定すると API が HTTP 400 で弾く。

`--sort` 必須。詳細は `bash scripts/search-by-role.sh -h` を参照。

例:

```bash
# 2024 年の参考人質疑を 50 件、日付降順で取得
bash scripts/search-by-role.sh 参考人 2024-01-01 2024-12-31 50 --sort date-desc
```

### list-meetings.sh

会議一覧を取得する（`GET /api/meeting_list`）。`issueID` 特定に使う。

```bash
bash scripts/list-meetings.sh <meeting_name> [from] [until] [limit] --sort <keys>
```

`--sort` 必須。`list-meetings.sh` は会議粒度のため有効 key は `date-asc` / `date-desc` のみ。詳細は `bash scripts/list-meetings.sh -h` を参照。

例:

```bash
# 2024-03 の予算委員会一覧を日付昇順で取得
bash scripts/list-meetings.sh 予算委員会 2024-03-01 2024-03-31 50 --sort date-asc
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

詳細は `bash scripts/fetch-meeting.sh -h` を参照。

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
- `jq`（**required**: `search-by-*.sh` / `list-meetings.sh` で `--sort` 必須化のため。`fetch-meeting.sh` のみ不要）
- `od` / `tr` / `grep`（URL エンコード用、POSIX 系で標準搭載）
- インターネット接続

## レート制限

NDL は「機械的アクセス時は数秒間隔」を要求している。連続呼び出し時は 2〜3 秒以上の間隔を空けること。並列実行は禁止。

## 関連ドキュメント

- [SKILL.md](../SKILL.md): skill 全体の使い方
- [api-reference.md](../references/api-reference.md): API 仕様
- [response-format.md](../references/response-format.md): レスポンス構造
- [recipes.md](../references/recipes.md): 複合パターン集
