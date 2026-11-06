---
name: design-review
description: Review UI screenshots against Refactoring UI principles using fresh reviewers that have no context on the work. Use whenever the user wants a design critiqued rather than a correctness review — "review this design", "does this UI look right", "critique this screen", "what's wrong with this layout", "is this well designed", "make this look less like a developer built it" — or hands over a screenshot or Figma frame and asks what they should change. For correctness bugs in code use /code-review instead.
allowed-tools: Read, Glob, Bash, Agent, Task, AskUserQuestion
---

# Design review

Hand screenshots to reviewers who know nothing about the work, and report what
they say.

## Why the reviewers are blind

The reviewers are fresh agents with no conversation history, and that is the
entire value of this skill. An agent that helped build a screen knows the
intent, is invested in it, and will rationalise its compromises — and
Refactoring UI gives it the vocabulary to do so, because "dense UIs have their
place" excuses almost any cramped layout. A reviewer that has never seen the
work before reads the screen the way its users will.

So: dispatch with `subagent_type: design-reviewer`, which starts fresh. **Never
use a fork** — a fork inherits this conversation, and the whole point is a
reader who has not had it. Your job is to assemble the input, dispatch, and
merge.

**You may look at the screenshots; you may not form a view on them.** Taking
inventory is part of your job — step 3 cannot prune reference files without
knowing what is on screen. Judging is not. The line is what you are looking
for: *what is present* (photography, colour, icons, an empty state) rather than
*what is wrong*. If you catch yourself noticing that the spacing is tight, that
is a reviewer's thought and it goes no further — not into a dispatch prompt, not
into the report. Your own critique is contaminated by this conversation, which
is exactly what you are dispatching around.

## 1. Get the screenshots onto disk

The reviewers can only `Read` files, so every screenshot must exist as a local
image file before you dispatch. This is the one thing that silently breaks the
skill, so settle it first:

- **Paths the user gave you** — confirm each exists.
- **A Figma frame** — use Figma tooling that *writes files* (`download_assets`)
  rather than a tool that returns an image into your context, which the
  reviewers cannot see.
- **An image pasted into the conversation** — if it only exists as conversation
  content and has no path on disk, say so and ask for the file. Do not fall back
  to reviewing it yourself; that throws away the blindness this skill exists for.

Ask for **two widths where the design is responsive** — roughly mobile and
desktop. Several rules in `layout-and-spacing.md` are claims about what changes
between widths and cannot be checked on one image. One width is fine; just say
in the report that the responsive checks did not run.

## 2. Get the brief

One line on what the screen is for: "checkout step two", "analytics dashboard,
density is deliberate", "marketing landing page".

This is intent, and a design reviewer is always told it. It is the difference
between a reviewer that flags tight spacing on a trading screen every time and
one that calibrates. If the user has not said and you cannot tell from the
screenshot, ask — it is one question and it changes the findings.

Pass **intent only**. Not the implementation history, not why a compromise was
made, not what the user already knows is wrong. That is the material the
blindness is protecting against.

## 3. Choose the areas

Seven reference files sit in `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/`
(use this skill's own directory if that variable is unset). Each is one chapter
of reviewable rules:

`hierarchy.md`, `layout-and-spacing.md`, `designing-text.md`,
`working-with-color.md`, `creating-depth.md`, `working-with-images.md`,
`finishing-touches.md`

**Drop any file the screenshots give nothing to judge.** No photography or
icons on screen means `working-with-images.md` goes; a wireframe or a greyscale
mock means `working-with-color.md` goes. Pruning is how you keep reviewers from
manufacturing findings to justify their dispatch — an images reviewer handed a
login form *will* reach.

Then group what survives. Default is **three reviewers**:

| Reviewer | Reference files |
| --- | --- |
| Structure | `hierarchy.md`, `layout-and-spacing.md` |
| Type | `designing-text.md` |
| Surface | `working-with-color.md`, `creating-depth.md`, `working-with-images.md`, `finishing-touches.md` |

The grouping is not arbitrary: it puts the rules that contradict each other
inside one reviewer's head, where the tension can be resolved rather than
landing on your desk as two opposed findings. "Use fewer borders" against "add
accent borders", and "start with too much white space" against "dense UIs have
their place", are both calls someone has to make.

When the user asks for **deep** (or thorough, or exhaustive), spawn one reviewer
per surviving file instead — up to seven. More thorough, roughly twice the cost,
and you will have more duplicate and conflicting findings to resolve. The cost
is driven by shipping the screenshots to every reviewer, not by the rules, so
seven reviewers is close to seven times the image cost.

If the user asks for one area by name — "just look at the typography" — spawn
that single reviewer.

## 4. Dispatch

**One message, multiple `Agent` calls, so they run in parallel.** Each gets:

- every screenshot path, and which width each one is
- the brief, verbatim and nothing more
- absolute paths to its reference files
- its area name, for attribution

Say nothing in the prompt about what you suspect is wrong. A reviewer handed a
hypothesis returns it confirmed, and you will have paid for three agents to
agree with you.

## 5. Merge and report

The reviewers could not see each other, so this step is yours and it is the one
that makes the output usable.

- **Deduplicate.** The same root cause often surfaces in two areas — cramped
  spacing reads as a hierarchy problem too. Merge them and keep the better
  explanation.
- **Resolve contradictions** rather than printing both. Where two reviewers
  genuinely disagree, make the call, say which way you went, and say why in a
  clause. The brief usually decides it.
- **Drop the reaches.** A `low` severity, `probable` confidence finding that
  reads as a stretch is noise. Cutting it is the most valuable thing you do
  here.
- **Rank by severity**, worst first, across all reviewers.

Report in this shape:

```
## <n> findings

### <title> — <severity>
<What is wrong and where, in a sentence or two.>
**Fix**: <the change>
*<Chapter> — <rule>*

## Clean
<Areas that came back with nothing, as a single line.>
```

Cite the principle behind each finding — it is what makes the review
checkable rather than an opinion, and it points the user at the chapter if they
want the reasoning.

If everything came back clean, say that plainly in a line. It is a real result
and the reviewers are instructed to allow it.

## Constraints

- **Read-only.** Report findings; do not edit code, components or stylesheets.
  Fixing is a separate request, and the user decides which findings they accept.
- Do not review correctness, accessibility compliance, performance or code
  quality. This is visual design against one book. `/code-review` is next door.
- **Never state a contrast ratio or a pixel measurement.** Neither you nor the
  reviewers can compute one from a raster image, and a confident wrong number is
  worse than "this looks hard to read". If the reviewers emit one anyway, strip
  it on the way out.
- Do not pad the report with what the screen does well beyond a line or two. The
  user came for the findings.
