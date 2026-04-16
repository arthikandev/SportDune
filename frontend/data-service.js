/**
 * SportDune - Data Service
 * Fetches data from Supabase using the new schema
 */

const SUPABASE_URL = 'https://pvmtcwqupalurwqlvdxy.supabase.co';
const SUPABASE_KEY = 'sb_publishable_fuqgloaY9Hi7mHi0HsH8DQ_fjvXS_E6';

// Simple cache
const cache = new Map();
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

/**
 * Make an API call to Supabase REST API
 */
async function apiCall(endpoint, options = {}) {
  const cacheKey = `${endpoint}${JSON.stringify(options)}`;
  const cached = cache.get(cacheKey);
  
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }
  
  const headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': 'Bearer ' + SUPABASE_KEY,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...options.headers
  };
  
  const response = await fetch(SUPABASE_URL + '/rest/v1/' + endpoint, {
    ...options,
    headers
  });
  
  if (!response.ok) {
    console.error('API Error:', response.status, response.statusText);
    return null;
  }
  
  const data = await response.json();
  cache.set(cacheKey, { data, timestamp: Date.now() });
  return data;
}

/**
 * Clear cache (call after mutations)
 */
function clearCache() {
  cache.clear();
}

/**
 * Fetch sports from database
 */
async function getSports() {
  return apiCall('sports?is_active=eq.true&order=nav_order.asc');
}

/**
 * Fetch leagues for a sport
 */
async function getLeagues(sportId) {
  if (!sportId) return [];
  return apiCall(`leagues?sport_id=eq.${sportId}&is_active=eq.true&order=display_order.asc`);
}

/**
 * Fetch articles with optional filters
 */
async function getArticles(options = {}) {
  const { sportId = '', leagueId = '', limit = 12, status = 'published', trending = false } = options;
  
  let query = `articles?select=*,sports: sport_id(name, slug, icon),leagues: league_id(name, slug),authors: author_id(display_name)&status=eq.${status}&order=is_featured.desc,published_at.desc&limit=${limit}`;
  
  if (sportId) {
    query += `&sport_id=eq.${sportId}`;
  }
  if (leagueId) {
    query += `&league_id=eq.${leagueId}`;
  }
  if (trending) {
    query += `&is_trending=eq.true`;
  }
  
  return apiCall(query);
}

/**
 * Fetch single article by slug
 */
async function getArticleBySlug(slug) {
  const data = await apiCall(`articles?select=*,sports: sport_id(name, slug, icon),leagues: league_id(name, slug),authors: author_id(display_name)&slug=eq.${slug}&status=eq.published&limit=1`);
  return data && data.length > 0 ? data[0] : null;
}

/**
 * Fetch live matches
 */
async function getLiveMatches(status = '') {
  let query = 'live_matches?select=*,sports: sport_id(name, icon),leagues: league_id(name)&order=match_date.desc,match_time.desc&limit=50';
  
  if (status) {
    query += `&status=eq.${status}`;
  }
  
  return apiCall(query);
}

/**
 * Fetch featured content
 */
async function getFeaturedContent() {
  return apiCall('featured_content?select=*,articles: article_id(title, slug, excerpt, featured_image_url, published_at)&is_active=eq.true&order=position.asc&limit=10');
}

/**
 * Fetch trending items
 */
async function getTrendingItems() {
  return apiCall('trending_items?select=*,articles: article_id(title, slug)&is_active=eq.true&order=position.asc&limit=10');
}

/**
 * Fetch navigation items
 */
async function getNavigation() {
  return apiCall('navigation?is_active=eq.true&order=sort_order.asc');
}

/**
 * Format date for display
 */
