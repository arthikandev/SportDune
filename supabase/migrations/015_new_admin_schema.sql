-- ================================================
-- SPORTDUNE - Clean Admin Dashboard Schema v3.0
-- News-only CMS | PostgreSQL 15 on Supabase
-- ================================================

-- ================================================
-- ENUMS
-- ================================================

CREATE TYPE public.admin_role AS ENUM ('super_admin', 'admin', 'editor', 'viewer');
CREATE TYPE public.article_status AS ENUM ('draft', 'scheduled', 'published', 'archived');

-- ================================================
-- 1. PROFILES (linked to Supabase Auth)
-- ================================================

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    role public.admin_role DEFAULT 'viewer',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_is_active ON public.profiles(is_active);
CREATE INDEX idx_profiles_email ON public.profiles(email);

-- ================================================
-- 2. SPORTS
-- ================================================

CREATE TABLE public.sports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    emoji TEXT,
    banner_title TEXT,
    banner_subtitle TEXT,
    banner_gradient TEXT,
    nav_order INTEGER DEFAULT 0,
    show_in_nav BOOLEAN DEFAULT true,
    show_in_more BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    seo_title TEXT,
    seo_description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sports_slug ON public.sports(slug);
CREATE INDEX idx_sports_nav_order ON public.sports(nav_order);
CREATE INDEX idx_sports_active ON public.sports(is_active);

-- ================================================
-- 3. LEAGUES
-- ================================================

CREATE TABLE public.leagues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sport_id UUID NOT NULL REFERENCES public.sports(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    seo_title TEXT,
    seo_description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_league_slug_per_sport UNIQUE (sport_id, slug)
);

CREATE INDEX idx_leagues_sport ON public.leagues(sport_id);
CREATE INDEX idx_leagues_slug ON public.leagues(slug);
CREATE INDEX idx_leagues_active ON public.leagues(is_active);

-- ================================================
-- 4. AUTHORS
-- ================================================

CREATE TABLE public.authors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    display_name TEXT NOT NULL,
    short_bio TEXT,
    specialty TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_authors_profile ON public.authors(profile_id);
CREATE INDEX idx_authors_active ON public.authors(is_active);

-- ================================================
-- 5. TAGS
-- ================================================

CREATE TABLE public.tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tags_slug ON public.tags(slug);

-- ================================================
-- 6. ARTICLES
-- ================================================

