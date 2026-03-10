---
name: annotate-lead-tags
description: Reviews items in the Langfuse "Lead Tagged Review" annotation queue. Reads traces where an LLM extracted structured job data from recruiter messages, compares extracted output against original input, and builds an assessment table for user approval. The user sets the scores manually, then Claude marks the item complete.
user-invocable: true
disable-model-invocation: false
allowed-tools: AskUserQuestion
---

You are an expert annotation reviewer. Your job is to review items in the Langfuse "Lead Tagged Review" annotation queue, where an LLM has extracted structured job data from unstructured recruiter messages. You compare the extracted output against the original input and score each field's accuracy.

## Workflow

Follow these steps in order. Do NOT skip steps or proceed without user confirmation where indicated.

### Step 1: Navigate to the queue

1. Use the Playwright MCP tool to navigate to:
   `https://cloud.langfuse.com/project/cmlib9i3a0131ad07268w56s9/annotation-queues/cmlmbcbez0cpuad07tvet21uq/items`
2. Take a snapshot of the page.
3. If a login page is shown (look for sign-in forms or login buttons), ask the user to log in manually, then keep taking snapshots every 10 seconds until the page changes to show the queue.
4. Once the queue is loaded, proceed to Step 2.

### Step 2: Read the trace data

1. Take a snapshot to read the page content.
2. Identify the **user input message** — this is the raw recruiter message that was sent to the LLM.
3. Identify the **assistant output** — this is the structured data the LLM extracted.
4. **Expand all collapsed fields**: Look for any elements showing "N items" or collapsed sections. Click each expand/toggle button to reveal the full content. After expanding, take another snapshot to read the complete values.
5. Extract all relevant fields from the assistant output. The key fields are:
   - `remote`
   - `daysOnSite`
   - `daysOnSiteFrequency`
   - `city`
   - `country`
   - `ir35`
   - `remuneration` (including `currency`, `high`, `low`)
   - `lengthInMonths`
   - `renewable`
   - `taggedContact` (including `email`, `phone`)
   - `securityClearance`

### Step 3: Build assessment table

For each of the following annotation scores, compare the assistant's extracted value against the user input:

- `city_accuracy`
- `contract_length_accuracy`
- `days_on_site_accuracy`
- `days_on_site_frequency_accuracy`
- `email_accuracy`
- `ir35_status_accuracy`
- `phone_number_accuracy`
- `remote_accuracy`
- `remuneration_accuracy`
- `renewable_contract_accuracy`
- `security_clearance_accuracy`

For each score, determine one of:
- **Correct** — the extracted value accurately reflects what is in the input
- **Incorrect** — the extracted value does not match or contradicts the input
- **Uncertain** — the input is ambiguous or the field cannot be verified

Build a markdown table with these columns:

| Score | Extracted Value | Assessment | Reference / Comment |
|-------|----------------|------------|---------------------|

- **Extracted Value** must be the literal value from the assistant's structured output payload (e.g. `"London"`, `"true"`, `"6"`, `null`). Do not paraphrase or summarise — use the exact value.
- If **Correct**: put the reference text from the input in the comment column
- If **Incorrect** or **Uncertain**: explain why in the comment column

Present this table to the user.

### Step 4: Gather user feedback

Ask the user:
> Do you agree with these assessments? If you'd like to change any scores, tell me which ones and what they should be.

- If the user wants changes, update the table accordingly
- Once the user confirms the final assessments, proceed to Step 5

### Step 5: Hand off to user

**Do NOT click or interact with any score dropdowns or checkboxes. The user will set these manually.**

Present the final assessments and ask the user to set the values in the browser manually. Then ask:
> Let me know when you're ready to continue.

Wait for the user to confirm before proceeding.

### Step 6: Mark completed

1. Click the "Mark Completed" button
2. Take a snapshot to confirm the queue advanced to the next item
3. Ask the user:
   > Item marked as completed. Would you like to continue with the next item?

- If yes: loop back to Step 2
- If no: end the workflow
