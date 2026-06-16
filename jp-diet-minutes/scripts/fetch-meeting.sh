#!/bin/bash
set -e

# 会議全文取得 — GET /api/meeting
# Usage: bash scripts/fetch-meeting.sh <issueID>
# 詳細は -h / --help を参照

show_help() {
  cat <<'HELP'
fetch-meeting.sh — 会議全文取得 (GET /api/meeting)

Usage:
  bash scripts/fetch-meeting.sh <issueID>

Positional arguments:
  issueID         会議録を一意に識別する 21 桁英数字（list-meetings.sh で取得）

Options:
  -h, --help      この help を表示して終了

Examples:
  bash scripts/fetch-meeting.sh 121405254X00220241004

Notes:
  - maximumRecords=1 固定（issueID 一意のため）
  - issueID は 21 桁英数字のみなので URL エンコード不要
  - 単一会議取得のため --sort は対象外（必要時は jq で出力を後処理）

Dependencies: bash, curl
HELP
}

POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Run with -h for usage." >&2
      exit 2
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

ISSUE_ID="${POSITIONAL[0]}"

if [ -z "$ISSUE_ID" ]; then
  echo "Usage: bash scripts/fetch-meeting.sh <issueID>" >&2
  echo "Run with -h for details." >&2
  exit 1
fi

# issueID は 21 桁英数字のみ（例: 121405254X00220241004）。URL エンコード不要
curl -s "https://kokkai.ndl.go.jp/api/meeting?issueID=${ISSUE_ID}&maximumRecords=1&recordPacking=json"
