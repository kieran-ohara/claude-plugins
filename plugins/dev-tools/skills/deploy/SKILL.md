---
name: deploy
description: "Deploy affected packages. Identifies which packages have changes relative to main, shows a summary, and deploys each in parallel using deploy-runner agents."
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion
---

# Deploy Affected Packages

Identify packages affected by current branch changes, summarise what changed, get user confirmation, then deploy each package in parallel.

## Your Task

### 0. Resolve Configuration

You need two values before proceeding: the **AWS profile** and the **deploy script name**.

For each, check Claude Code memory for a stored value for this project. If not found, stop and help the user save it:

**AWS profile**: Look in memory for the AWS deploy profile for this project. If not found, run `aws configure list-profiles` and show the available profiles as a hint, then ask the user to save the AWS deploy profile to memory first (e.g. "Please ask me to remember your AWS deploy profile, then run /deploy again").

**Deploy script name**: Look in memory for the deploy script name for this project (e.g. `deploy:dev`, `deploy:staging`). If not found, read `turbo.json` at the repo root to find available task names and show them as a hint, then ask the user to save the deploy script name to memory first.

If either value is missing, stop after asking — do not proceed to step 1.

### 1. Identify Affected Deployable Packages

Run turbo to find affected packages:

```bash
npx turbo ls --affected --output json
```

Parse the JSON output to get the list of affected package names and paths.

Then, for each affected package, read its `package.json` and check whether it has the deploy script. Only packages with that script are deployable — filter out the rest.

If no deployable packages are affected, tell the user and stop.

### 2. Summarise Changes

For each deployable package, run:

```bash
git diff main...HEAD --stat -- <package-path>
```

Present a table to the user:

```
| Package | Path | Files Changed |
|---------|------|---------------|
```

### 3. Get User Confirmation

Use AskUserQuestion to ask the user to confirm they want to deploy the listed packages. Wait for confirmation before proceeding.

If the user declines, stop.

### 4. Pre-authenticate AWS Vault

Before spawning parallel agents, force aws-vault to cache credentials so that multiple agents don't each trigger a keychain popup simultaneously:

```bash
AWS_PROFILE=<profile> aws sts get-caller-identity
```

Wait for this to succeed before proceeding. If it fails, stop and report the error.

### 5. Spawn Parallel Deploy Agents

For each confirmed package, spawn a `deploy-runner` agent using the Task tool:

- **subagent_type**: `deploy-runner`
- **description**: "Deploy: [package-name]"
- **prompt**:
  ```
  Deploy the following package:

  - **Package**: [package name]
  - **Path**: [package path]
  - **AWS Profile**: [profile]

  Run: `aws-vault exec <profile> -- npx turbo run <deploy-script> --filter=[package-name]`

  Monitor the output and report success or failure.
  ```

**Important**: Spawn all agents **in parallel** using a single response with multiple Task tool invocations.

### 6. Report Results

Collect results from all agents. Present a summary:

```
| Package | Status | Notes |
|---------|--------|-------|
```

## Constraints

- ALWAYS wait for user confirmation before deploying
- NEVER modify code or commit anything — this skill only deploys
- Use `aws-vault exec <profile> --` for CDK deploy commands
- Use turbo `--filter` so that synth dependencies are handled automatically
