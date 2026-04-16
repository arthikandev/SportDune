-- ================================================
-- SPORTDUNE - COMPLETE ADMIN SCHEMA
-- PostgreSQL 15 on Supabase
-- Version: 2.0 - Full Admin CMS
-- ================================================

-- ================================================
-- ENUMS
-- ================================================

CREATE TYPE admin_role AS ENUM (
  'super_admin',   -- Full system access
  'admin',         -- Manage content and users
  'editor',        -- Edit and publish content
  'author',        -- Create and manage own content
  'live_manager',  -- Manage live scores only
  'viewer'         -- Read-only access
);

CREATE TYPE article_status AS ENUM (
  'draft',          -- Work in progress
  'pending_review', -- Awaiting approval
  'published',      -- Live on site
  'archived'        -- Hidden from public
);

CREATE TYPE article_type AS ENUM (
  'news',     -- Breaking news
  'analysis', -- Deep dive
  'interview',-- Q&A
  'feature',  -- Long-form
  'opinion',  -- Commentary
  'preview',  -- Match preview
  'report'    -- Match report
);

CREATE TYPE match_status AS ENUM (
  'scheduled',  -- Upcoming
  'live',       -- In progress
  'halftime',   -- Half-time break
  'finished',   -- Completed
  'postponed',  -- Delayed
  'cancelled',  -- Cancelled
  'extra_time', -- Overtime
  'penalties'   -- Penalty shootout
);

CREATE TYPE log_level AS ENUM (
  'info',     -- General info
  'warning',  -- Attention needed
  'error',    -- Error occurred
  'critical'  -- System issue
);

CREATE TYPE placement_section AS ENUM (
  'hero',           -- Main hero slider
  'featured',       -- Featured section
  'trending',       -- Trending strip
  'latest',         -- Latest news
  'sport_sections', -- Per-sport sections
  'sidebar'         -- Sidebar widgets
);

-- ================================================
-- PROFILES (extends Supabase Auth)
-- ================================================

CREATE TABLE public.profiles (
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

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_is_active ON public.profiles(is_active);
CREATE INDEX idx_profiles_email ON public.profiles(email);

-- ================================================
-- SPORTS
-- ================================================

CREATE TABLE public.sports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  icon TEXT,                    -- Emoji or icon class (e.g., ⚽, 🏏)
  description TEXT,
  color TEXT,                   -- Theme color (hex)
  
  -- Banner content
  banner_title TEXT,
  banner_subtitle TEXT,
  banner_image_url TEXT,
  
  -- Navigation settings
  nav_order INTEGER DEFAULT 0,
  nav_placement TEXT DEFAULT 'dropdown' CHECK (nav_placement IN ('top', 'dropdown')),
  is_active BOOLEAN DEFAULT true,
  show_in_nav BOOLEAN DEFAULT true,
  
  -- SEO
  meta_title TEXT,
  meta_description TEXT,
  canonical_url TEXT,
  og_image_url TEXT,
  
  -- Settings
  is_featured BOOLEAN DEFAULT false,
  allow_comments BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id),
  
  -- Constraints
  CONSTRAINT unique_sport_slug UNIQUE (slug)
);

CREATE INDEX idx_sports_slug ON public.sports(slug);
CREATE INDEX idx_sports_nav_order ON public.sports(nav_order);
CREATE INDEX idx_sports_is_active ON public.sports(is_active);
CREATE INDEX idx_sports_show_in_nav ON public.sports(show_in_nav) WHERE show_in_nav = true;

-- ================================================
-- LEAGUES / COMPETITIONS
-- ================================================

CREATE TABLE public.leagues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id UUID NOT NULL REFERENCES public.sports(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  short_name TEXT,              -- e.g., "PL" for Premier League
  icon TEXT,                    -- Emoji or icon
  description TEXT,
  
  -- Display
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  show_in_filters BOOLEAN DEFAULT true,
  
  -- Banner
  banner_subtitle TEXT,
  banner_image_url TEXT,
  
  -- SEO
  meta_title TEXT,
  meta_description TEXT,
  canonical_url TEXT,
  og_image_url TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id),
  
  -- Constraints
  CONSTRAINT unique_league_slug_per_sport UNIQUE (sport_id, slug)
);

