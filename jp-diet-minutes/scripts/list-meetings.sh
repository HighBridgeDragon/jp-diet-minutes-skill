#!/bin/bash
set -e

# 会議一覧 — GET /api/meeting_list
# Usage: bash scripts/list-meetings.sh <meeting_name> [from] [until] [limit] --sort <keys>
# 詳細は -h / --help を参照

show_help() {
  cat <<'HELP'
list-meetings.sh — 会議一覧 (GET /api/meeting_list)

Usage:
  bash scripts/list-meetings.sh <meeting_name> [from] [until] [limit] --sort <keys>

Positional arguments:
  meeting_name    会議名（部分一致 OR、半角スペース区切りで複数指定可、ひらがな可）
  from            開会日付の下限 YYYY-MM-DD（省略可）
  until           開会日付の上限 YYYY-MM-DD（省略可）
  limit           maximumRecords (1〜100、既定 30)

Required options:
  --sort <keys>   結果をクライアント側でソート（必須）
                    取りうる値: date-asc / date-desc
                    （meetingRecord は会議粒度のため speech-order-* は対象外）
                    カンマ区切りで複合指定可（実質 date-asc または date-desc）
                    全キーは同方向。方向混在は非サポート

Options:
  -h, --help      この help を表示して終了

Examples:
  bash scripts/list-meetings.sh 予算委員会 2024-03-01 2024-03-31 50 --sort date-desc
  bash scripts/list-meetings.sh 予算委員会 2024-03-01 2024-03-31 50 --sort date-asc

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
        echo "Valid keys: date-asc, date-desc" >&2
        exit 2
      fi
      SORT_KEYS="$2"
      shift 2
      ;;
    --sort=*)
      SORT_KEYS="${1#--sort=}"
      if [ -z "$SORT_KEYS" ]; then
        echo "Error: --sort= requires a non-empty value." >&2
        echo "Valid keys: date-asc, date-desc" >&2
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

MEETING="${POSITIONAL[0]}"
FROM="${POSITIONAL[1]}"
UNTIL="${POSITIONAL[2]}"
LIMIT="${POSITIONAL[3]:-30}"

if [ -z "$MEETING" ]; then
  echo "Usage: bash scripts/list-meetings.sh <meeting_name> [from] [until] [limit] --sort <keys>" >&2
  echo "Run with -h for details." >&2
  exit 1
fi

if [ -z "$SORT_KEYS" ]; then
  echo "Error: --sort <keys> is required." >&2
  echo "Valid keys: date-asc, date-desc" >&2
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

ENCODED=$(urlencode "$MEETING")
URL="https://kokkai.ndl.go.jp/api/meeting_list?nameOfMeeting=${ENCODED}&maximumRecords=${LIMIT}&recordPacking=json"
[ -n "$FROM" ] && URL="${URL}&from=${FROM}"
[ -n "$UNTIL" ] && URL="${URL}&until=${UNTIL}"

IFS=',' read -ra KEY_ARR <<< "$SORT_KEYS"
FIELDS=()
DIRECTIONS=()
for key in "${KEY_ARR[@]}"; do
  case "$key" in
    date-asc) FIELDS+=(".date"); DIRECTIONS+=("asc") ;;
    date-desc) FIELDS+=(".date"); DIRECTIONS+=("desc") ;;
    *)
      echo "Error: Unknown sort key '$key' for list-meetings.sh." >&2
      echo "Valid keys: date-asc, date-desc" >&2
      echo "(speech-order-* keys are not supported because meetingRecord is meeting-level, not speech-level.)" >&2
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
  FULL_FILTER=".meetingRecord |= sort_by([${JQ_KEYS}])"
else
  FULL_FILTER=".meetingRecord |= (sort_by([${JQ_KEYS}]) | reverse)"
fi

curl -s "$URL" | jq "$FULL_FILTER"
