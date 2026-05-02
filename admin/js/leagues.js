async function loadLeagues() {
    const content = $('#content');
    content.innerHTML = `
        <div class="flex-between mb-24"><h2>Manage Leagues</h2><button class="btn btn-primary" id="add-league-btn">+ Add League</button></div>
        <div class="card"><div class="table-container" id="leagues-table"><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;"></div></div></div>`;
    try {
        const { data } = await supabase.from('leagues').select('*, sports(name, emoji)').order('display_order');
        renderLeaguesTable(data);
        $('#add-league-btn').addEventListener('click', () => leagueFormModal());
    } catch (err) { $('#leagues-table').innerHTML = `<p class="text-muted">Error: ${escapeHtml(err.message)}</p>`; }
}
function renderLeaguesTable(leagues) {
    const c = $('#leagues-table');
    if (!leagues?.length) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏆</div><div class="empty-state-text">No leagues added</div></div>'; return; }
    c.innerHTML = `<table class="table"><thead><tr><th>Sport</th><th>Name</th><th>Slug</th><th>Order</th><th>Status</th><th>Actions</th></tr></thead><tbody>${leagues.map(l => `<tr><td>${l.sports?.emoji || ''} ${escapeHtml(l.sports?.name || '—')}</td><td><strong>${escapeHtml(l.name)}</strong></td><td class="text-sm text-muted">${l.slug}</td><td>${l.display_order}</td><td>${activeBadge(l.is_active)}</td><td><div class="table-actions"><button class="btn btn-ghost btn-sm" onclick="leagueFormModal('${l.id}')">✏️</button><button class="btn btn-ghost btn-sm" onclick="deleteLeague('${l.id}','${escapeHtml(l.name)}')">🗑️</button></div></td></tr>`).join('')}</tbody></table>`;
}
function leagueFormModal(id = null) {
    showModal(id ? 'Edit League' : 'Add League', `
        <form id="league-form">
            <div class="form-group"><label class="form-label">Sport *</label><select class="form-select" id="lf-sport" required></select></div>
            <div class="form-group"><label class="form-label">Name *</label><input class="form-input" id="lf-name" required></div>
            <div class="form-group"><label class="form-label">Slug</label><input class="form-input" id="lf-slug"></div>
            <div class="form-group"><label class="form-label">Description</label><textarea class="form-textarea" id="lf-desc" rows="2"></textarea></div>
            <div class="form-group"><label class="form-label">Display Order</label><input type="number" class="form-input" id="lf-order" value="0"></div>
        </form>`, `<button class="btn btn-secondary" onclick="hideModal()">Cancel</button><button class="btn btn-primary" id="lf-save">${id ? 'Save' : 'Create'}</button>`);
    api.fetchAll('sports', { order: { column: 'nav_order' } }).then(sports => {
        $('#lf-sport').innerHTML = sports.map(s => `<option value="${s.id}">${s.emoji} ${s.name}</option>`).join('');
    });
    $('#lf-name').addEventListener('input', (e) => { if (!$('#lf-slug').dataset.manual) $('#lf-slug').value = slugify(e.target.value); });
    $('#lf-slug').addEventListener('input', () => { $('#lf-slug').dataset.manual = '1'; });
    if (id) loadLeagueForm(id);
    $('#lf-save').addEventListener('click', async () => {
        try {
            const row = { sport_id: $('#lf-sport').value, name: $('#lf-name').value, slug: $('#lf-slug').value || slugify($('#lf-name').value), description: $('#lf-desc').value, display_order: parseInt($('#lf-order').value) || 0, is_active: true };
            if (id) { await api.update('leagues', id, row); } else { await api.insert('leagues', row); }
            hideModal(); showToast(id ? 'League updated' : 'League created'); loadLeagues();
        } catch (err) { showToast('Failed: ' + err.message, 'error'); }
    });
}
async function loadLeagueForm(id) {
    const l = await api.fetchOne('leagues', id);
    $('#lf-sport').value = l.sport_id;
    $('#lf-name').value = l.name;
    $('#lf-slug').value = l.slug;
    $('#lf-desc').value = l.description || '';
    $('#lf-order').value = l.display_order;
}
async function deleteLeague(id, name) {
    if (!await confirmAction(`Delete "${name}"?`)) return;
    try { await api.remove('leagues', id); showToast('League deleted'); loadLeagues(); }
    catch (err) { showToast('Failed: ' + err.message, 'error'); }
}
