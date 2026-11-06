# Hierarchy

Whether the screen tells the viewer what matters. The highest-value area: a
screen with no hierarchy reads as noisy and "undesigned" even when the colours,
fonts and layout are all individually fine.

## What to look for

**Everything competing.** Scan the screenshot and ask what your eye lands on
first. If the answer is "nothing in particular", or if you can name four or five
things with equal pull, that is the finding. Fix: pick the one element that
matters and de-emphasise the rest.

**Size doing all the work.** Primary content that is merely *big*, and secondary
content shrunk to the point of being hard to read. Fix: carry the emphasis with
weight or colour instead, and bring both sizes back towards reasonable.

**Too many text colours or weights.** More than about three text colours (dark
primary, grey secondary, lighter grey tertiary) or more than two weights
suggests emphasis is being decided ad hoc. Also flag text that looks *thinner*
than regular body weight at small sizes — de-emphasis should come from a lighter
colour or smaller size, never a thinner weight.

**Grey text on a colour.** Grey on white works because it reduces contrast. The
same grey on a coloured background looks dirty rather than quiet. Washed-out,
faded or disabled-looking text on a coloured panel is the tell, and if the
background is an image or pattern you may see it through the letterforms. Fix: a
hand-picked colour at the background's hue with adjusted saturation and
lightness.

**An active state that does not read as active.** A selected nav item, tab or
toggle that has been given its own colour but still does not stand out, because
the inactive siblings are just as loud. Fix: soften the inactive ones rather
than shouting louder on the active one.

**`label: value` pairs.** Data presented as a label and a value with equal
emphasis, where the format or the context already identifies it — an email
address, a phone number, a price, a department under a person's name. Fix: drop
the label, or fold it into the value ("12 left in stock", "3 bedrooms"). Where a
label genuinely is needed for scanning, it should be visibly secondary to the
data.

**Section titles stealing attention.** Headings sized as if they were document
headings, where they are really labels on a panel and the content is the point.
Fix: make them small, or in extreme cases visually hidden.

**Icons overpowering their text.** A solid icon beside a label covers more
surface area than the text, so it reads as the emphasised element. Fix: lower
the icon's contrast until it sits level with the words.

**Buttons styled by meaning rather than importance.** Several equally loud
solid buttons, or a destructive action rendered big and red when deleting is not
the main thing the screen is for. Fix: one solid primary, outline or low-contrast
secondary, link-styled tertiary — and move the big red treatment into the
confirmation step where it *is* the primary action.

## What not to flag

- A deliberately flat hierarchy where every row genuinely has equal standing —
  a table of like-for-like data, a settings list.
- A quiet screen. Low contrast everywhere is not the same bug as no hierarchy;
  only call it if you cannot tell what the screen is *for*.
- Guessing at font weights from a screenshot. Say "reads lighter than the body
  text", not "this is 300".
