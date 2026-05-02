async function loadArticles() {
    const content = $('#content');
    content.innerHTML = `
        <div class="flex-between mb-24">
            <div class="filters">
                <input type="text" class="filter-input" id="article-search" placeholder="Search articles...">
                <select class="filter-input" id="article-sport-filter"><option value="">All Sports</option></select>
                <select class="filter-input" id="article-status-filter"><option value="">All Status</option><option value="published">Published</option><option value="draft">Draft</option><option value="scheduled">Scheduled</option><option value="archived">Archived</option></select>
            </div>
            <button class="btn btn-primary" onclick="location.hash='#article-new'">+ New Article</button>
        </div>
        <div class="card"><div class="table-container" id="articles-table"><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;"></div></div></div>`;
    try {
        const [articles, sports] = await Promise.all([
            api.searchArticles('', { limit: 100 }),
            api.fetchAll('sports', { order: { column: 'nav_order' } })
        ]);
        const sportSelect = $('#article-sport-filter');
        sports.forEach(s => { sportSelect.innerHTML += `<option value="${s.id}">${s.emoji} ${s.name}</option>`; });
        renderArticleTable(articles);
        const search = debounce(async () => {
            const q = $('#article-search').value;
            const sport = $('#article-sport-filter').value;
            const status = $('#article-status-filter').value;
            const results = await api.searchArticles(q, { sport_id: sport || undefined, status: status || undefined, limit: 100 });
            renderArticleTable(results);
        }, 300);
        $('#article-search').addEventListener('input', search);
        $('#article-sport-filter').addEventListener('change', search);
        $('#article-status-filter').addEventListener('change', search);
    } catch (err) {
        $('#articles-table').innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Failed to load articles</div><p class="text-muted">${escapeHtml(err.message)}</p></div>`;
    }
}
function renderArticleTable(articles) {
    const container = $('#articles-table');
    if (!articles?.length) { container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📝</div><div class="empty-state-text">No articles found</div></div>'; return; }
    container.innerHTML = `<table class="table"><thead><tr><th>Title</th><th>Sport</th><th>Status</th><th>Author</th><th>Date</th><th>Actions</th></tr></thead><tbody>${articles.map(a => `<tr><td><div class="truncate"><strong>${escapeHtml(a.title)}</strong>${a.is_breaking ? ' <span class="badge badge-breaking">Breaking</span>' : ''}${a.is_featured ? ' <span class="badge badge-featured">Featured</span>' : ''}</div></td><td>${a.sports?.emoji || ''} ${escapeHtml(a.sports?.name || '—')}</td><td>${statusBadge(a.status)}</td><td>${escapeHtml(a.authors?.display_name || '—')}</td><td class="text-sm text-muted">${formatDate(a.created_at)}</td><td><div class="table-actions"><button class="btn btn-ghost btn-sm" onclick="location.hash='#article-edit/${a.id}'">✏️</button><button class="btn btn-ghost btn-sm" onclick="duplicateArticle('${a.id}')">📋</button><button class="btn btn-ghost btn-sm" onclick="deleteArticle('${a.id}','${escapeHtml(a.title)}')">🗑️</button></div></td></tr>`).join('')}</tbody></table>`;
}
async function duplicateArticle(id) {
    try {
        const orig = await api.fetchOne('articles', id);
        const { id: _, created_at, updated_at, ...row } = orig;
        row.title = row.title + ' (Copy)';
        row.slug = slugify(row.title) + '-' + Date.now().toString(36);
        row.status = 'draft';
        await api.insert('articles', row);
        showToast('Article duplicated');
        loadArticles();
    } catch (err) { showToast('Failed to duplicate: ' + err.message, 'error'); }
}
async function deleteArticle(id, title) {
    if (!await confirmAction(`Delete "${title}"? This cannot be undone.`)) return;
    try { await api.remove('articles', id); await api.logAudit('DELETE', 'articles', id, null, null, `Deleted article: ${title}`); showToast('Article deleted'); loadArticles(); }
    catch (err) { showToast('Failed to delete: ' + err.message, 'error'); }
}
