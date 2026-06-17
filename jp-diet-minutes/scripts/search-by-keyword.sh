#!/bin/bash
set -e

# キーワードで発言検索 — GET /api/speech (any 検索, AND)
# Usage: bash scripts/search-by-keyword.sh <keyword> [from] [until] [limit] --sort <keys>
# 詳細は -h / --help を参照

show_help() {
  cat <<'HELP'
search-by-keyword.sh — キーワードで発言本文検索 (GET /api/speech, any 検索 / AND)

Usage:
  bash scripts/search-by-keyword.sh <keyword> [from] [until] [limit] --sort <keys>

Positional arguments:
  keyword         検索キーワード（部分一致 AND、半角スペース区切りで複数指定可）
  from            開会日付の下限 YYYY-MM-DD（省略可）
  until           開会日付の上限 YYYY-MM-DD（省略可）
  limit           maximumRecords (1〜100、既定 30)

Required options:
  --sort <keys>   結果をクライアント側でソート（必須）
                    取りうる値: date-asc / date-desc / speech-order-asc / speech-order-desc
                    カンマ区切りで複合指定可（左ほど主キー、右が副キー）
                    全キーは同方向（全 asc または全 desc）。方向混在は非サポート
                    例: --sort date-asc,speech-order-asc

Options:
  -h, --help      この help を表示して終了

Examples:
  bash scripts/search-by-keyword.sh マイナンバー 2024-01-01 2024-12-31 50 --sort date-desc
  bash scripts/search-by-keyword.sh 'マイナンバー 個人情報' 2024-01-01 2024-12-31 50 --sort date-desc

Dependencies: bash, curl, jq (required)
HELP
}

POSITIONAL=()
SORT_KEYS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    --sort)
      if [ $# -lt 2 ]; then
        echo "Error: --sort requires a value." >&2
        echo "Valid keys: date-asc, date-desc, speech-order-asc, speech-order-desc" >&2
        exit 2
      fi
      SORT_KEYS="$2"
      shift 2
      ;;
    --sort=*)
      SORT_KEYS="${1#--sort=}"
      if [ -z "$SORT_KEYS" ]; then
        echo "Error: --sort= requires a non-empty value." >&2
        echo "Valid keys: date-asc, date-desc, speech-order-asc, speech-order-desc" >&2
        exit 2
      fi
      shift
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

KEYWORD="${POSITIONAL[0]}"
FROM="${POSITIONAL[1]}"
UNTIL="${POSITIONAL[2]}"
LIMIT="${POSITIONAL[3]:-30}"

if [ -z "$KEYWORD" ]; then
  echo "Usage: bash scripts/search-by-keyword.sh <keyword> [from] [until] [limit] --sort <keys>" >&2
  echo "Run with -h for details." >&2
  exit 1
fi

if [ -z "$SORT_KEYS" ]; then
  echo "Error: --sort <keys> is required." >&2
  echo "Valid keys: date-asc, date-desc, speech-order-asc, speech-order-desc" >&2
  echo "Run with -h for full usage." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install jq and retry." >&2
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

IFS=',' read -ra KEY_ARR <<< "$SORT_KEYS"
FIELDS=()
DIRECTIONS=()
for key in "${KEY_ARR[@]}"; do
  case "$key" in
    date-asc) FIELDS+=(".date"); DIRECTIONS+=("asc") ;;
    date-desc) FIELDS+=(".date"); DIRECTIONS+=("desc") ;;
    speech-order-asc) FIELDS+=(".speechOrder"); DIRECTIONS+=("asc") ;;
    speech-order-desc) FIELDS+=(".speechOrder"); DIRECTIONS+=("desc") ;;
    *)
      echo "Error: Unknown sort key '$key'." >&2
      echo "Valid keys: date-asc, date-desc, speech-order-asc, speech-order-desc" >&2
      exit 2
      ;;
  esac
done

FIRST_DIR="${DIRECTIONS[0]}"
for dir in "${DIRECTIONS[@]}"; do
  if [ "$dir" != "$FIRST_DIR" ]; then
    echo "Error: Mixed asc/desc directions in --sort are not supported." >&2
    echo "Use all keys with the same direction (all -asc or all -desc)." >&2
    exit 2
  fi
done

JQ_KEYS=$(IFS=,; echo "${FIELDS[*]}")
if [ "$FIRST_DIR" = "asc" ]; then
  FULL_FILTER=".speechRecord |= sort_by([${JQ_KEYS}])"
else
  FULL_FILTER=".speechRecord |= (sort_by([${JQ_KEYS}]) | reverse)"
fi

curl -s "$URL" | jq "$FULL_FILTER"
