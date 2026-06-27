---
name: langfuse
description: Interact with Langfuse and access its documentation. Use when needing to (1) query or modify Langfuse data programmatically via the CLI — traces, prompts, datasets, scores, sessions, and any other API resource, (2) look up Langfuse documentation, concepts, integration guides, or SDK usage, or (3) understand how any Langfuse feature works. This skill covers CLI-based API access (via npx) and multiple documentation retrieval methods.
allowed-tools:
  - WebFetch(domain:langfuse.com)
  - Bash(langfuse api __schema *)
  - Bash(langfuse api * --help *)
  - Bash(langfuse api * list *)
  - Bash(langfuse api * get *)
  - Bash(langfuse api * get-*)
  - Bash(langfuse api annotation-queues update *)
  - Bash(bash */find-unannotated-scores.sh *)
  - Bash(bash */fetch-item-context.sh *)
  - Bash(bash */write-score.sh *)
  - Bash(bash */promote-to-dataset.sh *)
---

# Langfuse

This skill helps you use Langfuse effectively across all common workflows:
debugging traces, and accessing data programmatically.

## Core Principles

Follow these principles for ALL Langfuse work:

1. **Documentation First**: NEVER implement based on memory. Always fetch
   current docs before writing code (Langfuse updates frequently). See the
   section below on how to access documentation.
2. **CLI for Data Access**: Use `langfuse-cli` when querying/modifying Langfuse
   data. See the section below on how to use the CLI.
3. **Use latest Langfuse versions**: Unless the user specified otherwise or
   there's a good reason, always use the latest version of Langfuse SDKs/APIs.

## 1. Langfuse API via CLI

Use the `langfuse` CLI to interact with the full Langfuse REST API from the command line.

Documentation: https://langfuse.com/docs/api-and-data-platform/features/cli

Start by discovering the schema and available arguments:

```bash
# Discover all available resources
langfuse api __schema

# List actions for a resource
langfuse api <resource> --help

# Show args/options for a specific action
langfuse api <resource> <action> --help

# Preview the curl command without executing
langfuse api <resource> <action> --curl
```

### Tips

- Use `--json` for machine-readable JSON output
- Use `--curl` to preview the HTTP request without executing
- Pagination: use `--limit` and `--page` on list endpoints
- All list commands support filtering — check `<resource> <action> --help` for available options
- Prefer `observations-v2s` over `observations` — the v2 endpoint returns richer data
- Prefer `metrics-v2s` over `metrics` — the v2 endpoint returns richer data
- Prefer `score-v2s` over `scores` — the v1 `scores` resource only supports create/delete; use `score-v2s` for list and get operations

## 2. Annotation Queues

Annotation queues hold items (traces or observations) waiting for human review. Each queue has a fixed set of `scoreConfigIds` (the "scorecard") that reviewers fill in.

> **Lead Tagged Review queue**: the recurring "review my recruiter-lead extractions" workflow uses
> project `cmlib9i3a0131ad07268w56s9`, queue `cmlmbcbez0cpuad07tvet21uq`. Start from this queue ID
> when the user asks to review/annotate their lead tags.

### Concepts

- **Queue**: container with a name and a list of `scoreConfigIds`.
- **Queue item**: one trace/observation queued for review. Status is `PENDING` or `COMPLETED`.
- **Score config**: defines a single dimension to annotate (name, data type, allowed values).
- **Score**: an actual annotation written against a trace/observation, tied to a `configId` and (when entered via a queue) a `queueId`.

An item is "unannotated" for a given score config when no score with that `configId` exists on the item's object within the queue's context.

> **OTEL apps**: trace-level `input`/`output` is often null because the actual content lives on a child GENERATION observation. Expect queue items in these apps to use `objectType: OBSERVATION` pointing to the GENERATION observation ID, not `objectType: TRACE`.

### Listing queues and items

```bash
# All queues in the project
langfuse api annotation-queues list --json

# Items in a queue, filtered by status
langfuse api annotation-queues get-list-queue-items <queue-id> --status PENDING --limit 50 --json

# A single item (reveals objectId + objectType: OBSERVATION | TRACE)
langfuse api annotation-queues get-get-queue-item <queue-id> <item-id> --json
```

`--limit` is hard-capped at 100 on list endpoints; paginate with `--page` for larger queues.

### Finding unannotated score configs for an item

A helper script wraps the four-step query: resolve item → fetch queue scorecard → fetch existing scores for the object filtered by queue → diff.

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/find-unannotated-scores.sh <queue-id> <item-id>
```

Output is tab-separated `configId<TAB>name`, one missing config per line. Exit code `0` even when no configs are missing (empty output). Exit `2` on upstream API failure.

For a `PENDING` item, every config in the queue's `scoreConfigIds` will appear. For an in-progress item, only the gaps appear.

### Annotating an item

End-to-end workflow when the user wants to annotate a queue item.

#### 1. Fetch context

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-item-context.sh <queue-id> <item-id>
```

Returns a JSON blob containing the queue, item, observation/trace (with `input` and `output`), and the list of unannotated score configs (skip-listed names already removed). Each config includes its `dataType` and `categories` so you know the allowed values.

