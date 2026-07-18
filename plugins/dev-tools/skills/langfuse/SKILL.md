---
name: langfuse
description: Interact with Langfuse and access its documentation. Use when needing to (1) query or modify Langfuse data via MCP tools — traces, observations, prompts, datasets, scores, sessions, annotation queues, and any other API resource, (2) look up Langfuse documentation, concepts, integration guides, or SDK usage, or (3) understand how any Langfuse feature works. This skill covers MCP-based data access and multiple documentation retrieval methods.
allowed-tools:
  - WebFetch(domain:langfuse.com)
  - mcp__1mcp-dev__langfuse_1mcp_listAnnotationQueues
  - mcp__1mcp-dev__langfuse_1mcp_listAnnotationQueueItems
  - mcp__1mcp-dev__langfuse_1mcp_getAnnotationQueue
  - mcp__1mcp-dev__langfuse_1mcp_getAnnotationQueueItem
  - mcp__1mcp-dev__langfuse_1mcp_updateAnnotationQueueItem
  - mcp__1mcp-dev__langfuse_1mcp_listScores
  - mcp__1mcp-dev__langfuse_1mcp_getScoreConfig
  - mcp__1mcp-dev__langfuse_1mcp_createScore
  - mcp__1mcp-dev__langfuse_1mcp_getObservation
  - mcp__1mcp-dev__langfuse_1mcp_listObservations
  - mcp__1mcp-dev__langfuse_1mcp_upsertDataset
  - mcp__1mcp-dev__langfuse_1mcp_upsertDatasetItem
  - mcp__1mcp-dev__langfuse_1mcp_listDatasetItems
  - mcp__1mcp-dev__langfuse_1mcp_deleteDatasetItem
---

# Langfuse

This skill helps you use Langfuse effectively across all common workflows:
debugging traces, and accessing data programmatically.

## Core Principles

Follow these principles for ALL Langfuse work:

1. **Documentation First**: NEVER implement based on memory. Always fetch
   current docs before writing code (Langfuse updates frequently). See the
   section below on how to access documentation.
2. **MCP for Data Access**: Use the Langfuse MCP tools when querying/modifying
   Langfuse data. See the section below on how to use them.
3. **Use latest Langfuse versions**: Unless the user specified otherwise or
   there's a good reason, always use the latest version of Langfuse SDKs/APIs.

## 1. Langfuse Data Access via MCP

Use the Langfuse MCP tools (`mcp__1mcp-dev__langfuse_1mcp_*`) for all
programmatic access to Langfuse data — traces, observations, scores,
annotation queues, datasets, prompts, metrics, and more.

These tools are deferred; load their schemas once per session with
ToolSearch before calling them, e.g.:

```
select:mcp__1mcp-dev__langfuse_1mcp_listAnnotationQueues,mcp__1mcp-dev__langfuse_1mcp_getAnnotationQueueItem,mcp__1mcp-dev__langfuse_1mcp_createScore
```

or a keyword search (`langfuse dataset`, `langfuse prompt`, `langfuse metrics`,
...) for a tool not already listed in this skill's `allowed-tools`.

### Known gap: no trace-fetch tool

There is no `getTrace`/`listTraces` tool. To inspect a trace's own
input/output/metadata, call `listObservations` with `traceId` and take the
observation whose `parentObservationId` is empty (the root span) — its
`input`/`output`/`metadata` mirror the trace's. Trace-only fields (`tags`,
`bookmarked`, `public`, `release`) are not recoverable this way; none of the
workflows in this skill depend on them.

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

```
listAnnotationQueues({ page: 1, limit: 50 })

listAnnotationQueueItems({ queueId, status: "PENDING", page: 1, limit: 50 })

getAnnotationQueueItem({ queueId, itemId })   # reveals objectId + objectType: OBSERVATION | TRACE
```

`limit` is capped at 100; paginate with `page` for larger queues.

### Finding unannotated score configs for an item

