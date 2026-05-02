async function loadHomepage() {
    const content = $('#content');
    content.innerHTML = '<div class="skeleton" style="height:300px;"></div>';
    try {
        const [sections, articles, sports] = await Promise.all([
            api.fetchAll('homepage_sections', { order: { column: 'display_order' } }),
            api.fetchAll('articles', { filter: { status: 'published' }, order: { column: 'published_at', ascending: false }, limit: 200 }),
            api.fetchAll('sports', { order: { column: 'nav_order' } })
        ]);
        content.innerHTML = `
            <div class="flex-between mb-24"><h2>Homepage Sections</h2></div>
            <div id="homepage-sections">${sections.map(s => {
                const selected = s.article_ids || [];
                const articleOptions = articles.map(a => `<option value="${a.id}" ${selected.includes(a.id) ? 'selected' : ''}>${escapeHtml(a.title)}</option>`).join('');
                const sportFilter = s.sport_id ? `<p class="text-sm text-muted">Sport: ${(sports.find(sp => sp.id === s.sport_id))?.name || '—'}</p>` : '';
                return `<div class="card mb-16"><div class="card-header"><h3>${escapeHtml(s.title || s.section_key)}</h3><label class="checkbox-group"><input type="checkbox" class="section-visible" data-id="${s.id}" ${s.is_visible ? 'checked' : ''}><label>Visible</label></label></div><div class="card-body"><div class="form-group"><label class="form-label">Articles (select multiple)</label><select class="form-select" multiple size="5" data-section="${s.id}">${articleOptions}</select><p class="text-sm text-muted">Hold Ctrl/Cmd to select multiple</p></div>${sportFilter}</div></div>`;
            }).join('')}</div>
            <button class="btn btn-primary" id="save-homepage">Save Homepage</button>`;
        $('#save-homepage').addEventListener('click', async () => {
            try {
                for (const section of sections) {
                    const select = $(`select[data-section="${section.id}"]`);
                    const checkbox = $(`.section-visible[data-id="${section.id}"]`);
                    const ids = [...select.selectedOptions].map(o => o.value);
                    await api.update('homepage_sections', section.id, { article_ids: ids, is_visible: checkbox.checked });
                }
                await api.logAudit('UPDATE', 'homepage_sections', null, null, null, 'Updated homepage sections');
                showToast('Homepage saved');
            } catch (err) { showToast('Failed: ' + err.message, 'error'); }
        });
    } catch (err) {
        content.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Failed to load homepage config</div><p class="text-muted">${escapeHtml(err.message)}</p></div>`;
    }
}
