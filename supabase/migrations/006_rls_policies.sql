-- ================================================
-- SPORTDUNE - RLS POLICIES
-- Row Level Security for Admin Dashboard
-- ================================================

-- ================================================
-- ENABLE RLS ON ALL TABLES
-- ================================================

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
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- ================================================
-- HELPER FUNCTIONS
-- ================================================

-- Check if current user has admin role
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('super_admin', 'admin', 'editor')
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if current user has super_admin role
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'super_admin'
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if current user can manage live scores
CREATE OR REPLACE FUNCTION can_manage_live_scores()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('super_admin', 'admin', 'live_manager')
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if current user can edit article
CREATE OR REPLACE FUNCTION can_edit_article(article_author_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('super_admin', 'admin', 'editor')
    AND is_active = true
  )
  OR (auth.uid() = article_author_id AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'author'
    AND is_active = true
  ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS admin_role AS $$
BEGIN
  RETURN (
    SELECT role FROM public.profiles
    WHERE id = auth.uid()
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- PROFILES POLICIES
-- ================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (is_admin());

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    (
      full_name = COALESCE(full_name, NEW.full_name) OR
      avatar_url = COALESCE(avatar_url, NEW.avatar_url) OR
      bio = COALESCE(bio, NEW.bio)
    )
  );

-- Admins can update any profile
CREATE POLICY "Admins can update profiles"
  ON public.profiles FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());

-- Only super_admin can insert profiles (done via auth.users trigger)
CREATE POLICY "System can insert profiles"
  ON public.profiles FOR INSERT
  WITH CHECK (true);

-- Only super_admin can delete profiles
CREATE POLICY "Super admins can delete profiles"
  ON public.profiles FOR DELETE
  USING (is_super_admin());

-- ================================================
-- SPORTS POLICIES
-- ================================================

-- Everyone can view active sports
CREATE POLICY "Anyone can view active sports"
  ON public.sports FOR SELECT
  USING (is_active = true OR is_admin());

-- Only admins can manage sports
CREATE POLICY "Admins can insert sports"
  ON public.sports FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Admins can update sports"
  ON public.sports FOR UPDATE
  USING (is_admin());

CREATE POLICY "Super admins can delete sports"
  ON public.sports FOR DELETE
  USING (is_super_admin());

-- ================================================
-- LEAGUES POLICIES
-- ================================================

-- Everyone can view active leagues
CREATE POLICY "Anyone can view active leagues"
  ON public.leagues FOR SELECT
  USING (is_active = true OR is_admin());

-- Only admins can manage leagues
CREATE POLICY "Admins can insert leagues"
  ON public.leagues FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Admins can update leagues"
  ON public.leagues FOR UPDATE
  USING (is_admin());

CREATE POLICY "Super admins can delete leagues"
  ON public.leagues FOR DELETE
  USING (is_super_admin());

-- ================================================
-- TAGS POLICIES
-- ================================================

-- Everyone can view active tags
CREATE POLICY "Anyone can view active tags"
  ON public.tags FOR SELECT
  USING (is_active = true OR is_admin());

-- Editors and above can manage tags
CREATE POLICY "Editors can manage tags"
  ON public.tags FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Editors can update tags"
  ON public.tags FOR UPDATE
  USING (is_admin());

CREATE POLICY "Admins can delete tags"
  ON public.tags FOR DELETE
  USING (is_admin());

-- ================================================
-- AUTHORS POLICIES
-- ================================================

-- Everyone can view active authors
CREATE POLICY "Anyone can view active authors"
  ON public.authors FOR SELECT
  USING (is_active = true OR is_admin());

-- Admins can manage authors
CREATE POLICY "Admins can insert authors"
  ON public.authors FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Admins can update authors"
  ON public.authors FOR UPDATE
  USING (is_admin());

CREATE POLICY "Admins can delete authors"
  ON public.authors FOR DELETE
  USING (is_admin());

-- ================================================
-- ARTICLES POLICIES
-- ================================================

-- Public can view published articles
CREATE POLICY "Anyone can view published articles"
  ON public.articles FOR SELECT
  USING (
    status = 'published'
    OR is_admin()
    OR created_by = auth.uid()
  );

-- Authors can create articles
CREATE POLICY "Auth users can create articles"
  ON public.articles FOR INSERT
  WITH CHECK (
    is_admin() OR
    (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'author'))
  );

-- Editors and above can update any article
-- Authors can update their own articles (drafts only)
CREATE POLICY "Editors can update any article"
  ON public.articles FOR UPDATE
  USING (
    is_admin() OR
    (can_edit_article(created_by))
  );

-- Only admins and editors can delete articles
CREATE POLICY "Admins can delete articles"
  ON public.articles FOR DELETE
  USING (is_admin());

-- ================================================
-- ARTICLE TAGS POLICIES
-- ================================================

-- Everyone can view article tags
CREATE POLICY "Anyone can view article tags"
  ON public.article_tags FOR SELECT
  USING (true);

