# Expense Tracker (SwiftUI + SwiftData + Supabase)

A local-first expense tracker built with SwiftUI and SwiftData, with optional Supabase auth/profile.

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
