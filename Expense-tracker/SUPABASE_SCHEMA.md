# Supabase Database Schema for Expense Tracker

This document outlines the complete database schema needed for production deployment.

## Prerequisites

1. Create a Supabase project at https://supabase.com
2. Update `SupabaseConfig.swift` with your project URL and anon key
3. Run the SQL migrations below in your Supabase SQL editor

---

## Database Tables

### 1. Profiles Table

Stores user profile information.

```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  fiscal_month_start_day INTEGER DEFAULT 1,
  default_currency_code TEXT DEFAULT 'USD',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW 
  EXECUTE PROCEDURE update_updated_at_column();
```

---

### 2. Expenses Table

```sql
-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('expense', 'income')),
  amount DECIMAL(10, 2) NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'USD',
  title TEXT,
  notes TEXT,
  category TEXT NOT NULL,
  payment_method TEXT,
  emotional_tag TEXT,
  approval_status TEXT NOT NULL DEFAULT 'pending',
  occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  receipt_url TEXT
);

CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_occurred_at ON expenses(occurred_at DESC);

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own expenses" 
  ON expenses FOR ALL 
  USING (auth.uid() = user_id);
```

---

## Setup Instructions

See full schema in project documentation.
