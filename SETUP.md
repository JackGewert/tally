# Tally — Cloud Accounts Setup

This is the one-time setup to turn on cloud accounts, so your sister can sign in
on her phone and have her data saved to her account instead of just one browser.

You only do this once. Most of it is logging into services and copying two values.
The app code itself is already built — you are not writing any code here.

If you skip all of this, Tally still works: open `index.html` and it runs fully
locally in the browser with no account and no setup.

---

## Checklist

### 1. Create a free Supabase project

1. Go to **supabase.com** and sign in (create an account if you don't have one).
2. Click **New project**. Pick any name, set a database password (save it
   somewhere), choose the nearest region, and create it. It takes a minute or two
   to finish provisioning.
3. Once it's ready, open **Project Settings → API**. You need two values from here:
   - **Project URL** — looks like `https://abcdefghijklmnop.supabase.co`
   - **Project API keys → `anon` `public`** — a long string starting with `eyJ...`

   Use the **`anon` `public`** key. **Never** use the **`service_role`** key. The
   service_role key bypasses all security and would let anyone read every account's
   data if it ended up in the app. The anon public key is the only one that belongs
   in front-end code.

### 2. Run the database setup

1. In your Supabase project, open the **SQL Editor** (left sidebar).
2. Open `schema.sql` from this repo, copy its entire contents, and paste it into a
   new query in the SQL Editor.
3. Click **Run**.

   This creates the tables Tally needs and the per-user security policies (row level
   security), so each signed-in user can only ever see and change their own rows.

### 3. Email sign-in

Email and password sign-in is **on by default** in a new Supabase project, so there
is nothing to switch on. Two things to know:

- **New users must confirm their email.** After someone creates an account, Supabase
  emails them a confirmation link. They have to click it before their first sign-in
  works. (This is expected — tell your sister to check her inbox / spam.)
- **Once the app is hosted, add the site URL.** Go to
  **Authentication → URL Configuration** and set the **Site URL** to the hosted link
  from step 5. Confirmation and password-reset links are built from that URL, so if
  it's wrong those links won't work. (You'll come back here after step 5.)

### 4. Paste your two values into the app

Open `index.html` and find the two config constants at the top of the module script.
They look like this:

```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace the placeholders with the **Project URL** and the **`anon` `public`** key
from step 1. Keep the quotes. Save the file.

(If you leave the placeholders as-is, Tally just runs in local-only mode with no
accounts — that's the fallback, not an error.)

### 5. Host it so she gets a phone link

To use Tally on a phone, it needs to be on a real HTTPS link she can bookmark.
The repo is private at **github.com/JackGewert/tally**. Either of these is free and
connects straight to the repo:

- **Vercel** — vercel.com → **Add New → Project** → import the `tally` repo → Deploy.
- **Netlify** — app.netlify.com → **Add new site → Import an existing project** →
  pick the `tally` repo → Deploy.

Both give you an HTTPS URL like `https://tally-yourname.vercel.app`. That's the link
she bookmarks.

Then go back to Supabase → **Authentication → URL Configuration** and put that same
URL in the **Site URL** field (and in the redirect URLs list if it asks). This makes
the email confirmation and reset links point at the live site.

---

## How your sister uses it

1. Open the link you sent her (and bookmark it / add to home screen).
2. Create an account with her email and a password.
3. Check her email and click the confirmation link.
4. Come back to the link and sign in.
5. Upload her CSV the same way as before, on the Spending tab.

After that, her transactions and budget are tied to her account, so they're there on
any phone or browser where she signs in.

---

## Security note

- **Each account is isolated at the database level.** The per-user security policies
  from `schema.sql` mean one account literally cannot read or change another
  account's data, even if someone tried.
- **Only the public key is in the app.** The anon public key is meant to be visible
  in front-end code; it can't do anything a signed-in user isn't allowed to do. The
  service_role key never goes near the app.
- **Her data lives on Supabase's servers**, sent over HTTPS. If you never do this
  setup, nothing leaves the browser at all — that's the local-only default.
