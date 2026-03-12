---
name: verify-payslip
description: Verify and fix a draft Xero payslip against expected figures. Reads employee config, calculates expected values, inspects Xero, compares, and applies corrections with user approval.
argument-hint: <employee-name>
---

You are verifying a draft payslip in Xero Payroll for a specific employee. Follow each phase in order. Do NOT skip phases. Stop and wait for user approval before making any changes in Xero.

## Input

`$ARGUMENTS` is the employee name (e.g. "kieran"). Use this to select the correct config file from the skill directory.

Employee config files are in `${CLAUDE_SKILL_DIR}/` named like `irkb-kieran.md`. Read the matching file to get all employee details, contract terms, thresholds, expected figures, Xero URLs, and known issues.

## Phase 1: Load reference data

1. Read the employee config file from the skill directory
2. Find the most recent payslip PDF in the payslip archive path specified in the config
3. Read the previous payslip PDF to confirm figures are consistent with the config

Present a summary:
- Employee name, tax code, NI category
- Expected figures table from the config
- Any differences between the config and the previous payslip (flag these for the user)

## Phase 2: Inspect Xero draft

1. Navigate to the draft payruns page (URL from config)
2. Find and open the current draft payrun
3. Click into the employee's payslip
4. Capture all figures: earnings, deductions, employee taxes, employer taxes, employer pensions, net pay, total cost

Present a comparison table:

| Field | Expected | Actual | Status |
|---|---|---|---|
| Gross Earnings | ... | ... | ✓ / ✗ |
| Salary Sacrifice Pension | ... | ... | ✓ / ✗ |
| PAYE | ... | ... | ✓ / ✗ |
| Employee NI | ... | ... | ✓ / ✗ |
| Net Pay | ... | ... | ✓ / ✗ |
| Employer NI | ... | ... | ✓ / ✗ |

## Phase 3: Plan corrections

For each field marked ✗, explain:
- What the current value is and why it's wrong
- What needs to change and how
- Reference any known Xero issues from the config that apply

Present the plan as a numbered list of changes to make.

**STOP HERE. Ask the user to approve the plan before proceeding.**

## Phase 4: Execute corrections

Only after user approval:

1. Apply each change from the plan in order
2. After each change, take a snapshot to confirm it took effect
3. Check for known Xero issues (e.g. employer NI manual adjustment) and apply workarounds
4. Save the payslip

## Phase 5: Verify

1. Take a final snapshot of the saved payslip
2. Present a final comparison table showing all fields match expected values
3. Report any remaining discrepancies

## Rules

- Never make changes without user approval
- Always show your working — present tables and comparisons, not just conclusions
- If a figure doesn't match and you can't explain why, flag it and ask the user
- One change at a time — don't batch multiple fixes without checking intermediate state
