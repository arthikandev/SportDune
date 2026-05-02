async function loadDashboard() {
    const content = $('#content');
    content.innerHTML = `
        <div class="stats-grid">
            <div class="stat-card"><div class="stat-icon blue">📝</div><div><div class="stat-value" id="stat-articles">—</div><div class="stat-label">Total Articles</div></div></div>
            <div class="stat-card"><div class="stat-icon green">✅</div><div><div class="stat-value" id="stat-published">—</div><div class="stat-label">Published</div></div></div>
            <div class="stat-card"><div class="stat-icon orange">📋</div><div><div class="stat-value" id="stat-drafts">—</div><div class="stat-label">Drafts</div></div></div>
            <div class="stat-card"><div class="stat-icon purple">⚽</div><div><div class="stat-value" id="stat-sports">—</div><div class="stat-label">Sports</div></div></div>
            <div class="stat-card"><div class="stat-icon red">🏆</div><div><div class="stat-value" id="stat-leagues">—</div><div class="stat-label">Leagues</div></div></div>
            <div class="stat-card"><div class="stat-icon blue">🔥</div><div><div class="stat-value" id="stat-trending">—</div><div class="stat-label">Trending</div></div></div>
            <div class="stat-card"><div class="stat-icon green">🖼️</div><div><div class="stat-value" id="stat-media">—</div><div class="stat-label">Media Assets</div></div></div>
        </div>
        <div class="card">
            <div class="card-header"><h3>Recent Activity</h3></div>
            <div class="card-body" id="recent-activity"><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;"></div></div>
        </div>`;
    try {
        const [articles, sports, leagues, trending, media] = await Promise.all([
            api.fetchAll('articles', { count: true }),
            api.fetchAll('sports', { count: true }),
            api.fetchAll('leagues', { count: true }),
            api.fetchAll('trending_items', { filter: { is_active: true }, count: true }),
            api.fetchAll('media_assets', { count: true })
        ]);
        $('#stat-articles').textContent = articles.count || 0;
        $('#stat-sports').textContent = sports.count || 0;
        $('#stat-leagues').textContent = leagues.count || 0;
        $('#stat-trending').textContent = trending.count || 0;
        $('#stat-media').textContent = media.count || 0;
        const pub = articles.data.filter(a => a.status === 'published').length;
        const dr = articles.data.filter(a => a.status === 'draft').length;
        $('#stat-published').textContent = pub;
        $('#stat-drafts').textContent = dr;
        const { data: logs } = await supabase.from('audit_logs').select('*, profiles(full_name)').order('created_at', { ascending: false }).limit(5);
        const activityEl = $('#recent-activity');
        if (logs?.length) {
            activityEl.innerHTML = `<table class="table"><thead><tr><th>Action</th><th>Entity</th><th>User</th><th>Date</th></tr></thead><tbody>${logs.map(l => `<tr><td><span class="badge badge-${l.action === 'INSERT' ? 'published' : l.action === 'UPDATE' ? 'scheduled' : 'archived'}">${l.action}</span></td><td class="truncate">${l.entity_type}${l.entity_id ? ' #' + l.entity_id.slice(0, 8) : ''}</td><td>${l.user_email || 'System'}</td><td class="text-sm text-muted">${formatDateTime(l.created_at)}</td></tr>`).join('')}</tbody></table>`;
        } else {
            activityEl.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📋</div><div class="empty-state-text">No recent activity</div></div>';
        }
    } catch (err) {
        console.error('Dashboard load error:', err);
        showToast('Failed to load dashboard stats', 'error');
    }
}
