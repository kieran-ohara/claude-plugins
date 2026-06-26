#!/usr/bin/env bash
# Find score configs that have not yet been annotated for a given
# annotation queue item.
#
# Usage:
#   find-unannotated-scores.sh <queue-id> <item-id>
#
# Output (text, one per line):
#   <configId>\t<name>
#
# Exit codes:
#   0 - success (zero or more missing configs printed)
#   1 - usage error
#   2 - upstream API failure

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $(basename "$0") <queue-id> <item-id>" >&2
  exit 1
fi

QUEUE_ID="$1"
ITEM_ID="$2"

call() {
  local out
  if ! out=$(langfuse api "$@" --json 2>&1); then
    echo "langfuse api $* failed: $out" >&2
    exit 2
  fi
  if [ "$(echo "$out" | jq -r '.ok // false')" != "true" ]; then
    echo "langfuse api $* returned non-ok response:" >&2
    echo "$out" >&2
    exit 2
  fi
  echo "$out"
}

# 1. Resolve item -> observationId
ITEM_JSON=$(call annotation-queues get-get-queue-item "$QUEUE_ID" "$ITEM_ID")
OBJECT_ID=$(echo "$ITEM_JSON" | jq -r '.body.objectId')
OBJECT_TYPE=$(echo "$ITEM_JSON" | jq -r '.body.objectType')

if [ "$OBJECT_TYPE" != "OBSERVATION" ] && [ "$OBJECT_TYPE" != "TRACE" ]; then
  echo "unexpected objectType: $OBJECT_TYPE" >&2
  exit 2
fi

# 2. Expected score configs from the queue
QUEUE_JSON=$(call annotation-queues get-get-queue "$QUEUE_ID")
EXPECTED=$(echo "$QUEUE_JSON" | jq -r '.body.scoreConfigIds[]' | sort -u)

# 3. Score configs already annotated on this object within this queue
SCORE_FILTER=(--queue-id "$QUEUE_ID" --limit 100)
if [ "$OBJECT_TYPE" = "OBSERVATION" ]; then
  SCORE_FILTER+=(--observation-id "$OBJECT_ID")
else
  SCORE_FILTER+=(--trace-id "$OBJECT_ID")
fi
SCORES_JSON=$(call scores list "${SCORE_FILTER[@]}")
ANNOTATED=$(echo "$SCORES_JSON" | jq -r '.body.data[].configId // empty' | sort -u)

# 4. Diff and resolve names
MISSING=$(comm -23 <(echo "$EXPECTED") <(echo "$ANNOTATED") || true)
if [ -z "$MISSING" ]; then
  exit 0
fi

while IFS= read -r CFG; do
  [ -z "$CFG" ] && continue
  NAME=$(call score-configs get-get-by-id "$CFG" | jq -r '.body.name')
  printf '%s\t%s\n' "$CFG" "$NAME"
done <<< "$MISSING"
