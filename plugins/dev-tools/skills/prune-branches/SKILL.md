---
name: prune-branches
description: "Find and delete local branches whose content has already landed on the trunk — including squash-merged branches that git cannot detect as merged. Handles gh-stack-tracked branches via gh stack sync --prune, and classifies everything else by whether merging it into trunk today would change anything. Use when asked to prune branches, clean up landed/merged/zombie branches, or when rebasing old branches keeps producing conflicts that resolve to nothing."
allowed-tools: Bash, AskUserQuestion
---

# Prune Landed Branches

Local branches that were squash-merged (or rebase-merged) never appear merged to
git: the trunk got new commit objects, so `git branch -d` refuses, `git branch
--merged` misses them, and tools like git-branchless try to rebase the "unmerged"
commits — producing conflict after conflict that resolves to an empty change.
The reliable question is not "are these commits on trunk?" but **"would merging
this branch into trunk today change anything?"** — answered by `git merge-tree`
without touching the working copy.

## Your Task

### 1. Establish the trunk and fetch it

```bash
trunk=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||')
trunk=${trunk:-main}
git fetch origin "$trunk" --quiet
```

All comparisons below are against `origin/$trunk` (NOT local trunk — it may be
stale or ahead).

### 2. Enumerate candidate branches

```bash
git for-each-ref refs/heads/ --format='%(refname:short)'
git worktree list
```

Exclude from candidacy:
- The trunk itself.
- Any branch checked out in a worktree (including the current branch — it can
  still be *reported* as landed, but deleting it requires switching to trunk
  first, and a worktree checkout elsewhere blocks deletion entirely).
- Backup branches (`backup/*`) tied to a candidate — group them with their
  primary branch so they're offered for deletion together.

### 3. Partition: gh-stack-tracked vs standalone

`gh stack` keeps its tracking in a JSON file at
`$(git rev-parse --git-common-dir)/gh-stack`. Read it (read-only) to find which
local branches belong to a tracked stack:

```bash
stackfile="$(git rev-parse --git-common-dir)/gh-stack"
if [ -f "$stackfile" ]; then
  jq -r '.stacks[] | .id as $id | .branches[] | "\($id)\t\(.branch)\t\(.pullRequest.merged // false)"' "$stackfile"
fi
```

Cross-reference against the local branch list — the file may mention branches
already deleted; only rows whose branch still exists locally matter.

**Stack-tracked branches are pruned by gh-stack, not by hand.** For each stack
that still has local branches:

- If **every** branch in the stack has a merged PR, or the stack mixes merged
  and still-open branches: run `gh stack sync --prune` **from a branch in that
  stack** (`git checkout <any-stack-branch>` first — it does not work from
  trunk). This fetches, fast-forwards trunk, cascade-rebases still-open
  branches, and deletes local branches whose PRs are merged. Do this while the
  tracking still exists.
- If tracking is already lost (`gh stack view --json` from the branch reports
  it is not part of a stack), fall back to treating those branches as
  standalone (step 4).
- In non-interactive environments the prune prompt may not appear; if
  `sync --prune` reports merged branches it could not delete, delete them
  yourself with `git branch -D` after confirming the PR state.

Do NOT run `sync --prune` yet — collect what it *would* affect and fold it into
the single confirmation in step 6.

### 4. Classify each standalone branch

Two independent signals per branch; run both.

**a) Net content vs trunk** — the ground truth:

```bash
if t=$(git merge-tree --write-tree "origin/$trunk" "$b" 2>/dev/null); then
  n=$(git diff-tree -r --name-only "origin/$trunk^{tree}" "$t" | wc -l | tr -d ' ')
  # n=0        -> LANDED: merging today changes nothing
  # n>0        -> merges clean with $n files of real remaining change
else
  :            # CONFLICTS with trunk
fi
```

**b) PR state**:

```bash
gh pr list --head "$b" --state all --json number,state,title --jq '.[] | "\(.number) \(.state) \(.title)"'
```

Combine into buckets:

| Net content | PR state | Verdict |
|---|---|---|
| 0 files | any (or none) | **Landed — safe to delete** |
| >0 files, merges clean | OPEN | **Live — keep** |
| >0 files, merges clean | MERGED / none | **Residue** — show the remaining files; often trunk just evolved past a stale test or doc. Human call. |
| conflicts | MERGED | **Probably dead** — the PR landed but the local tip was rewritten afterwards. Verify below before deleting. |
| conflicts | OPEN | **Live but stale — keep**, note it needs a rebase |
| conflicts | CLOSED / none | **Human call** — abandoned spike or unlanded work |

For the **conflicts + MERGED** bucket, check whether the local tip holds
anything beyond what merged:

```bash
oid=$(gh pr view <pr-number> --json headRefOid --jq .headRefOid)
git log --oneline "$oid..$b"     # commits on the local tip beyond the merged head
git diff "origin/$trunk...$b" --stat   # what those would re-apply
```

If the extra commits are clearly the same content in rewritten form (rebased
duplicates of what landed), classify as landed. If genuinely novel, keep and
flag.

### 5. Present the analysis

One table, grouped by verdict, before touching anything:

```
## Branch Triage (vs origin/main)

### Safe to delete (content fully landed)
- big-ui-updates          PR #807 MERGED   0 net files   (+ backup/big-ui-updates-pre-squash)
- cv                      PR #801 MERGED   0 net files

### gh-stack: prune via `gh stack sync --prune`
- stack 663: 609-web-inline-highlights, 609-span-migration, ...  (all PRs merged)

### Keep (live work)
- phase-5-billing-polish  PR #370 OPEN     10 net files

### Needs your call
- agent-spike             no PR            conflicts with main
```

### 6. Confirm

Use AskUserQuestion (multiSelect) so the user can approve each action group
independently:

- **Delete landed branches** — the "safe to delete" list
- **Prune gh-stack branches** — run `gh stack sync --prune` per stack
- **Delete probably-dead branches** — the merged-but-rewritten ones, listed
  individually in the question description
- Skip anything not selected

### 7. Execute

- If the current branch is being deleted: `git checkout $trunk` first (and
  `git pull --ff-only` if behind).
- Deletions use `git branch -D` — squash-merged branches ALWAYS fail `-d`'s
  ancestor check; this is expected, not a danger sign. The safety came from the
  merge-tree classification, not from `-d`.
- gh-stack prunes: checkout into each stack, `gh stack sync --prune`, return.
- If git-branchless is in use (`.git/branchless` exists), deleted branches'
  commits may linger in the smartlog; run `git hide <commit>` on stragglers or
  suggest `git branchless sync` to tidy — never `sync --pull` on landed
  branches (that is the failure mode this skill exists to avoid).

### 8. Report

Show `git branch -vv` (or the surviving branch list) and summarise: deleted N,
pruned M via gh-stack, kept K, left L for the user to decide.

## Constraints

- NEVER delete a branch that wasn't classified as landed AND confirmed by the
  user. "Needs your call" branches are only deleted on explicit selection.
- NEVER touch remote branches — local pruning only (gh-stack's own prune
  behaviour excepted, since that is its documented contract).
- NEVER force-remove a worktree or delete a branch checked out in one.
- Read `.git/gh-stack` only — never write or edit it; all stack mutations go
  through the `gh stack` CLI.
- If `gh` is unauthenticated or there is no GitHub remote, degrade gracefully:
  classify on merge-tree alone and say PR state is unavailable.
