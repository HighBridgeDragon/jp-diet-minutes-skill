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
