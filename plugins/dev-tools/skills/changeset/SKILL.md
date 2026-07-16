---
name: changeset
description: "Create changesets for modified packages. Analyzes git changes to determine which packages need version bumps, what type of bump (major/minor/patch), and generates appropriate changeset files. Use when preparing a release, after completing a feature, or when the user wants to version their changes."
argument-hint: "[package-name (optional)]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Task
---

# Create Changeset

Generate changeset files by analyzing what has changed in the monorepo.

## Arguments

- `$ARGUMENTS` — Optional. A specific package name (e.g. `@my-org/api`). If omitted, auto-detect all changed packages.

## Your Task

### 0. Read Changeset Config

Find and read the `.changeset/config.json` file at the monorepo root using the Glob and Read tools. If it does not exist, this repo is not set up for Changesets — tell the user and stop.

Extract:
- `baseBranch` — the branch to diff against (usually `main`)
- `ignore` — package patterns to exclude from changesets

Use these values throughout the steps below.

### 1. Identify Changed Packages

If `$ARGUMENTS` is provided, use that as the target package. Otherwise, detect changed packages:

1. Run `git diff --name-only <baseBranch>...HEAD` to get all changed files since the base branch (use the value from changeset config)
2. For each changed file, determine which workspace package it belongs to by finding the nearest `package.json`
3. Read each affected `package.json` to get the package name and current version
4. Filter out packages that match the `ignore` patterns from the changeset config

If no packages have changes (or all are ignored), tell the user and stop.

### 2. Analyze Each Package

For each changed package, spawn a **changeset-package-analyzer** agent using the Task tool with:

- **subagent_type**: `changeset-package-analyzer`
- **description**: "Analyze changes: [package-name]"
- **prompt**: Construct a prompt with the following format:

```
## Package
- **Name**: [package name from package.json]
- **Current Version**: [version from package.json]
- **Path**: [path to package root, relative to monorepo root]
- **Base Branch**: [baseBranch from changeset config]

## Changed Files
[list of changed files within this package from the git diff]

Analyze the changes in this package and recommend a changeset.
```

**Important**: Spawn agents **in parallel** using a single response with multiple Task tool invocations.

### 3. Synthesize Results

Wait for all agents to complete. For each agent response, extract:

- Package name
- Recommended bump type (major / minor / patch)
- Summary of changes

### 4. Present Proposal

Present the proposed changeset(s) to the user:

```
# Proposed Changeset

## Packages

### [package-name] (current: x.y.z → proposed: a.b.c)
**Bump**: [major/minor/patch]
**Summary**: [1-2 sentence description of changes]

---

Shall I create this changeset?
```

Wait for user confirmation before proceeding.

### 5. Write Changeset File

Once confirmed, write a single changeset markdown file to `.changeset/` with a random kebab-case name (e.g. `.changeset/brave-foxes-dance.md`).

The file format is:

```markdown
---
"package-name-1": major
"package-name-2": minor
---

Summary of changes here.
```

If changes span multiple packages and the summaries are distinct, you may create separate changeset files — one per package. Use your judgement: if changes are related, a single file is cleaner.

## Constraints

- DO NOT run `npx changeset` — it is interactive and will hang
- DO NOT commit anything — just create the changeset file(s)
- DO NOT bump versions directly — changesets handles that separately
- ALWAYS wait for user confirmation before writing files
- Changeset filenames should be random two-word-verb kebab-case (e.g. `tall-dogs-fly.md`, `quick-pens-draw.md`)
