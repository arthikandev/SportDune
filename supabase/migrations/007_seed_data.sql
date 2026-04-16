-- ================================================
-- SPORTDUNE - SEED DATA
-- Initial sports, leagues, and settings
-- ================================================

-- ================================================
-- SPORTS SEED DATA
-- ================================================

INSERT INTO public.sports (name, slug, icon, description, color, banner_title, banner_subtitle, nav_order, nav_placement, is_active, meta_title, meta_description) VALUES
(
  'Football',
  'football',
  '⚽',
  'Latest football news from Premier League, Champions League, La Liga and more',
  '#1a3d00',
  'Football Coverage',
  'Premier League, Champions League, La Liga & More',
  1,
  'top',
  true,
  'Football News | SportDune',
  'Get the latest football news, match reports, and analysis from Premier League, Champions League, La Liga, and leagues around the world.'
),
(
  'Cricket',
  'cricket',
  '🏏',
  'Cricket news, match reports, IPL updates and Test series analysis',
  '#001f4d',
  'Cricket Coverage',
  'IPL, World Cup, Test Cricket & More',
  2,
  'top',
  true,
  'Cricket News | SportDune',
  'Cricket news, match reports, IPL updates, World Cup coverage, and in-depth analysis of Test cricket and limited-overs formats.'
),
(
  'Basketball',
  'basketball',
  '🏀',
  'NBA news, game recaps, analysis and live scores',
  '#1a2a0a',
  'Basketball Coverage',
  'NBA, EuroLeague, NCAA & More',
  3,
  'dropdown',
  true,
  'Basketball News | SportDune',
  'NBA news, game recaps, player analysis, trade rumors, and live scores from basketball leagues around the world.'
),
(
  'Formula 1',
  'f1',
  '🏎️',
  'F1 news, race results, driver standings and live timing',
  '#1a0a00',
  'Formula 1 Coverage',
  'Grand Prix, Driver Standings, Team News',
  4,
  'dropdown',
  true,
  'Formula 1 News | SportDune',
  'Formula 1 news, race results, driver and constructor standings, technical analysis, and behind-the-scenes team news.'
),
(
  'Tennis',
  'tennis',
  '🎾',
  'Tennis news, ATP & WTA reports, Grand Slam coverage',
  '#001a2a',
  'Tennis Coverage',
  'Grand Slams, ATP, WTA & Tour News',
  5,
  'dropdown',
  true,
  'Tennis News | SportDune',
  'Tennis news, ATP and WTA tour coverage, Grand Slam results, player profiles, and match analysis.'
),
(
  'Hockey',
  'hockey',
  '🏒',
  'NHL results, international hockey coverage and live scores',
  '#001430',
  'Hockey Coverage',
  'NHL, IIHF, International Hockey',
  6,
  'dropdown',
  true,
  'Hockey News | SportDune',
  'NHL news, international hockey coverage, game recaps, and live scores from hockey leagues worldwide.'
),
(
  'Rugby',
  'rugby',
  '🏉',
  'Rugby news, World Cup coverage and international matches',
  '#0a2010',
  'Rugby Coverage',
  'World Cup, Six Nations, Super Rugby',
  7,
  'dropdown',
  true,
  'Rugby News | SportDune',
  'Rugby news, World Cup coverage, Six Nations results, and international rugby match reports.'
),
(
  'Esports',
  'esports',
  '🎮',
  'Esports news covering Valorant, CS2, Dota 2 and tournaments',
  '#0d001a',
  'Esports Coverage',
  'Valorant, CS2, Dota 2, LoL & More',
  8,
  'dropdown',
  true,
  'Esports News | SportDune',
  'Esports news, tournament coverage, match results, and analysis for Valorant, CS2, Dota 2, and League of Legends.'
),
(
  'Combat Sports',
  'combat',
  '🥊',
  'UFC, boxing, MMA, wrestling and martial arts coverage',
  '#1a0000',
  'Combat Sports Coverage',
  'UFC, Boxing, MMA & More',
  9,
  'dropdown',
  true,
  'Combat Sports News | SportDune',
  'UFC, boxing, MMA news, fight predictions, results, and in-depth analysis of combat sports.'
),
(
  'NFL',
  'nfl',
  '🏈',
  'NFL news, game recaps, team analysis and draft coverage',
  '#001030',
  'NFL Coverage',
  'Regular Season, Playoffs, Super Bowl',
  10,
  'dropdown',
  true,
  'NFL News | SportDune',
  'NFL news, game recaps, power rankings, draft coverage, and analysis from the world of American football.'
),
(
  'Olympics',
  'olympics',
  '🏅',
  'Olympics coverage: events, athletes, medals and results',
  '#0a0a2a',
  'Olympics Coverage',
  'Summer & Winter Games, Athletes, Medal Table',
  11,
  'dropdown',
  true,
  'Olympics News | SportDune',
  'Olympics coverage, athlete profiles, medal counts, and results from Summer and Winter Olympic Games.'
);

