# Working with colour

The palette as it appears on screen: whether there are enough shades, whether
they look deliberate, and whether anything is unreadable.

## What to look for

**Too few shades.** The signature is compromise: text that is darker than it
wants to be because the next shade down was too light, panel backgrounds that
are all the same because there is only one off-white. A real palette carries
8–10 greys and 5–10 shades of each colour. If every grey on screen is one of
three, say so.

**Shades that look generated rather than chosen.** Several near-identical
variants of one colour in the same screenshot — three blues a fraction apart on
different elements. That is the look of `lighten()`/`darken()` at call sites
instead of a fixed set of shades.

**Washed-out light and dark shades.** In HSL, saturation loses its effect as
lightness approaches either end, so light and dark variants of a colour need
*more* saturation to stay colourful. A pale tint that looks grey-ish rather than
a pale version of the colour, or a dark shade that has gone muddy, is this bug.
Dark yellows and oranges show it worst — they go brown. Fix: raise saturation at
the extremes, and for light colours rotate the hue slightly (no more than
20–30°) towards orange as you darken rather than only dropping lightness.

**Unreadable text.** Report what you can actually see: white text on a mid-tone
background, a pale grey caption on white, coloured text on a coloured panel that
you have to work at. Describe it as hard to read and name the pair.

**A dark colour block pulling focus it does not deserve.** White-on-colour needs
the colour to be quite dark to stay legible, and a dark block grabs attention —
so a secondary element ends up louder than the primary one. Fix: flip the
contrast, dark coloured text on a light tint of the same colour. Keeps the
colour, loses the shouting.

**Grey that has no temperature, or two temperatures at once.** Pure
zero-saturation grey looks flat and slightly dead; most good greys carry a hint
of blue (cool) or yellow/orange (warm). Worth flagging when greys look lifeless,
and worth flagging harder when some greys on the screen are cool and others
warm, which reads as two palettes colliding.

**Colour as the only signal.** The accessibility finding that *is* reliably
visible. Up/down metrics, status pills, graph lines or category tags
distinguished purely by hue — a red-green colourblind viewer cannot read them.
Fix: add a second signal (an icon, a sign, a label), and for series of lines
vary *lightness* rather than hue, since light-versus-dark survives colour
blindness.

## What not to flag

- **A contrast ratio.** Do not state or estimate a figure — you cannot compute
  4.5:1 from a screenshot and a wrong number is worse than no number. Say the
  text is hard to read and let the user measure.
- Hex versus HSL, or how the colours are expressed in code. Invisible here.
- The choice of brand colour. "Blue was the wrong call" is not a finding.
- A restrained palette. Few colours used consistently is good design, not a
  shortage of shades — the finding is *compromise*, not *economy*.
