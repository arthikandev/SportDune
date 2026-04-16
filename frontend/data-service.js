// SportDune - Data Service
const SUPABASE_URL = 'https://pvmtcwqupalurwqlvdxy.supabase.co';
const SUPABASE_KEY = 'sb_publishable_fuqgloaY9Hi7mHi0HsH8DQ_fjvXS_E6';

async function apiCall(endpoint, options = {}) {
  const headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': 'Bearer ' + SUPABASE_KEY,
    'Content-Type': 'application/json',
    ...options.headers
  };
  
  const response = await fetch(SUPABASE_URL + '/rest/v1/' + endpoint, {
    ...options,
    headers
  });
  
  return response.json();
}

// Fetch articles from Supabase
async function getArticles(options = {}) {
  const { category = '', limit = 10, status = 'published' } = options;
  
  let query = `articles?select=*,categories:category_id(name,slug,icon),profiles:author_id(full_name)&status=eq.${status}&order=published_at.desc&limit=${limit}`;
  
  if (category) {
    query += `&category_id=eq.${category}`;
  }
  
  return apiCall(query);
}

// Fetch categories
async function getCategories() {
  return apiCall('categories?select=*&order=name.asc');
}

// Fetch single article by slug
async function getArticleBySlug(slug) {
  const data = await apiCall(`articles?select=*,categories:category_id(name,slug,icon),profiles:author_id(full_name)&slug=eq.${slug}&status=eq.published&limit=1`);
  return data[0] || null;
}

// Format date
function formatDate(dateStr) {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

// Generate article card HTML
function generateArticleCard(article, options = {}) {
  const { showExcerpt = true, size = 'normal' } = options;
  const category = article.categories || {};
  const icon = category.icon || '📰';
  const categoryName = category.name || 'News';
  const slug = article.slug || '';
  const excerpt = article.excerpt || article.content?.substring(0, 120) + '...' || '';
  
  return `
    <a href="news-detail.html?slug=${slug}" class="article-card">
      <div class="card-img t${Math.abs(slug.charCodeAt(0)) % 5 + 1}">${icon}</div>
      <div class="card-body">
        <span class="card-tag">${categoryName}</span>
        <h3 class="card-title">${article.title}</h3>
        ${showExcerpt ? `<p class="card-snippet">${excerpt}</p>` : ''}
        <div class="card-meta">
          ${formatDate(article.published_at)} &nbsp;·&nbsp; ${article.read_time || 3} min read
        </div>
      </div>
    </a>
  `;
}

// Generate trending card HTML
function generateTrendingCard(article) {
  const category = article.categories || {};
  const icon = category.icon || '📰';
  
  return `
    <a href="news-detail.html?slug=${article.slug}" class="trending-card">
      <div class="trending-thumb t${Math.abs(article.slug.charCodeAt(0)) % 5 + 1}">${icon}</div>
      <span class="trending-card-title">${article.title}</span>
    </a>
  `;
}

// Generate hero slide HTML
function generateHeroSlide(article, index) {
  const category = article.categories || {};
  const icon = category.icon || '📰';
  
  return `
    <div class="slide ${index === 0 ? 'active' : ''}" style="background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);">
      <div class="slide-content">
        <span class="slide-tag">${category.icon || ''} ${category.name || 'News'}</span>
        <h1 class="slide-title">${article.title}</h1>
        <p class="slide-excerpt">${article.excerpt || ''}</p>
        <a href="news-detail.html?slug=${article.slug}" class="slide-btn">Read More</a>
      </div>
    </div>
  `;
}

// Load homepage articles
async function loadHomepageArticles() {
  const articles = await getArticles({ limit: 12 });
  
  if (!articles || articles.length === 0) {
    return []; // Return empty array, demo data will show
  }
  
  return articles;
}
