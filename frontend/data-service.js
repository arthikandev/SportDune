const SportDuneData = (() => {
    let _supabase = null;
    const _cache = new Map();
    const _CACHE_TTL = 5 * 60 * 1000;

    function getSupabase() {
        if (_supabase) return _supabase;
        const cfg = window.SPORTDUNE_CONFIG || {
            SUPABASE_URL: 'https://wivrhymyyipwwppmvmif.supabase.co',
            SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndpdnJoeW15eWlwd3dwcG12bWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5ODM1MDcsImV4cCI6MjA2MTU1OTUwN30.X7b2hYvZqKp5vXq3xqF7YqZqKp5vXq3xqF7YqZqKp5v'
        };
        _supabase = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
        return _supabase;
    }

    function cache(key, data) { _cache.set(key, { data, ts: Date.now() }); return data; }
    function getCached(key) {
        const entry = _cache.get(key);
        if (entry && Date.now() - entry.ts < _CACHE_TTL) return entry.data;
        return null;
    }

    async function fetchSports() {
        const cached = getCached('sports');
        if (cached) return cached;
        const { data, error } = await getSupabase().from('sports').select('*').eq('is_active', true).order('nav_order');
        if (error) { console.error('fetchSports:', error); return []; }
        return cache('sports', data);
    }

    async function fetchLeagues(sportId = null) {
        const key = 'leagues' + (sportId || '');
        const cached = getCached(key);
        if (cached) return cached;
        let q = getSupabase().from('leagues').select('*, sports(name)').eq('is_active', true).order('display_order');
        if (sportId) q = q.eq('sport_id', sportId);
        const { data, error } = await q;
        if (error) { console.error('fetchLeagues:', error); return []; }
        return cache(key, data);
    }

    async function fetchArticles(opts = {}) {
        const { sportId, limit = 20, status = 'published' } = opts;
        const key = `articles-${sportId || 'all'}-${limit}-${status}`;
        const cached = getCached(key);
        if (cached) return cached;
        let q = getSupabase().from('articles').select('*, authors(display_name), sports(name, emoji), leagues(name)').eq('status', status).order('published_at', { ascending: false }).limit(limit);
        if (sportId) q = q.eq('sport_id', sportId);
        const { data, error } = await q;
        if (error) { console.error('fetchArticles:', error); return []; }
        return cache(key, data);
    }

    async function fetchArticleBySlug(slug) {
        const cached = getCached('article-' + slug);
        if (cached) return cached;
        const { data, error } = await getSupabase().from('articles').select('*, authors(display_name), sports(name, emoji), leagues(name)').eq('slug', slug).eq('status', 'published').single();
        if (error) { console.error('fetchArticleBySlug:', error); return null; }
        return cache('article-' + slug, data);
    }

    async function fetchTrending() {
        const cached = getCached('trending');
        if (cached) return cached;
        const { data, error } = await getSupabase().from('trending_items').select('*, articles(title, slug, cover_image_url, cover_emoji), sports(emoji)').eq('is_active', true).order('display_order');
        if (error) { console.error('fetchTrending:', error); return []; }
        return cache('trending', data);
    }

    async function fetchHomepageSections() {
        const cached = getCached('homepage');
        if (cached) return cached;
        const { data, error } = await getSupabase().from('homepage_sections').select('*').eq('is_visible', true).order('display_order');
        if (error) { console.error('fetchHomepageSections:', error); return []; }
        return cache('homepage', data);
    }

    async function fetchSettings() {
        const cached = getCached('settings');
        if (cached) return cached;
        const { data, error } = await getSupabase().from('site_settings').select('*').eq('is_public', true);
        if (error) { console.error('fetchSettings:', error); return {}; }
        const settings = {};
        data.forEach(s => { settings[s.key] = s.value; });
        return cache('settings', settings);
    }

    async function fetchMedia(sportId = null) {
        let q = getSupabase().from('media_assets').select('*').order('created_at', { ascending: false }).limit(50);
        if (sportId) q = q.eq('sport_id', sportId);
        const { data, error } = await q;
        if (error) { console.error('fetchMedia:', error); return []; }
        return data;
    }

    async function searchArticles(query, limit = 20) {
        const { data, error } = await getSupabase().from('articles').select('*, authors(display_name), sports(name, emoji), leagues(name)').eq('status', 'published').ilike('title', `%${query}%`).order('published_at', { ascending: false }).limit(limit);
        if (error) { console.error('searchArticles:', error); return []; }
        return data;
    }

    return { fetchSports, fetchLeagues, fetchArticles, fetchArticleBySlug, fetchTrending, fetchHomepageSections, fetchSettings, fetchMedia, searchArticles };
})();
