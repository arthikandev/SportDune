-- ================================================
-- SPORTDUNE - COMBINED SAFE MIGRATION
-- Run this single file to set up the complete database
-- ================================================

-- ================================================
-- STEP 1: ENUM TYPES (Skip if exists)
-- ================================================

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_role') THEN
    CREATE TYPE admin_role AS ENUM ('super_admin', 'admin', 'editor', 'author', 'live_manager', 'viewer');
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'article_status') THEN
    CREATE TYPE article_status AS ENUM ('draft', 'pending_review', 'published', 'archived');
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'article_type') THEN
    CREATE TYPE article_type AS ENUM ('news', 'analysis', 'interview', 'feature', 'opinion', 'preview', 'report');
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status') THEN
    CREATE TYPE match_status AS ENUM ('scheduled', 'live', 'halftime', 'finished', 'postponed', 'cancelled', 'extra_time', 'penalties');
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'placement_section') THEN
    CREATE TYPE placement_section AS ENUM ('hero', 'featured', 'trending', 'latest', 'sport_sections', 'sidebar');
  END IF;
END $$;

-- ================================================
-- STEP 2: TABLES (Skip if exists)
-- ================================================

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  role admin_role DEFAULT 'viewer',
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  login_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sports
CREATE TABLE IF NOT EXISTS public.sports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  icon TEXT,
  description TEXT,
  color TEXT,
  banner_title TEXT,
  banner_subtitle TEXT,
  banner_image_url TEXT,
  nav_order INTEGER DEFAULT 0,
  nav_placement TEXT DEFAULT 'dropdown',
  is_active BOOLEAN DEFAULT true,
  show_in_nav BOOLEAN DEFAULT true,
  meta_title TEXT,
  meta_description TEXT,
  canonical_url TEXT,
  og_image_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  allow_comments BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id)
);

-- Leagues
CREATE TABLE IF NOT EXISTS public.leagues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id UUID REFERENCES public.sports(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  short_name TEXT,
  icon TEXT,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  show_in_filters BOOLEAN DEFAULT true,
  banner_subtitle TEXT,
  banner_image_url TEXT,
  meta_title TEXT,
  meta_description TEXT,
  canonical_url TEXT,
  og_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id)
);

-- Tags
CREATE TABLE IF NOT EXISTS public.tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Authors
CREATE TABLE IF NOT EXISTS public.authors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  display_name TEXT NOT NULL,
  short_bio TEXT,
  specialty TEXT,
  twitter_handle TEXT,
  linkedin_url TEXT,
  website_url TEXT,
  article_count INTEGER DEFAULT 0,
  total_views BIGINT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
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
  type article_type DEFAULT 'news',
  featured_image_url TEXT,
  featured_image_alt TEXT,
  og_image_url TEXT,
  sport_id UUID REFERENCES public.sports(id) ON DELETE SET NULL,
  league_id UUID REFERENCES public.leagues(id) ON DELETE SET NULL,
  author_id UUID REFERENCES public.authors(id) ON DELETE SET NULL,
  status article_status DEFAULT 'draft',
  is_featured BOOLEAN DEFAULT false,
  is_trending BOOLEAN DEFAULT false,
  is_pinned BOOLEAN DEFAULT false,
  is_breaking BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  scheduled_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  read_time_minutes INTEGER DEFAULT 3,
  meta_title TEXT,
  meta_description TEXT,
  canonical_url TEXT,
  no_index BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  deleted_at TIMESTAMPTZ
);

-- Article Tags
CREATE TABLE IF NOT EXISTS public.article_tags (
  article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES public.tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (article_id, tag_id)
);

-- Article Images
CREATE TABLE IF NOT EXISTS public.article_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  alt TEXT,
  caption TEXT,
  sort_order INTEGER DEFAULT 0,
  is_cover BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teams
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id UUID NOT NULL REFERENCES public.sports(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  short_name TEXT,
  logo_url TEXT,
  abbreviation TEXT,
  country TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Live Matches
CREATE TABLE IF NOT EXISTS public.live_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id TEXT,
  sport_id UUID NOT NULL REFERENCES public.sports(id) ON DELETE CASCADE,
  league_id UUID REFERENCES public.leagues(id) ON DELETE SET NULL,
  team_a_id UUID REFERENCES public.teams(id),
  team_a_name TEXT NOT NULL,
  team_a_short TEXT,
  team_a_logo TEXT,
  team_a_score INTEGER DEFAULT 0,
  team_b_id UUID REFERENCES public.teams(id),
  team_b_name TEXT NOT NULL,
  team_b_short TEXT,
  team_b_logo TEXT,
  team_b_score INTEGER DEFAULT 0,
  status match_status DEFAULT 'scheduled',
  match_date DATE NOT NULL,
  match_time TIME,
  venue TEXT,
  location TEXT,
  round TEXT,
  minute_played INTEGER,
  added_time INTEGER,
  events JSONB DEFAULT '[]',
  is_featured BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  match_summary TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id)
);

