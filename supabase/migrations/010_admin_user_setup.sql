-- ================================================
-- SPORTDUNE - ADMIN USER SETUP
-- Run this AFTER migration to create admin user
-- ================================================

-- Step 1: Create admin user in Supabase Auth (via Dashboard)
-- Go to: Supabase Dashboard > Authentication > Users > Add User
-- Email: sportdune@gmail.com
-- Password: SportDune2026

-- Step 2: After creating the auth user, run this SQL to set their role
-- Note: Replace 'AUTH_USER_ID' with the actual UUID from auth.users

-- First, find the user
SELECT id, email FROM auth.users WHERE email = 'sportdune@gmail.com';

-- Then update their role
UPDATE public.profiles
SET role = 'super_admin', is_active = true
WHERE email = 'sportdune@gmail.com';

-- Verify
SELECT id, email, role, is_active FROM public.profiles WHERE email = 'sportdune@gmail.com';

-- ================================================
-- FALLBACK: Manual Profile Creation (if auto-create failed)
-- ================================================
-- Uncomment and run if profile wasn't auto-created:
/*
INSERT INTO public.profiles (id, email, full_name, role, is_active)
SELECT 
  id,
  email,
  split_part(email, '@', 1),
  'super_admin',
  true
FROM auth.users
WHERE email = 'sportdune@gmail.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'super_admin',
  is_active = true;
*/