CREATE INDEX idx_leagues_sport_id ON public.leagues(sport_id);
CREATE INDEX idx_leagues_slug ON public.leagues(slug);
CREATE INDEX idx_leagues_display_order ON public.leagues(sport_id, display_order);
CREATE INDEX idx_leagues_is_active ON public.leagues(is_active);

-- ================================================
-- TAGS
-- ================================================

CREATE TABLE public.tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT unique_tag_slug UNIQUE (slug)
);

CREATE INDEX idx_tags_slug ON public.tags(slug);
CREATE INDEX idx_tags_is_active ON public.tags(is_active);

-- ================================================
-- AUTHORS (extends profiles with author-specific data)
-- ================================================

CREATE TABLE public.authors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  
  -- Author details
  display_name TEXT NOT NULL,
  short_bio TEXT,
  specialty TEXT,               -- e.g., "Premier League", "Formula 1"
  
  -- Social links
  twitter_handle TEXT,
  linkedin_url TEXT,
  website_url TEXT,
  
  -- Stats
  article_count INTEGER DEFAULT 0,
  total_views BIGINT DEFAULT 0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_authors_profile_id ON public.authors(profile_id);
CREATE INDEX idx_authors_is_active ON public.authors(is_active);

-- ================================================
-- ARTICLES
-- ================================================

CREATE TABLE public.articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Content
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  excerpt TEXT,                 -- Short description for cards
  content TEXT NOT NULL,        -- Full article HTML/markdown
  type article_type DEFAULT 'news',
  
  -- Media
  featured_image_url TEXT,
  featured_image_alt TEXT,
  og_image_url TEXT,
  
  -- Classification
  sport_id UUID REFERENCES public.sports(id) ON DELETE SET NULL,
  league_id UUID REFERENCES public.leagues(id) ON DELETE SET NULL,
  author_id UUID REFERENCES public.authors(id) ON DELETE SET NULL,
  
  -- Workflow
  status article_status DEFAULT 'draft',
  
  -- Engagement flags
  is_featured BOOLEAN DEFAULT false,
  is_trending BOOLEAN DEFAULT false,
  is_pinned BOOLEAN DEFAULT false,
  is_breaking BOOLEAN DEFAULT false,
  
  -- Publishing
  published_at TIMESTAMPTZ,
  scheduled_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,
  
  -- Stats
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  read_time_minutes INTEGER DEFAULT 3,
  
  -- SEO
  meta_title TEXT,
  meta_description TEXT,
  canonical_url TEXT,
  no_index BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  deleted_at TIMESTAMPTZ,       -- Soft delete
  
  CONSTRAINT unique_article_slug UNIQUE (slug)
);

CREATE INDEX idx_articles_slug ON public.articles(slug);
CREATE INDEX idx_articles_sport ON public.articles(sport_id);
CREATE INDEX idx_articles_league ON public.articles(league_id);
CREATE INDEX idx_articles_author ON public.articles(author_id);
CREATE INDEX idx_articles_status ON public.articles(status);
CREATE INDEX idx_articles_published ON public.articles(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_articles_featured ON public.articles(is_featured) WHERE is_featured = true;
CREATE INDEX idx_articles_trending ON public.articles(is_trending) WHERE is_trending = true;
CREATE INDEX idx_articles_created ON public.articles(created_at DESC);
CREATE INDEX idx_articles_deleted ON public.articles(deleted_at) WHERE deleted_at IS NULL;

-- ================================================
-- ARTICLE TAGS (Many-to-Many)
-- ================================================

CREATE TABLE public.article_tags (
  article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES public.tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (article_id, tag_id)
);

CREATE INDEX idx_article_tags_tag ON public.article_tags(tag_id);

-- ================================================
-- ARTICLE GALLERY IMAGES
-- ================================================

CREATE TABLE public.article_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  alt TEXT,
  caption TEXT,
  sort_order INTEGER DEFAULT 0,
  is_cover BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_article_images_article ON public.article_images(article_id);

-- ================================================
-- TEAMS (for live scores)
-- ================================================

CREATE TABLE public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id UUID NOT NULL REFERENCES public.sports(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  short_name TEXT,
  logo_url TEXT,
  abbreviation TEXT,            -- e.g., "MCI" for Manchester City
  country TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_teams_sport ON public.teams(sport_id);
CREATE INDEX idx_teams_is_active ON public.teams(is_active);

-- ================================================
-- LIVE MATCHES
-- ================================================

CREATE TABLE public.live_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id TEXT,             -- ID from external API if integrated
  
  -- Classification
  sport_id UUID NOT NULL REFERENCES public.sports(id) ON DELETE CASCADE,
  league_id UUID REFERENCES public.leagues(id) ON DELETE SET NULL,
  
  -- Teams
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
  
  -- Match info
  status match_status DEFAULT 'scheduled',
  match_date DATE NOT NULL,
  match_time TIME,
  venue TEXT,
  location TEXT,
  round TEXT,                  -- e.g., "Round 15", "Semi-final"
  
  -- Live details
  minute_played INTEGER,
  added_time INTEGER,
  events JSONB DEFAULT '[]',  -- Array of match events (goals, cards, etc.)
  
  -- Display
  is_featured BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  
  -- Summary
  match_summary TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id),
  
  CONSTRAINT check_teams_different CHECK (team_a_name != team_b_name)
);

