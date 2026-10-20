---
name: hoist-conventions
description: "Review a session's conversation history for durable patterns in how the user works — preferences, corrections, mental models — and offer to hoist the ones worth keeping into CLAUDE.md. Use at the end of a session, or when the user asks what this session taught you about how they work."
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Grep, AskUserQuestion
---

# Hoist Conventions Into CLAUDE.md

Read back over the conversation, find the things the user said that would change how you behave *next* time, and offer to record them. Most sessions yield nothing. That is the expected outcome, not a failure.

## Your Task

### 1. Locate the Transcript

Sessions are stored as JSONL under a slug derived from the working directory (`/` and `.` both become `-`):

```bash
PROJECT_DIR="$HOME/.claude/projects/$(pwd | sed 's/[/.]/-/g')"
TRANSCRIPT="$PROJECT_DIR/${CLAUDE_SESSION_ID}.jsonl"
```

Default to the current session. If `$ARGUMENTS` names a session id, use that. If it asks for several (e.g. "last 5"), take the most recent:

```bash
ls -t "$PROJECT_DIR"/*.jsonl | head -5
```

**Recurrence across sessions is the strongest signal available.** A preference stated once may be about one task; the same correction in three sessions is a convention. When scanning multiple transcripts, weight accordingly.

**A repo worked in worktrees has one project dir per worktree**, because the slug comes from the path. Sessions in `app-kit.wt-1` land somewhere entirely separate from those in `app-kit`, and a dir outlives the worktree that created it. Scan all of them, or the recurrence signal above is measured against a fraction of the history:

```bash
REPO_ROOT="$(dirname "$(git rev-parse --git-common-dir)")"   # main checkout, from any worktree
SLUG="$(echo "$REPO_ROOT" | sed 's/[/.]/-/g')"
ls -dt "$HOME/.claude/projects/$SLUG"*                        # every worktree's dir, newest first
```

### 2. Extract the User's Own Words

Tool results are also stored as `type: "user"`, so filter to genuine typed prompts:

```bash
jq -r 'select(.type=="user")
       | (.message.content
          | if type=="string" then .
            else (map(select(.type=="text").text) | join(" ")) end)
       | select(length>0)' "$TRANSCRIPT" \
  | grep -v '^<system-reminder>' | grep -v '^<command-name>'
```

Read the user's lines first and in full. Do **not** dump the assistant side — it is the bulk of the file and mostly your own output. Pull surrounding assistant turns only for a specific candidate you cannot interpret without them.

### 3. Read What Is Already Recorded

Before proposing anything, know what is already written down. A candidate that restates existing guidance is noise:

```bash
cat "$HOME/.claude/CLAUDE.md"            # global: how the user works everywhere
cat ./CLAUDE.md 2>/dev/null              # project: this repo's architecture and conventions
cat "$HOME/.claude/projects/$SLUG"*/memory/*.md 2>/dev/null   # memory, across every worktree
```

Read memory across all the dirs from step 1, not just the current one. Memory written in one worktree is invisible from every other, so the dir you happen to be in is rarely the whole picture.

### 4. Identify Candidates

Look for:

- **Corrections.** The user redirected you — "no, use X", "never do that", "that's not what I asked". The strongest source by far.
- **Repeated instructions.** Anything the user had to say twice, in one session or across several, is something they should not have had to say at all.
- **Friction.** A point where the user re-explained context you should have had, or where you guessed wrong and they supplied the rule.
- **Stated preferences.** Explicit "I prefer", "I always", "we do it this way".
- **Mental models.** A sentence that reveals how the user thinks about their own system — why a thing is arranged the way it is, not just what it is. These are easy to miss and often the most valuable, because they let you predict the next decision instead of asking.
- **Vocabulary.** A domain word the user uses in a specific way.
- **Memory already holding guidance.** A `type: feedback` memory is, by definition, how the user wants work done — so it belongs in a CLAUDE.md, not in a path-keyed store that no other worktree will load. Treat every one as a hoist candidate in its own right, even when the current session never touched the subject. Memory is a *source* here, not only the duplicate filter step 3 uses it as.

