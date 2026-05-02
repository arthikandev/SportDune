async function loadAudit() {
    if (!checkRole('admin')) { $('#content').innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔒</div><div class="empty-state-text">Admin access required</div></div>'; return; }
    const content = $('#content');
    content.innerHTML = `
        <div class="flex-between mb-24"><h2>Audit Logs</h2></div>
        <div class="card"><div class="table-container" id="audit-table"><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;"></div></div></div>`;
    try {
        const { data } = await supabase.from('audit_logs').select('*').order('created_at', { ascending: false }).limit(100);
        renderAuditTable(data);
    } catch (err) { $('#audit-table').innerHTML = `<p class="text-muted">Error: ${escapeHtml(err.message)}</p>`; }
}
function renderAuditTable(logs) {
    const c = $('#audit-table');
    if (!logs?.length) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📋</div><div class="empty-state-text">No audit logs</div></div>'; return; }
    c.innerHTML = `<table class="table"><thead><tr><th>Action</th><th>Entity</th><th>User</th><th>Summary</th><th>Date</th></tr></thead><tbody>${logs.map(l => {
        const badgeClass = l.action === 'INSERT' ? 'badge-published' : l.action === 'UPDATE' ? 'badge-scheduled' : 'badge-archived';
        return `<tr><td><span class="badge ${badgeClass}">${l.action}</span></td><td class="text-sm">${escapeHtml(l.entity_type || '—')}${l.entity_id ? '<br><span class="text-muted" style="font-size:0.75rem;">' + l.entity_id.slice(0, 8) + '...</span>' : ''}</td><td class="text-sm">${escapeHtml(l.user_email || 'System')}</td><td class="text-sm text-muted truncate">${escapeHtml(l.changes_summary || '—')}</td><td class="text-sm text-muted">${formatDateTime(l.created_at)}</td></tr>`;
    }).join('')}</tbody></table>`;
}
