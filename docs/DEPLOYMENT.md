# SportDune Deployment Guide

## Overview

This guide covers deploying the SportDune admin dashboard and applying database migrations.

## Prerequisites

- Supabase account with project created
- Vercel account for hosting
- Git installed
- Node.js installed

## Step 1: Apply Database Migrations

### Option A: Using Supabase Dashboard

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **SQL Editor**
4. Run migrations in order:
   - `005_complete_admin_schema.sql`
   - `006_rls_policies.sql`
   - `007_seed_data.sql`
   - `008_storage_setup.sql`

### Option B: Using Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to project
supabase link --project-ref pvmtcwqupalurwqlvdxy

# Push migrations
supabase db push
```

## Step 2: Create Admin Storage Bucket

1. Go to Supabase Dashboard > **Storage**
2. Click **New Bucket**
3. Configure:
   - Name: `media`
   - Public: ✅ Yes
   - File size limit: `10MB`
   - Allowed MIME types: `image/*,video/*,application/pdf`

## Step 3: Create Admin User

### Option A: Via Dashboard

1. Go to Supabase Dashboard > **Authentication** > **Users**
2. Click **Add User**
3. Enter email and password
4. Click **Create User**

### Option B: Via SQL (after user is created)

```sql
-- Update user role to super_admin
UPDATE public.profiles 
SET role = 'super_admin' 
WHERE email = 'sportdune@gmail.com';

-- Or insert manually if profile doesn't exist
INSERT INTO public.profiles (id, email, full_name, role)
VALUES (
  'your-auth-uuid',
  'sportdune@gmail.com',
  'Admin',
  'super_admin'
);
```

## Step 4: Deploy Admin Dashboard

### Option A: Vercel (Recommended)

1. Push code to GitHub:
```bash
git add .
git commit -m "feat: new admin dashboard"
git push
```

2. Go to [Vercel Dashboard](https://vercel.com/dashboard)
3. Click **New Project**
4. Import from GitHub (select `SportDune` repo)
5. Configure:
   - Framework: `Other`
   - Root Directory: `./admin`
   - Build Command: Leave empty
   - Output Directory: `.`
6. Click **Deploy**

### Option B: Static Hosting

The admin dashboard is pure HTML/CSS/JS and can be hosted anywhere:

```bash
# Build (if needed)
# No build step required for static HTML

# Upload admin folder to:
# - Vercel
# - Netlify
# - GitHub Pages
# - AWS S3 Static Hosting
# - Any web server
```

## Step 5: Configure Environment Variables

No environment variables needed for the vanilla JS version as it uses the public Supabase keys.

For enhanced security, consider:

```javascript
// In js/app.js
const CONFIG = {
  SUPABASE_URL: process.env.SUPABASE_URL || 'https://pvmtcwqupalurwqlvdxy.supabase.co',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || 'sb_publishable_fuqgloaY9Hi7mHi0HsH8DQ_fjvXS_E6',
};
```

## Step 6: Verify Deployment

1. Access admin dashboard at `https://your-domain.com`
2. Login with admin credentials
3. Verify:
   - [ ] Dashboard loads with stats
   - [ ] Can view/create sports
   - [ ] Can view/create leagues
   - [ ] Can view/create articles
   - [ ] RLS policies work correctly
   - [ ] Storage upload works

## Troubleshooting

### CORS Errors
Ensure your Supabase project allows the correct origins:
1. Go to Supabase Dashboard > **Settings** > **API**
2. Add your domain to "CORS Origins"

### Authentication Not Working
1. Check Supabase Auth settings
2. Verify email confirmation is disabled or confirm email
3. Check RLS policies allow auth operations

### Storage Upload Failed
1. Verify storage bucket exists
2. Check storage policies
3. Ensure bucket is public

### Database Permission Errors
1. Check RLS policies are correctly applied
2. Verify service key has admin privileges
3. Test queries in Supabase SQL Editor first

## Security Checklist

- [ ] All RLS policies applied
- [ ] Storage bucket has appropriate policies
- [ ] Admin users have appropriate roles
- [ ] No sensitive data in client-side code
- [ ] Environment variables secured (if used)
- [ ] HTTPS enforced
- [ ] CORS configured correctly

## URLs Reference

| Environment | URL |
|-------------|-----|
| Frontend (Vercel) | https://sportdune.vercel.app |
| Admin Dashboard | https://sportdune-admin.vercel.app |
| Supabase API | https://pvmtcwqupalurwqlvdxy.supabase.co |
| Supabase Dashboard | https://supabase.com/dashboard/project/pvmtcwqupalurwqlvdxy |

## Support

For issues:
1. Check Supabase status page
2. Review browser console errors
3. Test API calls in Supabase SQL Editor
4. Contact support with error details
