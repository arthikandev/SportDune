-- ================================================
-- REMOVE LIVE SCORES FEATURE
-- Migration: 013_remove_live_scores.sql
-- ================================================

-- Drop live_matches table if exists
DROP TABLE IF EXISTS public.live_matches CASCADE;

-- Remove Live Scores from navigation
DELETE FROM public.navigation WHERE url = '/live-scores';

-- Note: Cannot remove 'live_manager' from admin_role enum as it may have existing data
-- It will be deprecated but not dropped to avoid migration failures

-- Verify removal
SELECT 'Live Scores feature removed' as status;

-- Check remaining tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
AND table_name NOT LIKE '%live%'
ORDER BY table_name;