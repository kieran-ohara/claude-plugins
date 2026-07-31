---
name: uber-invoice
description: Processes Uber invoice PDFs (Uber Eats orders and Uber rides/trips) and creates bank transactions in Xero for reconciliation. Detects the invoice type, applies the correct account codes and VAT treatment, and breaks out line items.
---

## Functionality

1. **Reads PDF invoice(s)** - Extracts order/trip details, line items, VAT, and amounts.
2. **Detects the invoice type** and routes to the correct handling:
   - **Eats** - a food order, usually a dual invoice (restaurant items + Uber delivery/service fees).
   - **Trips** - a ride, a single "Transportation service fare" line issued by Uber B.V.
     *on behalf of* an individual driver.
3. **Creates Xero bank transaction(s)** with:
   - **Bank**: Monzo Business Account (default)
   - **Contact**: Uber (auto-selected)
   - **Line items**: Categorised per the mapping below
   - **Transaction date**: the invoice date
   - **Reference**: the Uber invoice number (for traceability / reconciliation)
   - **Perfect reconciliation**: total matches the bank statement exactly

## Detecting the invoice type

Read the PDF text and classify before applying any rules:

- **Trips** if the line item reads **"Transportation service fare"** and the invoice is
  *"issued by Uber B.V. on behalf of"* a named driver. These typically carry the note
  *"VAT not applicable, below VAT registration threshold."*
- **Eats** if there are restaurant food items and/or an Uber delivery/service-fee invoice.

If a single PDF is ambiguous, inspect the line items — food items ⇒ Eats, a fare ⇒ Trips.

## One transaction per invoice

Each Uber **invoice** is its own bank transaction, matching one line on the bank statement:

- **Trips**: each ride is a separate invoice ⇒ a separate bank transaction. Do **not** merge
  multiple rides into one transaction, even when processing a batch of PDFs together.
- **Eats**: the restaurant invoice and the delivery invoice for the *same order* are the two
  halves of one payment ⇒ combine them into a single transaction with separate line items.

## VAT handling — read it from the invoice, never assume

Always take the VAT treatment from the actual invoice rather than hardcoding a rate.

### Trips

- Drivers below the VAT registration threshold charge **no VAT** (the invoice shows a "-" in the
  Tax / Tax Amount columns, or states *"VAT not applicable, below VAT registration threshold"*).
  Use the fare amount with the **`NONE`** tax type (Xero's "No VAT" rate).
- If a trip invoice *does* show a VAT amount, honour it: use the VAT-inclusive amount with
  **INPUT2** (20% VAT).

### Eats

- **Restaurant food**: VAT-inclusive amounts + **INPUT2** (20% VAT)
- **Delivery fees**: VAT-inclusive amounts + **INPUT2** (20% VAT)
- **Service fees**: VAT-inclusive amounts + **INPUT2** (20% VAT)
- **Tips**: **`NONE`** (tips are not VAT-able)

## Account Code Mapping

### Trips

- **Transportation service fare**: **493** (Travel - National)
- International rides: **494** (Travel - International)

### Eats

- **Food / Restaurant items**: **311** (Food)
- **Service fees**: **311** (Food)
- **Delivery fees**: **425** (Postage, Freight & Courier)
- **Tips**: **311** (Food)

## Line item descriptions

Make each line traceable back to its source:

- **Trips**: e.g. `Uber trip - 10 Jul 2026 - <driver name>`
- **Eats**: the restaurant name and item, plus a separate delivery/service line.

## Output

- **Transaction ID(s)** and Xero deep link(s)
- **Total amount** for each transaction, for bank reconciliation verification
- **Success confirmation** with the applied account codes and VAT treatment
- When processing a batch, a short summary table (date, driver/restaurant, amount, VAT).

## Special Cases Handled

### Trips

- Drivers below the VAT threshold (no reclaimable VAT)
- A batch of separate rides processed together (one transaction each)
- International rides (Travel - International)

### Eats

- Combined restaurant + delivery invoices (separate line items)
- Multiple items from the same restaurant
- Service fees and small order fees
- Driver tips (excluded from VAT)
- Promotional discounts

## Template

Uses the VAT-inclusive amounts printed on the invoice with the appropriate tax type
(**INPUT2** where VAT is charged, **`NONE`** where it is not — note Xero's no-VAT type is
`NONE`, not `NO_TAX`) so Xero calculates VAT automatically and the bank reconciliation
totals match exactly.
