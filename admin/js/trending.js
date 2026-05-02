async function loadTrending() {
    const content = $('#content');
    content.innerHTML = `
        <div class="flex-between mb-24"><h2>Trending Strip</h2><button class="btn btn-primary" id="add-trending-btn">+ Add Item</button></div>
        <div class="card"><div class="table-container" id="trending-table"><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;"></div></div></div>`;
    try {
        const { data } = await supabase.from('trending_items').select('*, articles(title), sports(emoji)').order('display_order');
        renderTrendingTable(data);
        $('#add-trending-btn').addEventListener('click', () => trendingFormModal());
    } catch (err) { $('#trending-table').innerHTML = `<p class="text-muted">Error: ${escapeHtml(err.message)}</p>`; }
}
function renderTrendingTable(items) {
    const c = $('#trending-table');
    if (!items?.length) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔥</div><div class="empty-state-text">No trending items</div></div>'; return; }
    c.innerHTML = `<table class="table"><thead><tr><th>Order</th><th>Article</th><th>Custom Title</th><th>Emoji</th><th>Status</th><th>Actions</th></tr></thead><tbody>${items.map(t => `<tr><td>${t.display_order}</td><td>${escapeHtml(t.articles?.title || '—')}</td><td>${escapeHtml(t.display_title || '—')}</td><td>${t.emoji || '—'}</td><td>${activeBadge(t.is_active)}</td><td><div class="table-actions"><button class="btn btn-ghost btn-sm" onclick="trendingFormModal('${t.id}')">✏️</button><button class="btn btn-ghost btn-sm" onclick="deleteTrending('${t.id}')">🗑️</button></div></td></tr>`).join('')}</tbody></table>`;
}
function trendingFormModal(id = null) {
    showModal(id ? 'Edit Trending' : 'Add Trending Item', `
        <form id="trending-form">
            <div class="form-group"><label class="form-label">Article *</label><select class="form-select" id="tf-article" required></select></div>
            <div class="form-group"><label class="form-label">Display Title (optional)</label><input class="form-input" id="tf-title" placeholder="Overrides article title"></div>
            <div class="form-group"><label class="form-label">Emoji</label><input class="form-input" id="tf-emoji" maxlength="4"></div>
            <div class="form-group"><label class="form-label">Display Order</label><input type="number" class="form-input" id="tf-order" value="0"></div>
            <div class="checkbox-group"><input type="checkbox" id="tf-active" checked><label for="tf-active">Active</label></div>
        </form>`, `<button class="btn btn-secondary" onclick="hideModal()">Cancel</button><button class="btn btn-primary" id="tf-save">${id ? 'Save' : 'Create'}</button>`);
    api.fetchAll('articles', { filter: { status: 'published' }, order: { column: 'published_at', ascending: false }, limit: 100 }).then(articles => {
        $('#tf-article').innerHTML = articles.map(a => `<option value="${a.id}">${escapeHtml(a.title)}</option>`).join('');
    });
    if (id) loadTrendingForm(id);
    $('#tf-save').addEventListener('click', async () => {
        try {
            const row = { article_id: $('#tf-article').value, display_title: $('#tf-title').value || null, emoji: $('#tf-emoji').value || null, display_order: parseInt($('#tf-order').value) || 0, is_active: $('#tf-active').checked };
            if (id) { await api.update('trending_items', id, row); } else { await api.insert('trending_items', row); }
            hideModal(); showToast('Saved'); loadTrending();
        } catch (err) { showToast('Failed: ' + err.message, 'error'); }
    });
}
async function loadTrendingForm(id) {
    const t = await api.fetchOne('trending_items', id);
    $('#tf-article').value = t.article_id;
    $('#tf-title').value = t.display_title || '';
    $('#tf-emoji').value = t.emoji || '';
    $('#tf-order').value = t.display_order;
    $('#tf-active').checked = t.is_active;
}
async function deleteTrending(id) {
    if (!await confirmAction('Remove this trending item?')) return;
    try { await api.remove('trending_items', id); showToast('Removed'); loadTrending(); }
    catch (err) { showToast('Failed: ' + err.message, 'error'); }
}
