async function loadUsers() {
    if (!checkRole('admin')) { $('#content').innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔒</div><div class="empty-state-text">Admin access required</div></div>'; return; }
    const content = $('#content');
    content.innerHTML = `
        <div class="flex-between mb-24"><h2>Manage Users</h2></div>
        <div class="card"><div class="table-container" id="users-table"><div class="skeleton" style="height:40px;margin-bottom:8px;"></div><div class="skeleton" style="height:40px;"></div></div></div>`;
    try {
        const { data } = await supabase.from('profiles').select('*').order('created_at', { ascending: false });
        renderUsersTable(data);
    } catch (err) { $('#users-table').innerHTML = `<p class="text-muted">Error: ${escapeHtml(err.message)}</p>`; }
}
function renderUsersTable(users) {
    const c = $('#users-table');
    if (!users?.length) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">👥</div><div class="empty-state-text">No users found</div></div>'; return; }
    c.innerHTML = `<table class="table"><thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Status</th><th>Last Login</th><th>Actions</th></tr></thead><tbody>${users.map(u => `<tr><td><strong>${escapeHtml(u.full_name || '—')}</strong></td><td class="text-sm">${escapeHtml(u.email)}</td><td>${roleBadge(u.role)}</td><td>${activeBadge(u.is_active)}</td><td class="text-sm text-muted">${u.last_login_at ? formatDateTime(u.last_login_at) : 'Never'}</td><td><div class="table-actions"><button class="btn btn-ghost btn-sm" onclick="editUserRole('${u.id}')">✏️</button></div></td></tr>`).join('')}</tbody></table>`;
}
function editUserRole(id) {
    api.fetchOne('profiles', id).then(u => {
        showModal('Edit User', `
            <form id="user-form">
                <div class="form-group"><label class="form-label">Full Name</label><input class="form-input" id="uf-name" value="${escapeHtml(u.full_name || '')}"></div>
                <div class="form-group"><label class="form-label">Role</label><select class="form-select" id="uf-role"><option value="viewer" ${u.role === 'viewer' ? 'selected' : ''}>Viewer</option><option value="editor" ${u.role === 'editor' ? 'selected' : ''}>Editor</option><option value="admin" ${u.role === 'admin' ? 'selected' : ''}>Admin</option><option value="super_admin" ${u.role === 'super_admin' ? 'selected' : ''}>Super Admin</option></select></div>
                <div class="checkbox-group"><input type="checkbox" id="uf-active" ${u.is_active ? 'checked' : ''}><label for="uf-active">Active</label></div>
            </form>`, `<button class="btn btn-secondary" onclick="hideModal()">Cancel</button><button class="btn btn-primary" id="uf-save">Save</button>`);
        $('#uf-save').addEventListener('click', async () => {
            try {
                await api.update('profiles', id, { full_name: $('#uf-name').value, role: $('#uf-role').value, is_active: $('#uf-active').checked });
                await api.logAudit('UPDATE', 'profiles', id, null, null, `Updated user: ${$('#uf-name').value}`);
                hideModal(); showToast('User updated'); loadUsers();
            } catch (err) { showToast('Failed: ' + err.message, 'error'); }
        });
    });
}
