# Production Deployment Guide

This guide will help you prepare the Expense Tracker app for production deployment with Supabase backend.

## Step 1: Supabase Setup

### 1.1 Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in your project details:
   - **Name**: Expense Tracker (or your preferred name)
   - **Database Password**: Create a strong password
   - **Region**: Choose closest to your users
4. Wait for project to be created (~2 minutes)

### 1.2 Run Database Migrations

1. Open your Supabase project
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New query**
4. Copy and paste the entire contents from `SUPABASE_SCHEMA.md`
5. Click **Run** to execute the SQL
6. Verify all tables were created in **Database → Tables**

Expected tables:
- profiles
- expenses  
- budgets
- goals
- expense_templates

### 1.3 Configure Storage

1. Go to **Storage** in Supabase dashboard
2. The `receipts` bucket should be auto-created by the schema
3. Verify bucket policies are in place

### 1.4 Get Your Credentials

1. Go to **Project Settings** → **API**
2. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (starts with `eyJ...`)

## Step 2: Update iOS App Configuration

### 2.1 Configure Supabase

Open `Core/Services/SupabaseConfig.swift` and update:

```swift
private static let urlString: String = "YOUR_PROJECT_URL_HERE"
private static let anonKeyString: String = "YOUR_ANON_KEY_HERE"
```

### 2.2 Verify URL Scheme

Check `Info.plist` contains:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>expense-tracker</string>
    </array>
  </dict>
</array>
```

### 2.3 Update Authentication Redirect

1. In Supabase Dashboard: **Authentication** → **URL Configuration**
2. Add to **Redirect URLs**: `expense-tracker://auth-callback`

## Step 3: Enable Cloud Sync

### 3.1 Add Sync on App Launch

The app will automatically sync when:
- User signs in
- App becomes active
- User manually pulls to refresh

### 3.2 Test Sync

1. Build and run the app
2. Sign up/Sign in with a test account
3. Add some expenses
4. Check Supabase Dashboard → **Table Editor** → **expenses**
5. Verify your expenses appear in the database

## Step 4: Remove Sample Data

All sample/static data has been removed. The app now:
- Uses only real user data from Supabase
- Falls back to local SwiftData when offline
- Syncs automatically when connection is restored

## Step 5: Production Checklist

### Security
- [ ] Supabase anon key is configured
- [ ] Row Level Security (RLS) is enabled on all tables
- [ ] Service role key is NOT in the app
- [ ] URL scheme matches Supabase auth settings

### Features
- [ ] User can sign up
- [ ] User can sign in
- [ ] Expenses sync to cloud
- [ ] Budgets sync to cloud
- [ ] Goals sync to cloud
- [ ] Data persists across devices
- [ ] App works offline (local-first)

### Testing
- [ ] Test on real device (not just simulator)
- [ ] Test with poor network connection
- [ ] Test offline mode
- [ ] Test signing out and back in
- [ ] Test with multiple accounts

### Performance
- [ ] App launches quickly
- [ ] Sync happens in background
- [ ] UI remains responsive during sync
- [ ] No memory leaks

## Step 6: Optional Enhancements

### 6.1 Enable Realtime (Live Sync)

Add to AppState or similar:

```swift
func setupRealtimeSync() {
    let channel = SupabaseClientProvider.shared.client
        .channel("expenses")
 .on("postgres_changes", 
            filter: ChannelFilter(
                event: "*",
                schema: "public",
                table: "expenses"
            )
        ) { message in
            // Handle realtime updates
            Task {
                await syncService.downloadExpensesFromCloud()
            }
        }
        .subscribe()
}
```

### 6.2 Add Analytics

Consider integrating:
- Firebase Analytics
- Mixpanel
- PostHog

### 6.3 Crash Reporting

Add crash reporting:
- Sentry
- Firebase Crashlytics
- Bugsnag

### 6.4 App Store Preparation

1. Update app version in Xcode
2. Create app screenshots
3. Write App Store description
4. Set up App Store Connect
5. Submit for review

## Step 7: Monitoring

### 7.1 Monitor Database

In Supabase Dashboard:
- Check **Database → Roles** for user growth
- Monitor **Database → Extensions** for performance
- Review **Database → Backups** regularly

### 7.2 Set Up Alerts

Configure in Supabase:
- Database size alerts
- API request alerts
- Error rate alerts

## Troubleshooting

### Users can't sign up
- Check Supabase **Authentication** → **Providers** is enabled
- Verify email templates are configured
- Check project is not paused (free tier)

### Data not syncing
- Verify RLS policies are correct
- Check user is authenticated
- Review Supabase logs in dashboard

### App crashes on launch
- Check Supabase URL and anon key are correct
- Verify Info.plist URL scheme is configured
- Review Xcode console for errors

## Support

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- GitHub Issues: [Your repo]

---

**You're ready for production! 🚀**

The app now has:
✅ Cloud sync with Supabase
✅ Offline-first architecture
✅ Secure authentication
✅ Production-ready database
✅ Modern, professional UI
