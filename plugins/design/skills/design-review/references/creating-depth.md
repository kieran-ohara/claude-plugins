# Creating depth

Whether the screen has a believable z-axis: what sits above what, and whether
the light is consistent.

## The one rule underneath everything

**Light comes from above.** Every shadow and edge treatment on the screen should
be consistent with a single light source overhead. A raised element shows a
slightly lighter top edge and casts a shadow *below* it; an inset element shows
a shadow at its top and a lighter bottom lip.

## What to look for

**Shadows pointing in different directions.** Two components on the same screen
whose shadows imply light from different places — one offset down, another
offset up or sideways. The clearest fault in this area and always worth
reporting.

**Raised and inset reversed.** A text input, checkbox or well that reads as
raised, or a button that reads as recessed when it is not pressed. Caused by the
light/dark edges being the wrong way round.

**Elevation that does not match importance.** Shadow size places an element on a
z-axis, and the closer something feels, the more it attracts focus. Expect
roughly: a tight shadow on a button, a medium one on a dropdown or popover, a
large soft one on a modal. Flag a modal with a timid shadow, or a static card
with a modal-sized one.

**More than about five distinct shadows.** Like type and spacing, shadows should
come from a small fixed set. Many subtly different ones is ad-hoc styling.

**Soft, blurry small shadows.** A shadow meant to lift something a couple of
pixels off the page should have a fairly *sharp* edge — look at the shadow under
a wall socket. A large blur radius on a slightly raised element reads as fog.

**Ambient shadow left on at high elevation.** The two-part shadow technique uses
a large soft shadow plus a tight dark one for the ambient-light-blocked area
underneath. That tight one should fade as elevation rises, because a lifted
object loses contact shadow. A modal with a hard dark line tucked under its edge
is wrong.

**Semi-transparent white used for a raised top edge.** Reads as desaturated
rather than lit — overlaying white sucks the colour out of what is underneath.
Fix: hand-pick a lighter shade of the actual colour.

**A flat design with no depth at all.** Flat does not mean depth-free. If
nothing on the screen separates from the background, note that lighter-than-
background reads as raised and darker reads as inset, and that a short
zero-blur solid shadow lifts a card without breaking the aesthetic.

**Overlapping elements clashing.** Where a design deliberately overlaps things
to create layers, images butting directly against each other lose their edges.
Fix: an "invisible border" in the background colour, so there is always a gap.

## What not to flag

- A flat design *as such*. Only flag it when nothing reads as separated from the
  background at all.
- Absence of shadows on a design that is clearly using colour or borders for
  separation instead. That is a legitimate choice.
- Exact shadow values. Describe what reads wrong, not `0 4px 6px`.
