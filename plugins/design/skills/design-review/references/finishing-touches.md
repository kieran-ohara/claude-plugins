# Finishing touches

The area that asks what is *missing* rather than what is wrong — the difference
between a correct screen and a designed one. Findings here are opportunities,
so hold them to a higher bar than the other areas: only raise one where the
screen genuinely reads as plain.

## What to look for

**Browser defaults left in place.** The clearest signal of an undesigned screen.
Default checkboxes and radios, default bullet discs, default blue underlined
links, default `select` chrome. Fix: even just the brand colour on the selected
state takes a form from boring to deliberate.

**Lists that could carry icons.** A bulleted feature list where the bullets
could be checkmarks, arrows, or something specific to the content — a padlock
for security features.

**Nothing anywhere to anchor the eye.** A screen with no accent colour at all.
The cheapest fix in the book is a coloured accent border: across the top of a
card, on the active nav item, down the side of an alert, under a headline, or
across the top of the layout.

**Large flat expanses of one background colour.** Fixes: change the background
colour on a panel or section to distinguish it; a slight gradient (two hues no
more than ~30° apart); a low-contrast repeating pattern, possibly only along one
edge; or a simple geometric shape or illustration placed deliberately. Keep the
contrast low in all cases so nothing fights the content.

**Quote marks and emphasis left as plain text.** A testimonial where the
quotation marks could be promoted into a visual element, or a pull-quote styled
like body copy.

**Borders everywhere.** Several nested boxes each outlined, which reads busy and
cluttered. Three alternatives, any of which is usually enough on its own: a box
shadow instead of a border (works when the element differs in colour from the
background), two slightly different background colours, or simply more space. If
an element has both a distinct background *and* a border, the border is probably
redundant.

**Components that are the generic version of themselves.** Worth raising only
where the component is central to the screen. A dropdown that is a plain list of
links where it could have sections, columns, supporting text or icons. A table
where unsortable columns could be combined to create hierarchy, or enriched with
images and colour. A stack of radio buttons that could be selectable cards.

## Empty states

Judge this one only if the screenshot *is* an empty state, in which case it is
the most valuable finding available — empty states are a user's first contact
with a feature and are usually an afterthought.

- Bare "No items" text with no illustration and no call to action.
- A prominent, encouraging call to action is the thing to add.
- Supporting UI — tabs, filters, sort controls, a search box — still showing
  when there is nothing to operate on. It should be hidden entirely.

## What not to flag

- A deliberately austere aesthetic. Restraint is a style; plainness is an
  oversight. If the brief says minimal, hold back.
- Decoration for its own sake on an information-dense screen. A dashboard does
  not need background patterns.
- More than two or three suggestions in total. This area will always generate
  ideas, and a long list of "could add" buries the real findings from the other
  reviewers.
