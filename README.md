# fam-tree
# 🌳 Family Tree

A private website where your family can build a shared family tree together.
People sign up with a secret **family code**, claim their own box on the tree, add relatives, share photos in a **scrapbook**, send each other messages, and see everyone on a **timeline**.

**Built with:** Next.js (the website) · Supabase (database + logins) · Cloudinary (photo storage) · Vercel (hosting). All have free plans that are plenty for a family.

---

## 📋 The Big Picture (read this first)

You will do 6 things, in this order. Each one is explained below.

| # | Part | Time | What it does |
|---|------|------|--------------|
| 1 | **Fill in 4 things in the code** | 5 min | Your email, your name, your family code, your welcome letter |
| 2 | **Supabase** | 10 min | Creates the database + login system |
| 3 | **Cloudinary** *(optional)* | 5 min | Lets people upload photos |
| 4 | **GitHub** | 5 min | Stores your code online so Vercel can find it |
| 5 | **Vercel** | 5 min | Puts the website on the internet |
| 6 | **First login** | 2 min | You create the admin account |

> 💡 **You don't need to install anything** to put this online. Everything can be done in your web browser.

---

# PART 1 — Fill in your information

There are **4 places** to fill in. Open each file (on your computer, in any text editor like Notepad, TextEdit or VS Code) and change only what is described.

## ✏️ Place 1: `lib/config.ts` — your settings (the main one)

| Line | Name | What to put | Example |
|------|------|-------------|---------|
| **8** | `SITE_NAME` | The title of your site | `'The Garcia Family Tree'` |
| **14** | `ADMIN_EMAIL` | **Your** email. You become the admin (the only person who can delete things). | `'maria@gmail.com'` |
| **18** | `ADMIN_NAME` | Your first name. Shown in messages like "Ask Maria for the code". | `'Maria'` |
| **24** | `FAMILY_CODE` | A secret word relatives type to join. Not case-sensitive. | `'sunflower2026'` |
| **28** | `CLOUDINARY_CLOUD_NAME` | *(Part 3 — skip for now if you want)* | `'dab12xyz'` |
| **29** | `CLOUDINARY_UPLOAD_PRESET` | *(Part 3)* Leave as is unless you named it differently | `'family_tree_unsigned'` |

⚠️ Keep the quotes `' '` around each value. Don't delete them.

## ✏️ Place 2: `supabase/schema.sql` — your admin email again (line 26)

Find this line (around line 26):

```sql
values ('admin_email', 'you@example.com')
```

Change `you@example.com` to **the exact same email** you used for `ADMIN_EMAIL` above.

> Why twice? The website needs it to show/hide buttons. The database needs it to enforce the rules. If they don't match, your admin buttons won't work.

## ✏️ Place 3: `components/WelcomeLetter.tsx` — your welcome letter (lines 21–61)

This is the letter every relative sees when they first sign in.
- **Lines 21–40** = English letter (`LETTER_EN`)
- **Lines 42–61** = Spanish letter (`LETTER_ES`)

It's just normal sentences. Change anything you like. Keep the backtick `` ` `` at the start and end of each letter. Your name at the bottom and the site name are filled in automatically from `lib/config.ts`.

*(Don't want two languages? Replace the Spanish text with your family's language, or copy the English text into it.)*

## ✏️ Place 4: `.env.local` — your Supabase keys (you'll do this in Part 2)

You don't create this file for the online version. Vercel gets these keys a different way (Part 5). The file `.env.local.example` just shows you what they look like. **You only need `.env.local` if you want to run the site on your own computer** (see the "Run it on your computer" section at the bottom).

---

# PART 2 — Supabase (database + logins)

### Step 2.1 — Create the project

1. Go to **https://supabase.com** → click **Start your project** → sign up (the "Continue with GitHub" button is easiest).
2. Click **New project**.
3. Fill in:
   - **Name:** anything (e.g. `family-tree`)
   - **Database password:** click **Generate a password**, then **copy it into a safe place** (you won't need it often, but don't lose it)
   - **Region:** pick the one closest to your family
4. Click **Create new project**. Wait about 2 minutes while it sets up.

