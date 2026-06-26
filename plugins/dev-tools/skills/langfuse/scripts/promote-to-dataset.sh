#!/usr/bin/env bash
# Promote a completed annotation queue item to a dataset item.
#
# Reads the queue item's source observation, extracts the user message
# as `input` and the model's parsed output as `expectedOutput`, then
# POSTs to /api/public/dataset-items. If --correction is provided, the
# correction object is deep-merged into the output before saving so
# the dataset reflects the *correct* answer, not the model's mistakes.
#
# Usage:
#   promote-to-dataset.sh \
#     --queue-id <id> \
#     --item-id <id> \
#     --dataset-name <name> \
#     [--correction '<json>'] \
#     [--correction-file <path>]
#
# Assumes the observation is a langchain-style GENERATION whose `input`
# is a JSON-encoded chat messages array and whose `output.content` is a
# JSON-encoded structured extraction. Only OBSERVATION-typed queue
# items are supported.
#
# Requires env vars: LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY.
# Optional:           LANGFUSE_BASE_URL (default https://cloud.langfuse.com)
#
# Exit codes:
#   0 - success
#   1 - usage error
#   2 - missing credentials
#   3 - upstream Langfuse API failure (CLI calls)
#   4 - POST dataset-items failed

set -euo pipefail

ITEM_ID=""
QUEUE_ID=""
DATASET_NAME=""
CORRECTION=""
CORRECTION_FILE=""
OUTPUT_JSON=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --queue-id)        QUEUE_ID="$2"; shift 2 ;;
    --item-id)         ITEM_ID="$2"; shift 2 ;;
    --dataset-name)    DATASET_NAME="$2"; shift 2 ;;
    --correction)      CORRECTION="$2"; shift 2 ;;
    --correction-file) CORRECTION_FILE="$2"; shift 2 ;;
    --json)            OUTPUT_JSON=true; shift ;;
    -h|--help)
      sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
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
require QUEUE_ID     --queue-id
require ITEM_ID      --item-id
require DATASET_NAME --dataset-name

if [ -z "${LANGFUSE_PUBLIC_KEY:-}" ] || [ -z "${LANGFUSE_SECRET_KEY:-}" ]; then
  echo "LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY must be set" >&2
  exit 2
fi
BASE_URL="${LANGFUSE_BASE_URL:-https://cloud.langfuse.com}"

call() {
  local out
  if ! out=$(langfuse api "$@" --json 2>&1); then
    echo "langfuse api $* failed: $out" >&2
    exit 3
  fi
  if [ "$(echo "$out" | jq -r '.ok // false')" != "true" ]; then
    echo "langfuse api $* returned non-ok:" >&2
    echo "$out" >&2
    exit 3
  fi
  echo "$out"
}

ITEM=$(call annotation-queues get-get-queue-item "$QUEUE_ID" "$ITEM_ID" | jq '.body')
OBJECT_ID=$(echo "$ITEM" | jq -r '.objectId')
OBJECT_TYPE=$(echo "$ITEM" | jq -r '.objectType')
if [ "$OBJECT_TYPE" != "OBSERVATION" ]; then
  echo "only OBSERVATION-typed queue items are supported (got $OBJECT_TYPE)" >&2
  exit 1
fi

OBS=$(call observations list \
  --filter "[{\"type\":\"string\",\"column\":\"id\",\"operator\":\"=\",\"value\":\"$OBJECT_ID\"}]" \
  --fields "core,basic,io" \
  --limit 1 \
  | jq '.body.data[0]')
TRACE_ID=$(echo "$OBS" | jq -r '.traceId')

# Input = the user message content (the source text being extracted from).
INPUT_TEXT=$(echo "$OBS" | jq -r '.input' \
  | jq -r '[.[] | select(.role == "user")] | last | .content')

# Output = the parsed JSON extraction. The observation's output is
# {"content": "<json-string>", "role": "assistant"}; we want the
# decoded JSON object inside .content.
OUTPUT_JSON=$(echo "$OBS" | jq -r '.output' | jq -r '.content' | jq '.')

# Resolve correction (file takes precedence if both given).
CORRECTION_JSON=""
if [ -n "$CORRECTION_FILE" ]; then
  CORRECTION_JSON=$(cat "$CORRECTION_FILE")
elif [ -n "$CORRECTION" ]; then
  CORRECTION_JSON="$CORRECTION"
fi

if [ -n "$CORRECTION_JSON" ]; then
  EXPECTED=$(echo "$OUTPUT_JSON" | jq --argjson c "$CORRECTION_JSON" '. * $c')
else
  EXPECTED="$OUTPUT_JSON"
fi

BODY=$(jq -nc \
  --arg datasetName       "$DATASET_NAME" \
  --arg input             "$INPUT_TEXT" \
  --argjson expectedOutput "$EXPECTED" \
  --arg sourceTraceId     "$TRACE_ID" \
  --arg sourceObservationId "$OBJECT_ID" \
  --arg queueId           "$QUEUE_ID" \
  --arg itemId            "$ITEM_ID" \
  '{
    datasetName: $datasetName,
    input: $input,
    expectedOutput: $expectedOutput,
    sourceTraceId: $sourceTraceId,
    sourceObservationId: $sourceObservationId,
    metadata: {
      fromAnnotationQueueId: $queueId,
      fromAnnotationQueueItemId: $itemId
    }
  }')

RESP=$(curl -sS -u "$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY" \
  -X POST "$BASE_URL/api/public/dataset-items" \
  -H 'Content-Type: application/json' \
  -w '\n%{http_code}' \
  -d "$BODY")

STATUS=$(echo "$RESP" | tail -n1)
PAYLOAD=$(echo "$RESP" | sed '$d')

if [ "$STATUS" -lt 200 ] || [ "$STATUS" -ge 300 ]; then
  echo "POST /api/public/dataset-items -> $STATUS" >&2
  echo "$PAYLOAD" >&2
  exit 4
fi

if [ "$OUTPUT_JSON" = "true" ]; then
  echo "$PAYLOAD"
else
  echo "$PAYLOAD" | jq -r '"dataset item: \(.id)  (source obs: \(.sourceObservationId))"'
fi