CREATE INDEX idx_matches_sport ON public.live_matches(sport_id);
CREATE INDEX idx_matches_league ON public.live_matches(league_id);
CREATE INDEX idx_matches_status ON public.live_matches(status);
CREATE INDEX idx_matches_date ON public.live_matches(match_date DESC);
CREATE INDEX idx_matches_featured ON public.live_matches(is_featured) WHERE is_featured = true;

-- ================================================
-- FEATURED CONTENT (Homepage Sections)
-- ================================================

CREATE TABLE public.featured_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
  section placement_section NOT NULL,
  position INTEGER DEFAULT 0,
  sport_id UUID REFERENCES public.sports(id) ON DELETE CASCADE,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  
  -- Display settings
  is_active BOOLEAN DEFAULT true,
  show_image BOOLEAN DEFAULT true,
  show_excerpt BOOLEAN DEFAULT true,
  
  -- Time-based
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  
  -- Metadata
  custom_title TEXT,
  custom_subtitle TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id),
  
  CONSTRAINT unique_section_position UNIQUE (section, position)
);

CREATE INDEX idx_featured_section ON public.featured_content(section);
CREATE INDEX idx_featured_article ON public.featured_content(article_id);
CREATE INDEX idx_featured_active ON public.featured_content(is_active) WHERE is_active = true;

-- ================================================
-- TRENDING ITEMS
-- ================================================

CREATE TABLE public.trending_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
  position INTEGER DEFAULT 0,
  sport_id UUID REFERENCES public.sports(id) ON DELETE CASCADE,
  
  is_active BOOLEAN DEFAULT true,
  view_threshold INTEGER DEFAULT 1000,  -- Min views to auto-trend
  expires_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.profiles(id)
);

CREATE INDEX idx_trending_article ON public.trending_items(article_id);
CREATE INDEX idx_trending_position ON public.trending_items(position);
CREATE INDEX idx_trending_active ON public.trending_items(is_active) WHERE is_active = true;

-- ================================================
-- NAVIGATION ITEMS
-- ================================================

CREATE TABLE public.navigation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,
  url TEXT NOT NULL,
  icon TEXT,
  
  -- Hierarchy
  parent_id UUID REFERENCES public.navigation(id) ON DELETE CASCADE,
  is_dropdown BOOLEAN DEFAULT false,
  
  -- Placement
  placement TEXT DEFAULT 'header' CHECK (placement IN ('header', 'footer', 'mobile')),
  
  -- Order
  sort_order INTEGER DEFAULT 0,
  
  -- Behavior
  target TEXT DEFAULT '_self' CHECK (target IN ('_self', '_blank')),
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,  -- For special items like "Live"
  
  -- Metadata
  badge_text TEXT,
  badge_color TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_navigation_parent ON public.navigation(parent_id);
CREATE INDEX idx_navigation_placement ON public.navigation(placement);
CREATE INDEX idx_navigation_active ON public.navigation(is_active) WHERE is_active = true;

-- ================================================
-- MEDIA ASSETS
-- ================================================