### Step 2.2 — Build the database (copy–paste, one time)

1. Make sure you've already changed the email on line 26 of `schema.sql` (Part 1, Place 2).
2. In Supabase's left sidebar, click **SQL Editor**.
3. Click **New query**.
4. Open `supabase/schema.sql` on your computer, **select everything (Ctrl+A / Cmd+A), copy it**, and **paste it** into the Supabase box.
5. Click the green **Run** button (bottom right).
6. You should see: ✅ **"Success. No rows returned."**

> If you see a red error: the most common cause is that the file was only partly copied. Clear the box and copy the *whole* file again. It's safe to run it multiple times.

### Step 2.3 — Turn OFF email confirmation ⚠️ (important!)

If you skip this, people will get stuck on the sign-up page.

1. Left sidebar → **Authentication**.
2. Click **Sign In / Providers**.
3. Click **Email** to expand it.
4. Switch **Confirm email** to **OFF**.
5. Click **Save**.

### Step 2.4 — Copy your 2 keys (save them in Notepad for Part 5)

1. Click the **Connect** button at the top of the Supabase page (or go to **Project Settings → API Keys**).
2. Copy these two things into a Notepad file:

| Name | Where it is | Looks like |
|------|-------------|-----------|
| **Project URL** | Connect dialog / Project Settings | `https://abcdefgh.supabase.co` |
| **Publishable key** | Settings → **API Keys** tab (click *Create new API Keys* if you don't see one) | `sb_publishable_xxxxxxxx` |

> 🔑 **If your project still shows an "anon" key** (a very long text starting with `eyJ`), that works too. Use whichever you see. Supabase is slowly replacing "anon" with "publishable".
>
> 🚫 **NEVER** use the **"secret"** or **"service_role"** key. Those are like the master password to your whole database.

✅ Supabase is done.

---

# PART 3 — Cloudinary (photo uploads) — *optional*

Without this, the site still works but nobody can upload photos. You can add it later.

1. Go to **https://cloudinary.com** → sign up for free.
2. On your dashboard, find your **Cloud name** (top left or under "Product Environment Credentials"). Copy it.
3. Open `lib/config.ts` and paste it on **line 28** between the quotes.
4. In Cloudinary: click the **gear icon ⚙️ (Settings)** → **Upload** tab → scroll to **Upload presets** → **Add upload preset**.
5. Set:
   - **Preset name:** `family_tree_unsigned` (must match line 29 of `lib/config.ts`)
   - **Signing mode:** **Unsigned** ← very important
6. Click **Save**.

✅ Photos will now work.

---

# PART 4 — Put your code on GitHub

Vercel needs your code to be on GitHub. (Free account at **https://github.com**.)

1. Log in to GitHub → click the **+** at the top right → **New repository**.
2. **Repository name:** `family-tree`.
3. Choose **Private** (recommended — it's your family's site).
4. Click **Create repository**.
5. On the next page, click the link that says **"uploading an existing file"**.
6. Open the project folder on your computer. **Select everything INSIDE the folder** (all the files and folders: `app`, `components`, `lib`, `supabase`, `package.json`, etc.) and **drag them into the GitHub page**.

   > ⚠️ Drag the *contents*, not the outer folder. On GitHub you should see `package.json` right at the top level of the list, not inside another folder. This is the #1 mistake.
   >
   > ⚠️ Do **not** upload a folder called `node_modules` or `.next` if you have one. Do **not** upload `.env.local`.

7. Wait for the files to finish uploading. At the bottom click **Commit changes**.

✅ Your code is on GitHub.

> **Prefer an app?** Download **GitHub Desktop** instead: File → Add Local Repository → Publish. Same result.

---

# PART 5 — Vercel (put it on the internet)

1. Go to **https://vercel.com** → **Sign Up** → **Continue with GitHub**.
2. Click **Add New… → Project**.
3. Find your `family-tree` repo in the list and click **Import**.
   *(Don't see it? Click "Adjust GitHub App Permissions" and give Vercel access to the repo.)*
4. Vercel will detect **Next.js** by itself. **Don't change** any build settings. Leave **Root Directory** as `./`.
5. Click **Environment Variables** to expand it, and add **two** variables (copy these names exactly, then paste the values from your Notepad from Step 2.4):

   | Name (key) | Value |
   |-----------|-------|
   | `NEXT_PUBLIC_SUPABASE_URL` | your Project URL |
   | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | your Publishable key (or anon key) |

   > Yes, the second one says "ANON" even if you're pasting a publishable key. That's just the variable's name in the code; leave it exactly like that.

6. Click **Deploy**.
7. Wait 1–2 minutes. When you see 🎉 confetti, click **Continue to Dashboard**, then click the picture of your site (or **Visit**) — that's your website address (`something.vercel.app`).

✅ Your site is live!

> **Later changes:** any time you change a file on GitHub, Vercel automatically re-publishes in about a minute.
> **If you change an environment variable** in Vercel (Settings → Environment Variables), go to **Deployments → ⋯ → Redeploy** for it to take effect.

---

# PART 6 — First login (YOU first!)

⚠️ **Do this before you give the link to anyone.** The first account must be the admin.

1. Open your site → under the sign-in box click **Create one** (or go straight to `yoursite.vercel.app/register`).
2. Type your **family code** (from `FAMILY_CODE` in `lib/config.ts`).
3. Create your account using **exactly the email** you put in `ADMIN_EMAIL`.
4. Choose **"I'm not on the tree yet — create my profile"** and finish.
5. You should land on the tree with your box on it. You are now the admin: you'll see extra buttons (Import, delete approvals, private mode, etc.).

**Then invite family:** send them the link + the family code.

### 🔒 Locking it down (recommended, 1 minute)

Once everyone has joined, close the door so strangers can't sign up even if they find the code:

Supabase → **Authentication → Sign In / Providers** → turn **OFF "Allow new users to sign up"** → Save.
(Turn it back ON any time a new relative needs to join.)

> **Honest note about the family code:** it's checked inside the website itself, so a determined technical person could find it. It keeps casual visitors out, but the toggle above is the real lock.

---

# 🗺️ WHO CAN DO WHAT

| Action | Regular family member | You (admin) |
|--------|:--:|:--:|
| See the tree, scrapbooks, timeline | ✅ | ✅ |
| Add people, relationships, photos, notes | ✅ | ✅ |
| Edit anyone's details | ✅ | ✅ |
| Drag cards (only changes *their own* view) | ✅ | ✅ |
| Delete a person / line / scrapbook item | ❌ they press **"Request deletion"** | ✅ |
| Approve or deny deletion requests | ❌ | ✅ |
| Import a GEDCOM file / merge duplicates | ❌ | ✅ |
| Private people & notes (only you see them) | ❌ | ✅ |
| Private messages | ✅ only the two people in the chat | ✅ |

---

# 🧭 WHERE IS EVERYTHING? (the code map)

If you want to change something, here's which file to open.

### Screens (pages)

| Page on the site | File | Notes |
|------------------|------|-------|
| Home (just redirects) | `app/page.tsx` | Sends you to `/tree` or `/login` |
| Sign in | `app/login/page.tsx` | `handleLogin()` — line 16 |
| Register | `app/register/page.tsx` | `checkCode()` line 25 · `handleRegister()` line 35 · `handleClaim()` line 69 |
| **The tree** | `app/tree/page.tsx` | `loadData()` line 130 · `savePositions` line 380 · `onEdgesChange` line 447 · sign-out line 602 |
| Scrapbook (per person) | `app/scrapbook/[memberId]/page.tsx` | `scheduleItemSave()` line 189 · `deleteItem()` line 216 |
| Timeline | `app/timeline/page.tsx` | `WORLD_EVENTS` list line 8 (add/remove history events here) · `saveCustomEvent` line 188 |
| Import GEDCOM *(admin)* | `app/import/page.tsx` | Imports a family-tree file from Ancestry/FamilySearch/etc. |
| Find duplicates *(admin)* | `app/duplicates/page.tsx` | Merge people who were added twice |
| Fix relationships *(admin)* | `app/fix-relationships/page.tsx` | Repair tool for GEDCOM imports. You can ignore it. |

### Pieces used inside pages

| Piece | File | Notes |
|-------|------|-------|
| Add/edit/connect-person popup | `components/MemberModal.tsx` | `handlePhotoUpload()` line 93 · `handleSave()` line 120 · `handleDelete()` line 208 |
| A person's card on the tree | `components/MemberNode.tsx` | Look/size of each card |
| Sticky notes | `components/StickyNoteNode.tsx` | |
| Welcome letter | `components/WelcomeLetter.tsx` | ✏️ Part 1, Place 3 |
| "Request deletion" popup | `components/DeleteRequestModal.tsx` | |
| Messaging | `components/MessageBox.tsx` | `sendMessage()` line 111 |
| Relationship picker | `components/RelationshipPanel.tsx` | |

### Behind-the-scenes files

| File | What it is |
|------|-----------|
| `lib/config.ts` | ✏️ **Your settings** (Part 1, Place 1) |
| `lib/supabase.ts` | Connects the site to Supabase (uses your 2 keys) |
| `lib/cloudinary.ts` | Sends photos to Cloudinary |
| `lib/parseGedcom.ts` | Reads GEDCOM files |
| `lib/autoLayout.ts` | Automatically arranges cards on the tree |
| `lib/types.ts` | Describes what a "person" and "relationship" look like |
| `supabase/schema.sql` | ✏️ The database blueprint (Part 1, Place 2 · Part 2) |
| `app/globals.css` | Colors & fonts (the brown/gold look) |
| `package.json` | List of tools the site uses. Don't edit. |

---

# 💻 Run it on your computer (optional)

Only needed if you want to test changes before publishing.

1. Install **Node.js** (the "LTS" version) from https://nodejs.org
2. Open a terminal in the project folder.
3. Make your secrets file:
   - Copy `.env.local.example` and name the copy `.env.local`
   - Open it and paste your Supabase URL and key
4. Run:

```bash
npm install
npm run dev
```

5. Open http://localhost:3000

---

# 🆘 TROUBLESHOOTING

| Problem | Fix |
|---------|-----|
| **Vercel build fails: "Couldn't find any `pages` or `app` directory"** | Your files are inside an extra folder on GitHub. Re-upload so `package.json` is at the top level (Part 4, step 6). |
| **Site loads but login says "Invalid API key" or "fetch failed"** | The two Environment Variables in Vercel are wrong or missing. Fix them, then **Redeploy**. Check there are no spaces before/after the values. |
| **Register says "waiting for email confirmation"** | Part 2, Step 2.3. Turn **Confirm email** OFF. |
| **Register says "User already registered"** | That email already has an account. Use **Sign in**. |
| **"Incorrect code"** | The code must match `FAMILY_CODE` in `lib/config.ts` (not case-sensitive). If you just changed it, wait for Vercel to finish re-deploying. |
| **I'm not seeing admin buttons** | `ADMIN_EMAIL` in `lib/config.ts` and the email in `schema.sql` must both match the email you registered with. If the SQL one was wrong: fix it, paste the whole SQL file into the SQL Editor again, and Run. |
| **"Only the admin can delete people"** | You're signed in with a non-admin account. |
| **Photo upload fails** | Part 3: the preset must be **Unsigned**, and its name must match line 29 of `lib/config.ts`. Cloud name on line 28 must be right. |
| **Site stopped working after a few weeks of no use** | Free Supabase projects **pause** after about a week with no activity. Open your Supabase dashboard and click **Restore project**. |
| **A big tree only shows some people** | Supabase returns at most 1,000 rows at a time by default. Fine for most families; if you import thousands of people, ask a developer to add paging to `loadData()`. |
| **A message about the "SQL migration"** | That means the database is missing something. Re-run the whole `supabase/schema.sql` (safe to repeat). |

---

# 🔐 Safety checklist

- ✅ Never put the **secret / service_role** key anywhere in this project.
- ✅ Never upload `.env.local` to GitHub (the included `.gitignore` already blocks it).
- ✅ Keep your GitHub repo **Private**.
- ✅ Register as admin **first**, before sharing the link.
- ✅ Turn off "Allow new users to sign up" once everyone has joined.
- ✅ Don't put passwords or personal info in this README or in code files.