-- ================================================
-- LEAGUES SEED DATA
-- ================================================

-- Football Leagues
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'football'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('Premier League', 'premier-league', 'PL', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Premier League - English top flight', 1),
  ('UEFA Champions League', 'champions-league', 'UCL', '🏆', 'UEFA Champions League - European club competition', 2),
  ('La Liga', 'la-liga', 'LL', '🇪🇸', 'La Liga - Spanish top division', 3),
  ('Bundesliga', 'bundesliga', 'BL', '🇩🇪', 'Bundesliga - German top division', 4),
  ('Serie A', 'serie-a', 'SA', '🇮🇹', 'Serie A - Italian top division', 5),
  ('Ligue 1', 'ligue-1', 'L1', '🇫🇷', 'Ligue 1 - French top division', 6),
  ('UEFA Europa League', 'europa-league', 'UEL', '🥉', 'UEFA Europa League', 7),
  ('FA Cup', 'fa-cup', 'FAC', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'FA Cup - English knockout competition', 8),
  ('Carabao Cup', 'carabao-cup', 'CC', '🏆', 'Carabao Cup - English League Cup', 9),
  ('FIFA World Cup', 'world-cup', 'WC', '🌍', 'FIFA World Cup - International tournament', 10),
  ('UEFA Euro', 'euro', 'EUR', '🏆', 'UEFA European Championship', 11)
) AS v(name, slug, short_name, icon, description, display_order);

-- Cricket Leagues
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'cricket'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('Indian Premier League', 'ipl', 'IPL', '🏏', 'IPL - Indian Premier League T20', 1),
  ('ICC Cricket World Cup', 'icc-world-cup', 'WC', '🏆', 'ICC Cricket World Cup', 2),
  ('The Ashes', 'the-ashes', 'ASH', '🏏', 'The Ashes - Australia vs England Test series', 3),
  ('ICC T20 World Cup', 't20-world-cup', 'T20', '🌍', 'ICC T20 World Cup', 4),
  ('ICC Champions Trophy', 'champions-trophy', 'CT', '🏆', 'ICC Champions Trophy', 5),
  ('Test Championship', 'test-championship', 'WTC', '🏏', 'World Test Championship Final', 6),
  ('Big Bash League', 'bbl', 'BBL', '🇦🇺', 'Big Bash League - Australian T20', 7),
  ('Caribbean Premier League', 'cpl', 'CPL', '🏏', 'Caribbean Premier League T20', 8),
  ('Pakistan Super League', 'psl', 'PSL', '🇵🇰', 'Pakistan Super League T20', 9)
) AS v(name, slug, short_name, icon, description, display_order);