-- Featured Content
CREATE TABLE IF NOT EXISTS public.featured_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
  section placement_section NOT NULL,
  position INTEGER DEFAULT 0,
  sport_id UUID REFERENCES public.sports(id) ON DELETE CASCADE,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  show_image BOOLEAN DEFAULT true,
  show_excerpt BOOLEAN DEFAULT true,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  custom_title TEXT,
  custom_subtitle TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id)
);

-- Trending Items
CREATE TABLE IF NOT EXISTS public.trending_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
  position INTEGER DEFAULT 0,
  sport_id UUID REFERENCES public.sports(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  view_threshold INTEGER DEFAULT 1000,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id)
);

-- Navigation
CREATE TABLE IF NOT EXISTS public.navigation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,
  url TEXT NOT NULL,
  icon TEXT,
  parent_id UUID REFERENCES public.navigation(id) ON DELETE CASCADE,
  is_dropdown BOOLEAN DEFAULT false,
  placement TEXT DEFAULT 'header',
  sort_order INTEGER DEFAULT 0,
  target TEXT DEFAULT '_self',
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  badge_text TEXT,
  badge_color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Media
CREATE TABLE IF NOT EXISTS public.media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filename TEXT NOT NULL,
  url TEXT NOT NULL,
  storage_path TEXT,
  type TEXT NOT NULL,
  size INTEGER NOT NULL,
  alt_text TEXT,
  caption TEXT,
  width INTEGER,
  height INTEGER,
  sport_id UUID REFERENCES public.sports(id) ON DELETE SET NULL,
  folder TEXT DEFAULT 'general',
  used_in_articles INTEGER DEFAULT 0,
  used_in_matches INTEGER DEFAULT 0,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Site Settings
CREATE TABLE IF NOT EXISTS public.site_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL,
  description TEXT,
  group_name TEXT DEFAULT 'general',
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
  user_role admin_role,
  old_values JSONB,
  new_values JSONB,
  changes_summary TEXT,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- STEP 3: INDEXES (Skip if exists)
