#!/usr/bin/env bash
# Fetch all context needed to annotate a single annotation queue item:
# the trace/observation input + output, plus the score configs that still
# need annotating (after applying the skip-list).
#
# Usage:
#   fetch-item-context.sh <queue-id> <item-id>
#
# Output: JSON on stdout, shape:
#   {
#     "queue":       { "id", "name" },
#     "item":        { "id", "objectId", "objectType", "status" },
#     "observation": { "id", "traceId", "name", "type", "input", "output", "metadata" }   # if OBSERVATION
#     "trace":       { ...full trace }                                                     # if TRACE
#     "configs":     [ { "id", "name", "dataType", "categories", "minValue", "maxValue" } ]
#   }
#
# The "configs" array contains only configs that are (a) on the queue,
# (b) not yet annotated for this item, and (c) not in skip-configs.txt.
#
# Exit codes:
#   0 - success
#   1 - usage error
#   2 - upstream API failure

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $(basename "$0") <queue-id> <item-id>" >&2
  exit 1
fi

QUEUE_ID="$1"
ITEM_ID="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_FILE="$SCRIPT_DIR/skip-configs.txt"

call() {
  local out
  if ! out=$(langfuse api "$@" --json 2>&1); then
    echo "langfuse api $* failed: $out" >&2
    exit 2
  fi
  if [ "$(echo "$out" | jq -r '.ok // false')" != "true" ]; then
    echo "langfuse api $* returned non-ok:" >&2
    echo "$out" >&2
    exit 2
  fi
  echo "$out"
}

ITEM=$(call annotation-queues get-get-queue-item "$QUEUE_ID" "$ITEM_ID" | jq '.body')
OBJECT_ID=$(echo "$ITEM" | jq -r '.objectId')
OBJECT_TYPE=$(echo "$ITEM" | jq -r '.objectType')

QUEUE=$(call annotation-queues get-get-queue "$QUEUE_ID" | jq '.body | {id, name}')
EXPECTED_IDS=$(call annotation-queues get-get-queue "$QUEUE_ID" | jq -r '.body.scoreConfigIds[]' | sort -u)

# Object payload (observation or trace)
if [ "$OBJECT_TYPE" = "OBSERVATION" ]; then
  OBJ=$(call observations list \
    --filter "[{\"type\":\"string\",\"column\":\"id\",\"operator\":\"=\",\"value\":\"$OBJECT_ID\"}]" \
    --fields "core,basic,io,metadata,model" \
    --limit 1 \
    | jq '.body.data[0] | {id, traceId, name, type, input, output, metadata}')
  OBJ_KEY="observation"
  SCORE_FILTER=(--queue-id "$QUEUE_ID" --observation-id "$OBJECT_ID")
elif [ "$OBJECT_TYPE" = "TRACE" ]; then
  OBJ=$(call traces get "$OBJECT_ID" | jq '.body')
  OBJ_KEY="trace"
  SCORE_FILTER=(--queue-id "$QUEUE_ID" --trace-id "$OBJECT_ID")
else
  echo "unexpected objectType: $OBJECT_TYPE" >&2
  exit 2
fi

# Already-annotated config IDs for this object in this queue
ANNOTATED=$(call scores list "${SCORE_FILTER[@]}" --limit 100 | jq -r '.body.data[].configId // empty' | sort -u)

# Diff -> missing config IDs
MISSING=$(comm -23 <(echo "$EXPECTED_IDS") <(echo "$ANNOTATED") || true)

# Skip-list (names, one per line, '#' comments allowed)
SKIP_NAMES=""
if [ -f "$SKIP_FILE" ]; then
  SKIP_NAMES=$(grep -vE '^\s*(#|$)' "$SKIP_FILE" || true)
fi

# Build configs array, filtering out skipped names
CONFIGS="[]"
while IFS= read -r CFG; do
  [ -z "$CFG" ] && continue
  CFG_JSON=$(call score-configs get-get-by-id "$CFG" \
    | jq '.body | {id, name, dataType, categories: (.categories // null), minValue, maxValue, description}')
  CFG_NAME=$(echo "$CFG_JSON" | jq -r '.name')
  if echo "$SKIP_NAMES" | grep -Fxq "$CFG_NAME"; then
    continue
  fi
  CONFIGS=$(jq --argjson c "$CFG_JSON" '. + [$c]' <<<"$CONFIGS")
done <<<"$MISSING"

jq -n \
  --argjson queue "$QUEUE" \
  --argjson item "$ITEM" \
  --argjson obj "$OBJ" \
  --arg obj_key "$OBJ_KEY" \
  --argjson configs "$CONFIGS" \
  '{queue: $queue, item: $item, configs: $configs} + {($obj_key): $obj}'
