# SportDune - Complete Setup & Deployment Guide

## Project Overview

SportDune is a sports news platform built with:
- **Frontend**: HTML5, CSS3, JavaScript (static, deployed on Vercel)
- **Backend**: TypeScript (Supabase Edge Functions)
- **Database**: PostgreSQL 15 (Supabase)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (for images)

## Quick Start (Recommended)

### Step 1: Run Setup Wizard
1. Open `setup.html` in your browser
2. Follow the step-by-step instructions
3. Copy the SQL into Supabase SQL Editor
4. Create your admin user

### Step 2: Create Admin User
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Authentication → Users → Add User**
4. Enter email and password
5. Run: `UPDATE public.profiles SET role = 'super_admin' WHERE email = 'your-email';`

### Step 3: Configure Auth
1. Go to **Authentication → Settings**
2. Set Site URL to your domain (e.g., `https://sportdune.com/admin`)
3. Add redirect URLs for production

---

## PHASE 1: Supabase Setup

### Step 1.1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Choose a region closest to your users
3. Set a strong database password (save this!)
4. Wait for the project to provision (~2 minutes)

### Step 1.2: Get Your Credentials

From your Supabase project dashboard:

1. **Project Settings → API**
   - Copy `Project URL` → `VITE_SUPABASE_URL`
   - Copy `anon public` key → `VITE_SUPABASE_ANON_KEY`
   - Copy `service_role` key → `SUPABASE_SERVICE_ROLE_KEY` (keep this secret!)

### Step 1.3: Run Database Migrations

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link to your project:
   ```bash
   cd supabase
   supabase link --project-ref your-project-ref
   ```

4. Push migrations:
   ```bash
   supabase db push
   ```

   Or run the SQL manually in Supabase Dashboard → SQL Editor:

   1. Copy contents of `supabase/migrations/001_initial_schema.sql`
   2. Paste and execute
   3. Copy contents of `supabase/migrations/002_rls_policies.sql`
   4. Paste and execute

### Step 1.4: Configure Authentication

1. Go to **Authentication → Settings**
2. Configure:
   - Site URL: `http://localhost:5173` (for dev) or `https://yourdomain.com`
   - Redirect URLs: Add your admin URL
   - Enable Email confirmations (recommended)
   - Customize email templates

### Step 1.5: Create Admin User

1. Go to **Authentication → Users**
2. Click **Add User**
3. Enter email and password
4. After creation, go to the `profiles` table
5. Update the user's role to `super_admin`

```sql
UPDATE profiles 
SET role = 'super_admin' 
WHERE email = 'your-admin@email.com';
```

### Step 1.6: Set Up Storage

1. Go to **Storage → New Bucket**
2. Create bucket: `article-images`
3. Set to Public
4. Create bucket: `avatars`
5. Set to Public

---

## PHASE 2: Vercel Setup

### Step 2.1: Install Vercel CLI

```bash
npm install -g vercel
```

### Step 2.2: Deploy Frontend

```bash
# Login to Vercel
vercel login

# Deploy
cd frontend
vercel --prod
```

### Step 2.3: Configure Environment Variables

In Vercel Dashboard → Project → Settings → Environment Variables:

```
VITE_SUPABASE_URL = https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY = eyJxxx...
```

### Step 2.4: Custom Domain (Optional)

1. Go to Project Settings → Domains
2. Add your domain (e.g., sportdune.com)
3. Update DNS records as instructed
4. Wait for SSL certificate

---

## PHASE 3: Frontend Integration

### Step 3.1: Connect Supabase Client

Add to your HTML files (before closing `</body>`):

```html
<script type="module">
  import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
  
  const supabase = createClient(
    'YOUR_SUPABASE_URL',
    'YOUR_SUPABASE_ANON_KEY'
  );
  
  // Now you can use supabase...
</script>
```

### Step 3.2: Fetch Articles

```javascript
// Fetch published articles
async function loadArticles() {
  const { data, error } = await supabase
    .from('articles')
    .select(`
      *,
      category:categories(name, slug),
      author:profiles(full_name)
    `)
    .eq('status', 'published')
    .order('published_at', { ascending: false })
    .limit(20);
  
  if (error) {
    console.error('Error loading articles:', error);
    return;
  }
  
  // Render articles
  renderArticles(data);
}
```

### Step 3.3: Protect Admin Routes

```javascript
// In admin pages, check authentication
async function checkAuth() {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    window.location.href = '/admin/login.html';
    return;
  }
  
  // Verify admin role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', session.user.id)
    .single();
  
  if (!profile || !['admin', 'super_admin'].includes(profile.role)) {
    window.location.href = '/';
    return;
  }
  
  // User is authenticated admin
  showDashboard();
}
```

---

## PHASE 4: Edge Functions (Optional)

For complex backend logic, create Supabase Edge Functions:

### Step 4.1: Create Function

```bash
cd supabase/functions
mkdir v1-articles
cd v1-articles
```

Create `index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data, error } = await supabaseClient
      .from('articles')
      .select('*')
      .eq('status', 'published')
      .order('published_at', { ascending: false })
      .limit(20)

    if (error) throw error

    return new Response(JSON.stringify({ data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
```

### Step 4.2: Deploy Function

```bash
supabase functions deploy v1-articles
```

---

## PHASE 5: Final Checklist

### Security
- [ ] RLS enabled on all tables
- [ ] RLS policies configured correctly
- [ ] Service role key kept secret
- [ ] CORS configured for Edge Functions
- [ ] Email confirmation required for signups

### Database
- [ ] All migrations applied
- [ ] Indexes created for performance
- [ ] Seed data inserted
- [ ] Backups configured (Supabase Pro plan)

### Authentication
- [ ] Admin user created with correct role
- [ ] Password reset enabled
- [ ] Session timeout configured
- [ ] Protected routes working

### Frontend
- [ ] Supabase client configured
- [ ] Environment variables set in Vercel
- [ ] Admin dashboard accessible
- [ ] Articles loading correctly

### Deployment
- [ ] Frontend deployed to Vercel
- [ ] Custom domain configured (optional)
- [ ] SSL certificate active
- [ ] Production URL working

---

## Troubleshooting

### "Unauthorized" Errors
- Check RLS policies allow your operation
- Verify you're authenticated
- Check user role permissions

### CORS Errors
- Configure CORS headers in Edge Functions
- Add redirect URL in Supabase Authentication settings

### Database Connection Issues
- Verify SUPABASE_URL is correct
- Check if IP whitelist includes your IP
- Ensure RLS isn't blocking all operations

### Auth Session Issues
- Clear browser localStorage
- Check cookies aren't blocked
- Verify redirect URLs are correct

---

## Support

For issues specific to:
- **Supabase**: Check [docs.supabase.com](https://docs.supabase.com)
- **Vercel**: Check [vercel.com/docs](https://vercel.com/docs)
- **This Project**: Create an issue on GitHub

---

## Next Steps (Future Enhancements)

1. **Real-time Updates**: Use Supabase Realtime for live scores
2. **Search**: Implement full-text search with Supabase pg_search
3. **Email Notifications**: Integrate Resend or SendGrid
4. **Analytics**: Add custom analytics dashboard
5. **CDN**: Set up CloudFront for media assets
6. **Rate Limiting**: Add rate limiting to Edge Functions
7. **A/B Testing**: Split test different article layouts