#### 2. Present a verdict table to the user

Map each remaining config to the field in the model's output it scores. Display a table:

| Field | Extracted value | Score config | Suggested | Reason |
|---|---|---|---|---|

Read the system prompt embedded in the trace (often in `observation.input[0].content`) to understand the extraction rules — these define what "correct" means. Common rule families:
- "Only what is explicitly and literally stated" → inferred-from-context values are `incorrect`.
- Schema notes like "Do not calculate from date ranges" → calculated values are `incorrect`.

Confirm verdicts with the user before writing.

#### 3. Write scores

One call per config:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/write-score.sh \
  --queue-id <queue-id> \
  --trace-id <trace-id> \
  --observation-id <observation-id> \
  --config-id <config-id> \
  --name <score-name> \
  --value <category-label> \
  --comment "<short reason>"
```

For categorical configs (the common case), `--value` is the category **label** (e.g. `"correct"`), not the numeric value. Langfuse fills in `stringValue` and the numeric `value` automatically from the config.

#### 4. Mark the item completed

Items do not auto-complete when the scorecard is filled. Patch the status:

```bash
langfuse api annotation-queues update <queue-id> <item-id> --status COMPLETED
```

#### Skip-list

`scripts/skip-configs.txt` lists score-config names to omit from the unannotated list. One name per line, `#` comments allowed. Add a name here to stop the workflow proposing verdicts for an orphaned/deprecated config without archiving it in Langfuse.

### Promoting completed items to a dataset

After an item is `COMPLETED`, you can promote it to a Langfuse dataset. The user message becomes `input`, the parsed extraction becomes `expectedOutput`, and the dataset item is linked back to the source observation.

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/promote-to-dataset.sh \
  --queue-id <queue-id> \
  --item-id <item-id> \
  --dataset-name <dataset-name> \
  [--correction '<json>' | --correction-file <path>] \
  [--json]
```

Use `--correction` (or `--correction-file`) to deep-merge a correction object into `expectedOutput` before saving — useful when the model's extraction was wrong and you want the dataset to reflect the ground-truth value.

By default prints `dataset item: <id>  (source obs: <obs-id>)`. Pass `--json` for the raw API response.

### Underlying API calls

If you need to do this without the scripts:

1. `annotation-queues get-get-queue-item <queue-id> <item-id>` → `body.objectId`, `body.objectType`
2. `annotation-queues get-get-queue <queue-id>` → `body.scoreConfigIds[]`
3. `scores list --queue-id <queue-id> --observation-id <obj-id>` (or `--trace-id` for trace-typed items) → existing `configId`s
4. Set difference of (2) minus (3), then `score-configs get-get-by-id <id>` to resolve each missing config to its name.
5. Write each missing score via `POST /api/public/scores` directly (the CLI's `legacy-score-v1s create` is broken for valued bodies). Body: `{traceId, observationId?, name, value, dataType, configId, queueId?, comment?}`. Auth is HTTP Basic with `LANGFUSE_PUBLIC_KEY:LANGFUSE_SECRET_KEY`.
6. Patch the item: `annotation-queues update <queue-id> <item-id> --status COMPLETED`.

## 3. Langfuse Documentation

Three methods to access Langfuse docs, in order of preference. **Always prefer your application's native web fetch and search tools** (e.g., `WebFetch`, `WebSearch`, `mcp_fetch`, etc.) over `curl` when available. The URLs and patterns below work with any fetching method — the `curl` examples are just illustrative.

### 2a. Documentation Index (llms.txt)

Fetch the full index of all documentation pages:

```bash
curl -s https://langfuse.com/llms.txt
```

Returns a structured list of every doc page with titles and URLs. Use this to discover the right page for a topic, then fetch that page directly.

Alternatively, you can start on `https://langfuse.com/docs` and explore the site to find the page you need.

### 2b. Fetch Individual Pages as Markdown

Any page listed in llms.txt can be fetched as markdown by appending `.md` to its path or by using `Accept: text/markdown` in the request headers. Use this when you know which page contains the information needed. Returns clean markdown with code examples and configuration details.

```bash
curl -s "https://langfuse.com/docs/observability/overview.md"
curl -s "https://langfuse.com/docs/observability/overview" -H "Accept: text/markdown"
```

### 2c. Search Documentation

When you need to find information across all docs and github issues/discussions without knowing the specific page:

```bash
curl -s "https://langfuse.com/api/search-docs?query=<url-encoded-query>"
```

Example:

```bash
curl -s "https://langfuse.com/api/search-docs?query=How+do+I+trace+LangGraph+agents"
```

Returns a JSON response with:

- `query`: the original query
- `answer`: a JSON string containing an array of matching documents, each with:
  - `url`: link to the doc page
  - `title`: page title
  - `source.content`: array of relevant text excerpts from the page

Search is a great fallback if you cannot find the relevant pages or need more context. Especially useful when debugging issues as all GitHub Issues and Discussions are also indexed. Responses can be large — extract only the relevant portions.

### Documentation Workflow

1. Start with **llms.txt** to orient — scan for relevant page titles
2. **Fetch specific pages** when you identify the right one
3. Fall back to **search** when the topic is unclear and you want more context

