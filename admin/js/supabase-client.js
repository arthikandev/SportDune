let supabaseClient = null;
const getSupabase = () => {
    if (supabaseClient) return supabaseClient;
    const cfg = window.SPORTDUNE_ADMIN_CONFIG;
    if (!cfg || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY) {
        throw new Error('Supabase configuration missing. Check config.js.');
    }
    try {
        supabaseClient = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
        return supabaseClient;
    } catch (err) {
        throw new Error('Failed to initialize Supabase: ' + err.message);
    }
};
const supabase = getSupabase();
window.supabase = supabaseClient;
