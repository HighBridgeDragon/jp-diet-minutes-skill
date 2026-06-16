#!/bin/bash
set -e

# 議員名で発言検索 — GET /api/speech
# Usage: bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit] --sort <keys>
# 詳細は -h / --help を参照

show_help() {
  cat <<'HELP'
search-by-speaker.sh — 議員名で発言検索 (GET /api/speech)

Usage:
  bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit] --sort <keys>

Positional arguments:
  speaker_name    議員名（部分一致 OR、半角スペース区切りで複数指定可）
  from            開会日付の下限 YYYY-MM-DD（省略可）
  until           開会日付の上限 YYYY-MM-DD（省略可）
  limit           maximumRecords (1〜100、既定 30)

Required options:
  --sort <keys>   結果をクライアント側でソート（必須）
                    取りうる値: date-asc / date-desc / speech-order-asc / speech-order-desc
                    カンマ区切りで複合指定可（左ほど主キー、右が副キー）
                    例: --sort date-asc,speech-order-asc

Options:
  -h, --help      この help を表示して終了

Examples:
  bash scripts/search-by-speaker.sh 岸田文雄 2024-01-01 2024-12-31 50 --sort date-desc
  bash scripts/search-by-speaker.sh 松岡克由 1972-06-08 1972-06-08 100 --sort date-asc,speech-order-asc

Dependencies: bash, curl, jq (required)
HELP
}

# 引数解析: positional + --sort (必須) + -h/--help
POSITIONAL=()
SORT_KEYS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    --sort)
      SORT_KEYS="$2"
      shift 2
      ;;
    --sort=*)
      SORT_KEYS="${1#--sort=}"
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

SPEAKER="${POSITIONAL[0]}"
FROM="${POSITIONAL[1]}"
UNTIL="${POSITIONAL[2]}"
LIMIT="${POSITIONAL[3]:-30}"

# Positional 必須チェック
if [ -z "$SPEAKER" ]; then
  echo "Usage: bash scripts/search-by-speaker.sh <speaker_name> [from] [until] [limit] --sort <keys>" >&2
  echo "Run with -h for details." >&2
  exit 1
fi

# --sort 必須チェック
if [ -z "$SORT_KEYS" ]; then
  echo "Error: --sort <keys> is required." >&2
  echo "Valid keys: date-asc, date-desc, speech-order-asc, speech-order-desc" >&2
  echo "Run with -h for full usage." >&2
  exit 1
fi

# jq 必須チェック
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

ENCODED=$(urlencode "$SPEAKER")
URL="https://kokkai.ndl.go.jp/api/speech?speaker=${ENCODED}&maximumRecords=${LIMIT}&recordPacking=json"
[ -n "$FROM" ] && URL="${URL}&from=${FROM}"
[ -n "$UNTIL" ] && URL="${URL}&until=${UNTIL}"

# sort key を jq フィルタに変換 (逆順 loop で安定ソートを利用)
IFS=',' read -ra KEY_ARR <<< "$SORT_KEYS"
JQ_FILTER='.'
for (( i=${#KEY_ARR[@]}-1; i>=0; i-- )); do
  key="${KEY_ARR[i]}"
  case "$key" in
    date-asc) JQ_FILTER="${JQ_FILTER} | sort_by(.date)" ;;
    date-desc) JQ_FILTER="${JQ_FILTER} | sort_by(.date) | reverse" ;;
    speech-order-asc) JQ_FILTER="${JQ_FILTER} | sort_by(.speechOrder)" ;;
    speech-order-desc) JQ_FILTER="${JQ_FILTER} | sort_by(.speechOrder) | reverse" ;;
    *)
      echo "Error: Unknown sort key '$key'." >&2
      echo "Valid keys: date-asc, date-desc, speech-order-asc, speech-order-desc" >&2
      exit 2
      ;;
  esac
done

FULL_FILTER=".speechRecord |= (${JQ_FILTER})"
curl -s "$URL" | jq "$FULL_FILTER"
