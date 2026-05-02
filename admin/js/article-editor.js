async function loadArticleEditor(id = null) {
    const content = $('#content');
    content.innerHTML = '<div class="skeleton" style="height:400px;"></div>';
    try {
        const [sports, leagues, authors, tags] = await Promise.all([
            api.fetchAll('sports', { order: { column: 'nav_order' } }),
            api.fetchAll('leagues', { order: { column: 'display_order' } }),
            api.fetchAll('authors', { filter: { is_active: true } }),
            api.fetchAll('tags', { order: { column: 'name' } })
        ]);
        let article = null;
        if (id) { article = await api.fetchOne('articles', id); $('#page-title').textContent = 'Edit Article'; }
        const sportOptions = sports.map(s => `<option value="${s.id}" ${article?.sport_id === s.id ? 'selected' : ''}>${s.emoji} ${s.name}</option>`).join('');
        const leagueOptions = `<option value="">None</option>` + leagues.map(l => `<option value="${l.id}" ${article?.league_id === l.id ? 'selected' : ''}>${l.name}</option>`).join('');
        const authorOptions = `<option value="">None</option>` + authors.map(a => `<option value="${a.id}" ${article?.author_id === a.id ? 'selected' : ''}>${a.display_name}</option>`).join('');
        const tagCheckboxes = tags.map(t => `<label class="checkbox-group"><input type="checkbox" value="${t.id}" ${article?.article_tags?.some(at => at.tag_id === t.id) ? 'checked' : ''}> ${escapeHtml(t.name)}</label>`).join('');
        content.innerHTML = `
            <form id="article-form">
                <div class="editor-grid">
                    <div class="card"><div class="card-body">
                        <div class="form-group"><label class="form-label">Title *</label><input type="text" class="form-input" id="f-title" value="${escapeHtml(article?.title || '')}" required></div>
                        <div class="form-group"><label class="form-label">Slug</label><input type="text" class="form-input" id="f-slug" value="${escapeHtml(article?.slug || '')}"><p class="text-sm text-muted">Auto-generated from title if empty</p></div>
                        <div class="form-group"><label class="form-label">Excerpt</label><textarea class="form-textarea" id="f-excerpt" rows="3">${escapeHtml(article?.excerpt || '')}</textarea></div>
                        <div class="form-group"><label class="form-label">Body *</label><textarea class="form-textarea" id="f-body" rows="16" required>${escapeHtml(article?.body || '')}</textarea><p class="text-sm text-muted">Supports HTML formatting</p></div>
                    </div></div>
                    <div class="editor-sidebar">
                        <div class="card"><div class="card-body">
                            <div class="form-group"><label class="form-label">Sport</label><select class="form-select" id="f-sport"><option value="">Select sport</option>${sportOptions}</select></div>
                            <div class="form-group"><label class="form-label">League</label><select class="form-select" id="f-league">${leagueOptions}</select></div>
                            <div class="form-group"><label class="form-label">Author</label><select class="form-select" id="f-author">${authorOptions}</select></div>
                        </div></div>
                        <div class="card"><div class="card-body">
                            <div class="form-group"><label class="form-label">Cover Image URL</label><input type="url" class="form-input" id="f-cover" value="${escapeHtml(article?.cover_image_url || '')}"></div>
                            <div class="form-group"><label class="form-label">Cover Emoji</label><input type="text" class="form-input" id="f-emoji" value="${escapeHtml(article?.cover_emoji || '')}" maxlength="4"></div>
                            <div class="form-group"><label class="form-label">Card Theme</label><input type="text" class="form-input" id="f-theme" value="${escapeHtml(article?.card_theme || '')}" placeholder="e.g. linear-gradient(...)"></div>
                        </div></div>
                        <div class="card"><div class="card-body">
                            <div class="form-group"><label class="form-label">Status</label><select class="form-select" id="f-status"><option value="draft" ${article?.status === 'draft' || !article ? 'selected' : ''}>Draft</option><option value="scheduled" ${article?.status === 'scheduled' ? 'selected' : ''}>Scheduled</option><option value="published" ${article?.status === 'published' ? 'selected' : ''}>Published</option><option value="archived" ${article?.status === 'archived' ? 'selected' : ''}>Archived</option></select></div>
                            <div class="form-group"><label class="form-label">Publish Date</label><input type="datetime-local" class="form-input" id="f-published" value="${article?.published_at ? article.published_at.slice(0, 16) : ''}"></div>
                            <div class="checkbox-group"><input type="checkbox" id="f-featured" ${article?.is_featured ? 'checked' : ''}><label for="f-featured">Featured</label></div>
                            <div class="checkbox-group mt-16"><input type="checkbox" id="f-trending" ${article?.is_trending ? 'checked' : ''}><label for="f-trending">Trending</label></div>
                            <div class="checkbox-group mt-16"><input type="checkbox" id="f-breaking" ${article?.is_breaking ? 'checked' : ''}><label for="f-breaking">Breaking News</label></div>
                        </div></div>
                        <div class="card"><div class="card-body">
                            <div class="form-group"><label class="form-label">SEO Title</label><input type="text" class="form-input" id="f-seo-title" value="${escapeHtml(article?.seo_title || '')}"></div>
                            <div class="form-group"><label class="form-label">SEO Description</label><textarea class="form-textarea" id="f-seo-desc" rows="2">${escapeHtml(article?.seo_description || '')}</textarea></div>
                            <div class="form-group"><label class="form-label">Read Time (minutes)</label><input type="number" class="form-input" id="f-read-time" value="${article?.read_time_minutes || 3}" min="1" max="60"></div>
                        </div></div>
                        <div class="card"><div class="card-body">
                            <label class="form-label">Tags</label>
                            <div style="display:flex;flex-direction:column;gap:6px;">${tagCheckboxes}</div>
                        </div></div>
                    </div>
                </div>
                <div style="display:flex;gap:12px;margin-top:24px;">
                    <button type="submit" class="btn btn-primary" id="form-submit">${id ? 'Save Changes' : 'Create Article'}</button>
                    <button type="button" class="btn btn-secondary" onclick="location.hash='#articles'">Cancel</button>
                </div>
            </form>`;
        $('#f-title').addEventListener('input', (e) => { if (!$('#f-slug').dataset.manual) $('#f-slug').value = slugify(e.target.value); });
        $('#f-slug').addEventListener('input', () => { $('#f-slug').dataset.manual = '1'; });
        $('#article-form').addEventListener('submit', async (ev) => {
            ev.preventDefault();
            const btn = $('#form-submit');
            btn.disabled = true;
            btn.textContent = 'Saving...';
            try {
                const tags = [...$$('input[type="checkbox"]:checked')].map(cb => cb.value);
                const row = {
                    title: $('#f-title').value.trim(),
                    slug: $('#f-slug').value.trim() || slugify($('#f-title').value),
                    excerpt: $('#f-excerpt').value.trim(),
                    body: $('#f-body').value.trim(),
                    sport_id: $('#f-sport').value || null,
                    league_id: $('#f-league').value || null,
                    author_id: $('#f-author').value || null,
                    cover_image_url: $('#f-cover').value.trim() || null,
                    cover_emoji: $('#f-emoji').value.trim() || null,
                    card_theme: $('#f-theme').value.trim() || null,
                    status: $('#f-status').value,
                    is_featured: $('#f-featured').checked,
                    is_trending: $('#f-trending').checked,
                    is_breaking: $('#f-breaking').checked,
                    published_at: $('#f-published').value ? new Date($('#f-published').value).toISOString() : null,
                    seo_title: $('#f-seo-title').value.trim() || null,
                    seo_description: $('#f-seo-desc').value.trim() || null,
                    read_time_minutes: parseInt($('#f-read-time').value) || 3,
                    updated_by: currentUser?.id
                };
                if (!id) row.created_by = currentUser?.id;
                let result;
                if (id) { result = await api.update('articles', id, row); await api.logAudit('UPDATE', 'articles', id, article, row, `Updated: ${row.title}`); }
                else { result = await api.insert('articles', row); await api.logAudit('INSERT', 'articles', result.id, null, row, `Created: ${row.title}`); }
                if (tags.length) {
                    await supabase.from('article_tags').delete().eq('article_id', result.id);
                    if (tags.length) await supabase.from('article_tags').insert(tags.map(t => ({ article_id: result.id, tag_id: t })));
                }
                showToast(id ? 'Article updated' : 'Article created');
                location.hash = '#articles';
            } catch (err) { showToast('Failed: ' + err.message, 'error'); btn.disabled = false; btn.textContent = id ? 'Save Changes' : 'Create Article'; }
        });
    } catch (err) {
        content.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Failed to load editor</div><p class="text-muted">${escapeHtml(err.message)}</p></div>`;
    }
}
