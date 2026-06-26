#!/usr/bin/env bash
# Create one score on a trace or observation, optionally tied to an
# annotation queue context.
#
# The langfuse CLI's legacy-score-v1s create rejects categorical/numeric
# bodies, so this calls POST /api/public/scores directly.
#
# Usage:
#   write-score.sh \
#     --queue-id <id> \
#     --trace-id <id> \
#     [--observation-id <id>] \
#     --config-id <id> \
#     --name <score-name> \
#     --value <string|number> \
#     [--comment <text>] \
#     [--data-type CATEGORICAL|NUMERIC|BOOLEAN]   # default: CATEGORICAL
#
# Requires env vars: LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY.
# Optional:           LANGFUSE_BASE_URL (default https://cloud.langfuse.com)
#
# Output: JSON from the API on stdout (contains the new score id).
# Exit codes:
#   0 - success
#   1 - usage error
#   2 - missing credentials
#   3 - API failure

set -euo pipefail

QUEUE_ID=""
TRACE_ID=""
OBS_ID=""
CONFIG_ID=""
NAME=""
VALUE=""
COMMENT=""
DATA_TYPE="CATEGORICAL"
OUTPUT_JSON=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --queue-id)       QUEUE_ID="$2"; shift 2 ;;
    --trace-id)       TRACE_ID="$2"; shift 2 ;;
    --observation-id) OBS_ID="$2"; shift 2 ;;
    --config-id)      CONFIG_ID="$2"; shift 2 ;;
    --name)           NAME="$2"; shift 2 ;;
    --value)          VALUE="$2"; shift 2 ;;
    --comment)        COMMENT="$2"; shift 2 ;;
    --data-type)      DATA_TYPE="$2"; shift 2 ;;
    --json)           OUTPUT_JSON=true; shift ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

require() {
  local var="$1" flag="$2"
  if [ -z "${!var}" ]; then
    echo "missing required $flag" >&2
    exit 1
  fi
}
require TRACE_ID  --trace-id
require CONFIG_ID --config-id
require NAME      --name
require VALUE     --value

if [ -z "${LANGFUSE_PUBLIC_KEY:-}" ] || [ -z "${LANGFUSE_SECRET_KEY:-}" ]; then
  echo "LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY must be set" >&2
  exit 2
fi

BASE_URL="${LANGFUSE_BASE_URL:-https://cloud.langfuse.com}"

# CATEGORICAL/BOOLEAN take string value; NUMERIC takes number.
if [ "$DATA_TYPE" = "NUMERIC" ]; then
  VALUE_JQ=(--argjson value "$VALUE")
else
  VALUE_JQ=(--arg value "$VALUE")
fi

BODY=$(jq -nc \
  --arg traceId "$TRACE_ID" \
  --arg name "$NAME" \
  --arg dataType "$DATA_TYPE" \
  --arg configId "$CONFIG_ID" \
  --arg queueId "$QUEUE_ID" \
  --arg obsId "$OBS_ID" \
  --arg comment "$COMMENT" \
  "${VALUE_JQ[@]}" \
  '{traceId: $traceId, name: $name, value: $value, dataType: $dataType, configId: $configId}
   + (if $queueId  != "" then {queueId: $queueId}             else {} end)
   + (if $obsId    != "" then {observationId: $obsId}         else {} end)
   + (if $comment  != "" then {comment: $comment}             else {} end)')

RESP=$(curl -sS -u "$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY" \
  -X POST "$BASE_URL/api/public/scores" \
  -H 'Content-Type: application/json' \
  -w '\n%{http_code}' \
  -d "$BODY")

STATUS=$(echo "$RESP" | tail -n1)
PAYLOAD=$(echo "$RESP" | sed '$d')

if [ "$STATUS" -lt 200 ] || [ "$STATUS" -ge 300 ]; then
  echo "POST /api/public/scores -> $STATUS" >&2
  echo "$PAYLOAD" >&2
  exit 3
fi

if [ "$OUTPUT_JSON" = "true" ]; then
  echo "$PAYLOAD"
else
  ID=$(echo "$PAYLOAD" | jq -r '.id')
  printf '%s\t%s\t%s\n' "$NAME" "$VALUE" "$ID"
fi
