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
