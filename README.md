# SaveToWIN!

A simple personal budgeting web app. It runs entirely in your browser as a single HTML file — nothing to install and no account needed. By default your data never leaves your device (it is saved in the browser's local storage).

It can also use optional cloud accounts: sign in with an email and password and your transactions and budget are saved to your account, so they follow you to any phone or browser. This is off until it is configured; see [SETUP.md](SETUP.md). When it is not configured, the app behaves exactly as before — fully local, no setup, no account.

## What it does

- **Spending** — upload a transactions file (CSV) from your bank and SaveToWIN! sorts each purchase into categories, then shows where your money went for the month: a total, a breakdown by category, recurring charges, and a month-to-month trend.
- **Plan** — set your take-home income and a Needs / Wants / Savings budget (starting at 50/30/20, fully adjustable). See how much is safe to spend, how each category is tracking, and what is left to save.

## Using it

1. Open `index.html` in any browser. It opens with sample data so you can look around.
2. To use your own numbers, download your transactions as a CSV from your bank:
   - **Wells Fargo:** sign in → account activity → Download → Comma Delimited (.csv)
   - **American Express:** Statements & Activity → Download → CSV
3. On the Spending tab, tap **Add transactions** and pick the file. SaveToWIN! reads both the Wells Fargo and American Express formats.
4. Tap any transaction to recategorize it; SaveToWIN! remembers that merchant next time.
5. Use the month arrows to move between past and future months.

## Cloud accounts (optional)

SaveToWIN! can save data to a per-user account instead of just one browser, so it syncs across devices. It uses Supabase for sign-in and storage, with each account's data isolated at the database level. Turning this on is a one-time setup (a free Supabase project, running the database script, and hosting the app on a free HTTPS link). The full walkthrough is in [SETUP.md](SETUP.md). Until it is configured, SaveToWIN! stays local-only with no account.

## Notes

- The app is one file (`index.html`) with no build step.
- Without cloud accounts configured, transactions and budget are stored locally in the browser, so clearing browser data or switching devices starts fresh.
- With cloud accounts configured and signed in, transactions and budget are saved to the account and follow you across devices.
