(function() {
    try {
        var cfg = window.SPORTDUNE_ADMIN_CONFIG;
        if (!cfg || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY) {
            throw new Error('Supabase config missing in index.html');
        }
        var lib = window.supabase;
        if (!lib) {
            throw new Error('Supabase CDN script failed to load');
        }
        if (typeof lib.createClient !== 'function') {
            throw new Error('Supabase CDN loaded but createClient not found');
        }
        window.supabase = lib.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
        window.supabaseClient = window.supabase;
    } catch (e) {
        console.error('[Supabase Init Error]', e.message);
        window.supabase = null;
        window.__supabaseInitError = e.message;
        var ls = document.getElementById('loading-screen');
        var es = document.getElementById('error-screen');
        if (ls) ls.style.display = 'none';
        if (es) {
            es.style.display = 'flex';
            var msgEl = document.getElementById('error-message');
            var detEl = document.getElementById('error-details');
            if (msgEl) msgEl.textContent = 'Supabase connection failed';
            if (detEl) detEl.textContent = e.message;
        }
    }
})();