### 5. Apply the Bar

For each candidate, ask: **what will I do differently next session because this is written down?** If there is no clear answer, drop it.

Reject:

- Anything already covered in either CLAUDE.md — even loosely. Duplication drifts.
- Anything derivable from the repo: file layout, available scripts, what the code does, what git history records.
- Anything true only of this one task. "The Arden token lives in vault X" is a fact about today; "secrets are mounted, never rendered at install time" is a convention.
- Your own mistakes, unless the user corrected a *pattern* rather than a slip. "You misread a file size" is not a convention.
- Praise. "good stuff" and "all good" are not instructions.
- Anything you would be embarrassed to have a reviewer read as a rule, because it is too vague to act on. "Prefers clear explanations" fails this.

**Rule of thumb on volume:** more than two or three candidates from a single session usually means the bar has slipped. Say you found nothing rather than padding.

### 6. Route Each Survivor

| Destination | Holds | Survives a worktree? | Example |
|---|---|---|---|
| `~/.claude/CLAUDE.md` | How the user wants work done, in any project | yes — path-independent | "Never rename a test on your own initiative" |
| `./CLAUDE.md` | How *this* codebase is arranged and why | once merged — it is a tracked file | "Client secrets mount at the `~/src/<client>` root" |
| Project memory | Facts that were true when written, not instructions | **no** — keyed by path, dies with the worktree | "`stat` reports size=0 for these mounts" |

If a candidate is a fact rather than an instruction, it belongs in memory, not CLAUDE.md. Do not put it in both.

The third column inverts the convenience ordering: memory is the easiest store to write and the least likely to be read again. In a repo worked in worktrees, prefer a CLAUDE.md for anything that should outlive the branch, and leave memory for what is genuinely local and perishable.

### 7. Present Before Writing

Show each survivor with the **user's actual words as evidence**, the proposed wording, and the destination. Never present a candidate you cannot quote.

```
## Candidate 1 — global CLAUDE.md

Evidence (session 300c62fc, turn 9):
  "that is the intention. like everything under src arden gets the dotfiles"

Proposed, under "## Clients":
  Client config is deliberately set at the `~/src/<client>` root so every
  repo and worktree beneath inherits it. Do not add per-repo config.

Why it earns a place: predicts the next placement decision instead of asking.
```

Then use `AskUserQuestion` to confirm, per candidate — not one approval for the batch. The user may want one of three.

### 8. Apply Narrowly

- Add to the **existing** section that covers the topic. Only create a new heading when nothing fits.
- Never reword, reorder, retitle, or tidy surrounding guidance. Edit narrowly; the diff should contain only what was approved.
- Match the voice of the file you are editing.
- Keep each approved item to a few lines. CLAUDE.md is read in full on every session; length is a real cost.
- One commit per hoist, and only if the user asks for a commit.

**A hoist out of memory is a move, not a copy.** Once the guidance is in a
CLAUDE.md, delete the memory file and its line in that directory's
`MEMORY.md`. Leaving both means two copies of one rule in stores that cannot
be kept in step, and the duplicate is the one nothing will load. Delete only
after the CLAUDE.md edit is written, and only for items the user approved —
a declined candidate stays exactly where it is.

When the same guidance sits in several worktrees' memory dirs, remove every
copy, not just the one under the current path.

## Notes

- This skill is manual-only (`disable-model-invocation: true`) — it reads back over the user's words and proposes edits to their standing instructions, which should happen when they ask for it, not when you decide the session felt instructive.
- `${CLAUDE_SESSION_ID}` resolves to the running session, so the current transcript includes the turns up to the moment the skill is invoked.
- Finding nothing is a valid, common result. Report it in one line and stop.
