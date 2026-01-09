# Expense Tracker (SwiftUI + SwiftData + Supabase)

A local-first expense tracker built with SwiftUI + SwiftData, with Supabase email/password auth, profile support, and a Supabase sync service.

## Features

### Expense & income tracking

- Local-first persistence using SwiftData
- Add transactions as **Expense** or **Income**
- Fields: amount, currency, date/time, title, category, payment method, notes, and mood/emotional tag
- Approval workflow for expenses: **pending → approved** (or **discarded**) with a dedicated **Review** screen

### Dashboard & analytics

- Monthly **Financial Health Score** (0–100) with explainable scoring factors
- Key stats: total spent, average per day, transactions count, and daily logging ratio/streak
- Category breakdown chart (pie)
- 30-day spending trend chart (line)
- Rule-based, explainable insights (e.g., mood correlation, category breadth, volatility change)
- “Quick Add” templates for common expenses

### Budgets, goals, and timeline

- Monthly budgets with per-category planned amounts
- Optional **zero-based budgeting** (assigned income + unassigned calculation)
- Per-category carry-forward rules: next month / savings / none
- Automatic carry-forward processing on app launch and when the app becomes active
- Savings goals with progress tracking and optional deadlines
- Quick allocate savings to a goal via swipe actions (records goal allocation events)
- Timeline combining transactions, budgets, budget changes, and goal allocation events

### Settings, safety, and data tools

- Appearance: System / Light / Dark theme
- Preferences: default currency code and fiscal month start day
- Review reminder: optional daily local notification + configurable time
- Security: optional app lock (Face ID / Touch ID / device passcode)
- Export: generate and share a JSON export of expenses
- Data integrity checks (monthly): duplicate detection + outlier detection
- Reset tools: delete local expenses for the current month or current year

### Supabase (cloud)

- Email/password authentication
- Password reset flow (deep link back into the app)
- Profiles table support (stores full name and basic profile data)
- Sync service:
  - Download expenses from Supabase into local SwiftData
  - Upload local expenses, budgets, goals, and templates to Supabase

## Project Structure

- `Expense-tracker/` – app source
- Local storage: SwiftData models in-app (offline/manual entry)
- Supabase (optional): email/password auth + `profiles` table

## Supabase Setup

### 1) Configure Supabase URL + anon key

Edit:
- `Expense-tracker/Core/Services/SupabaseConfig.swift`

Set:
- `SupabaseConfig.urlString` (Project URL)
- `SupabaseConfig.anonKeyString` (anon/publishable key)

### 2) Configure redirect URL (for password reset)

This app registers the URL scheme:
- `expense-tracker://auth-callback`

It’s defined in:
- `Expense-tracker/Core/Services/SupabaseConfig.swift` (`SupabaseConfig.redirectURL`)

And registered in:
- `Expense-tracker/Info.plist` (`CFBundleURLTypes`)

In the Supabase dashboard:
- Authentication → URL Configuration
- Add this Redirect URL:
  - `expense-tracker://auth-callback`

### 3) Create `profiles` table

In Supabase SQL editor, create a `profiles` table (example):

```sql
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  updated_at timestamptz not null default now()
);
```

### 4) Enable RLS + policies

```sql
alter table public.profiles enable row level security;

create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = id);

create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);
```

## Password Reset (Forgot Password)

- From the Auth screen, tap **Forgot password?** and send the reset email.
- Open the email link on this device.
- The app handles the deep link and shows a **Reset password** screen.

## Session / JWT Tokens

The app listens to Supabase auth events and caches the session access token (JWT) in memory.
- Initial session is read at app start.
- Token refreshes are captured via the `TOKEN_REFRESHED` event.

(These values are stored in `AppState` as `accessTokenJWT`, `refreshToken`, and `tokenExpiresAt`.)

## Running

- Open `Expense-tracker.xcodeproj` in Xcode.
- Select an iOS simulator/device.
- Build & Run.

If auth-related features fail:
- Confirm `SupabaseConfig` is set correctly.
- Confirm the Redirect URL is added in Supabase.
- Confirm the `profiles` table + RLS policies exist.

## Dark Mode / Theme

Choose **Settings → Appearance → Theme** to force Light/Dark, or keep **System**.
