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

CREATE TABLE IF NOT EXISTS public.article_tags (
  article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES public.tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (article_id, tag_id)
);

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

CREATE TABLE IF NOT EXISTS public.featured_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
  section TEXT NOT NULL,
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

CREATE INDEX IF NOT EXISTS idx_sports_slug ON public.sports(slug);
CREATE INDEX IF NOT EXISTS idx_sports_nav_order ON public.sports(nav_order);
CREATE INDEX IF NOT EXISTS idx_sports_show_in_nav ON public.sports(show_in_nav) WHERE show_in_nav = true;
CREATE INDEX IF NOT EXISTS idx_leagues_sport_id ON public.leagues(sport_id);
CREATE INDEX IF NOT EXISTS idx_leagues_slug ON public.leagues(slug);
CREATE INDEX IF NOT EXISTS idx_authors_profile_id ON public.authors(profile_id);
CREATE INDEX IF NOT EXISTS idx_article_tags_tag ON public.article_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_article_images_article ON public.article_images(article_id);
CREATE INDEX IF NOT EXISTS idx_teams_sport ON public.teams(sport_id);
CREATE INDEX IF NOT EXISTS idx_featured_section ON public.featured_content(section);
CREATE INDEX IF NOT EXISTS idx_featured_article ON public.featured_content(article_id);
CREATE INDEX IF NOT EXISTS idx_trending_article ON public.trending_items(article_id);
CREATE INDEX IF NOT EXISTS idx_navigation_parent ON public.navigation(parent_id);
CREATE INDEX IF NOT EXISTS idx_navigation_placement ON public.navigation(placement);
CREATE INDEX IF NOT EXISTS idx_media_sport ON public.media(sport_id);
CREATE INDEX IF NOT EXISTS idx_media_folder ON public.media(folder);

ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS type article_type DEFAULT 'news';
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS slug TEXT UNIQUE;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS league_id UUID REFERENCES public.leagues(id) ON DELETE SET NULL;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES public.authors(id) ON DELETE SET NULL;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS status article_status DEFAULT 'draft';
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS is_trending BOOLEAN DEFAULT false;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS is_breaking BOOLEAN DEFAULT false;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS read_time_minutes INTEGER DEFAULT 3;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS meta_title TEXT;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS meta_description TEXT;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS canonical_url TEXT;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS no_index BOOLEAN DEFAULT false;
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.articles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS external_id TEXT;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS team_a_short TEXT;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS team_a_logo TEXT;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS team_b_short TEXT;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS team_b_logo TEXT;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS minute_played INTEGER;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS added_time INTEGER;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS events JSONB DEFAULT '[]';
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE public.live_matches ADD COLUMN IF NOT EXISTS match_summary TEXT;

ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS group_name TEXT DEFAULT 'general';
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false;

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_sports_updated_at ON public.sports;
CREATE TRIGGER update_sports_updated_at BEFORE UPDATE ON public.sports FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_leagues_updated_at ON public.leagues;
CREATE TRIGGER update_leagues_updated_at BEFORE UPDATE ON public.leagues FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_articles_updated_at ON public.articles;
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_live_matches_updated_at ON public.live_matches;
CREATE TRIGGER update_live_matches_updated_at BEFORE UPDATE ON public.live_matches FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_navigation_updated_at ON public.navigation;
CREATE TRIGGER update_navigation_updated_at BEFORE UPDATE ON public.navigation FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;
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

DROP POLICY IF EXISTS "Public can read sports" ON public.sports;
CREATE POLICY "Public can read sports" ON public.sports FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read leagues" ON public.leagues;
CREATE POLICY "Public can read leagues" ON public.leagues FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read authors" ON public.authors;
CREATE POLICY "Public can read authors" ON public.authors FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read published articles" ON public.articles;
CREATE POLICY "Public can read published articles" ON public.articles FOR SELECT USING (status = 'published');

DROP POLICY IF EXISTS "Public can read live matches" ON public.live_matches;
CREATE POLICY "Public can read live matches" ON public.live_matches FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can read navigation" ON public.navigation;
CREATE POLICY "Public can read navigation" ON public.navigation FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated can insert articles" ON public.articles;
CREATE POLICY "Authenticated can insert articles" ON public.articles FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can update articles" ON public.articles;
CREATE POLICY "Authenticated can update articles" ON public.articles FOR UPDATE USING (auth.uid() IS NOT NULL);

INSERT INTO public.sports (name, slug, icon, description, color, banner_title, banner_subtitle, nav_order, nav_placement, is_active) VALUES
('Football', 'football', '⚽', 'Latest football news from Premier League, Champions League, La Liga and more', '#1a3d00', 'Football Coverage', 'Premier League, Champions League, La Liga & More', 1, 'top', true)
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

INSERT INTO public.navigation (label, url, icon, placement, sort_order, is_active, is_featured) VALUES
('Home', '/', NULL, 'header', 1, true, false),
('Live Scores', '/live-scores', NULL, 'header', 2, true, true),
('Football', '/football', '⚽', 'header', 3, true, false),
('Cricket', '/cricket', '🏏', 'header', 4, true, false)
ON CONFLICT DO NOTHING;

SELECT 'Migration completed' as status;
