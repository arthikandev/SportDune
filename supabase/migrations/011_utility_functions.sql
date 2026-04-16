-- ================================================
-- SPORTDUNE - UTILITY FUNCTIONS
-- Additional SQL functions for the database
-- ================================================

-- Function to increment article views
CREATE OR REPLACE FUNCTION increment_article_views(article_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.articles 
  SET view_count = view_count + 1 
  WHERE id = article_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update setting safely
CREATE OR REPLACE FUNCTION update_setting(p_key TEXT, p_value JSONB)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.site_settings (key, value, updated_at)
  VALUES (p_key, p_value, NOW())
  ON CONFLICT (key) 
  DO UPDATE SET value = p_value, updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
  p_action TEXT,
  p_entity_type TEXT DEFAULT NULL,
  p_entity_id UUID DEFAULT NULL,
  p_user_id UUID DEFAULT NULL,
  p_user_email TEXT DEFAULT NULL,
  p_user_role admin_role DEFAULT NULL,
  p_old_values JSONB DEFAULT NULL,
  p_new_values JSONB DEFAULT NULL,
  p_changes_summary TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.audit_logs (
    action, entity_type, entity_id, user_id, user_email, user_role,
    old_values, new_values, changes_summary
  ) VALUES (
    p_action, p_entity_type, p_entity_id, p_user_id, p_user_email, p_user_role,
    p_old_values, p_new_values, p_changes_summary
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- VERIFICATION QUERIES
-- ================================================

-- Check all tables exist
SELECT 'Tables Check:' as info;
SELECT table_name, (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) as exists_count
FROM (VALUES 
  ('profiles'), ('sports'), ('leagues'), ('tags'), ('authors'),
  ('articles'), ('article_tags'), ('article_images'), ('teams'),
  ('live_matches'), ('featured_content'), ('trending_items'),
  ('navigation'), ('media'), ('site_settings'), ('audit_logs')
) AS t(table_name);

-- Check sports were seeded
SELECT 'Sports Count:' as info, COUNT(*) as count FROM public.sports;

-- Check enums exist
SELECT 'Enums Check:' as info;
SELECT typname as enum_name FROM pg_type WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public') AND typtype = 'e';

-- Check RLS is enabled
SELECT 'RLS Check:' as info;
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'sports', 'articles', 'live_matches');

-- ================================================
-- SAMPLE DATA FOR TESTING
-- ================================================

-- Sample articles (uncomment to add test data)
/*
INSERT INTO public.articles (title, slug, excerpt, content, sport_id, status, published_at, is_featured)
SELECT 
  'Test Article 1',
  'test-article-1',
  'This is a test article for the SportDune platform.',
  '<p>This is the full content of the test article.</p>',
  id,
  'published',
  NOW(),
  true
FROM public.sports WHERE slug = 'football'
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.articles (title, slug, excerpt, content, sport_id, status, published_at)
SELECT 
  'Test Article 2',
  'test-article-2',
  'Another test article with more content.',
  '<p>More content here.</p>',
  id,
  'published',
  NOW() - INTERVAL '1 day'
FROM public.sports WHERE slug = 'cricket'
ON CONFLICT (slug) DO NOTHING;
*/

-- Sample live matches
/*
INSERT INTO public.live_matches (sport_id, team_a_name, team_b_name, team_a_score, team_b_score, status, match_date, match_time)
SELECT 
  id,
  'Manchester United',
  'Liverpool',
  2,
  1,
  'finished',
  CURRENT_DATE,
  '15:00'
FROM public.sports WHERE slug = 'football'
ON CONFLICT DO NOTHING;

INSERT INTO public.live_matches (sport_id, team_a_name, team_b_name, status, match_date, match_time)
SELECT 
  id,
  'Arsenal',
  'Chelsea',
  'scheduled',
  CURRENT_DATE + 1,
  '17:30'
FROM public.sports WHERE slug = 'football'
ON CONFLICT DO NOTHING;
*/
