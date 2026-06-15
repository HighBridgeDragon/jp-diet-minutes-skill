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

# issueID は 21 桁英数字のみ（例: 121405254X00220241004）。URL エンコード不要
curl -s "https://kokkai.ndl.go.jp/api/meeting?issueID=${ISSUE_ID}&maximumRecords=1&recordPacking=json"