-- Editors can manage article tags
CREATE POLICY "Editors can manage article tags"
  ON public.article_tags FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Editors can delete article tags"
  ON public.article_tags FOR DELETE
  USING (is_admin());

-- ================================================
-- ARTICLE IMAGES POLICIES
-- ================================================

-- Everyone can view article images
CREATE POLICY "Anyone can view article images"
  ON public.article_images FOR SELECT
  USING (true);

-- Editors can manage article images
CREATE POLICY "Editors can manage article images"
  ON public.article_images FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Editors can update article images"
  ON public.article_images FOR UPDATE
  USING (is_admin());

CREATE POLICY "Editors can delete article images"
  ON public.article_images FOR DELETE
  USING (is_admin());

-- ================================================
-- TEAMS POLICIES
-- ================================================

-- Everyone can view active teams
CREATE POLICY "Anyone can view active teams"
  ON public.teams FOR SELECT
  USING (is_active = true OR is_admin());

-- Admins can manage teams
CREATE POLICY "Admins can manage teams"
  ON public.teams FOR ALL
  USING (is_admin());

-- ================================================
-- LIVE MATCHES POLICIES
-- ================================================

-- Everyone can view live matches
CREATE POLICY "Anyone can view live matches"
  ON public.live_matches FOR SELECT
  USING (true);

-- Live managers and admins can manage matches
CREATE POLICY "Live managers can insert matches"
  ON public.live_matches FOR INSERT
  WITH CHECK (can_manage_live_scores());

CREATE POLICY "Live managers can update matches"
  ON public.live_matches FOR UPDATE
  USING (can_manage_live_scores());

CREATE POLICY "Admins can delete matches"
  ON public.live_matches FOR DELETE
  USING (is_admin());

-- ================================================
-- FEATURED CONTENT POLICIES
-- ================================================

-- Everyone can view active featured content
CREATE POLICY "Anyone can view active featured content"
  ON public.featured_content FOR SELECT
  USING (is_active = true OR is_admin());

-- Admins can manage featured content
CREATE POLICY "Admins can manage featured content"
  ON public.featured_content FOR ALL
  USING (is_admin());

-- ================================================
-- TRENDING ITEMS POLICIES
-- ================================================

-- Everyone can view active trending items
CREATE POLICY "Anyone can view active trending items"
  ON public.trending_items FOR SELECT
  USING (is_active = true OR is_admin());

-- Admins can manage trending items
CREATE POLICY "Admins can manage trending items"
  ON public.trending_items FOR ALL
  USING (is_admin());

-- ================================================
-- NAVIGATION POLICIES
-- ================================================

-- Everyone can view active navigation
CREATE POLICY "Anyone can view active navigation"
  ON public.navigation FOR SELECT
  USING (is_active = true OR is_admin());

-- Admins can manage navigation
CREATE POLICY "Admins can manage navigation"
  ON public.navigation FOR ALL
  USING (is_admin());

-- ================================================
-- MEDIA POLICIES
-- ================================================

-- Everyone can view media
CREATE POLICY "Anyone can view media"
  ON public.media FOR SELECT
  USING (true);

-- Authenticated users can upload media
CREATE POLICY "Auth users can upload media"
  ON public.media FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Uploaders and admins can update media
CREATE POLICY "Uploaders can update media"
  ON public.media FOR UPDATE
  USING (
    uploaded_by = auth.uid() OR
    is_admin()
  );

-- Admins can delete media
CREATE POLICY "Admins can delete media"
  ON public.media FOR DELETE
  USING (is_admin());

-- ================================================
-- SITE SETTINGS POLICIES
-- ================================================

-- Public settings can be viewed by anyone
CREATE POLICY "Anyone can view public settings"
  ON public.site_settings FOR SELECT
  USING (is_public = true OR is_admin());

-- Only admins can manage settings
CREATE POLICY "Admins can manage settings"
  ON public.site_settings FOR ALL
  USING (is_admin());

-- ================================================
-- AUDIT LOGS POLICIES
-- ================================================

-- Admins can view audit logs
CREATE POLICY "Admins can view audit logs"
  ON public.audit_logs FOR SELECT
  USING (is_admin());

-- System inserts audit logs (via trigger/function)
CREATE POLICY "System can insert audit logs"
  ON public.audit_logs FOR INSERT
  WITH CHECK (true);

-- ================================================
-- COMMENTS POLICIES
-- ================================================

-- Anyone can view approved comments
CREATE POLICY "Anyone can view approved comments"
  ON public.comments FOR SELECT
  USING (is_approved = true AND is_spam = false);

-- Editors can manage comments
CREATE POLICY "Editors can manage comments"
  ON public.comments FOR ALL
  USING (is_admin());

-- Anyone can insert comments (will be pending approval)
CREATE POLICY "Anyone can insert comments"
  ON public.comments FOR INSERT
  WITH CHECK (true);
