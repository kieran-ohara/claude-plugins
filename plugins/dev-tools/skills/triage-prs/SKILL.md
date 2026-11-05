---
name: triage-prs
description: Triage the user's open pull requests — list them, work out which can actually be merged, explain exactly what blocks the rest, and emit the mergeable ones as bullets carrying the link and the reviewers who still owe an approval. Use this whenever the user asks anything about the state of their pull requests: "is this good to merge", "are my PRs ready", "what's blocking my PRs", "who still needs to review", "can I merge yet", "chase my reviewers", or just "my PRs". Applies to a single PR on the current branch as much as to a whole queue of them. Works on both GitHub (gh) and Bitbucket (bkt).
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion, Skill
---

# Triage PRs

Answer one question per pull request: **can this be merged right now, and if not, why not?**

The value here is a decision, not an audit. Someone asking this has pull requests
sitting around and wants to know which ones to click merge on and whom to chase
for the rest. So resist the pull towards reviewing the code — a correctness
review is `/code-review`, and doing one here buries the answer the user came for
under findings they did not ask for.

## 1. Collect the signals

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/triage-prs/scripts/pr-report.py"
```

The script lives at `scripts/pr-report.py` beside this file, so if
`CLAUDE_PLUGIN_ROOT` is unset use this skill's base directory instead of
guessing at a path. Run it from inside a git repository — it reads `origin` to
name the host in play, then gathers every pull request the user authored across
their repositories, with CI state, approvals, conflicts, open tasks and
behind-ness. It emits JSON and decides nothing.

It collects from both hosts by default, so the result spans everything the user
has open regardless of which repo they happen to be standing in. Useful flags:
`--limit N` (default 30), `--host github|bitbucket|both`, and `--owner <name>`
to narrow to one organisation or workspace.

A failure on one host lands in `warnings` rather than `error` — an expired `gh`
login should not hide Bitbucket work. Report warnings briefly so the user knows
the picture is partial, and only stop outright on `error`, which means nothing
could be collected at all (usually authentication: `gh auth status`,
`bkt auth status`).

## 2. Work out whose pull requests to report on

The `owners` field lists every organisation and workspace the results touch.
People rarely want their employer's review queue and their own side projects in
one list — mixing them buries the thing they were actually asking about.

So when `owners` holds more than one name and the user has not already said
which they mean, ask with `AskUserQuestion` before reporting. Offer each owner
as an option, with the open count so the choice is informed, plus an "all of
them" option for when they genuinely want the lot:

```
Which pull requests do you want? [ardenuniversity (1 open)] [irkb (3 open)] [all of them]
```

Skip the question whenever the answer is already known — one owner in the
results, a company or repo named in the request, or an obvious cue like "my
work PRs". Asking a question you could have answered yourself is just friction,
and this skill exists to remove friction.

Scope otherwise: if the user asked only about the current branch or repo, filter
the collected result rather than re-running anything.

## 3. Decide what mergeable means

A pull request is **mergeable** when nothing mechanically stops the merge:

- `draft` is false
- `conflicts.status` is `clean`
- `checks_state` is `green` (or `none`, where the repo runs no CI)
- no `open_tasks`
- the host is not refusing the merge on policy

That last point is where this gets interesting, and it differs by host:

- **GitHub** tells you directly. `merge_state_status` of `BLOCKED` means a
  branch protection rule is refusing — most often a required review, which
  `review_decision` of `REVIEW_REQUIRED` confirms. `CHANGES_REQUESTED` blocks
  too. `BEHIND` means the repo requires the branch be up to date first.
- **Bitbucket** exposes no policy at all, so `enforces_approvals` is null.
  Treat outstanding approvals as something to chase, **not** as a blocker —
  Bitbucket repos commonly allow merging without them, and reporting a green
  pull request as blocked sends the user off to badger people for no reason. If
  the merge button turns out to be disabled, that is the repo's merge checks;
  mention that possibility rather than guessing at it.

So an approval nobody has given yet does not by itself make a pull request
blocked. That is the whole reason the mergeable bullets carry the reviewer
names: those pull requests can go in, and the names are who to nudge if the
user would rather have the review first.

## 4. Report

Use this shape. Lead with what the user can act on.

```
## Ready to merge
- <url> — awaiting: <reviewer>, <reviewer>
- <url> — no reviews outstanding

## Blocked
### <url> — <title>
<What is blocking it, concretely, and the one thing that clears it.>
```

Drop a section entirely if it is empty, and say so in a line instead. If
everything is mergeable and fully approved, say that plainly — no ceremony.

Blocker explanations earn their place by being specific. Name the thing and
link it:

- **CI red** — name the failing check and give its URL. Offer `/babysit-pr`,
  which will diagnose and fix it.
- **Conflicts** — list the conflicting files from `conflicts.files`. They came
  from a real merge, so they are accurate.
- **Behind base** — say how far, and that a rebase is needed first.
- **Changes requested** — name who requested them.
- **Required review missing** — name the reviewers the host is waiting on.
- **Open tasks** — quote them; they are usually one-line asks.

Where `conflicts.status` is `unknown`, say why (the reason field explains it —
normally the pull request lives in a repo that is not checked out locally) and
do not present a guess as a finding. Honest "could not determine" beats a
confident wrong answer, because the user will act on this.

## Constraints

- This is read-only triage. Never merge, push, approve or comment on anything —
  the user decides what to merge, and a surprise merge is unrecoverable.
- Do not review the code or re-litigate the content of a pull request. If you
  happen to notice something genuinely alarming, mention it in one line and
  point at `/code-review`.
- Do not pad the report with PR titles, ages, diff sizes or commit counts
  nobody asked for. The bullets exist to be pasted into Slack.
