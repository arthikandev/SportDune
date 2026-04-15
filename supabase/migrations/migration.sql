-- SportDune Database Schema

-- Enums
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'editor', 'author', 'public');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE article_status AS ENUM ('draft', 'pending_review', 'published', 'archived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE article_type AS ENUM ('news', 'analysis', 'interview', 'feature', 'opinion');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    role user_role DEFAULT 'public',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Categories
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    color TEXT,
    parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Articles
CREATE TABLE IF NOT EXISTS public.articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    excerpt TEXT,
    content TEXT NOT NULL,
    featured_image_url TEXT,
    featured_image_alt TEXT,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    type article_type DEFAULT 'news',
    status article_status DEFAULT 'draft',
    author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    meta_title TEXT,
    meta_description TEXT,
    canonical_url TEXT,
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    is_trending BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    published_at TIMESTAMPTZ,
    scheduled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Tags
CREATE TABLE IF NOT EXISTS public.tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Article Tags
CREATE TABLE IF NOT EXISTS public.article_tags (
    article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES public.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (article_id, tag_id)
);

-- Live Matches
CREATE TABLE IF NOT EXISTS public.live_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id TEXT,
    home_team TEXT NOT NULL,
    home_team_short TEXT,
    away_team TEXT NOT NULL,
    away_team_short TEXT,
    home_score INTEGER DEFAULT 0,
    away_score INTEGER DEFAULT 0,
    sport TEXT NOT NULL,
    league_name TEXT,
    league_short TEXT,
    status TEXT DEFAULT 'scheduled',
    match_time TEXT,
    match_date DATE,
    minute_played INTEGER,
    venue TEXT,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Page Views
CREATE TABLE IF NOT EXISTS public.page_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_url TEXT NOT NULL,
    page_type TEXT,
    article_id UUID REFERENCES public.articles(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    visitor_id TEXT,
    session_id TEXT,
    referrer TEXT,
    user_agent TEXT,
    device_type TEXT,
    browser TEXT,
    country TEXT,
    viewed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analytics Daily
CREATE TABLE IF NOT EXISTS public.analytics_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    total_page_views INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    article_views INTEGER DEFAULT 0,
    new_articles INTEGER DEFAULT 0,
    avg_time_on_site INTEGER,
    bounce_rate DECIMAL(5,2),
    top_article_ids UUID[],
    mobile_views INTEGER DEFAULT 0,
    desktop_views INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Site Settings
CREATE TABLE IF NOT EXISTS public.site_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL,
    entity_type TEXT,
    entity_id UUID,
    user_id UUID REFERENCES public.profiles(id),
    user_email TEXT,
    user_role user_role,
    old_values JSONB,
    new_values JSONB,
    changes_summary TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    action_url TEXT,
    action_label TEXT,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Triggers
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_articles_updated_at ON public.articles;
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_live_matches_updated_at ON public.live_matches;
CREATE TRIGGER update_live_matches_updated_at BEFORE UPDATE ON public.live_matches FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_site_settings_updated_at ON public.site_settings;
CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN 
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)), 'public')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW; 
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.page_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies (simplified - allow all for now)
DROP POLICY IF EXISTS "Allow all on profiles" ON public.profiles;
CREATE POLICY "Allow all on profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on categories" ON public.categories;
CREATE POLICY "Allow all on categories" ON public.categories FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on articles" ON public.articles;
CREATE POLICY "Allow all on articles" ON public.articles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on tags" ON public.tags;
CREATE POLICY "Allow all on tags" ON public.tags FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on article_tags" ON public.article_tags;
CREATE POLICY "Allow all on article_tags" ON public.article_tags FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on live_matches" ON public.live_matches;
CREATE POLICY "Allow all on live_matches" ON public.live_matches FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on page_views" ON public.page_views;
CREATE POLICY "Allow all on page_views" ON public.page_views FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on analytics_daily" ON public.analytics_daily;
CREATE POLICY "Allow all on analytics_daily" ON public.analytics_daily FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on site_settings" ON public.site_settings;
CREATE POLICY "Allow all on site_settings" ON public.site_settings FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on audit_logs" ON public.audit_logs;
CREATE POLICY "Allow all on audit_logs" ON public.audit_logs FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on notifications" ON public.notifications;
CREATE POLICY "Allow all on notifications" ON public.notifications FOR ALL USING (true) WITH CHECK (true);

-- Seed Data (only insert if not exists)
INSERT INTO public.categories (name, slug, description, icon, color, sort_order) 
SELECT * FROM (VALUES
    ('Football', 'football', 'Latest football news from Premier League, Champions League, La Liga and more', '⚽', '#1a3d00', 1),
    ('Cricket', 'cricket', 'Cricket news, match reports, IPL updates and Test series analysis', '🏏', '#001f4d', 2),
    ('Basketball', 'basketball', 'NBA news, game recaps, analysis and live scores', '🏀', '#1a2a0a', 3),
    ('Formula 1', 'f1', 'F1 news, race results, driver standings and live timing', '🏎️', '#1a0a00', 4),
    ('Tennis', 'tennis', 'Tennis news, ATP & WTA reports, Grand Slam coverage', '🎾', '#001a2a', 5),
    ('Hockey', 'hockey', 'NHL results, international hockey coverage and live scores', '🏒', '#001430', 6),
    ('Rugby', 'rugby', 'Rugby news, World Cup coverage and international matches', '🏉', '#0a2010', 7),
    ('Esports', 'esports', 'Esports news covering Valorant, CS2, Dota 2 and tournaments', '🎮', '#0d001a', 8),
    ('Combat Sports', 'combat', 'UFC, boxing, MMA, wrestling and martial arts coverage', '🥊', '#1a0000', 9),
    ('NFL', 'nfl', 'NFL news, game recaps, team analysis and draft coverage', '🏈', '#001030', 10),
    ('Olympics', 'olympics', 'Olympics coverage: events, athletes, medals and results', '🏅', '#0a0a2a', 11)
) AS v(name, slug, description, icon, color, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE slug = v.slug);

INSERT INTO public.tags (name, slug) 
SELECT * FROM (VALUES
    ('Transfer News', 'transfer-news'),
    ('Match Highlights', 'match-highlights'),
    ('Player Profiles', 'player-profiles'),
    ('Analysis', 'analysis'),
    ('Interviews', 'interviews'),
    ('Breaking News', 'breaking-news')
) AS v(name, slug)
WHERE NOT EXISTS (SELECT 1 FROM public.tags WHERE slug = v.slug);

INSERT INTO public.site_settings (key, value, description, is_public) 
SELECT * FROM (VALUES
    ('site_name', '"SportDune"'::jsonb, 'Website name', true),
    ('site_tagline', '"Live. Bold. Now."'::jsonb, 'Website tagline', true),
    ('contact_email', '"contact@sportdune.com"'::jsonb, 'Contact email', true)
) AS v(key, value, description, is_public)
WHERE NOT EXISTS (SELECT 1 FROM public.site_settings WHERE key = v.key);

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
