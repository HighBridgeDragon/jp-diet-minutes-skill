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
