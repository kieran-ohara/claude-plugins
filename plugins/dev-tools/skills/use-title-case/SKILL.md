---
name: use-title-case
description: Converts a title, heading, or headline to title case following standard English capitalization rules. Use whenever the user asks to title-case, capitalize, or fix the capitalization of a heading, title, or headline.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Edit, Write
---

Convert the text in `$ARGUMENTS` (or the text/selection the user indicates) to **title case**, following the capitalization rules below. If no text is supplied, ask the user what to title-case.

Return the converted title. When the title lives in a file the user points you at, edit it in place; otherwise just output the result.

## Title case rules

Apply these rules to each word in the title:

1. **Always capitalize the first word** of the title, no matter what it is.
2. **Always capitalize the last word** of the title, no matter what it is.
3. **Capitalize the major words**: nouns, pronouns, verbs (including short verbs like *is*, *be*, *are*), adjectives, and adverbs.
4. **Lowercase the minor words** when they fall in the middle of the title:
   - Articles: *a*, *an*, *the*
   - Coordinating conjunctions: *and*, *but*, *or*, *for*, *nor*, *yet*, *so*
   - Short prepositions: *at*, *by*, *in*, *of*, *off*, *on*, *out*, *to*, *up*, *as*, *per*, *via* (and similar words of roughly four letters or fewer)
5. **Capitalize longer prepositions and conjunctions** (five letters or more), e.g. *Between*, *Through*, *Against*, *About*, *Because*, *Before*, *Under*, *Over*.

## Words that keep their own casing

These override the rules above:

- **Proper nouns** stay capitalized: names of people, places, countries, nationalities, languages, brands, companies, organizations, days, months, holidays, and named historical events.
- **The pronoun *I*** is always capitalized.
- **Acronyms and initialisms** keep their established casing (*NASA*, *iOS*, *PDF*, *API*).
- **Brand/style casing** is preserved (*iPhone*, *eBay*, *YouTube*).
- **Hyphenated compounds**: capitalize each part that would be capitalized on its own (*Well-Being*, *Self-Portrait*, *Mother-in-Law* → the minor *in* stays lowercase).

## Punctuation and structure

- Capitalize the first word after a **colon** or **em dash** in a title (it begins a new subtitle).
- Capitalize the first word inside a quoted phrase within the title.
- **Seasons** (*spring*, *summer*, *autumn*, *winter*) are lowercase in running text but **capitalized in titles** as major words.

## Examples

| Input | Title case output |
|---|---|
| the lord of the rings | The Lord of the Rings |
| a tale of two cities | A Tale of Two Cities |
| what to expect when you're expecting | What to Expect When You're Expecting |
| gone with the wind | Gone With the Wind |
| the man in the high castle | The Man in the High Castle |
| learning ios development with swift | Learning iOS Development With Swift |
| notes on a scandal: a novel | Notes on a Scandal: A Novel |

## Process

1. Identify the title(s) to convert. If given a file, read it and locate the heading(s) the user means.
2. Apply the rules above word by word.
3. Present the converted title. If editing a file, make the edit and confirm what changed.
