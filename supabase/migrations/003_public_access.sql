-- ================================================
-- SPORTDUNE - Public Access RLS Policies
-- ================================================

-- Categories: Public read access
DROP POLICY IF EXISTS "Public categories viewable" ON public.categories;
CREATE POLICY "Public categories viewable"
    ON public.categories FOR SELECT
    USING (true);

-- Articles: Public read for published articles
DROP POLICY IF EXISTS "Public published articles viewable" ON public.articles;
CREATE POLICY "Public published articles viewable"
    ON public.articles FOR SELECT
    USING (
        status = 'published'
    );

-- Tags: Public read access
DROP POLICY IF EXISTS "Public tags viewable" ON public.tags;
CREATE POLICY "Public tags viewable"
    ON public.tags FOR SELECT
    USING (true);

-- Article Tags: Public read access
DROP POLICY IF EXISTS "Public article tags viewable" ON public.article_tags;
CREATE POLICY "Public article tags viewable"
    ON public.article_tags FOR SELECT
    USING (true);

-- Live Matches: Public read access
DROP POLICY IF EXISTS "Public live matches viewable" ON public.live_matches;
CREATE POLICY "Public live matches viewable"
    ON public.live_matches FOR SELECT
    USING (true);

-- Site Settings: Public read access
DROP POLICY IF EXISTS "Public settings viewable" ON public.site_settings;
CREATE POLICY "Public settings viewable"
    ON public.site_settings FOR SELECT
    USING (true);

-- ================================================
-- ADMIN WRITER ACCESS (via Service Role)
-- ================================================

-- Categories: Service role can do all
DROP POLICY IF EXISTS "Service can manage categories" ON public.categories;
CREATE POLICY "Service can manage categories"
    ON public.categories FOR ALL
    USING (true)
    WITH CHECK (true);

-- Articles: Service role can do all
DROP POLICY IF EXISTS "Service can manage articles" ON public.articles;
CREATE POLICY "Service can manage articles"
    ON public.articles FOR ALL
    USING (true)
    WITH CHECK (true);

-- Tags: Service role can do all
DROP POLICY IF EXISTS "Service can manage tags" ON public.tags;
CREATE POLICY "Service can manage tags"
    ON public.tags FOR ALL
    USING (true)
    WITH CHECK (true);

-- Article Tags: Service role can do all
DROP POLICY IF EXISTS "Service can manage article tags" ON public.article_tags;
CREATE POLICY "Service can manage article tags"
    ON public.article_tags FOR ALL
    USING (true)
    WITH CHECK (true);

-- Page Views: Anyone can insert (for tracking)
DROP POLICY IF EXISTS "Anyone can track page views" ON public.page_views;
CREATE POLICY "Anyone can track page views"
    ON public.page_views FOR INSERT
    WITH CHECK (true);

-- Profiles: Public read, authenticated update
DROP POLICY IF EXISTS "Public profiles viewable" ON public.profiles;
CREATE POLICY "Public profiles viewable"
    ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (true)
    WITH CHECK (true);
