async function loadSports() {
    const content = $('#content');
    content.innerHTML = `
        <div class="flex-between mb-24"><h2>Manage Sports</h2><button class="btn btn-primary" id="add-sport-btn">+ Add Sport</button></div>
        <div class="card"><div class="table-container" id="sports-table"><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;"></div></div></div>`;
    try {
        const sports = await api.fetchAll('sports', { order: { column: 'nav_order' } });
        renderSportsTable(sports);
        $('#add-sport-btn').addEventListener('click', () => sportFormModal());
    } catch (err) { $('#sports-table').innerHTML = `<p class="text-muted">Error: ${escapeHtml(err.message)}</p>`; }
}
function renderSportsTable(sports) {
    const c = $('#sports-table');
    if (!sports?.length) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚽</div><div class="empty-state-text">No sports added</div></div>'; return; }
    c.innerHTML = `<table class="table"><thead><tr><th>Emoji</th><th>Name</th><th>Slug</th><th>Nav Order</th><th>Status</th><th>Actions</th></tr></thead><tbody>${sports.map(s => `<tr><td>${s.emoji || '—'}</td><td><strong>${escapeHtml(s.name)}</strong></td><td class="text-sm text-muted">${s.slug}</td><td>${s.nav_order}</td><td>${activeBadge(s.is_active)}</td><td><div class="table-actions"><button class="btn btn-ghost btn-sm" onclick="sportFormModal('${s.id}')">✏️</button><button class="btn btn-ghost btn-sm" onclick="deleteSport('${s.id}','${escapeHtml(s.name)}')">🗑️</button></div></td></tr>`).join('')}</tbody></table>`;
}
function sportFormModal(id = null) {
    showModal(id ? 'Edit Sport' : 'Add Sport', `
        <form id="sport-form">
            <div class="form-group"><label class="form-label">Name *</label><input class="form-input" id="sf-name" required></div>
            <div class="form-group"><label class="form-label">Slug</label><input class="form-input" id="sf-slug"></div>
            <div class="form-group"><label class="form-label">Emoji</label><input class="form-input" id="sf-emoji" maxlength="4"></div>
            <div class="form-group"><label class="form-label">Banner Title</label><input class="form-input" id="sf-banner-title"></div>
            <div class="form-group"><label class="form-label">Banner Subtitle</label><input class="form-input" id="sf-banner-subtitle"></div>
            <div class="form-group"><label class="form-label">Banner Gradient</label><input class="form-input" id="sf-gradient" placeholder="linear-gradient(...)"></div>
            <div class="form-group"><label class="form-label">Nav Order</label><input type="number" class="form-input" id="sf-order" value="0"></div>
            <div class="checkbox-group"><input type="checkbox" id="sf-nav" checked><label for="sf-nav">Show in Nav</label></div>
            <div class="checkbox-group mt-16"><input type="checkbox" id="sf-more"><label for="sf-more">Show in More</label></div>
        </form>`, `<button class="btn btn-secondary" onclick="hideModal()">Cancel</button><button class="btn btn-primary" id="sf-save">${id ? 'Save' : 'Create'}</button>`);
    $('#sf-name').addEventListener('input', (e) => { if (!$('#sf-slug').dataset.manual) $('#sf-slug').value = slugify(e.target.value); });
    $('#sf-slug').addEventListener('input', () => { $('#sf-slug').dataset.manual = '1'; });
    if (id) loadSportForm(id);
    $('#sf-save').addEventListener('click', async () => {
        try {
            const row = { name: $('#sf-name').value, slug: $('#sf-slug').value || slugify($('#sf-name').value), emoji: $('#sf-emoji').value, banner_title: $('#sf-banner-title').value, banner_subtitle: $('#sf-banner-subtitle').value, banner_gradient: $('#sf-gradient').value, nav_order: parseInt($('#sf-order').value) || 0, show_in_nav: $('#sf-nav').checked, show_in_more: $('#sf-more').checked, is_active: true };
            if (id) { await api.update('sports', id, row); await api.logAudit('UPDATE', 'sports', id, null, row, `Updated sport: ${row.name}`); }
            else { await api.insert('sports', row); await api.logAudit('INSERT', 'sports', null, null, row, `Created sport: ${row.name}`); }
            hideModal(); showToast(id ? 'Sport updated' : 'Sport created'); loadSports();
        } catch (err) { showToast('Failed: ' + err.message, 'error'); }
    });
}
async function loadSportForm(id) {
    const s = await api.fetchOne('sports', id);
    $('#sf-name').value = s.name || '';
    $('#sf-slug').value = s.slug || '';
    $('#sf-emoji').value = s.emoji || '';
    $('#sf-banner-title').value = s.banner_title || '';
    $('#sf-banner-subtitle').value = s.banner_subtitle || '';
    $('#sf-gradient').value = s.banner_gradient || '';
    $('#sf-order').value = s.nav_order || 0;
    $('#sf-nav').checked = s.show_in_nav;
    $('#sf-more').checked = s.show_in_more;
}
async function deleteSport(id, name) {
    if (!await confirmAction(`Delete "${name}" and all its leagues?`)) return;
    try { await api.remove('sports', id); await api.logAudit('DELETE', 'sports', id, null, null, `Deleted sport: ${name}`); showToast('Sport deleted'); loadSports(); }
    catch (err) { showToast('Failed: ' + err.message, 'error'); }
}
