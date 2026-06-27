---
name: fixup
description: "Analyse branch commits for fix-up opportunities. Identifies commits that are corrections to earlier commits and offers to squash them via interactive rebase with autosquash."
allowed-tools: Bash, AskUserQuestion
---

# Fixup Branch Commits

Analyse commits on the current branch, identify which are fixes/corrections to earlier commits, and offer to squash them for a cleaner history.

## Your Task

### 1. Identify the Base Branch

Determine the base branch (usually `main`). Run:

```bash
git merge-base HEAD main
```

### 2. List Branch Commits

Get all commits on the branch since the merge base:

```bash
git log --reverse --format="%H %s" $(git merge-base HEAD main)..HEAD
```

Parse into a numbered list of commits with their hashes and messages.

### 3. Analyse Each Commit for Fixup Candidates

For each commit, determine whether it is:

- **A standalone commit**: introduces new functionality, a new file, a new feature, or a meaningful refactor.
- **A fixup candidate**: a correction, bug fix, or tweak to something introduced by an earlier commit on this branch.

To decide, for each potential fixup candidate:

1. Run `git diff-tree --no-commit-id --name-only -r <hash>` to see which files it touches.
2. Compare those files against the files touched by earlier commits on the branch.
3. Read the commit message — look for signals like "fix", "correct", "update", "rename", "typo", "use X instead of Y", "add missing", etc.
4. If it modifies the same files as an earlier commit AND the change is clearly a correction/refinement (not a new feature layered on top), it's a fixup candidate.

**Important distinctions:**

- A commit that adds a NEW capability to the same file is NOT a fixup — it's a new feature.
- A commit that fixes a bug introduced by an earlier commit on this branch IS a fixup.
- A commit that changes a config value, renames something, or fixes a typo from an earlier commit IS a fixup.
- Infrastructure/build changes (turbo.json, package.json scripts) that support an earlier feature commit CAN be fixups if they were clearly meant to be part of that original commit.

### 4. Present the Analysis

Show the user a clear summary. For each commit on the branch, show:

```
## Branch Commits

1. abc1234 — Add user authentication module
   → Standalone: introduces new auth feature

2. def5678 — Fix bcrypt import in auth module
   → Fixup → #1 (abc1234 "Add user authentication module")
   Files overlap: src/auth/handler.ts
   Reason: fixes a broken import from the original commit

3. ghi9012 — Add rate limiting to auth endpoints
   → Standalone: adds new rate-limiting capability

4. jkl3456 — Use correct rate limit window value
   → Fixup → #3 (ghi9012 "Add rate limiting to auth endpoints")
   Files overlap: src/auth/rate-limit.ts
   Reason: corrects a config value from the rate limiting commit
```

### 5. Propose the Rebase Plan

If there are fixup candidates, show what the history would look like after squashing:

```
## Proposed Clean History

1. abc1234 — Add user authentication module
   (includes: "Fix bcrypt import in auth module")

2. ghi9012 — Add rate limiting to auth endpoints
   (includes: "Use correct rate limit window value")
```

### 6. Get User Confirmation

Use AskUserQuestion to ask the user whether to proceed with the fixup rebase. Options:

- **Apply all fixups** — squash all identified fixup candidates
- **Cancel** — leave history as-is

If the user confirms, proceed to step 7.

### 7. Execute the Rebase

For each fixup candidate (in reverse order — latest first), rename the commit to a `fixup!` commit targeting the original:

```bash
# For each fixup commit, create a fixup commit message
git rebase --onto <merge-base> <merge-base> HEAD --exec "true"
```

The safest approach:

1. Note the merge base hash.
2. For each fixup candidate, run:
   ```bash
   GIT_SEQUENCE_EDITOR="sed -i '' 's/^pick <fixup-hash>/fixup <fixup-hash>/'" git rebase -i <merge-base>
   ```

   Actually, use this approach instead — it's simpler and non-interactive:

   a. For each fixup commit (from latest to earliest), run:
      ```bash
      git commit --fixup=<target-hash>
      ```
      But since the commits already exist, we need to rewrite. Use:

   The correct approach:
   1. Run `git rebase -i <merge-base>` with a `GIT_SEQUENCE_EDITOR` that rewrites the todo list.
   2. Build a sed command that changes `pick <fixup-hash>` to `fixup <fixup-hash>` for each identified fixup.
   3. Also reorder so each fixup appears immediately after its target commit.

   Build the full `GIT_SEQUENCE_EDITOR` command:

   ```bash
   GIT_SEQUENCE_EDITOR="<sed-script>" git rebase -i <merge-base>
   ```

   The sed script should:
   - Remove the fixup commit lines from their current positions
   - Insert them as `fixup` lines immediately after their target commit lines

   Example for a single fixup (def5678 fixing abc1234):
   ```bash
   GIT_SEQUENCE_EDITOR="sed -i '' -e '/^pick def5678/d' -e '/^pick abc1234/a\\
   fixup def5678 Fix bcrypt import in auth module'" git rebase -i <merge-base>
   ```

   For multiple fixups, chain the sed commands.

### 8. Report Results

After the rebase completes, show:

```bash
git log --oneline <merge-base>..HEAD
```

And confirm the fixups were applied successfully.

If the rebase fails (e.g. conflicts), abort with `git rebase --abort` and tell the user what went wrong.

## Constraints

- NEVER force-push — only rewrite local branch history
- ALWAYS show the plan and get confirmation before rewriting history
- If the rebase fails, abort cleanly and report
- Only consider commits on the current branch (ahead of base), never rewrite shared history
