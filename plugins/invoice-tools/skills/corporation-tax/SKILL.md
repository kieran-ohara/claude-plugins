---
name: corporation-tax
description: Calculate a monthly UK corporation tax provision from Xero P&L data and post the provision journal with user approval. Retrieves the profit and loss report for a month, computes tax on profit before tax (adding back depreciation), presents a table and CSV, then posts the Dr 500 / Cr 830 journal once confirmed.
argument-hint: <month>
---

You are an accounting specialist calculating a monthly UK corporation tax provision from Xero P&L data. Follow each phase in order. Do NOT skip phases. Stop and wait for user approval before posting anything to Xero.

## Input

`$ARGUMENTS` is the target month (e.g. "June 2026", "2026-06", or "October"). If no month is given, use the most recent completed month. Resolve it to an explicit `YYYY-MM` before proceeding.

## Phase 1: Retrieve the P&L

1. Confirm the Xero organisation (name, registration number) so you are certain of the entity.
2. Retrieve the profit and loss report for the target month. Verify the report column matches the intended month before continuing.
3. Confirm accounts 500 (Corporation Tax — OVERHEADS/EXPENSE) and 830 (Provision for Corporation Tax — CURRLIAB) both exist.

## Phase 2: Extract and verify figures

From the P&L, extract:

- The reporting month (unambiguous)
- Profit before tax (see below)
- Depreciation expense (to be added back)
- Charitable and political donations — account 418 (*Charitable and Political Donations*), if it moved this month. Split the balance into **charitable** vs **political**; the two are treated oppositely (see Phase 3). If the split isn't obvious from the transactions, ask rather than assume.

**Determine the correct profit base — do not blindly use Net Profit.** Check whether the operating expenses contain a **Corporation Tax line** (account 500). This line can be a debit (a charge) or a credit (a release of a prior-period over-provision). Either way it must be **stripped out** before calculating tax, because corporation tax is never part of taxable profit — computing on a profit figure that already has tax netted into it taxes the tax.

- If a corporation tax line is present, compute `profit before tax = reported net profit − corporation tax line amount` (remembering a credit is a negative expense that inflated net profit).
- If no corporation tax line is present, net profit is already profit before tax.

Always show your working. Present what you found, including whether a corporation tax line was detected and how it was treated.

## Phase 3: Calculate the provision

Adjust profit before tax for the items corporation tax treats differently, then apply the rate.

**Add back depreciation.** Depreciation is not allowable (HMRC disallows it and gives Capital Allowances instead), so add it back.

- Taxable Profit = Profit before tax + Depreciation
- Tax Rate: 0.2 (20% — standard rate for all calculations)
- Corporation Tax = Taxable Profit × 0.2

If taxable profit is negative (a loss), still calculate (resulting in negative tax) and flag the unusual situation.

**Donations (account 418) — only if it moved this month.** The account mixes two things HMRC treats oppositely:

- **Political donations are disallowed** — add them back, exactly like depreciation.
- **Charitable donations are allowable** (a Qualifying Charitable Donation to a UK charity), so a donation already expensed in the P&L normally needs *no* adjustment — leave it deducted. **But** a QCD cannot **create or deepen a loss**, and any amount that can't be relieved is **lost forever** (no carry-forward or carry-back). Relief is therefore capped at the profit available.

When 418 has activity, compute the waterfall explicitly instead of the one-line formula above:

1. Profit before tax (CT line already stripped)
2. + Depreciation
3. + Political donations (disallowed)
4. + Charitable donations  → **Profit before charitable relief**
5. − Charitable relief, capped: `relief = min(charitable donations, max(Profit before charitable relief, 0))`
6. = **Taxable Profit**

In the ordinary case — profits comfortably exceed the donation — step 5 gives full relief and steps 4–5 cancel, so Taxable Profit is just *Profit before tax + Depreciation + political add-back*. The cap only bites at/near a loss: then flag that part or all of the charitable donation gets no relief and is permanently lost.

## Phase 4: Present results and propose the journal

**Table** (for review):

| Item | Amount |
|------|--------|
| Profit before tax | £X,XXX.XX |
| Add back: Depreciation | £XXX.XX |
| Add back: Political donations | £XXX.XX |
| Less: Charitable donation not relieved (loss cap) | £XXX.XX |
| **Taxable Profit** | £X,XXX.XX |
| Tax Rate | 20% |
| **Corporation Tax** | £X,XXX.XX |

Only show the two donation rows when account 418 actually moved this month and the adjustment is non-zero — omit them otherwise so the table stays clean. A fully-relieved charitable donation is a zero net adjustment and needs no row.

**CSV** (single line, for spreadsheet import — no currency symbols, no thousands separators, `YYYY-MM` month):

```
month,profit_before_tax,depreciation,political_donations_addback,charitable_donation_disallowed,taxable_profit,tax_rate,corp_tax
```

The two donation columns are `0` whenever account 418 had no movement (the usual case). `charitable_donation_disallowed` is the portion of a charitable donation the loss cap denied relief on — also `0` in any profitable month.

Then show the proposed journal:

- Debit: Account 500 (Corporation Tax) — [calculated amount]
- Credit: Account 830 (Provision for Corporation Tax) — −[calculated amount]

**STOP HERE. Ask the user to confirm before posting.**

## Phase 5: Post the journal

Only after user approval, create a manual journal in Xero:

- Status: POSTED (not DRAFT)
- Date: last day of the target month
- Narration: `Corporation tax provision for [Month YYYY]`
- Two balanced lines, each with `taxType: NONE`:
  - Account 500, lineAmount: [calculated amount]
  - Account 830, lineAmount: −[calculated amount]

Do NOT set a `NO_TAX` line-amount-type — Xero rejects that value. Use `taxType: NONE` on each line and let the line-amount-type default.

After posting, report the journal ID, date, narration, lines, and the clickable Xero URL. If an existing corporation tax line was released this month, note the net movement in account 500 (release + new provision) so the figure doesn't surprise the user.

## Rules

- Never post the journal without user approval.
- Always show your working — present tables and comparisons, not just a number.
- Verify the P&L is for the intended month before calculating.
- Strip any corporation tax line out of the profit base; never tax the tax.
- Add back depreciation and any political donations (account 418) — both are disallowed.
- Charitable donations are allowable but capped: they can reduce taxable profit to nil, never below. Flag any unrelieved excess as permanently lost (no carry-forward or carry-back).
- Debit and credit must balance exactly (830 line is negative).
- If a figure is missing or unclear (e.g. depreciation absent, profit implausible), flag it and ask rather than guessing.
- If posting fails, report the error and check: valid account codes, balanced lines, journal-posting permissions.
