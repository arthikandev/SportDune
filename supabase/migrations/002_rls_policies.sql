-- ================================================
-- SPORTDUNE - Row Level Security Policies
-- ================================================

-- ================================================
-- ENABLE RLS ON ALL TABLES
-- ================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.page_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ================================================
-- PROFILES POLICIES
-- ================================================

-- Users can view any profile (for author bylines)
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Only admins can insert profiles (via trigger)
CREATE POLICY "Admins can insert profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

-- Only super_admins can delete profiles
CREATE POLICY "Only super_admins can delete profiles"
    ON public.profiles FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- ================================================
-- CATEGORIES POLICIES
-- ================================================

-- Anyone can view active categories
CREATE POLICY "Active categories are viewable by everyone"
    ON public.categories FOR SELECT
    USING (is_active = true);

-- Only admins can manage categories
CREATE POLICY "Admins can insert categories"
    ON public.categories FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

CREATE POLICY "Admins can update categories"
    ON public.categories FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

CREATE POLICY "Only super_admins can delete categories"
    ON public.categories FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- ================================================
-- ARTICLES POLICIES
-- ================================================

-- Anyone can view published articles
CREATE POLICY "Published articles are viewable by everyone"
    ON public.articles FOR SELECT
    USING (
        status = 'published'
        OR author_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin', 'editor')
        )
    );

-- Authors can create articles
CREATE POLICY "Authors can create articles"
    ON public.articles FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin', 'editor', 'author')
        )
    );

-- Editors can update any article, authors can update own
CREATE POLICY "Editors can update articles"
    ON public.articles FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin', 'editor')
        )
        OR author_id = auth.uid()
    );

-- Only admins and editors can delete
CREATE POLICY "Admins can delete articles"
    ON public.articles FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin', 'editor')
        )
    );

-- ================================================
-- TAGS POLICIES
-- ================================================

-- Anyone can view tags
CREATE POLICY "Tags are viewable by everyone"
    ON public.tags FOR SELECT
    USING (true);

-- Only admins can manage tags
CREATE POLICY "Admins can manage tags"
    ON public.tags FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

-- ================================================
-- ARTICLE TAGS POLICIES
-- ================================================

CREATE POLICY "Article tags viewable by everyone"
    ON public.article_tags FOR SELECT
    USING (true);

CREATE POLICY "Editors can manage article tags"
    ON public.article_tags FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin', 'editor')
        )
    );

-- ================================================
-- LIVE MATCHES POLICIES
-- ================================================

-- Anyone can view live matches
CREATE POLICY "Live matches are viewable by everyone"
    ON public.live_matches FOR SELECT
    USING (true);

-- Only admins can manage matches
CREATE POLICY "Admins can manage live matches"
    ON public.live_matches FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

-- ================================================
-- PAGE VIEWS POLICIES
-- ================================================

-- Anyone can insert page views (tracking)
CREATE POLICY "Anyone can track page views"
    ON public.page_views FOR INSERT
    WITH CHECK (true);

-- Only admins can view analytics
CREATE POLICY "Admins can view all page views"
    ON public.page_views FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

-- ================================================
-- ANALYTICS DAILY POLICIES
-- ================================================

-- Public can view daily analytics summary
CREATE POLICY "Daily analytics are viewable by everyone"
    ON public.analytics_daily FOR SELECT
    USING (true);

-- Only admins can manage analytics
CREATE POLICY "Admins can manage analytics"
    ON public.analytics_daily FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

-- ================================================
-- SITE SETTINGS POLICIES
-- ================================================

-- Public settings are viewable by everyone
CREATE POLICY "Public settings are viewable by everyone"
    ON public.site_settings FOR SELECT
    USING (is_public = true);

-- Only admins can manage all settings
CREATE POLICY "Admins can manage all settings"
    ON public.site_settings FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

-- ================================================
-- AUDIT LOGS POLICIES
-- ================================================

-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs"
    ON public.audit_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
        )
    );

-- System can insert audit logs (via service role)
CREATE POLICY "Service role can insert audit logs"
    ON public.audit_logs FOR INSERT
    WITH CHECK (true);

-- ================================================
-- NOTIFICATIONS POLICIES
-- ================================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
    ON public.notifications FOR SELECT
    USING (user_id = auth.uid());

-- Users can update their own notifications
CREATE POLICY "Users can update own notifications"
    ON public.notifications FOR UPDATE
    USING (user_id = auth.uid());

-- System can create notifications
CREATE POLICY "Service role can create notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (true);

-- ================================================
-- HELPER FUNCTIONS
-- ================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() 
        AND role IN ('super_admin', 'admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is editor or above
CREATE OR REPLACE FUNCTION public.is_editor()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() 
        AND role IN ('super_admin', 'admin', 'editor')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user role
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role AS $$
DECLARE
    user_role user_role;
BEGIN
    SELECT role INTO user_role
    FROM public.profiles
    WHERE id = auth.uid();
    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
