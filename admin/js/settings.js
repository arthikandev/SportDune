async function loadSettings() {
    if (!checkRole('admin')) { $('#content').innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔒</div><div class="empty-state-text">Admin access required</div></div>'; return; }
    const content = $('#content');
    content.innerHTML = '<div class="skeleton" style="height:400px;"></div>';
    try {
        const settings = await api.fetchAll('site_settings', { order: { column: 'group_name' } });
        const grouped = {};
        settings.forEach(s => { if (!grouped[s.group_name]) grouped[s.group_name] = []; grouped[s.group_name].push(s); });
        content.innerHTML = `
            <div class="flex-between mb-24"><h2>Site Settings</h2></div>
            <form id="settings-form">
                ${Object.entries(grouped).map(([group, items]) => `
                    <div class="card mb-24">
                        <div class="card-header"><h3>${group.charAt(0).toUpperCase() + group.slice(1)}</h3></div>
                        <div class="card-body">
                            ${items.map(s => {
                                const val = typeof s.value === 'string' ? s.value.replace(/^"|"$/g, '') : JSON.stringify(s.value);
                                return `<div class="form-group"><label class="form-label">${escapeHtml(s.description || s.key)}</label><input type="text" class="form-input setting-input" data-key="${s.key}" value="${escapeHtml(val)}"></div>`;
                            }).join('')}
                        </div>
                    </div>`).join('')}
                <button type="submit" class="btn btn-primary">Save Settings</button>
            </form>`;
        $('#settings-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = e.target.querySelector('button[type="submit"]');
            btn.disabled = true;
            btn.textContent = 'Saving...';
            try {
                for (const input of $$('.setting-input')) {
                    await api.update('site_settings', input.dataset.key, { value: JSON.stringify(input.value) });
                }
                await api.logAudit('UPDATE', 'site_settings', null, null, null, 'Updated site settings');
                showToast('Settings saved');
            } catch (err) { showToast('Failed: ' + err.message, 'error'); }
            finally { btn.disabled = false; btn.textContent = 'Save Settings'; }
        });
    } catch (err) {
        content.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Failed to load settings</div><p class="text-muted">${escapeHtml(err.message)}</p></div>`;
    }
}
