# Frontend Integration Guide

This document explains how the existing SportDune frontend will integrate with the admin dashboard's database.

## Overview

The admin dashboard creates content in Supabase PostgreSQL. The frontend should be updated to fetch this content via the Supabase REST API or client SDK.

## API Endpoints

### Sports
```
GET /rest/v1/sports?is_active=eq.true&order=nav_order.asc
```
Returns active sports ordered by navigation position.

### Leagues
```
GET /rest/v1/leagues?sport_id=eq.{sport_id}&is_active=eq.true&order=display_order.asc
```
Returns leagues for a specific sport.

### Articles
```
GET /rest/v1/articles?status=eq.published&order=published_at.desc
```
Returns published articles.

### Live Matches
```
GET /rest/v1/live_matches?order=match_date.desc,match_time.desc
```
Returns all matches ordered by date/time.

### Navigation
```
GET /rest/v1/navigation?is_active=eq.true&order=sort_order.asc
```
Returns active navigation items.

### Featured Content
```
GET /rest/v1/featured_content?is_active=eq.true&order=position.asc
```
Returns featured homepage content.

## Frontend Data Fetching Pattern

### Option 1: Client-Side Fetching
```javascript
const SUPABASE_URL = 'https://pvmtcwqupalurwqlvdxy.supabase.co';
const SUPABASE_KEY = 'sb_publishable_fuqgloaY9Hi7mHi0HsH8DQ_fjvXS_E6';

async function fetchArticles() {
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/articles?status=eq.published&order=published_at.desc`,
    {
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`
      }
    }
  );
  return response.json();
}
```

### Option 2: Supabase Client SDK
```javascript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function fetchArticles() {
  const { data, error } = await supabase
    .from('articles')
    .select('*, sports(name), authors(display_name)')
    .eq('status', 'published')
    .order('published_at', { ascending: false });
  
  return data;
}
```

## Page-Specific Integration

### Homepage
1. Fetch featured content from `featured_content` table
2. Fetch trending articles from `trending_items` with article data
3. Fetch latest published articles
4. Fetch live matches with `status=eq.live`

### Sport Pages (e.g., /football)
1. Fetch sport details from `sports` table
2. Fetch leagues for this sport from `leagues` table
3. Fetch published articles where `sport_id` matches
4. Fetch trending items for this sport

### Article Detail Pages
1. Fetch article by slug from `articles` table
2. Fetch related articles (same sport/league)
3. Increment view count

### Live Scores Page
1. Fetch all live matches grouped by sport
2. Fetch scheduled matches
3. Fetch finished matches (recent results)

### Navigation
1. Fetch navigation items from `navigation` table
2. Build header menu dynamically
3. Update footer links from site_settings

## Caching Strategy

### Static Data (Sports, Leagues)
- Cache for 5-15 minutes
- Invalidate on admin changes

### Dynamic Data (Articles, Scores)
- Articles: Cache for 1-5 minutes
- Live Scores: Cache for 30 seconds to 1 minute
- Always show fresh data for live matches

### Implementation Example
```javascript
// Simple caching utility
const cache = new Map();
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

async function fetchWithCache(url) {
  const cached = cache.get(url);
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }
  
  const response = await fetch(url);
  const data = await response.json();
  cache.set(url, { data, timestamp: Date.now() });
  return data;
}
```

## Migration Checklist

When ready to switch frontend to database:

- [ ] Update `data-service.js` to fetch from Supabase
- [ ] Update homepage template to use dynamic data
- [ ] Update category pages to fetch sport-specific content
- [ ] Update article detail pages to fetch by slug
- [ ] Update live scores page to use database
- [ ] Update navigation to use database
- [ ] Implement caching layer
- [ ] Test all page loads
- [ ] Monitor performance

## Database Schema Reference

See `supabase/migrations/005_complete_admin_schema.sql` for complete table definitions.

## Sample Queries

### Get Homepage Data
```sql
SELECT 
  a.*,
  s.name as sport_name,
  s.icon as sport_icon,
  au.display_name as author_name
FROM articles a
LEFT JOIN sports s ON a.sport_id = s.id
LEFT JOIN authors au ON a.author_id = au.id
WHERE a.status = 'published'
ORDER BY a.published_at DESC
LIMIT 20;
```

### Get Sport Page Data
```sql
SELECT 
  a.*,
  l.name as league_name
FROM articles a
LEFT JOIN leagues l ON a.league_id = l.id
WHERE a.sport_id = 'sport-uuid'
  AND a.status = 'published'
ORDER BY a.is_featured DESC, a.published_at DESC;
```

### Get Live Scores
```sql
SELECT 
  m.*,
  s.name as sport_name,
  l.name as league_name
FROM live_matches m
LEFT JOIN sports s ON m.sport_id = s.id
LEFT JOIN leagues l ON m.league_id = l.id
WHERE m.status IN ('live', 'scheduled')
ORDER BY 
  CASE WHEN m.status = 'live' THEN 0 ELSE 1 END,
  m.match_date,
  m.match_time;
```