-- Basketball Leagues
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'basketball'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('NBA', 'nba', 'NBA', '🏀', 'National Basketball Association', 1),
  ('EuroLeague', 'euroleague', 'EL', '🏀', 'EuroLeague - European elite competition', 2),
  ('NCAA Basketball', 'ncaa', 'NCAA', '🏀', 'NCAA College Basketball', 3),
  ('WNBA', 'wnba', 'WNBA', '🏀', 'Women''s National Basketball Association', 4),
  ('FIBA Champions League', 'fiba-champions', 'FIBACL', '🏆', 'FIBA Basketball Champions League', 5)
) AS v(name, slug, short_name, icon, description, display_order);

-- Formula 1
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'f1'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('Formula 1 World Championship', 'f1-championship', 'F1', '🏎️', 'FIA Formula 1 World Championship', 1),
  ('Driver Standings', 'driver-standings', 'DRV', '🏆', 'F1 Driver Championship Standings', 2),
  ('Constructor Standings', 'constructor-standings', 'CTR', '🏭', 'F1 Constructor Championship Standings', 3),
  ('Sprint Races', 'sprint-races', 'SPR', '🏎️', 'F1 Sprint Race Weekends', 4)
) AS v(name, slug, short_name, icon, description, display_order);

-- Tennis
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'tennis'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('Australian Open', 'australian-open', 'AO', '🎾', 'Australian Open - Grand Slam', 1),
  ('French Open', 'french-open', 'FO', '🎾', 'French Open (Roland Garros) - Grand Slam', 2),
  ('Wimbledon', 'wimbledon', 'WIM', '🎾', 'Wimbledon - Grand Slam', 3),
  ('US Open', 'us-open', 'USO', '🎾', 'US Open - Grand Slam', 4),
  ('ATP Tour', 'atp-tour', 'ATP', '🎾', 'ATP Tour - Men''s tennis', 5),
  ('WTA Tour', 'wta-tour', 'WTA', '🎾', 'WTA Tour - Women''s tennis', 6),
  ('ATP Finals', 'atp-finals', 'ATPF', '🏆', 'ATP Finals - Season finale', 7),
  ('Davis Cup', 'davis-cup', 'DC', '🎾', 'Davis Cup - International men''s team competition', 8)
) AS v(name, slug, short_name, icon, description, display_order);

-- Hockey
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'hockey'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('NHL', 'nhl', 'NHL', '🏒', 'National Hockey League', 1),
  ('Field Hockey', 'field-hockey', 'FH', '🏑', 'International Field Hockey', 2),
  ('IIHF World Championship', 'iihf', 'IIHF', '🏆', 'IIHF World Championship', 3),
  ('CHL', 'chl', 'CHL', '🏒', 'Canadian Hockey League', 4),
  ('KHL', 'khl', 'KHL', '🏒', 'Kontinental Hockey League', 5)
) AS v(name, slug, short_name, icon, description, display_order);

-- Rugby
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'rugby'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('Rugby World Cup', 'rugby-world-cup', 'RWC', '🏉', 'Rugby World Cup', 1),
  ('Six Nations', 'six-nations', '6N', '🏉', 'Six Nations Championship', 2),
  ('Super Rugby', 'super-rugby', 'SR', '🏉', 'Super Rugby - Southern Hemisphere', 3),
  ('Premiership Rugby', 'premiership', 'PRL', '🏉', 'English Premiership Rugby', 4),
  ('Top 14', 'top-14', 'T14', '🏉', 'Top 14 - French Championship', 5),
  ('United Rugby Championship', 'urf', 'URC', '🏉', 'United Rugby Championship', 6)
) AS v(name, slug, short_name, icon, description, display_order);

-- Esports
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'esports'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('Valorant Champions Tour', 'vct', 'VCT', '🎮', 'Valorant Champions Tour', 1),
  ('CS2 Major', 'cs2-major', 'MAJ', '🎮', 'CS2 Major Championships', 2),
  ('The International', 'ti', 'TI', '🏆', 'The International - Dota 2', 3),
  ('League of Legends Worlds', 'lol-worlds', 'WORLDS', '🎮', 'League of Legends World Championship', 4),
  ('LCS', 'lcs', 'LCS', '🎮', 'League Championship Series - NA', 5),
  ('LEC', 'lec', 'LEC', '🎮', 'League of Legends European Championship', 6),
  ('BLAST Premier', 'blast', 'BLAST', '🎮', 'BLAST Premier CS2 Events', 7),
  ('ESL Pro League', 'esl', 'ESL', '🎮', 'ESL Pro League', 8)
) AS v(name, slug, short_name, icon, description, display_order);

