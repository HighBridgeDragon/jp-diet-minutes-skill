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