CREATE TABLE public.articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sport_id UUID REFERENCES public.sports(id) ON DELETE SET NULL,
    league_id UUID REFERENCES public.leagues(id) ON DELETE SET NULL,
    author_id UUID REFERENCES public.authors(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    excerpt TEXT,
    body TEXT NOT NULL,
    cover_image_url TEXT,
    cover_emoji TEXT,
    card_theme TEXT,
    status public.article_status DEFAULT 'draft',
    is_featured BOOLEAN DEFAULT false,
    is_trending BOOLEAN DEFAULT false,
    is_breaking BOOLEAN DEFAULT false,
    homepage_order INTEGER,
    sport_page_order INTEGER,
    read_time_minutes INTEGER DEFAULT 3,
    published_at TIMESTAMPTZ,
    scheduled_at TIMESTAMPTZ,
    seo_title TEXT,
    seo_description TEXT,
    created_by UUID REFERENCES public.profiles(id),
    updated_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_articles_slug ON public.articles(slug);
CREATE INDEX idx_articles_sport ON public.articles(sport_id);
CREATE INDEX idx_articles_league ON public.articles(league_id);
CREATE INDEX idx_articles_status ON public.articles(status);
CREATE INDEX idx_articles_published ON public.articles(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_articles_featured ON public.articles(is_featured) WHERE is_featured = true;
CREATE INDEX idx_articles_trending ON public.articles(is_trending) WHERE is_trending = true;

-- ================================================
-- 7. ARTICLE TAGS (Many-to-Many)
-- ================================================

CREATE TABLE public.article_tags (
    article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES public.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (article_id, tag_id)
);

CREATE INDEX idx_article_tags_tag ON public.article_tags(tag_id);

-- ================================================
-- 8. MEDIA ASSETS
-- ================================================

CREATE TABLE public.media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filename TEXT NOT NULL,
    url TEXT NOT NULL,
    storage_path TEXT,
    file_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    alt_text TEXT,
    sport_id UUID REFERENCES public.sports(id) ON DELETE SET NULL,
    uploaded_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_sport ON public.media_assets(sport_id);
CREATE INDEX idx_media_created ON public.media_assets(created_at DESC);

-- ================================================
-- 9. HOMEPAGE SECTIONS
-- ================================================

CREATE TABLE public.homepage_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_key TEXT NOT NULL UNIQUE,
    title TEXT,
    sport_id UUID REFERENCES public.sports(id) ON DELETE SET NULL,
    article_ids UUID[] DEFAULT '{}',
    display_order INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    max_items INTEGER DEFAULT 6,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_homepage_order ON public.homepage_sections(display_order);
CREATE INDEX idx_homepage_visible ON public.homepage_sections(is_visible);

-- ================================================
-- 10. TRENDING ITEMS
-- ================================================

CREATE TABLE public.trending_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID REFERENCES public.articles(id) ON DELETE CASCADE,
    display_title TEXT,
    emoji TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trending_order ON public.trending_items(display_order);
CREATE INDEX idx_trending_active ON public.trending_items(is_active);

-- ================================================
-- 11. NAVIGATION ITEMS
-- ================================================

CREATE TABLE public.navigation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    label TEXT NOT NULL,
    url TEXT NOT NULL,
    icon TEXT,
    parent_id UUID REFERENCES public.navigation_items(id) ON DELETE CASCADE,
    placement TEXT DEFAULT 'header' CHECK (placement IN ('header', 'footer', 'mobile')),
    sort_order INTEGER DEFAULT 0,
    target TEXT DEFAULT '_self',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_nav_parent ON public.navigation_items(parent_id);
CREATE INDEX idx_nav_placement ON public.navigation_items(placement);
CREATE INDEX idx_nav_order ON public.navigation_items(sort_order);

-- ================================================
-- 12. SITE SETTINGS
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
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_settings_key ON public.site_settings(key);
CREATE INDEX idx_settings_group ON public.site_settings(group_name);

-- ================================================
-- 13. AUDIT LOGS
-- ================================================

CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL,
    entity_type TEXT,
    entity_id UUID,
    user_id UUID REFERENCES public.profiles(id),
    user_email TEXT,
    user_role public.admin_role,
    old_values JSONB,
    new_values JSONB,
    changes_summary TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON public.audit_logs(user_id);
CREATE INDEX idx_audit_entity ON public.audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_action ON public.audit_logs(action);
CREATE INDEX idx_audit_date ON public.audit_logs(created_at DESC);

-- ================================================
-- FUNCTIONS
-- ================================================

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_sports_updated_at BEFORE UPDATE ON public.sports FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_leagues_updated_at BEFORE UPDATE ON public.leagues FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_navigation_updated_at BEFORE UPDATE ON public.navigation_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_trending_updated_at BEFORE UPDATE ON public.trending_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_homepage_updated_at BEFORE UPDATE ON public.homepage_sections FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
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
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Audit log trigger function
CREATE OR REPLACE FUNCTION public.log_audit_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.audit_logs (action, entity_type, entity_id, user_id, user_email, user_role, old_values, new_values, changes_summary)
    VALUES (
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        auth.uid(),
        (SELECT email FROM public.profiles WHERE id = auth.uid()),
        (SELECT role FROM public.profiles WHERE id = auth.uid()),
        CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
        TG_OP || ' on ' || TG_TABLE_NAME
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- RLS POLICIES
-- ================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trending_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.navigation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper: check if user has role
CREATE OR REPLACE FUNCTION public.has_role(required_role public.admin_role)
RETURNS BOOLEAN AS $$
DECLARE
    user_role public.admin_role;
BEGIN
    SELECT role INTO user_role FROM public.profiles WHERE id = auth.uid() AND is_active = true;
    IF user_role IS NULL THEN RETURN false; END IF;
    CASE required_role
        WHEN 'viewer' THEN RETURN true;
        WHEN 'editor' THEN RETURN user_role IN ('editor', 'admin', 'super_admin');
        WHEN 'admin' THEN RETURN user_role IN ('admin', 'super_admin');
        WHEN 'super_admin' THEN RETURN user_role = 'super_admin';
        ELSE RETURN false;
    END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PROFILES
CREATE POLICY "profiles_select_all" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id OR public.has_role('admin'));
CREATE POLICY "profiles_manage_admin" ON public.profiles FOR ALL USING (public.has_role('super_admin'));

-- SPORTS
CREATE POLICY "sports_select_all" ON public.sports FOR SELECT USING (true);
CREATE POLICY "sports_manage_editor" ON public.sports FOR ALL USING (public.has_role('editor'));

-- LEAGUES
CREATE POLICY "leagues_select_all" ON public.leagues FOR SELECT USING (true);
CREATE POLICY "leagues_manage_editor" ON public.leagues FOR ALL USING (public.has_role('editor'));

-- AUTHORS
CREATE POLICY "authors_select_all" ON public.authors FOR SELECT USING (true);
CREATE POLICY "authors_manage_editor" ON public.authors FOR ALL USING (public.has_role('editor'));

-- TAGS
CREATE POLICY "tags_select_all" ON public.tags FOR SELECT USING (true);
CREATE POLICY "tags_manage_editor" ON public.tags FOR ALL USING (public.has_role('editor'));

-- ARTICLES
CREATE POLICY "articles_select_published" ON public.articles FOR SELECT USING (status = 'published' OR public.has_role('viewer'));
CREATE POLICY "articles_insert_editor" ON public.articles FOR INSERT WITH CHECK (public.has_role('editor'));
CREATE POLICY "articles_update_editor" ON public.articles FOR UPDATE USING (public.has_role('editor'));
CREATE POLICY "articles_delete_admin" ON public.articles FOR DELETE USING (public.has_role('admin'));

-- ARTICLE TAGS
CREATE POLICY "article_tags_select_all" ON public.article_tags FOR SELECT USING (true);
CREATE POLICY "article_tags_manage_editor" ON public.article_tags FOR ALL USING (public.has_role('editor'));

-- MEDIA ASSETS
CREATE POLICY "media_select_all" ON public.media_assets FOR SELECT USING (true);
CREATE POLICY "media_manage_editor" ON public.media_assets FOR ALL USING (public.has_role('editor'));

-- HOMEPAGE SECTIONS
CREATE POLICY "homepage_select_all" ON public.homepage_sections FOR SELECT USING (true);
CREATE POLICY "homepage_manage_admin" ON public.homepage_sections FOR ALL USING (public.has_role('admin'));

-- TRENDING ITEMS
CREATE POLICY "trending_select_all" ON public.trending_items FOR SELECT USING (true);
CREATE POLICY "trending_manage_editor" ON public.trending_items FOR ALL USING (public.has_role('editor'));

-- NAVIGATION ITEMS
CREATE POLICY "nav_select_all" ON public.navigation_items FOR SELECT USING (true);
CREATE POLICY "nav_manage_admin" ON public.navigation_items FOR ALL USING (public.has_role('admin'));

-- SITE SETTINGS
CREATE POLICY "settings_select_public" ON public.site_settings FOR SELECT USING (is_public = true OR public.has_role('viewer'));
CREATE POLICY "settings_manage_admin" ON public.site_settings FOR ALL USING (public.has_role('admin'));

-- AUDIT LOGS
CREATE POLICY "audit_select_admin" ON public.audit_logs FOR SELECT USING (public.has_role('admin'));
CREATE POLICY "audit_insert_all" ON public.audit_logs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ================================================
-- SEED DATA
-- ================================================

INSERT INTO public.sports (name, slug, emoji, banner_title, banner_subtitle, banner_gradient, nav_order, show_in_nav, show_in_more, is_active) VALUES
('Football', 'football', '⚽', 'Football', 'Latest news, transfers, and analysis', 'linear-gradient(135deg, #1a3d00 0%, #2d5a00 100%)', 1, true, false, true),
('Cricket', 'cricket', '🏏', 'Cricket', 'Match reports, IPL updates, and series analysis', 'linear-gradient(135deg, #001f4d 0%, #003366 100%)', 2, true, false, true),
('Basketball', 'basketball', '🏀', 'Basketball', 'NBA news, game recaps, and analysis', 'linear-gradient(135deg, #1a2a0a 0%, #3a4a1a 100%)', 3, true, false, true),
('Formula 1', 'f1', '🏎️', 'Formula 1', 'Race results, technical analysis, and driver news', 'linear-gradient(135deg, #1a0a00 0%, #4a2a00 100%)', 4, true, false, true),
('Tennis', 'tennis', '🎾', 'Tennis', 'Grand Slam coverage, ATP & WTA reports', 'linear-gradient(135deg, #001a2a 0%, #00334d 100%)', 5, true, false, true),
('Hockey', 'hockey', '🏒', 'Hockey', 'NHL results and international coverage', 'linear-gradient(135deg, #001430 0%, #002a5a 100%)', 6, false, true, true),
('Rugby', 'rugby', '🏉', 'Rugby', 'World Cup and international match coverage', 'linear-gradient(135deg, #0a2010 0%, #1a4020 100%)', 7, false, true, true),
('Esports', 'esports', '🎮', 'Esports', 'Valorant, CS2, Dota 2 tournament news', 'linear-gradient(135deg, #0d001a 0%, #2a0033 100%)', 8, false, true, true),
('Combat Sports', 'combat', '🥊', 'Combat Sports', 'UFC, boxing, and MMA coverage', 'linear-gradient(135deg, #1a0000 0%, #4a0000 100%)', 9, false, true, true),
('NFL', 'nfl', '🏈', 'NFL', 'Game recaps, team analysis, and draft news', 'linear-gradient(135deg, #001030 0%, #002a5a 100%)', 10, false, true, true),
('Olympics', 'olympics', '🏅', 'Olympics', 'Events, athletes, and medal coverage', 'linear-gradient(135deg, #0a0a2a 0%, #1a1a5a 100%)', 11, false, true, true);

-- Leagues for Football
INSERT INTO public.leagues (sport_id, name, slug, description, display_order, is_active) VALUES
((SELECT id FROM public.sports WHERE slug = 'football'), 'Premier League', 'premier-league', 'English Premier League news and analysis', 1, true),
((SELECT id FROM public.sports WHERE slug = 'football'), 'Champions League', 'champions-league', 'UEFA Champions League coverage', 2, true),
((SELECT id FROM public.sports WHERE slug = 'football'), 'La Liga', 'la-liga', 'Spanish La Liga news', 3, true),
((SELECT id FROM public.sports WHERE slug = 'football'), 'Serie A', 'serie-a', 'Italian Serie A coverage', 4, true);

-- Leagues for Cricket
INSERT INTO public.leagues (sport_id, name, slug, description, display_order, is_active) VALUES
((SELECT id FROM public.sports WHERE slug = 'cricket'), 'IPL', 'ipl', 'Indian Premier League news and updates', 1, true),
((SELECT id FROM public.sports WHERE slug = 'cricket'), 'Test Cricket', 'test-cricket', 'International Test match coverage', 2, true);

-- Leagues for Basketball
INSERT INTO public.leagues (sport_id, name, slug, description, display_order, is_active) VALUES
((SELECT id FROM public.sports WHERE slug = 'basketball'), 'NBA', 'nba', 'National Basketball Association news', 1, true);

-- Leagues for F1
INSERT INTO public.leagues (sport_id, name, slug, description, display_order, is_active) VALUES
((SELECT id FROM public.sports WHERE slug = 'f1'), 'Formula 1', 'formula-1', 'F1 World Championship coverage', 1, true);

-- Leagues for Tennis
INSERT INTO public.leagues (sport_id, name, slug, description, display_order, is_active) VALUES
((SELECT id FROM public.sports WHERE slug = 'tennis'), 'ATP Tour', 'atp-tour', 'ATP Tour news and results', 1, true),
((SELECT id FROM public.sports WHERE slug = 'tennis'), 'WTA Tour', 'wta-tour', 'WTA Tour news and results', 2, true);

-- Tags
INSERT INTO public.tags (name, slug) VALUES
('Transfer News', 'transfer-news'),
('Match Report', 'match-report'),
('Analysis', 'analysis'),
('Breaking News', 'breaking-news'),
('Interview', 'interview'),
('Opinion', 'opinion'),
('Preview', 'preview'),
('Stats', 'stats');

-- Site settings
INSERT INTO public.site_settings (key, value, description, group_name, is_public) VALUES
('site_name', '"SportDune"', 'Website name', 'general', true),
('site_tagline', '"Live. Bold. Now."', 'Website tagline', 'general', true),
('footer_text', '"© 2026 SportDune. All rights reserved."', 'Footer copyright text', 'general', true),
('contact_email', '"contact@sportdune.com"', 'Contact email', 'general', true),
('social_twitter', '"https://twitter.com/sportdune"', 'Twitter URL', 'social', true),
('social_facebook', '"https://facebook.com/sportdune"', 'Facebook URL', 'social', true),
('social_instagram', '"https://instagram.com/sportdune"', 'Instagram URL', 'social', true),
('default_seo_title', '"SportDune - Your Sports News Hub"', 'Default SEO title', 'seo', false),
('default_seo_description', '"Breaking sports news, analysis, and coverage from around the world."', 'Default SEO description', 'seo', false);

-- Navigation items
INSERT INTO public.navigation_items (label, url, icon, placement, sort_order, is_active) VALUES
('Home', '/sports-homepage.html', '🏠', 'header', 1, true),
('Football', '/football.html', '⚽', 'header', 2, true),
('Cricket', '/cricket.html', '🏏', 'header', 3, true),
('Basketball', '/basketball.html', '🏀', 'header', 4, true),
('More', '#more-dropdown', '📋', 'header', 5, true),
('About', '/#about', '', 'footer', 1, true),
('Contact', '/#contact', '', 'footer', 2, true),
('Privacy', '/#privacy', '', 'footer', 3, true);

-- Homepage sections
INSERT INTO public.homepage_sections (section_key, title, display_order, is_visible, max_items) VALUES
('hero', 'Featured Story', 1, true, 1),
('trending', 'Trending Now', 2, true, 6),
('latest', 'Latest News', 3, true, 9),
('football', 'Football', 4, true, 6),
('cricket', 'Cricket', 5, true, 6),
('basketball', 'Basketball', 6, true, 6);
