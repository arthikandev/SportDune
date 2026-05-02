-- ================================================
-- SPORTDUNE - Remove Old Admin Dashboard Objects
-- Safe cleanup migration - drops only old admin-specific objects
-- ================================================

-- ================================================
-- DROP OLD POLICIES
-- ================================================

-- Profiles policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Only super_admins can delete profiles" ON public.profiles;

-- Categories policies
DROP POLICY IF EXISTS "Active categories are viewable by everyone" ON public.categories;
DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
DROP POLICY IF EXISTS "Only super_admins can delete categories" ON public.categories;

-- Articles policies
DROP POLICY IF EXISTS "Published articles are viewable by everyone" ON public.articles;
DROP POLICY IF EXISTS "Authors can create articles" ON public.articles;
DROP POLICY IF EXISTS "Editors can update articles" ON public.articles;
DROP POLICY IF EXISTS "Admins can delete articles" ON public.articles;

-- Tags policies
DROP POLICY IF EXISTS "Tags are viewable by everyone" ON public.tags;
DROP POLICY IF EXISTS "Admins can manage tags" ON public.tags;

-- Article tags policies
DROP POLICY IF EXISTS "Article tags viewable by everyone" ON public.article_tags;
DROP POLICY IF EXISTS "Editors can manage article tags" ON public.article_tags;

-- Live matches policies
DROP POLICY IF EXISTS "Live matches are viewable by everyone" ON public.live_matches;
DROP POLICY IF EXISTS "Admins can manage live matches" ON public.live_matches;

-- Page views policies
DROP POLICY IF EXISTS "Anyone can track page views" ON public.page_views;
DROP POLICY IF EXISTS "Admins can view all page views" ON public.page_views;

-- Analytics policies
DROP POLICY IF EXISTS "Daily analytics are viewable by everyone" ON public.analytics_daily;
DROP POLICY IF EXISTS "Admins can manage analytics" ON public.analytics_daily;

-- Site settings policies
DROP POLICY IF EXISTS "Public settings are viewable by everyone" ON public.site_settings;
DROP POLICY IF EXISTS "Admins can manage all settings" ON public.site_settings;

-- Audit logs policies
DROP POLICY IF EXISTS "Admins can view audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Service role can insert audit logs" ON public.audit_logs;

-- Notifications policies
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Service role can create notifications" ON public.notifications;

-- Article images policies
DROP POLICY IF EXISTS "Article images viewable by everyone" ON public.article_images;
DROP POLICY IF EXISTS "Editors can manage article images" ON public.article_images;

-- ================================================
-- DROP OLD TRIGGERS
-- ================================================

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
DROP TRIGGER IF EXISTS update_articles_updated_at ON public.articles;
DROP TRIGGER IF EXISTS update_live_matches_updated_at ON public.live_matches;
DROP TRIGGER IF EXISTS update_site_settings_updated_at ON public.site_settings;
DROP TRIGGER IF EXISTS article_view_increment ON public.page_views;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_sports_updated_at ON public.sports;
DROP TRIGGER IF EXISTS update_leagues_updated_at ON public.leagues;
DROP TRIGGER IF EXISTS update_navigation_updated_at ON public.navigation;
DROP TRIGGER IF EXISTS article_tag_count ON public.article_tags;
DROP TRIGGER IF EXISTS article_author_count ON public.articles;
DROP TRIGGER IF EXISTS on_login ON auth.users;

-- ================================================
-- DROP OLD FUNCTIONS
-- ================================================

DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.increment_article_views() CASCADE;
DROP FUNCTION IF EXISTS public.increment_article_stats() CASCADE;
DROP FUNCTION IF EXISTS public.update_tag_usage_count() CASCADE;
DROP FUNCTION IF EXISTS public.update_author_article_count() CASCADE;
DROP FUNCTION IF EXISTS public.log_login_activity() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.is_editor() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_role() CASCADE;

-- ================================================
-- DROP OLD TABLES (old admin-only or forbidden modules)
-- ================================================

-- Drop notifications (not needed for news-only CMS)
DROP TABLE IF EXISTS public.notifications CASCADE;

-- Drop analytics_daily (not needed for news-only CMS)
DROP TABLE IF EXISTS public.analytics_daily CASCADE;

-- Drop page_views (complex analytics not needed)
DROP TABLE IF EXISTS public.page_views CASCADE;

-- Drop live_matches (Live Scores module - forbidden)
DROP TABLE IF EXISTS public.live_matches CASCADE;

-- Drop article_images (simplified to single cover image in articles)
DROP TABLE IF EXISTS public.article_images CASCADE;

-- Drop teams (Live Scores dependency - forbidden)
DROP TABLE IF EXISTS public.teams CASCADE;

-- Drop featured_content (replaced by homepage_sections)
DROP TABLE IF EXISTS public.featured_content CASCADE;

-- Drop categories (replaced by sports + leagues structure)
DROP TABLE IF EXISTS public.categories CASCADE;

-- Drop comments (not needed for news-only CMS)
DROP TABLE IF EXISTS public.comments CASCADE;

-- ================================================
-- DROP OLD ENUMS (will be recreated clean)
-- ================================================

DROP TYPE IF EXISTS public.user_role CASCADE;
DROP TYPE IF EXISTS public.article_status CASCADE;
DROP TYPE IF EXISTS public.article_type CASCADE;
DROP TYPE IF EXISTS public.log_level CASCADE;
DROP TYPE IF EXISTS public.admin_role CASCADE;
DROP TYPE IF EXISTS public.match_status CASCADE;
DROP TYPE IF EXISTS public.placement_section CASCADE;
