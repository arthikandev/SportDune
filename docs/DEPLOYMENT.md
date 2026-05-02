# SportDune Deployment Guide

## Overview

SportDune has two deployments:
1. **Public Frontend** — sports news site at https://sportdune.vercel.app
2. **Admin Dashboard** — CMS at a separate Vercel project

## Prerequisites

- Supabase project: `wivrhymyyipwwppmvmif`
- Vercel account
- Git

## Database Setup

Run these migrations **in order** via Supabase Dashboard > SQL Editor:

1. `014_remove_old_admin_dashboard.sql` — cleans up old tables/policies
2. `015_new_admin_schema.sql` — creates clean schema with RLS policies and seed data

## Storage Bucket

Create a public bucket named `media` in Supabase Dashboard > Storage:
- Name: `media`
- Public: Yes
- File size limit: 10MB
- Allowed MIME types: `image/*`

## Admin User

1. Go to Supabase Dashboard > Authentication > Users
2. Create a user with email/password
3. Run in SQL Editor:
```sql
UPDATE public.profiles SET role = 'super_admin' WHERE email = 'YOUR_EMAIL';
```

## Deploy Frontend (Vercel)

Root directory: `./frontend`
Build command: (empty)
Output directory: (leave default)

## Deploy Admin (Vercel)

1. New Vercel project
2. Import SportDune repo
3. Root directory: `./admin`
4. Build command: (empty)
5. Output directory: `.`

## URLs

| Component | URL |
|-----------|-----|
| Frontend | https://sportdune.vercel.app |
| Admin | Deploy to separate Vercel project |
| Supabase | https://wivrhymyyipwwppmvmif.supabase.co |
