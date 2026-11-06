# Working with images

Photography, icons and screenshots as they appear in the design — mostly a
question of contrast and intended size.

## What to look for

**Text over a busy photo.** The most common image fault. A headline on a hero
image where part of the text sits over light areas and part over dark, so no
single text colour works — some words pop and some disappear. The problem is the
image, not the text colour. Fixes, roughly in order of how much they preserve
the photo:

- a semi-transparent overlay (black to help light text, white to help dark text)
- lowering the image's own contrast, then adjusting brightness to compensate
- colourising it: low contrast, desaturate, solid fill on *multiply*
- a text shadow with a large blur and **no offset**, so it reads as a glow
  rather than a drop shadow — preserves the most of the image

**Icons blown up past their intended size.** Small UI icons (drawn for 16–24px)
used large in a feature grid or empty state. They look chunky and detail-free
because there is no detail to show. Fix: keep the icon near its intended size
and put it inside a shape with a background colour to fill the space.

**Icons scaled down.** The inverse, and most visible in favicons and small
avatars — a logo drawn large turns to mush at 16px. Fix: redraw a simplified
version at the target size.

**A whole-app screenshot shrunk to fit.** Visible as a block of illegible
grey-line text. 16px type in the app becomes 4px in the image and nobody can
read it. Fixes: take the shot at a smaller viewport, crop to a meaningful
portion, or replace it with a simplified drawing of the UI where small text
becomes plain lines.

**Fuzzy bitmaps.** Raster images displayed larger than their natural size.

**User content breaking the layout.** Images at their own aspect ratios in a
grid, so rows are ragged and heights inconsistent. Fix: fixed containers,
centred, cropping the overflow — `background-size: cover`.

**Uploaded images bleeding into the page.** A photo or avatar whose own
background matches the page background, so its edges vanish and it loses its
shape. Fix: a subtle *inner* box shadow, which nobody consciously notices — not
a border, which will clash with the colours in the image.

## What not to flag

- The taste or subject of the photography. "Use a better photo" is not
  actionable from a review.
- Image compression artefacts in the *screenshot itself* rather than in the
  design. Check whether what you are seeing is the screenshot's own quality
  before reporting it — this is an easy false positive.
- Illustration style.
- Any screen with no images on it. Return no findings and say so.
