-- ================================================
-- SPORTDUNE - Complete Database Schema
-- PostgreSQL 15 on Supabase
-- ================================================

-- ================================================
-- ENUMS
-- ================================================

CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'editor', 'author', 'public');
CREATE TYPE article_status AS ENUM ('draft', 'pending_review', 'published', 'archived');
CREATE TYPE article_type AS ENUM ('news', 'analysis', 'interview', 'feature', 'opinion');
CREATE TYPE log_level AS ENUM ('info', 'warning', 'error', 'critical');

-- ================================================
-- PROFILES (extends Supabase Auth)
-- ================================================

CREATE TABLE public.profiles (
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

-- Index for role-based queries
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_is_active ON public.profiles(is_active);

-- ================================================
-- CATEGORIES
-- ================================================

CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT, -- emoji or icon class
    color TEXT, -- hex color for UI
    parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_slug ON public.categories(slug);
CREATE INDEX idx_categories_parent ON public.categories(parent_id);
CREATE INDEX idx_categories_sort ON public.categories(sort_order);

-- ================================================
-- ARTICLES
-- ================================================

CREATE TABLE public.articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    excerpt TEXT, -- short description for cards
    content TEXT NOT NULL, -- full article HTML/markdown
    
    -- Media
    featured_image_url TEXT,
    featured_image_alt TEXT,
    
    -- Classification
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    type article_type DEFAULT 'news',
    status article_status DEFAULT 'draft',
    
    -- Author
    author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    
    -- SEO
    meta_title TEXT,
    meta_description TEXT,
    canonical_url TEXT,
    
    -- Engagement
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    
    -- Features
    is_featured BOOLEAN DEFAULT false,
    is_trending BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    
    -- Publishing
    published_at TIMESTAMPTZ,
    scheduled_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ -- soft delete
);