function formatDate(dateStr, format = 'short') {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  
  if (format === 'relative') {
    const now = new Date();
    const diff = now - date;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
  }
  
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

/**
 * Generate article card HTML
 */
function generateArticleCard(article, options = {}) {
  const { showExcerpt = true, size = 'normal' } = options;
  const sport = article.sports || {};
  const icon = sport.icon || '📰';
  const sportName = sport.name || 'News';
  const slug = article.slug || '';
  const excerpt = article.excerpt || '';
  const imageUrl = article.featured_image_url;
  
  const colorClass = `t${Math.abs((slug || 'a').charCodeAt(0)) % 5 + 1}`;
  
  return `
    <a href="news-detail.html?slug=${slug}" class="article-card">
      ${imageUrl 
        ? `<div class="card-img ${colorClass}" style="background-image: url('${imageUrl}'); background-size: cover;"></div>` 
        : `<div class="card-img ${colorClass}">${icon}</div>`
      }
      <div class="card-body">
        <span class="card-tag">${icon} ${sportName}</span>
        <h3 class="card-title">${article.title}</h3>
        ${showExcerpt ? `<p class="card-snippet">${excerpt.substring(0, 100)}${excerpt.length > 100 ? '...' : ''}</p>` : ''}
        <div class="card-meta">
          ${formatDate(article.published_at)} &nbsp;·&nbsp; ${article.read_time_minutes || 3} min read
        </div>
      </div>
    </a>
  `;
}

/**
 * Generate trending card HTML
 */
function generateTrendingCard(article, index = 1) {
  const sport = article.sports || {};
  const icon = sport.icon || '📰';
  
  return `
    <a href="news-detail.html?slug=${article.slug}" class="trending-card">
      <div class="trending-thumb t${index % 5 + 1}">${icon}</div>
      <span class="trending-card-title">${article.title}</span>
    </a>
  `;
}

/**
 * Generate hero slide HTML
 */
function generateHeroSlide(article, index = 0) {
  const sport = article.sports || {};
  const icon = sport.icon || '📰';
  const sportName = sport.name || 'News';
  const imageUrl = article.featured_image_url;
  
  return `
    <div class="slide ${index === 0 ? 'active' : ''}" style="${imageUrl 
      ? `background: linear-gradient(rgba(0,0,0,0.3), rgba(0,0,0,0.6)), url('${imageUrl}') center/cover no-repeat;` 
      : 'background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);'}">
      <div class="slide-content">
        <span class="slide-tag">${icon} ${sportName}</span>
        <h1 class="slide-title">${article.title}</h1>
        <p class="slide-excerpt">${article.excerpt || ''}</p>
        <a href="news-detail.html?slug=${article.slug}" class="slide-btn">Read More</a>
      </div>
    </div>
  `;
}

/**
 * Generate match card HTML
 */
function generateMatchCard(match) {
  const sport = match.sports || {};
  const icon = sport.icon || '🏟️';
  const league = match.leagues || {};
  const leagueName = league.name || sport.name || '';
  
  const statusClass = match.status === 'live' ? 'live' : match.status === 'finished' ? 'finished' : 'scheduled';
  const statusText = match.status === 'live' ? `LIVE ${match.minute_played || ''}` : 
                     match.status === 'finished' ? 'FT' : 
                     match.match_time ? match.match_time : formatDate(match.match_date);
  
  return `
    <div class="score-card">
      <div class="score-header">
        <span>${icon} ${leagueName}</span>
        <span class="score-status ${statusClass}">${statusText}</span>
      </div>
      <div class="score-teams">
        <span class="team-name">${match.team_a_name}</span>
        <span class="team-score">${match.team_a_score}</span>
      </div>
      <div class="score-teams">
        <span class="team-name">${match.team_b_name}</span>
        <span class="team-score">${match.team_b_score}</span>
      </div>
    </div>
  `;
}

/**
 * Load homepage articles
 */
async function loadHomepageArticles() {
  const articles = await getArticles({ limit: 12 });
  return articles || [];
}

/**
 * Increment article view count
 */
async function incrementViewCount(articleId) {
  // Fire and forget - don't await
  fetch(`${SUPABASE_URL}/rest/v1/rpc/increment_views`, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': 'Bearer ' + SUPABASE_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ article_id: articleId })
  }).catch(() => {});
}

// Export for global use
window.apiCall = apiCall;
window.clearCache = clearCache;
window.getSports = getSports;
window.getLeagues = getLeagues;
window.getArticles = getArticles;
window.getArticleBySlug = getArticleBySlug;
window.getLiveMatches = getLiveMatches;
window.getFeaturedContent = getFeaturedContent;
window.getTrendingItems = getTrendingItems;
window.getNavigation = getNavigation;
window.formatDate = formatDate;
window.generateArticleCard = generateArticleCard;
window.generateTrendingCard = generateTrendingCard;
window.generateHeroSlide = generateHeroSlide;
window.generateMatchCard = generateMatchCard;
window.loadHomepageArticles = loadHomepageArticles;
window.incrementViewCount = incrementViewCount;