-- Combat Sports
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'combat'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('UFC', 'ufc', 'UFC', '🥊', 'Ultimate Fighting Championship', 1),
  ('Boxing', 'boxing', 'BOX', '🥊', 'Professional Boxing', 2),
  ('Bellator', 'bellator', 'BELL', '🥊', 'Bellator MMA', 3),
  ('ONE Championship', 'one-championship', 'ONE', '🥊', 'ONE Championship', 4),
  ('WWE', 'wwe', 'WWE', '🤼', 'WWE Wrestling', 5),
  ('PFL', 'pfl', 'PFL', '🥊', 'Professional Fighters League', 6),
  ('WBC', 'wbc', 'WBC', '🏆', 'World Boxing Council', 7),
  ('WBA', 'wba', 'WBA', '🏆', 'World Boxing Association', 8)
) AS v(name, slug, short_name, icon, description, display_order);

-- NFL
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'nfl'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('NFL Regular Season', 'nfl-regular', 'REG', '🏈', 'NFL Regular Season', 1),
  ('NFL Playoffs', 'nfl-playoffs', 'PLAY', '🏈', 'NFL Playoffs', 2),
  ('Super Bowl', 'super-bowl', 'SB', '🏆', 'Super Bowl', 3),
  ('NFL Draft', 'nfl-draft', 'DRF', '📝', 'NFL Draft', 4),
  ('NFL Preseason', 'nfl-preseason', 'PRE', '🏈', 'NFL Preseason', 5),
  ('Free Agency', 'free-agency', 'FA', '🏈', 'NFL Free Agency', 6)
) AS v(name, slug, short_name, icon, description, display_order);

-- Olympics
INSERT INTO public.leagues (sport_id, name, slug, short_name, icon, description, display_order, is_active)
SELECT 
  (SELECT id FROM public.sports WHERE slug = 'olympics'),
  name, slug, short_name, icon, description, display_order, true
FROM (VALUES
  ('Paris 2024', 'paris-2024', 'PAR24', '🏅', 'Paris 2024 Summer Olympics', 1),
  ('LA 2028', 'la-2028', 'LA28', '🏅', 'Los Angeles 2028 Summer Olympics', 2),
  ('Milan-Cortina 2026', 'milan-2026', 'MIL26', '🏅', 'Milan-Cortina 2026 Winter Olympics', 3),
  ('Athletes', 'athletes', 'ATH', '🏃', 'Olympic Athletes', 4),
  ('Medal Table', 'medals', 'MED', '🏆', 'Olympic Medal Table', 5),
  ('Paris 2024 Results', 'paris-results', 'RES', '📊', 'Paris 2024 Results', 6)
) AS v(name, slug, short_name, icon, description, display_order);

-- ================================================
-- TAGS SEED DATA
-- ================================================

INSERT INTO public.tags (name, slug, description) VALUES
('Transfer News', 'transfer-news', 'Football transfer rumors and completed transfers'),
('Match Highlights', 'match-highlights', 'Key moments from matches'),
('Player Profiles', 'player-profiles', 'In-depth player coverage'),
('Analysis', 'analysis', 'Expert analysis and commentary'),
('Interviews', 'interviews', 'Exclusive interviews'),
('Breaking News', 'breaking-news', 'Breaking news stories'),
('Opinion', 'opinion', 'Opinion pieces'),
('Statistics', 'statistics', 'Data and statistics'),
('Injury News', 'injury-news', 'Injury updates and returns'),
('Trade Rumors', 'trade-rumors', 'Trade and transfer rumors'),
('Draft Coverage', 'draft-coverage', 'Draft-related content'),
('Champions League', 'champions-league', 'UEFA Champions League coverage'),
('Premier League', 'premier-league', 'Premier League coverage'),
('IPL 2026', 'ipl-2026', 'Indian Premier League 2026'),
('NBA Playoffs', 'nba-playoffs', 'NBA Playoffs coverage'),
('Grand Slam', 'grand-slam', 'Tennis Grand Slam tournaments');

