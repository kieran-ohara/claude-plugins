# Layout and spacing

Whether elements have room to breathe, and whether the spacing says which things
belong together.

## What to look for

**Cramped everything.** The commonest fault in developer-built UI: every element
has just enough padding not to look actively broken. Fix: more space, pretty
much everywhere, then take some back.

**Ambiguous grouping.** The highest-value check in this area, because it causes
real mistakes rather than just looking worse. Whenever spacing alone is doing
the grouping, there must be **more space around a group than inside it**. Look
for:

- a stacked form where the gap under the label matches the gap under the input,
  so you cannot tell which label belongs to which field
- section headings sitting closer to the paragraph above them than the one below
- list items whose separation matches the line spacing within a wrapped item
- horizontal groups — a row of label/value pairs with even gaps throughout

**Inconsistent spacing.** Gaps that are close but not equal — a 20px gutter
beside a 24px one, three cards with slightly different padding. Judge this
comparatively across the screenshot rather than by guessing pixel values: say
"these two gaps differ slightly and look unintentional". The underlying rule is
that a usable spacing scale has no two steps closer than about 25%, so near-miss
values are the signature of no scale at all.

**Content stretched to fill the viewport.** Full-width rows of text or form
fields because the window is wide, not because the content needs it. Fix: give
the element the width it needs and leave the rest empty — a `max-width`, not a
percentage.

**Everything matched to the widest thing.** A narrow form or card forced
full-width because the nav above it is full-width. Fix: let each element take
the space it actually needs. If a narrow element looks unbalanced in a wide
frame, split it into columns rather than widening it.

**Elements that shrink when there is room.** Visible when you have both widths:
something that is *wider at the medium width than at the large width*, which is
what percentage-based grid columns do. Fix: cap it with a `max-width` and only
let it shrink below that.

**Proportional scaling across widths.** With both widths to compare: large
things should shrink *faster* than small things. A headline that is right on
desktop and still enormous on mobile is the tell (the giveaway that it was set in
`em` relative to body copy). Likewise a button whose padding scales with its
font size reads as a zoomed button rather than a bigger or smaller one — padding
should get proportionally more generous as things grow and tighter as they
shrink.

## What not to flag

- **Density, when it is clearly deliberate.** Dashboards, data tables,
  trading-style screens and admin tools legitimately trade breathing room for
  information on one screen. If the brief says the screen is dense on purpose,
  do not report tightness as a finding — report it only where the tightness
  creates *ambiguity* about what belongs with what.
- Generous empty space. Space the design has chosen to leave empty is not a
  fault, and "could fit more in" is not a finding.
- Exact pixel claims. You cannot measure from a screenshot; describe
  relationships ("roughly twice the gap"), not measurements.
