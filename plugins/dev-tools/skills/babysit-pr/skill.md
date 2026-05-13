---
name: babysit-pr
description: Detect the PR for the current branch, rebase if behind base, check CI, fix failures, push, and use /loop to poll until green.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion, Skill
---

# Babysit PR

Shepherd the current branch's PR through CI. Detect the PR, check CI once, fix any failures, push, and hand off polling to `/loop`.

## Your Task

### 1. Detect the PR

Find the PR associated with the current branch:

```bash
gh pr view --json url,number,title --jq '{url, number, title}'
```

If no PR exists, tell the user and stop.

Report the PR URL and title to the user.

### 2. Sync Local Branch

Pull any remote changes (e.g. from a previous GitHub-side rebase):

```bash
git pull --rebase
```

### 3. Check if Branch is Behind Base

Check whether the PR branch is behind its base branch using the compare API (more reliable than `mergeStateStatus` which can return `UNKNOWN`):

```bash
gh pr view --json baseRefName,headRefName --jq '{baseRefName, headRefName}'
gh api repos/{owner}/{repo}/compare/{baseRefName}...{headRefName} --jq '{behind_by: .behind_by}'
```

If `behind_by` is greater than 0:

1. Tell the user the branch is behind and you're rebasing via GitHub.
2. Use the GitHub API to trigger an update (rebase):

```bash
gh api repos/{owner}/{repo}/pulls/{number}/update-branch -X PUT -f update_method=rebase
```

3. After triggering the rebase, use the `/loop` skill to re-run `/babysit-pr` every 5 minutes (the rebase will trigger a new CI run). Stop here.

If not behind, proceed to step 4.

### 4. Check CI Status

Query the PR's check status:

```bash
gh pr checks
```

Categorise the result:
- **All passed**: Tell the user "CI is green!" and stop.
- **Still running**: Use the `/loop` skill to re-run `/babysit-pr` every 5 minutes. Tell the user you've set up polling and stop.
- **Failed**: Proceed to step 5.

### 5. Identify the Failure

Get details of the failing check(s):

```bash
gh pr checks --json name,state,detailsUrl --jq '.[] | select(.state == "FAILURE" or .state == "ERROR")'
```

For each failing check, fetch the build logs:

```bash
gh run view <run-id> --log-failed 2>&1 | tail -200
```

If the run ID is not directly available, list runs for the branch:

```bash
gh run list --branch $(git branch --show-current) --limit 5 --json databaseId,status,conclusion,name
```

Then view the failed run's logs.

### 6. Diagnose and Fix

Analyse the failure logs to determine the root cause. Common causes:
- **Test failures**: Read the failing test and the code under test, then fix
- **Lint / format errors**: Run the linter/formatter locally and fix
- **Type errors**: Read the relevant files and fix type issues
- **Build errors**: Read build output and fix

Make the minimal fix needed. Run the relevant check locally to verify:
- Tests: `yarn turbo test:unit` (or scoped to the affected workspace)
- Lint: `npx prettier --check '**/*.{ts,tsx,md}'` in the relevant package
- Types: `npx tsc --noEmit` in the relevant package

### 7. Commit and Push

Once the local check passes:

1. Stage only the changed files (never `git add .` or `git add -A`)
2. Commit with a plain, descriptive message explaining the fix
3. Push to the remote branch:

```bash
git push
```

### 8. Loop

After pushing a fix, use the `/loop` skill to re-run `/babysit-pr` every 5 minutes so that the next CI run is checked automatically.

If this is already the 3rd fix attempt (check git log for previous fix commits on this branch since the last non-fix commit), present a summary of what was tried and ask the user how to proceed instead of looping.

### 9. Report

Once CI is green, tell the user:
- The PR URL
- How many fix iterations were needed
- A brief summary of what was fixed

## Constraints

- NEVER use `git add .` or `git add -A` — always stage specific files
- NEVER amend existing commits
- NEVER force push
- NEVER use conventional commit prefixes (no `feat:`, `fix:`, etc.)
- NEVER make changes unrelated to fixing the CI failure
- NEVER poll CI with sleep loops — use `/loop` instead
- Maximum 3 fix-and-push iterations before asking the user
- If the failure is ambiguous or unclear, ask the user rather than guessing
- If a failure requires infrastructure changes (e.g. CDK, AWS config), ask the user before proceeding