-- ================================================

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_sports_slug ON public.sports(slug);
CREATE INDEX IF NOT EXISTS idx_sports_nav_order ON public.sports(nav_order);
CREATE INDEX IF NOT EXISTS idx_sports_show_in_nav ON public.sports(show_in_nav) WHERE show_in_nav = true;
CREATE INDEX IF NOT EXISTS idx_leagues_sport_id ON public.leagues(sport_id);
CREATE INDEX IF NOT EXISTS idx_leagues_slug ON public.leagues(slug);
CREATE INDEX IF NOT EXISTS idx_leagues_display_order ON public.leagues(sport_id, display_order);
CREATE INDEX IF NOT EXISTS idx_tags_slug ON public.tags(slug);
CREATE INDEX IF NOT EXISTS idx_tags_is_active ON public.tags(is_active);
CREATE INDEX IF NOT EXISTS idx_authors_profile_id ON public.authors(profile_id);
CREATE INDEX IF NOT EXISTS idx_articles_slug ON public.articles(slug);
CREATE INDEX IF NOT EXISTS idx_articles_sport ON public.articles(sport_id);
CREATE INDEX IF NOT EXISTS idx_articles_league ON public.articles(league_id);
CREATE INDEX IF NOT EXISTS idx_articles_author ON public.articles(author_id);
CREATE INDEX IF NOT EXISTS idx_articles_status ON public.articles(status);
CREATE INDEX IF NOT EXISTS idx_articles_published ON public.articles(published_at DESC) WHERE status = 'published';
CREATE INDEX IF NOT EXISTS idx_articles_featured ON public.articles(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_articles_trending ON public.articles(is_trending) WHERE is_trending = true;
CREATE INDEX IF NOT EXISTS idx_article_tags_tag ON public.article_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_article_images_article ON public.article_images(article_id);
CREATE INDEX IF NOT EXISTS idx_teams_sport ON public.teams(sport_id);
CREATE INDEX IF NOT EXISTS idx_matches_sport ON public.live_matches(sport_id);
CREATE INDEX IF NOT EXISTS idx_matches_league ON public.live_matches(league_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.live_matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_date ON public.live_matches(match_date DESC);
CREATE INDEX IF NOT EXISTS idx_matches_featured ON public.live_matches(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_featured_section ON public.featured_content(section);
CREATE INDEX IF NOT EXISTS idx_featured_article ON public.featured_content(article_id);
CREATE INDEX IF NOT EXISTS idx_featured_active ON public.featured_content(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_trending_article ON public.trending_items(article_id);
CREATE INDEX IF NOT EXISTS idx_trending_position ON public.trending_items(position);
CREATE INDEX IF NOT EXISTS idx_trending_active ON public.trending_items(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_navigation_parent ON public.navigation(parent_id);
CREATE INDEX IF NOT EXISTS idx_navigation_placement ON public.navigation(placement);
CREATE INDEX IF NOT EXISTS idx_navigation_active ON public.navigation(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_media_sport ON public.media(sport_id);
CREATE INDEX IF NOT EXISTS idx_media_folder ON public.media(folder);
CREATE INDEX IF NOT EXISTS idx_media_created ON public.media(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_settings_key ON public.site_settings(key);
CREATE INDEX IF NOT EXISTS idx_settings_group ON public.site_settings(group_name);
CREATE INDEX IF NOT EXISTS idx_audit_user ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON public.audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_date ON public.audit_logs(created_at DESC);

-- ================================================
-- STEP 4: TRIGGERS & FUNCTIONS
-- ================================================

-- Update updated_at function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_sports_updated_at ON public.sports;
CREATE TRIGGER update_sports_updated_at BEFORE UPDATE ON public.sports FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_leagues_updated_at ON public.leagues;
CREATE TRIGGER update_leagues_updated_at BEFORE UPDATE ON public.leagues FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_articles_updated_at ON public.articles;
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_live_matches_updated_at ON public.live_matches;
CREATE TRIGGER update_live_matches_updated_at BEFORE UPDATE ON public.live_matches FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_site_settings_updated_at ON public.site_settings;
CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_navigation_updated_at ON public.navigation;
CREATE TRIGGER update_navigation_updated_at BEFORE UPDATE ON public.navigation FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    'viewer'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Log login activity
CREATE OR REPLACE FUNCTION log_login_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles SET last_login_at = NOW(), login_count = login_count + 1 WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_login ON auth.users;
CREATE TRIGGER on_login AFTER UPDATE ON auth.users FOR EACH ROW WHEN (NEW.last_sign_in_at IS DISTINCT FROM OLD.last_sign_in_at) EXECUTE FUNCTION log_login_activity();

-- ================================================
-- STEP 5: RLS POLICIES (Safe - only if RLS not already enabled)
-- ================================================

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.featured_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trending_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.navigation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Public read policies (allow anonymous reads)
DROP POLICY IF EXISTS "Public can read profiles" ON public.profiles;
CREATE POLICY "Public can read profiles" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read sports" ON public.sports;
CREATE POLICY "Public can read sports" ON public.sports FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read leagues" ON public.leagues;
CREATE POLICY "Public can read leagues" ON public.leagues FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read tags" ON public.tags;
CREATE POLICY "Public can read tags" ON public.tags FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read authors" ON public.authors;
CREATE POLICY "Public can read authors" ON public.authors FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read published articles" ON public.articles;
CREATE POLICY "Public can read published articles" ON public.articles FOR SELECT USING (status = 'published');

DROP POLICY IF EXISTS "Public can read article tags" ON public.article_tags;
CREATE POLICY "Public can read article tags" ON public.article_tags FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read article images" ON public.article_images;
CREATE POLICY "Public can read article images" ON public.article_images FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read teams" ON public.teams;
CREATE POLICY "Public can read teams" ON public.teams FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read live matches" ON public.live_matches;
CREATE POLICY "Public can read live matches" ON public.live_matches FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read featured content" ON public.featured_content;
CREATE POLICY "Public can read featured content" ON public.featured_content FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read trending items" ON public.trending_items;
CREATE POLICY "Public can read trending items" ON public.trending_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read navigation" ON public.navigation;
CREATE POLICY "Public can read navigation" ON public.navigation FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read media" ON public.media;
CREATE POLICY "Public can read media" ON public.media FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read public settings" ON public.site_settings;
CREATE POLICY "Public can read public settings" ON public.site_settings FOR SELECT USING (is_public = true);

DROP POLICY IF EXISTS "Public can read audit logs" ON public.audit_logs;
CREATE POLICY "Public can read audit logs" ON public.audit_logs FOR SELECT USING (true);

-- Insert policies for authenticated users
DROP POLICY IF EXISTS "Authenticated can insert profiles" ON public.profiles;
CREATE POLICY "Authenticated can insert profiles" ON public.profiles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated can update own profile" ON public.profiles;
CREATE POLICY "Authenticated can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Authenticated can insert articles" ON public.articles;
CREATE POLICY "Authenticated can insert articles" ON public.articles FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can update articles" ON public.articles;
CREATE POLICY "Authenticated can update articles" ON public.articles FOR UPDATE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can insert live matches" ON public.live_matches;
CREATE POLICY "Authenticated can insert live matches" ON public.live_matches FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can update live matches" ON public.live_matches;
CREATE POLICY "Authenticated can update live matches" ON public.live_matches FOR UPDATE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can insert media" ON public.media;
CREATE POLICY "Authenticated can insert media" ON public.media FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can insert audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated can insert audit logs" ON public.audit_logs FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated can update navigation" ON public.navigation;
CREATE POLICY "Authenticated can update navigation" ON public.navigation FOR UPDATE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can insert navigation" ON public.navigation;
CREATE POLICY "Authenticated can insert navigation" ON public.navigation FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can update site settings" ON public.site_settings;
CREATE POLICY "Authenticated can update site settings" ON public.site_settings FOR UPDATE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can insert site settings" ON public.site_settings;
CREATE POLICY "Authenticated can insert site settings" ON public.site_settings FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ================================================
-- STEP 6: SEED DATA
-- ================================================

-- Sports
INSERT INTO public.sports (name, slug, icon, description, color, banner_title, banner_subtitle, nav_order, nav_placement, is_active, meta_title, meta_description) VALUES
('Football', 'football', '⚽', 'Latest football news from Premier League, Champions League, La Liga and more', '#1a3d00', 'Football Coverage', 'Premier League, Champions League, La Liga & More', 1, 'top', true, 'Football News | SportDune', 'Get the latest football news, match reports, and analysis.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.sports (name, slug, icon, description, color, banner_title, banner_subtitle, nav_order, nav_placement, is_active) VALUES
('Cricket', 'cricket', '🏏', 'Cricket news, match reports, IPL updates and Test series analysis', '#001f4d', 'Cricket Coverage', 'IPL, World Cup, Test Cricket', 2, 'top', true),
('Basketball', 'basketball', '🏀', 'NBA news, game recaps, analysis and live scores', '#1a2a0a', 'Basketball Coverage', 'NBA, EuroLeague, NCAA', 3, 'dropdown', true),
('Formula 1', 'f1', '🏎️', 'F1 news, race results, driver standings and live timing', '#1a0a00', 'Formula 1 Coverage', 'Grand Prix, Driver Standings', 4, 'dropdown', true),
('Tennis', 'tennis', '🎾', 'Tennis news, ATP & WTA reports, Grand Slam coverage', '#001a2a', 'Tennis Coverage', 'Grand Slams, ATP, WTA', 5, 'dropdown', true),
('Hockey', 'hockey', '🏒', 'NHL results, international hockey coverage and live scores', '#001430', 'Hockey Coverage', 'NHL, IIHF, International Hockey', 6, 'dropdown', true),
('Rugby', 'rugby', '🏉', 'Rugby news, World Cup coverage and international matches', '#0a2010', 'Rugby Coverage', 'World Cup, Six Nations', 7, 'dropdown', true),
('Esports', 'esports', '🎮', 'Esports news covering Valorant, CS2, Dota 2 and tournaments', '#0d001a', 'Esports Coverage', 'Valorant, CS2, Dota 2', 8, 'dropdown', true),
('Combat Sports', 'combat', '🥊', 'UFC, boxing, MMA, wrestling and martial arts coverage', '#1a0000', 'Combat Sports Coverage', 'UFC, Boxing, MMA', 9, 'dropdown', true),
('NFL', 'nfl', '🏈', 'NFL news, game recaps, team analysis and draft coverage', '#001030', 'NFL Coverage', 'Regular Season, Playoffs, Super Bowl', 10, 'dropdown', true),
('Olympics', 'olympics', '🏅', 'Olympics coverage: events, athletes, medals and results', '#0a0a2a', 'Olympics Coverage', 'Summer & Winter Games', 11, 'dropdown', true)
ON CONFLICT (slug) DO NOTHING;

-- Navigation
INSERT INTO public.navigation (label, url, icon, placement, sort_order, is_active, is_featured) VALUES
('Home', '/', NULL, 'header', 1, true, false),
('Live Scores', '/live-scores', NULL, 'header', 2, true, true),
('Football', '/football', '⚽', 'header', 3, true, false),
('Cricket', '/cricket', '🏏', 'header', 4, true, false)
ON CONFLICT DO NOTHING;

-- Site Settings
INSERT INTO public.site_settings (key, value, description, group_name, is_public) VALUES
('site_name', '"SportDune"', 'Website name', 'general', true),
('site_tagline', '"Live. Bold. Now."', 'Website tagline', 'general', true),
('contact_email', '"contact@sportdune.com"', 'Contact email', 'contact', true),
('social_twitter', '"https://twitter.com/sportdune"', 'Twitter URL', 'social', true),
('articles_per_page', '12', 'Articles per page', 'content', false),
('featured_articles_count', '6', 'Featured articles on homepage', 'content', false)
ON CONFLICT (key) DO NOTHING;

-- ================================================
-- STEP 7: VERIFICATION
-- ================================================

SELECT 'Migration Complete!' as status;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
