# Tally

A simple personal budgeting web app. It runs entirely in your browser as a single HTML file — nothing to install, no account, and your data never leaves your device (it is saved in the browser's local storage).

## What it does

- **Spending** — upload a transactions file (CSV) from your bank and Tally sorts each purchase into categories, then shows where your money went for the month: a total, a breakdown by category, recurring charges, and a month-to-month trend.
- **Plan** — set your take-home income and a Needs / Wants / Savings budget (starting at 50/30/20, fully adjustable). See how much is safe to spend, how each category is tracking, and what is left to save.

## Using it

1. Open `index.html` in any browser. It opens with sample data so you can look around.
2. To use your own numbers, download your transactions as a CSV from your bank:
   - **Wells Fargo:** sign in → account activity → Download → Comma Delimited (.csv)
   - **American Express:** Statements & Activity → Download → CSV
3. On the Spending tab, tap **Add transactions** and pick the file. Tally reads both the Wells Fargo and American Express formats.
4. Tap any transaction to recategorize it; Tally remembers that merchant next time.
5. Use the month arrows to move between past and future months.

## Notes

- Everything is in one file (`index.html`) with no dependencies and no build step.
- Transactions and budget are stored locally in the browser, so clearing browser data or switching devices starts fresh. Cross-device sync is a possible future addition.
