---
name: find-use-cases
description: Scans a codebase to discover and catalogue all use cases (API endpoints, event handlers, frontend pages, background jobs). Use when onboarding to a new project or before running analyse-use-cases.
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Grep
  - Glob
---

You are a codebase analyst. Scan the codebase at `$ARGUMENTS` and produce a comprehensive catalogue of all use cases, then present it in the conversation.

## 1. Discovery

Scan the target path to identify use cases by examining:

- UI pages, screens, and user-facing components
- API endpoints, route definitions, and controllers
- Command handlers, event handlers, and message consumers
- Background jobs, scheduled tasks, and workflows

## 2. Catalogue Each Use Case

For each use case found, record its name, description, trigger, entry point, and external integrations. The trigger format depends on the type:

- API: `<HTTP verb> <endpoint URL>`
- Event Handler: `<EventName>`
- Frontend Page: `<route path>`
- Background Job: `<schedule or trigger>`

## 3. Organise and Present

Present the catalogue in two sections:

### Frontend Pages — grouped by domain

Group frontend pages by the domain concept they relate to (e.g. Orders, Users, Settings), not by backend service. These represent what the user is trying to do.

```markdown
# Frontend Pages

## <Domain Area>

<One-line description of this domain area>

- **<Use Case Name>**: One-line description
  - Route: `<route path>`
  - Entry point: `<file path>`
  - External integrations: <list, or "None">
```

### Backend Use Cases — grouped by service

Group APIs, event handlers, and background jobs by the service they belong to.

```markdown
# <Service Name>

<2-3 sentence service description derived from its use cases>

## APIs

- **<Use Case Name>**: One-line description
  - Endpoint: `<HTTP verb> <endpoint URL>`
  - Entry point: `<file path>`
  - External integrations: <list, or "None">

## Event Handlers

- **<Use Case Name>**: One-line description
  - Event: `<EventName>`
  - Entry point: `<file path>`
  - External integrations: <list, or "None">

## Background Jobs

- **<Use Case Name>**: One-line description
  - Schedule: `<schedule or trigger>`
  - Entry point: `<file path>`
  - External integrations: <list, or "None">
```

Omit any sub-section that has no use cases for that service.

## Quality Checks

Before presenting, verify:

- Every use case has all template fields filled in
- Entry points reference real file paths found in the codebase
- Services are named consistently across use cases
- Frontend pages are grouped by domain concept, not by technical structure
- No duplicate use cases across sections
