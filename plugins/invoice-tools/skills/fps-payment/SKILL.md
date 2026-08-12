---
name: fps-payment
description: Records a payroll PAYE/NIC payment to HMRC in Xero from a Full Payment Submission (FPS) charges breakdown. Reads the FPS charge lines (Income Tax, Employer's NICs, Employees' NI deductions, and any student-loan/other lines), maps them to the PAYE/NIC payable accounts, and posts a Spend Money transaction to HMRC after user approval — clearing the liabilities the pay run already posted rather than creating a new charge.
argument-hint: [pay date]
---

You are a payroll accounting specialist recording a monthly PAYE/NIC payment to HMRC in Xero, taken from a Full Payment Submission (FPS) charges breakdown. Follow each phase in order. Do NOT skip phases. Stop and wait for user approval before posting anything to Xero.

## What this skill records — read this first

The FPS "Charges" screen lists the amounts due to HMRC for a pay run: Income Tax (PAYE), Employer's NICs, Employees' NI deductions, and sometimes student-loan or other lines. In Xero, **the pay run has already posted these as liabilities** to the PAYE/NIC payable accounts. So this skill records the **payment that settles those liabilities** — a `SPEND` bank transaction whose line items are coded to the payable accounts, clearing them.

**Do NOT post a fresh liability journal.** Recognising the FPS charges again (Dr expense / Cr payable) would double-count what the pay run already booked. The guard in Phase 2 protects against this.

## Input

- The **FPS charges** — an image/screenshot or PDF of the "Charges / Full Payment Submission (FPS)" screen. If a PDF, read it with the poppler CLI (`pdftotext` / `pdftoppm`).
- The **pay date** for the run — `$ARGUMENTS` may carry it (e.g. "12 August 2026"). If absent, take it from the FPS or ask.

Extract every charge line and the **"Total amount due from FPS"**.

## Phase 1: Confirm the entity and read the FPS

1. Confirm the Xero organisation (name, registration number) so you are certain of the entity.
2. Read the FPS image/PDF. Extract each charge line and its amount, plus the total. Typical lines:
   - **Income Tax**
   - **Employer's NICs**
   - **Employees' NI deductions**
   - Occasionally: **Student/Postgraduate Loan deductions**, **Class 1A NIC**, recoveries/credits (e.g. SMP reclaim, Employment Allowance).
3. Note the total — you will reconcile the transaction against **"Total amount due from FPS"** exactly.

## Phase 2: Map charges to accounts and guard against double-counting

Map each FPS line to the payable account that the pay run posts it to:

| FPS charge line | Account |
|---|---|
| Income Tax | **825** PAYE Payable |
| Employer's NICs | **826** NIC Payable |
| Employees' NI deductions | **826** NIC Payable |
| Student/Postgraduate Loan deductions | **947** Student Loan Deductions Payable |
| Class 1A NIC | **827** Class 1A NIC Payable |

- Employer and employee NI both clear **826** (NIC Payable) — two separate line items, same account.
- Every line uses **`taxType: NONE`** (there is no VAT on PAYE/NIC).
- Anything not in this table (Apprenticeship Levy, CIS suffered, statutory recoveries, etc.) — **stop and ask**; do not guess an account.

**Reconcile:** the mapped line amounts must sum to the FPS "Total amount due" exactly. Honour the printed total — if the FPS nets off a credit (Employment Allowance, statutory reclaim), the total already reflects it; don't re-derive it.

**Double-count guard (critical).** Confirm the pay run has already posted the liabilities before proposing a payment that clears them. Retrieve the trial balance and check that **825 (PAYE Payable)** and **826 (NIC Payable)** carry credit balances consistent with the amounts you are about to pay. 

- If they carry balances → good, this is a settling payment. Proceed.
- If they are **empty/zero** → the pay run did NOT post these liabilities. **Stop.** Paying against empty payable accounts would push them negative. Flag it and ask whether payroll is posted via a different route (e.g. a manual payroll journal is needed first) before continuing.

## Phase 3: Propose the Spend Money transaction — STOP

Present the proposed transaction for review:

- **Type**: Spend Money (`SPEND`)
- **Bank**: Monzo Business Account (default — look up its account ID by name)
- **Contact**: HMRC
- **Date**: the pay date (see the date note below)
- **Reference**: `PAYE/NIC to HMRC - FPS <tax month or pay date>`

| Line | Account | Amount |
|---|---|---|
| Income Tax | 825 PAYE Payable | £X.XX |
| Employer's NICs | 826 NIC Payable | £X.XX |
| Employees' NI deductions | 826 NIC Payable | £X.XX |
| **Total** | | **£X,XXX.XX** |

**Date note.** Electronic PAYE/NIC is due to HMRC by the 22nd of the following tax month, so the pay date is often earlier than the day the money actually leaves the bank. For clean bank reconciliation the transaction date should match the **date the payment clears the account**. Use the pay date if that is what the user asked for, but flag this and offer to re-date it to the actual payment date.

**STOP HERE. Ask the user to confirm before posting.**

## Phase 4: Post the transaction

Only after user approval, create the bank transaction in Xero:

- `type`: `SPEND`
- `bankAccountId`: Monzo Business Account
- `contactId`: HMRC
- `date`: the agreed date
- `reference`: as above
- `lineItems`: one per FPS charge — `description`, `quantity: 1`, `unitAmount`, `accountCode`, `taxType: NONE`

After posting, report the transaction ID, date, total, the line breakdown, and the clickable Xero deep link. Confirm the total equals the FPS "Total amount due" for reconciliation.

## Rules

- Never post without user approval.
- This is a **payment that clears** PAYE/NIC liabilities — never a fresh liability journal. Do not double-count what the pay run posted.
- Verify the entity and that the FPS is the intended pay run before posting.
- The transaction total must equal the FPS "Total amount due from FPS" exactly.
- Employer and employee NI both clear account 826 (two lines, one account).
- Use `taxType: NONE` on every line (no VAT on PAYE/NIC).
- If a charge line isn't in the mapping table, or the payable accounts don't carry the expected balances, stop and ask rather than guessing.
- If posting fails, report the error and check: valid account codes, valid bank/contact IDs, and bank-transaction permissions.