CREATE TABLE public.media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- File info
  filename TEXT NOT NULL,
  url TEXT NOT NULL,
  storage_path TEXT,
  type TEXT NOT NULL,           -- MIME type
  size INTEGER NOT NULL,        -- Bytes
  
  -- Metadata
  alt_text TEXT,
  caption TEXT,
  width INTEGER,
  height INTEGER,
  
  -- Organization
  sport_id UUID REFERENCES public.sports(id) ON DELETE SET NULL,
  folder TEXT DEFAULT 'general',
  
  -- Usage tracking
  used_in_articles INTEGER DEFAULT 0,
  used_in_matches INTEGER DEFAULT 0,
  
  -- Upload info
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_sport ON public.media(sport_id);
CREATE INDEX idx_media_folder ON public.media(folder);
CREATE INDEX idx_media_created ON public.media(created_at DESC);
CREATE INDEX idx_media_type ON public.media(type);

-- ================================================
-- SITE SETTINGS
-- ================================================

CREATE TABLE public.site_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL,
  description TEXT,
  group_name TEXT DEFAULT 'general',
  is_public BOOLEAN DEFAULT false,
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT unique_setting_key UNIQUE (key)
);

CREATE INDEX idx_settings_key ON public.site_settings(key);
CREATE INDEX idx_settings_group ON public.site_settings(group_name);

-- ================================================
-- AUDIT LOGS
-- ================================================

CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Action info
  action TEXT NOT NULL,        -- create, update, delete, login, publish, etc.
  entity_type TEXT,            -- articles, profiles, sports, etc.
  entity_id UUID,
  
  -- User info
  user_id UUID REFERENCES public.profiles(id),
  user_email TEXT,
  user_role admin_role,
  
  -- Change details
  old_values JSONB,
  new_values JSONB,
  changes_summary TEXT,
  
  -- Context
  ip_address INET,
  user_agent TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON public.audit_logs(user_id);
CREATE INDEX idx_audit_entity ON public.audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_action ON public.audit_logs(action);
CREATE INDEX idx_audit_date ON public.audit_logs(created_at DESC);

-- ================================================
-- COMMENTS (Optional)
-- ================================================

CREATE TABLE public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
  author_name TEXT NOT NULL,
  author_email TEXT,
  content TEXT NOT NULL,
  
  -- Status
  is_approved BOOLEAN DEFAULT false,
  is_spam BOOLEAN DEFAULT false,
  
  -- Threading
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  
  -- Metadata
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  approved_by UUID REFERENCES public.profiles(id)
);

CREATE INDEX idx_comments_article ON public.comments(article_id);
CREATE INDEX idx_comments_approved ON public.comments(is_approved) WHERE is_approved = true;
CREATE INDEX idx_comments_parent ON public.comments(parent_id);

-- ================================================
-- FUNCTIONS
-- ================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for each table with updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_sports_updated_at
    BEFORE UPDATE ON public.sports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_leagues_updated_at
    BEFORE UPDATE ON public.leagues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_articles_updated_at
    BEFORE UPDATE ON public.articles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_live_matches_updated_at
    BEFORE UPDATE ON public.live_matches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_site_settings_updated_at
    BEFORE UPDATE ON public.site_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_navigation_updated_at
    BEFORE UPDATE ON public.navigation
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

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

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Increment article stats
CREATE OR REPLACE FUNCTION increment_article_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.articles 
  SET view_count = view_count + 1 
  WHERE id = NEW.article_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update tag usage count
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER article_tag_count
    AFTER INSERT OR DELETE ON public.article_tags
    FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();

-- Update author article count
CREATE OR REPLACE FUNCTION update_author_article_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.authors SET article_count = article_count + 1 WHERE id = NEW.author_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.authors SET article_count = article_count - 1 WHERE id = OLD.author_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.author_id != NEW.author_id THEN
      UPDATE public.authors SET article_count = article_count - 1 WHERE id = OLD.author_id;
      UPDATE public.authors SET article_count = article_count + 1 WHERE id = NEW.author_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER article_author_count
    AFTER INSERT OR UPDATE OR DELETE ON public.articles
    FOR EACH ROW EXECUTE FUNCTION update_author_article_count();

-- Log login activity
CREATE OR REPLACE FUNCTION log_login_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles 
  SET last_login_at = NOW(), login_count = login_count + 1
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_login
    AFTER UPDATE ON auth.users
    FOR EACH ROW WHEN (NEW.last_sign_in_at IS DISTINCT FROM OLD.last_sign_in_at)
    EXECUTE FUNCTION log_login_activity();