1. `getAnnotationQueueItem({ queueId, itemId })` → `objectId`, `objectType`
2. `getAnnotationQueue({ queueId })` → `scoreConfigIds[]` (the expected scorecard)
3. `listScores({ queueId, observationId: [objectId], page: 1, limit: 100 })` — or `traceId: objectId` when `objectType` is `TRACE` — → `configId`s already scored on this object within this queue
4. Missing configs = `scoreConfigIds` minus the `configId`s from step 3 (plain set diff, no tooling needed)
5. For each missing id, `getScoreConfig({ configId })` → resolve to `{name, dataType, categories}`

For a `PENDING` item, every config in the queue's `scoreConfigIds` will appear missing. For an in-progress item, only the gaps appear.

Score reads are eventually consistent — a score just written may not show up in `listScores` immediately; retry briefly if a just-created score seems to be missing.

### Annotating an item

End-to-end workflow when the user wants to annotate a queue item.

#### 1. Fetch context

Assemble in one pass:

- `getAnnotationQueue({ queueId })` → queue name + `scoreConfigIds[]`
- `getAnnotationQueueItem({ queueId, itemId })` → `objectId`, `objectType`, `status`
- The object itself:
  - `objectType: OBSERVATION` → `getObservation({ observationId: objectId, fields: ["*"] })` for `input`/`output`/`metadata`
  - `objectType: TRACE` → `listObservations({ traceId: objectId, fields: ["*"] })`, then take the root observation (empty `parentObservationId`) — see the trace-fetch gap note above
- Missing score configs (the 5-step lookup above)
- Filter out any config whose `name` appears in `skip-configs.txt` (see below)

Each remaining config includes its `dataType` and `categories` so you know the allowed values.

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

```
createScore({
  traceId,
  observationId,   // only when scoring an observation
  configId,
  queueId,
  name,
  value,           // category LABEL for CATEGORICAL/TEXT/CORRECTION (e.g. "correct"), a number for NUMERIC/BOOLEAN
  dataType,        // "CATEGORICAL" | "NUMERIC" | "BOOLEAN" | "CORRECTION" | "TEXT"
  comment,
})
```

For categorical configs (the common case), `value` is the category **label**, not the numeric value — Langfuse fills in `stringValue` and the numeric `value` automatically from the config.

#### 4. Mark the item completed

Items do not auto-complete when the scorecard is filled. Update the status:

```
updateAnnotationQueueItem({ queueId, itemId, status: "COMPLETED" })
```

#### Skip-list

`skip-configs.txt` lists score-config names to omit from the unannotated list. One name per line, `#` comments allowed. Add a name here to stop the workflow proposing verdicts for an orphaned/deprecated config without archiving it in Langfuse.

### Promoting completed items to a dataset

After an item is `COMPLETED`, you can promote it to a Langfuse dataset. Only `OBSERVATION`-typed items are supported (dataset items are sourced from an observation's input/output).

1. `getAnnotationQueueItem({ queueId, itemId })` → `objectId`
2. `getObservation({ observationId: objectId, fields: ["*"] })` → inspect the *actual* `input`/`output` shape for this integration before extracting. Do not assume a fixed shape (e.g. langchain chat-messages in, `{content, role}` out) — extraction targets vary per app. Derive:
   - `input`: the source content being extracted from (e.g. the user-facing message text)
   - `expectedOutput`: the parsed extraction to treat as ground truth
3. If the user supplies a correction, deep-merge it into `expectedOutput` before saving, so the dataset reflects the *correct* answer rather than the model's mistake
4. `upsertDataset({ name: <dataset-name> })` → idempotent; returns the dataset whether it already existed or not — use its `id` next
5. `upsertDatasetItem({ datasetId, input, expectedOutput, sourceTraceId: <observation.traceId>, sourceObservationId: objectId, metadata: { fromAnnotationQueueId: queueId, fromAnnotationQueueItemId: itemId } })`

Pass an explicit `id` to `upsertDatasetItem` if you need retries to be idempotent — otherwise a new item is created (with an auto-generated id) on every call.

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
