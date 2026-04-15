/**
 * SportDune - Frontend Integration Guide
 * 
 * This file shows how to integrate Supabase with your existing
 * frontend pages. Follow these patterns to connect your static
 * HTML pages to the database.
 */

// ================================================
// INTEGRATION INSTRUCTIONS
// ================================================

/**
 * STEP 1: Add Supabase SDK to Your HTML
 * 
 * Add this script tag before the closing </body> tag in all pages:
 */
 /*
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script>
  // Your Supabase configuration
  const SUPABASE_URL = 'https://your-project.supabase.co';
  const SUPABASE_ANON_KEY = 'your-anon-key';
  
  const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
</script>
*/

/**
 * STEP 2: Example - Homepage Integration
 * 
 * Replace static article cards with dynamic content:
 */
async function loadHomepageArticles() {
  // Fetch featured articles
  const { data: featured } = await supabase
    .from('articles')
    .select('*, category:categories(name, slug, icon)')
    .eq('status', 'published')
    .eq('is_featured', true)
    .limit(6);

  // Fetch latest articles
  const { data: latest } = await supabase
    .from('articles')
    .select('*, category:categories(name, slug, icon)')
    .eq('status', 'published')
    .order('published_at', { ascending: false })
    .limit(10);

  // Fetch trending (most viewed)
  const { data: trending } = await supabase
    .from('articles')
    .select('*, category:categories(name, slug, icon)')
    .eq('status', 'published')
    .order('view_count', { ascending: false })
    .limit(5);

  // Render to DOM
  renderFeaturedSection(featured);
  renderLatestSection(latest);
  renderTrendingSection(trending);
}

/**
 * STEP 3: Example - Category Page Integration
 */
async function loadCategoryArticles(categorySlug) {
  // Get category ID from slug
  const { data: category } = await supabase
    .from('categories')
    .select('id, name')
    .eq('slug', categorySlug)
    .single();

  if (!category) {
    console.error('Category not found');
    return;
  }

  // Get articles for this category
  const { data: articles } = await supabase
    .from('articles')
    .select('*, author:profiles(full_name)')
    .eq('category_id', category.id)
    .eq('status', 'published')
    .order('published_at', { ascending: false });

  // Update page title
  document.title = `${category.name} News - SportDune`;

  // Render articles
  renderArticleGrid(articles);
}

/**
 * STEP 4: Example - Article Detail Integration
 */
async function loadArticle(slug) {
  const { data: article } = await supabase
    .from('articles')
    .select(`
      *,
      category:categories(name, slug, icon),
      author:profiles(full_name, avatar_url, bio)
    `)
    .eq('slug', slug)
    .eq('status', 'published')
    .single();

  if (!article) {
    // Article not found - show 404
    window.location.href = '/404.html';
    return;
  }

  // Track page view
  await supabase.from('page_views').insert({
    page_url: window.location.href,
    page_type: 'article',
    article_id: article.id,
    category_id: article.category_id
  });

  // Render article content
  document.getElementById('articleTitle').textContent = article.title;
  document.getElementById('articleContent').innerHTML = article.content;
  document.getElementById('articleMeta').innerHTML = `
    <span>By ${article.author?.full_name || 'SportDune Staff'}</span>
    <span>•</span>
    <span>${article.category?.name || 'Sports'}</span>
    <span>•</span>
    <span>${new Date(article.published_at).toLocaleDateString()}</span>
  `;

  // Update meta tags for SEO
  document.title = article.meta_title || `${article.title} - SportDune`;
  document.querySelector('meta[name="description"]').content = article.meta_description || article.excerpt;
}

/**
 * STEP 5: Example - Search Integration
 */
async function searchArticles(query) {
  if (!query || query.length < 2) return;

  const { data: results } = await supabase
    .from('articles')
    .select('*, category:categories(name, slug)')
    .eq('status', 'published')
    .or(`title.ilike.%${query}%,excerpt.ilike.%${query}%,content.ilike.%${query}%`)
    .order('published_at', { ascending: false })
    .limit(20);

  renderSearchResults(results);
}

/**
 * STEP 6: Example - Live Scores Integration
 */
async function loadLiveScores() {
  const { data: matches } = await supabase
    .from('live_matches')
    .select('*')
    .order('match_date', { ascending: true });

  renderLiveScores(matches);

  // Subscribe to real-time updates
  supabase
    .channel('live_scores')
    .on('postgres_changes', {
      event: '*',
      schema: 'public',
      table: 'live_matches'
    }, (payload) => {
      // Update scores in real-time
      updateMatchScore(payload.new);
    })
    .subscribe();
}

// ================================================
// UTILITY FUNCTIONS
// ================================================

function renderArticleCard(article) {
  const date = article.published_at 
    ? new Date(article.published_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    : 'Draft';

  return `
    <a href="/news-detail.html?slug=${article.slug}" class="article-card">
      <div class="card-img ${article.category?.slug || 't1'}">
        ${article.featured_image_url 
          ? `<img src="${article.featured_image_url}" alt="${article.title}">`
          : '📰'
        }
      </div>
      <div class="card-body">
        <span class="card-tag">${article.category?.name || 'Sports'} ${article.type ? '· ' + article.type : ''}</span>
        <h3 class="card-title">${article.title}</h3>
        ${article.excerpt ? `<p class="card-snippet">${article.excerpt}</p>` : ''}
        <div class="card-meta">${date} ${article.view_count ? '· ' + article.view_count.toLocaleString() + ' views' : ''}</div>
      </div>
    </a>
  `;
}

function renderFeaturedSection(articles) {
  const container = document.getElementById('featuredGrid');
  if (!container) return;
  
  container.innerHTML = articles.map(renderArticleCard).join('');
}

function renderLatestSection(articles) {
  const container = document.getElementById('latestGrid');
  if (!container) return;
  
  container.innerHTML = articles.map(renderArticleCard).join('');
}

// ================================================
// INITIALIZATION
// ================================================

document.addEventListener('DOMContentLoaded', () => {
  // Detect current page and load appropriate data
  const path = window.location.pathname;
  
  if (path.includes('sports-homepage') || path === '/' || path === '/index.html') {
    loadHomepageArticles();
  } else if (path.includes('news-detail')) {
    const params = new URLSearchParams(window.location.search);
    const slug = params.get('slug');
    if (slug) loadArticle(slug);
  } else if (path.includes('search')) {
    // Search page already has its own logic
  } else if (path.includes('live')) {
    loadLiveScores();
  } else {
    // Category pages - extract category from URL
    const categorySlug = path.replace('.html', '').replace('/', '');
    loadCategoryArticles(categorySlug);
  }
});
