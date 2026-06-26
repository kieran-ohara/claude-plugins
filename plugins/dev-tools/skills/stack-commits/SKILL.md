---
name: stack-commits
description: >-
  Reorganize the commits on the current branch (main..HEAD) into a small set of
  independent, cohesive, atomic commits — one feature per commit, ordered by
  dependency. Use when the user wants to stack, restack, restructure, or clean
  up branch history; split interleaved work into separate commits or PRs;
  collapse a messy WIP branch into reviewable units; or prepare a branch for
  review. Triggers on phrases like "stack the work", "do some git fu", "make
  these atomic commits", "split this branch", or "clean up the history".
argument-hint: "[base-branch — defaults to main]"
---

# Stack commits into independent, cohesive units

Turn the raw commit history of a feature branch into a handful of clean,
atomic commits where **each commit introduces one independent, cohesive
feature** and the commits are ordered by dependency. The rewrite must be
**lossless** — the final tree byte-identical to the original HEAD.

This is judgement work, not a script. Think first, get the human to decide the
shape, then execute with a safety net.

## Operating principles

- **One commit = one purpose.** A reviewer should grasp each commit's intent
  from its diff alone. No "and also" commits.
- **Orthogonal threads float to the base.** Work that touches a disjoint set of
  files (a backend fix, a dead-code deletion) has no dependency on the feature
  and should land first as its own commit/PR.
- **Lossless or it didn't happen.** Always prove the rebuilt tree equals the
  original with an empty `git diff`. This is the non-negotiable safety gate.
- **The human owns the shape.** Granularity (how many commits) and delivery
  (one branch vs separate PRs) are their call — ask before rewriting.

## Procedure

### 1. Map the work

```bash
git rev-list --count <base>..HEAD
git log --reverse --oneline --name-only <base>..HEAD   # per-commit file lists
git diff --name-status <base>..HEAD                     # net change set
```

Read both: per-commit files show *how the work was done*; the net diff shows
*what the branch actually delivers* (including renames `R###` and
add-then-delete churn that cancels out).

### 2. Cluster into threads

Group the source commits into **threads** — each a candidate final commit.
Cluster by *concern*, not by chronology. Typical threads:

- Backend / infra changes (often a disjoint file set → orthogonal).
- Pure deletions / dead-code removal (orthogonal).
- Structural moves / renames / relocations.
- The actual feature (UI restyle, new capability) — usually the bulk.

For each thread note its **files** and whether it **shares files** with another
thread (this is where conflicts will live — see §5).

### 3. Order by dependency

Determine which threads truly depend on others (e.g. a restyle that edits files
at paths a *relocation* thread created depends on it). Draw the stack:

```
<base>
 ├─ A  orthogonal-fix      (independent)
 ├─ B  dead-code-removal   (independent)
 └─ C  relocation
        └─ D  the-feature
```

### 4. Let the human decide shape

Use AskUserQuestion for the two decisions that change execution:

- **Granularity** — collapse each thread to one commit? split the big feature
  further? or just reorder and keep existing messages?
- **Delivery** — one stacked branch (single PR) or separate branches/PRs so the
  orthogonal threads can merge independently?

### 5. Rebuild — safely

**Always back up first:**

```bash
git branch -f backup/<branch>-pre-stack <branch>
```

Replay onto a temp branch at the base, building each commit's tree:

```bash
git checkout -B stack-tmp <base>
```

Then, thread by thread in dependency order:

- **Already-atomic, clean threads** → `git cherry-pick <sha>`.
- **Multi-commit threads** → cherry-pick each source commit one at a time
  (resolving conflicts as they surface), then collapse:
  `git reset --soft HEAD~<n>` and re-commit with a single cohesive message.
- **The FINAL thread is free.** Because it is the last commit, its tree is *by
  definition* identical to the original HEAD. Skip the replay-and-resolve dance
  entirely:

  ```bash
  git checkout backup/<branch>-pre-stack -- .   # stages original content
  git commit -m "<final thread message>"
  ```

  The diff from the previous commit to this one *is* the final thread, exactly.

**Resolving conflicts from reordering:** conflicts appear on files two reordered
threads both touch. You always know the answer — the original HEAD is ground
truth. For a file fully owned by the current-or-earlier thread,
`git checkout backup/<branch>-pre-stack -- <file>` gives its correct content.
For genuinely split files, take the side matching that thread's intent (read the
source commit's diff to confirm). Watch for **add-then-remove pairs** across
reordered threads (e.g. a class added in the feature and removed in the
relocation) — after reordering one side may no-op; that's fine as long as the
final tree verifies.

### 6. Prove it is lossless

```bash
git diff --quiet backup/<branch>-pre-stack stack-tmp && echo "IDENTICAL" || echo "MISMATCH — STOP"
git log --oneline --stat <base>..stack-tmp   # eyeball each commit is cohesive
```

If the trees differ, **do not proceed** — investigate the mismatch.

### 7. Land it

```bash
git checkout <branch>
git reset --hard stack-tmp
git branch -D stack-tmp
```

Then report:

- The final stack (table: commit → what it is → depends on).
- That the rewrite is lossless (verified) and the backup ref still exists, with
  the command to delete it once they're happy.
- **If the branch was already pushed**, the remote now diverges — they need
  `git push --force-with-lease origin <branch>`. Never force-push for them
  without being asked.

## Gotchas

- `git add .` / `git add -A` may be blocked by repo hooks — stage explicit
  paths. `git checkout <ref> -- .` stages as it writes, avoiding the need.
- Use `--force-with-lease`, never bare `--force`.
- Renames: prefer letting git detect them (`R###` in `--name-status`); resolve
  rename conflicts by taking the moved-to path and `git rm` the moved-from path.
- Don't run the full rewrite without the user's granularity/delivery answers —
  the shape determines the replay.
- Optionally offer to `typecheck`/`lint` each intermediate commit for
  bisectability, but the verified-identical tip already builds as before.