-- ================================================
-- SITE SETTINGS SEED DATA
-- ================================================

INSERT INTO public.site_settings (key, value, description, group_name, is_public) VALUES
('site_name', '"SportDune"', 'Website name', 'general', true),
('site_tagline', '"Live. Bold. Now."', 'Website tagline', 'general', true),
('site_logo', '""', 'Logo URL', 'general', true),
('site_favicon', '""', 'Favicon URL', 'general', true),
('contact_email', '"contact@sportdune.com"', 'Contact email', 'contact', true),
('social_twitter', '"https://twitter.com/sportdune"', 'Twitter URL', 'social', true),
('social_facebook', '"https://facebook.com/sportdune"', 'Facebook URL', 'social', true),
('social_instagram', '"https://instagram.com/sportdune"', 'Instagram URL', 'social', true),
('social_youtube', '"https://youtube.com/sportdune"', 'YouTube URL', 'social', true),
('social_tiktok', '"https://tiktok.com/@sportdune"', 'TikTok URL', 'social', true),
('articles_per_page', '12', 'Articles per page for pagination', 'content', false),
('featured_articles_count', '6', 'Number of featured articles on homepage', 'content', false),
('trending_articles_count', '10', 'Number of trending articles', 'content', false),
('related_articles_count', '4', 'Number of related articles', 'content', false),
('cache_duration_minutes', '5', 'Cache duration for API responses', 'performance', false),
('auto_trending_threshold', '5000', 'View threshold for auto-trending', 'content', false),
('breaking_news_cooldown_hours', '24', 'Cooldown between breaking news', 'content', false),
('allow_comments', 'true', 'Enable article comments', 'community', false),
('moderate_comments', 'true', 'Require comment approval', 'community', false),
('api_rate_limit', '100', 'API rate limit per minute', 'api', false),
('enable_search_indexing', 'true', 'Allow search engine indexing', 'seo', false);

-- ================================================
-- NAVIGATION SEED DATA
-- ================================================

INSERT INTO public.navigation (label, url, icon, placement, sort_order, is_active, is_featured) VALUES
('Home', '/', NULL, 'header', 1, true, false),
('Live Scores', '/live-scores', NULL, 'header', 2, true, true),
('Football', '/football', '⚽', 'header', 3, true, false),
('Cricket', '/cricket', '🏏', 'header', 4, true, false),
('More', '#', NULL, 'header', 5, true, false);

-- Dropdown items for "More"
INSERT INTO public.navigation (label, url, icon, parent_id, placement, sort_order, is_active)
SELECT name, '/' || slug, icon, (SELECT id FROM public.navigation WHERE label = 'More'), 'header', display_order, true
FROM public.sports 
WHERE slug IN ('basketball', 'f1', 'tennis', 'hockey', 'rugby', 'esports', 'combat', 'nfl', 'olympics');

-- Footer navigation
INSERT INTO public.navigation (label, url, placement, sort_order, is_active) VALUES
('About Us', '/about', 'footer', 1, true),
('Contact', '/contact', 'footer', 2, true),
('Privacy Policy', '/privacy', 'footer', 3, true),
('Terms of Service', '/terms', 'footer', 4, true),
('Advertise', '/advertise', 'footer', 5, true);

-- ================================================
-- CREATE ADMIN USER
-- ================================================

-- Note: The admin user will be created via Supabase Auth
-- This seed creates the profile link if the user already exists in auth.users
-- Run after creating the auth user:
-- UPDATE public.profiles SET role = 'super_admin' WHERE email = 'sportdune@gmail.com';