CREATE INDEX idx_articles_slug ON public.articles(slug);
CREATE INDEX idx_articles_category ON public.articles(category_id);
CREATE INDEX idx_articles_author ON public.articles(author_id);
CREATE INDEX idx_articles_status ON public.articles(status);
CREATE INDEX idx_articles_published ON public.articles(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_articles_featured ON public.articles(is_featured) WHERE is_featured = true;
CREATE INDEX idx_articles_trending ON public.articles(is_trending) WHERE is_trending = true;

-- ================================================
-- TAGS
-- ================================================

CREATE TABLE public.tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tags_slug ON public.tags(slug);

-- ================================================
-- ARTICLE TAGS (Many-to-Many)
-- ================================================

CREATE TABLE public.article_tags (
    article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES public.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (article_id, tag_id)
);

-- ================================================
-- ARTICLE IMAGES (Gallery)
-- ================================================

CREATE TABLE public.article_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    alt TEXT,
    caption TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- LIVE SCORES (Cached/Mock Data)
-- ================================================

CREATE TABLE public.live_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id TEXT, -- ID from external API if integrated
    
    -- Match Info
    home_team TEXT NOT NULL,
    home_team_short TEXT,
    away_team TEXT NOT NULL,
    away_team_short TEXT,
    home_score INTEGER DEFAULT 0,
    away_score INTEGER DEFAULT 0,
    
    -- Sport
    sport TEXT NOT NULL, -- football, cricket, basketball, etc.
    
    -- Competition
    league_name TEXT,
    league_short TEXT,
    
    -- Status
    status TEXT DEFAULT 'scheduled', -- live, finished, postponed
    match_time TEXT, -- HH:MM format
    match_date DATE,
    minute_played INTEGER, -- for live matches
    
    -- Metadata
    venue TEXT,
    location TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_matches_sport ON public.live_matches(sport);
CREATE INDEX idx_matches_status ON public.live_matches(status);
CREATE INDEX idx_matches_date ON public.live_matches(match_date);

-- ================================================
-- PAGE VIEWS (Analytics)
-- ================================================

CREATE TABLE public.page_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Page Info
    page_url TEXT NOT NULL,
    page_type TEXT, -- article, category, homepage, etc.
    article_id UUID REFERENCES public.articles(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    
    -- Visitor Info
    visitor_id TEXT, -- anonymous or user ID
    session_id TEXT,
    referrer TEXT,
    
    -- Device Info
    user_agent TEXT,
    device_type TEXT, -- mobile, desktop, tablet
    browser TEXT,
    country TEXT,
    
    -- Timestamps
    viewed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partition by date for performance (optional, for high traffic)
CREATE INDEX idx_views_page ON public.page_views(page_url);
CREATE INDEX idx_views_article ON public.page_views(article_id);
CREATE INDEX idx_views_date ON public.page_views(viewed_at DESC);

-- ================================================
-- ANALYTICS SUMMARY (Daily Aggregates)
-- ================================================

CREATE TABLE public.analytics_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    
    -- Page Views
    total_page_views INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    
    -- Articles
    article_views INTEGER DEFAULT 0,
    new_articles INTEGER DEFAULT 0,
    
    -- Engagement
    avg_time_on_site INTEGER, -- seconds
    bounce_rate DECIMAL(5,2), -- percentage
    
    -- Top Content
    top_article_ids UUID[], -- array of article UUIDs
    
    -- Device Split
    mobile_views INTEGER DEFAULT 0,
    desktop_views INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_analytics_date ON public.analytics_daily(date DESC);

-- ================================================
-- SITE SETTINGS
-- ================================================

CREATE TABLE public.site_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    value JSONB NOT NULL, -- flexible JSON storage
    description TEXT,
    is_public BOOLEAN DEFAULT false, -- show in footer/about
    updated_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- AUDIT LOGS
-- ================================================

CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Action Info
    action TEXT NOT NULL, -- create, update, delete, login, etc.
    entity_type TEXT, -- articles, users, settings, etc.
    entity_id UUID,
    
    -- User Info
    user_id UUID REFERENCES public.profiles(id),
    user_email TEXT,
    user_role user_role,
    
    -- Change Details
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
CREATE INDEX idx_audit_date ON public.audit_logs(created_at DESC);

-- ================================================
-- NOTIFICATIONS
-- ================================================

CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Content
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info', -- info, success, warning, error
    
    -- Action
    action_url TEXT,
    action_label TEXT,
    
    -- State
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

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

-- Create trigger for each table with updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON public.categories
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

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        'public'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Increment view count
CREATE OR REPLACE FUNCTION increment_article_views()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.articles 
    SET view_count = view_count + 1 
    WHERE id = NEW.article_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER article_view_increment
    AFTER INSERT ON public.page_views
    FOR EACH ROW EXECUTE FUNCTION increment_article_views();

-- ================================================
-- SEED DATA
-- ================================================

-- Insert categories
INSERT INTO public.categories (name, slug, description, icon, color, sort_order) VALUES
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
('Olympics', 'olympics', 'Olympics coverage: events, athletes, medals and results', '🏅', '#0a0a2a', 11);

-- Insert tags
INSERT INTO public.tags (name, slug) VALUES
('Transfer News', 'transfer-news'),
('Match Highlights', 'match-highlights'),
('Player Profiles', 'player-profiles'),
('Analysis', 'analysis'),
('Interviews', 'interviews'),
('Breaking News', 'breaking-news'),
('Opinion', 'opinion'),
('Statistics', 'statistics'),
('Champions League', 'champions-league'),
('Premier League', 'premier-league'),
('IPL 2026', 'ipl-2026'),
('NBA Playoffs', 'nba-playoffs');

-- Insert site settings
INSERT INTO public.site_settings (key, value, description, is_public) VALUES
('site_name', '"SportDune"', 'Website name', true),
('site_tagline', '"Live. Bold. Now."', 'Website tagline', true),
('contact_email', '"contact@sportdune.com"', 'Contact email', true),
('social_twitter', '"https://twitter.com/sportdune"', 'Twitter URL', true),
('social_facebook', '"https://facebook.com/sportdune"', 'Facebook URL', true),
('social_instagram', '"https://instagram.com/sportdune"', 'Instagram URL', true),
('articles_per_page', '20', 'Articles per page', false),
('featured_articles_count', '6', 'Number of featured articles on homepage', false),
('trending_articles_count', '10', 'Number of trending articles', false),
('cache_duration_minutes', '5', 'Cache duration for API responses', false);
