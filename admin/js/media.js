async function loadMedia() {
    const content = $('#content');
    content.innerHTML = `
        <div class="flex-between mb-24"><h2>Media Library</h2><button class="btn btn-primary" id="upload-btn">Upload</button></div>
        <div class="media-upload-zone" id="upload-zone">
            <p style="font-size:24px;margin-bottom:8px;">📁</p>
            <p>Click or drag images to upload</p>
            <input type="file" id="file-input" accept="image/*" multiple style="display:none;">
        </div>
        <div class="media-grid" id="media-grid"><div class="skeleton" style="aspect-ratio:1;"></div><div class="skeleton" style="aspect-ratio:1;"></div><div class="skeleton" style="aspect-ratio:1;"></div></div>`;
    try {
        const media = await api.fetchAll('media_assets', { order: { column: 'created_at', ascending: false } });
        renderMediaGrid(media);
        $('#upload-zone').addEventListener('click', () => $('#file-input').click());
        $('#upload-zone').addEventListener('dragover', (e) => { e.preventDefault(); $('#upload-zone').style.borderColor = 'var(--primary)'; });
        $('#upload-zone').addEventListener('dragleave', () => { $('#upload-zone').style.borderColor = ''; });
        $('#upload-zone').addEventListener('drop', async (e) => {
            e.preventDefault();
            $('#upload-zone').style.borderColor = '';
            for (const file of e.dataTransfer.files) await uploadFile(file);
            reloadMedia();
        });
        $('#file-input').addEventListener('change', async (e) => {
            for (const file of e.target.files) await uploadFile(file);
            reloadMedia();
            e.target.value = '';
        });
        $('#upload-btn').addEventListener('click', () => $('#file-input').click());
    } catch (err) { $('#media-grid').innerHTML = `<p class="text-muted">Error: ${escapeHtml(err.message)}</p>`; }
}
function renderMediaGrid(media) {
    const g = $('#media-grid');
    if (!media?.length) { g.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🖼️</div><div class="empty-state-text">No media uploaded</div></div>'; return; }
    g.innerHTML = media.map(m => `
        <div class="media-item">
            <img src="${escapeHtml(m.url)}" alt="${escapeHtml(m.alt_text || m.filename)}" loading="lazy" onerror="this.style.display='none'">
            <div class="media-item-overlay">
                <button onclick="copyUrl('${escapeHtml(m.url)}')">Copy URL</button>
                <button onclick="deleteMediaAsset('${m.id}')">Delete</button>
            </div>
        </div>`).join('');
}
async function uploadFile(file) {
    if (!file.type.startsWith('image/')) { showToast('Only images allowed', 'warning'); return; }
    if (file.size > 5 * 1024 * 1024) { showToast('Max 5MB per file', 'warning'); return; }
    try {
        await api.uploadMedia(file);
        showToast(`Uploaded ${file.name}`);
    } catch (err) { showToast(`Failed: ${err.message}`, 'error'); }
}
async function reloadMedia() {
    try {
        const media = await api.fetchAll('media_assets', { order: { column: 'created_at', ascending: false } });
        renderMediaGrid(media);
    } catch (e) { console.error(e); }
}
function copyUrl(url) { navigator.clipboard.writeText(url); showToast('URL copied'); }
async function deleteMediaAsset(id) {
    if (!await confirmAction('Delete this media file?')) return;
    try { await api.deleteMedia(id); showToast('Deleted'); reloadMedia(); }
    catch (err) { showToast('Failed: ' + err.message, 'error'); }
}
