# Designing text

Typography: the sizes in play, how text reads as prose, and how it aligns.

## What to look for

**No type scale.** Count the distinct text sizes you can distinguish. More than
about six on one screen, or several pairs that are *nearly* the same size,
means sizes are being picked ad hoc rather than from a scale. Near-identical
sizes are the stronger signal: two headings a hair apart look like a mistake,
where a clear jump looks intentional.

**Lines too long.** The single most reliable typography finding. Body text
should run **45–75 characters per line**. You can count this from a screenshot:
read a full line and estimate. Much past 75 and the reader loses their place
returning to the left edge. Fix: cap the paragraph width (roughly 20–35em) even
when the surrounding content area is wider — mixing widths inside one column is
correct, not sloppy.

**Line-height wrong for the measure.** Line spacing exists so the eye can find
the next line. It should be **proportional to line length** — narrow columns can
take ~1.5, wide ones need more — and **inversely proportional to size**. So:
small text with tight leading is a real finding, and a large headline with
body-text leading looks unintentionally airy. Headlines can sit at 1.

**Mixed sizes centred instead of baseline-aligned.** A large title and a smaller
label or action sitting on the same line, vertically centred, so neither sits on
a shared baseline. Obvious when the two are close together. Fix: align on the
baseline.

**Long text centred.** Centring is fine for a headline or a short standalone
block. Past two or three lines it reads badly because every line starts in a
different place. Fix: left-align it, or cut the copy short enough to centre.

**Numbers left-aligned in a table.** Columns of figures should be right-aligned
so the decimal points line up and values compare at a glance.

**Justified text without hyphenation.** Visible as rivers of white space
between words. Fix: hyphenate, or left-align.

**All-caps at default letter-spacing.** Capitals are uniform in height and lose
the ascender/descender variety that makes lowercase legible, so default spacing
reads as cramped. Fix: increase letter-spacing on all-caps labels, buttons and
eyebrow headings.

**Headline letter-spacing untouched.** A text face used large often looks loose
as a headline, because its spacing was tuned for legibility at small sizes. Fix:
tighten slightly. The reverse never works — a headline face does not become a
text face by adding space.

**Every link coloured.** In an interface where most things are clickable,
paragraph-style link treatment on all of them is overbearing. Fix: emphasise
most links with weight or a darker colour, and for genuinely ancillary ones show
the underline on hover only.

## What not to flag

- Whether the typeface is a *good* typeface. You can note that it reads as
  condensed or has a short x-height for UI text, but "use a better font" is not
  an actionable finding from a screenshot.
- `em` versus `rem` versus `px`, or any claim about the units — invisible here.
- Specific size values. Say "these two sizes are nearly identical", not "16px
  and 17px".
- Deliberately tight leading on a large display headline. That is correct.
