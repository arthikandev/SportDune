-- Public read access policies
DO $$
BEGIN
  -- Categories: Public read access
  DROP POLICY IF EXISTS "Public categories viewable" ON public.categories;
  CREATE POLICY "Public categories viewable"
      ON public.categories FOR SELECT
      USING (true);

  -- Articles: Public read for published articles
  DROP POLICY IF EXISTS "Public published articles viewable" ON public.articles;
  CREATE POLICY "Public published articles viewable"
      ON public.articles FOR SELECT
      USING (status = 'published');

  -- Tags: Public read access
  DROP POLICY IF EXISTS "Public tags viewable" ON public.tags;
  CREATE POLICY "Public tags viewable"
      ON public.tags FOR SELECT
      USING (true);

  -- Article Images: Public read access
  DROP POLICY IF EXISTS "Public article images viewable" ON public.article_images;
  CREATE POLICY "Public article images viewable"
      ON public.article_images FOR SELECT
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

  -- Profiles: Public read access
  DROP POLICY IF EXISTS "Public profiles viewable" ON public.profiles;
  CREATE POLICY "Public profiles viewable"
      ON public.profiles FOR SELECT
      USING (true);

  RAISE NOTICE 'Public access policies created successfully';
END $$;
