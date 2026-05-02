const pages = {
    dashboard: { title: 'Dashboard', load: loadDashboard },
    articles: { title: 'Articles', load: loadArticles },
    'article-new': { title: 'New Article', load: () => loadArticleEditor() },
    'article-edit': { title: 'Edit Article', load: () => loadArticleEditor(window._editId) },
    sports: { title: 'Sports', load: loadSports },
    leagues: { title: 'Leagues', load: loadLeagues },
    trending: { title: 'Trending', load: loadTrending },
    homepage: { title: 'Homepage', load: loadHomepage },
    media: { title: 'Media Library', load: loadMedia },
    users: { title: 'Users', load: loadUsers },
    settings: { title: 'Settings', load: loadSettings },
    audit: { title: 'Audit Logs', load: loadAudit }
};
const initRouter = () => {
    const handleRoute = () => {
        const hash = location.hash.slice(1) || 'dashboard';
        const [page, ...rest] = hash.split('/');
        const pageInfo = pages[page];
        if (!pageInfo) { location.hash = '#dashboard'; return; }
        if (rest[0]) window._editId = rest[0];
        $('#page-title').textContent = pageInfo.title;
        $$('.nav-item').forEach(n => n.classList.toggle('active', n.dataset.page === page));
        $('#sidebar')?.classList.remove('open');
        pageInfo.load().catch(err => {
            $('#content').innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Failed to load ${pageInfo.title.toLowerCase()}</div><p class="text-muted">${escapeHtml(err.message)}</p><button class="btn btn-primary mt-16" onclick="location.reload()">Retry</button></div>`;
        });
    };
    window.addEventListener('hashchange', handleRoute);
    handleRoute();
};
