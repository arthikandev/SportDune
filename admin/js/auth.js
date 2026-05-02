let currentUser = null;
const initAuth = async () => {
    try {
        const { data: { session }, error } = await supabase.auth.getSession();
        if (error) throw error;
        if (session?.user) {
            await setSession(session.user);
        } else {
            showLogin();
        }
    } catch (err) {
        showError('Failed to initialize authentication', err.message);
    }
};
const setSession = async (user) => {
    try {
        const { data: profile, error } = await supabase.from('profiles').select('*').eq('id', user.id).single();
        if (error && error.code !== 'PGRST116') throw error;
        if (profile && !profile.is_active) {
            await supabase.auth.signOut();
            showLogin('Your account has been deactivated. Contact an administrator.');
            return;
        }
        currentUser = { ...user, profile };
        showDashboard();
    } catch (err) {
        showError('Failed to load user profile', err.message);
    }
};
const login = async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    await setSession(data.user);
};
const logout = async () => {
    await supabase.auth.signOut();
    currentUser = null;
    showLogin();
};
const checkRole = (role) => {
    if (!currentUser?.profile) return false;
    const r = currentUser.profile.role;
    if (role === 'viewer') return true;
    if (role === 'editor') return ['editor', 'admin', 'super_admin'].includes(r);
    if (role === 'admin') return ['admin', 'super_admin'].includes(r);
    if (role === 'super_admin') return r === 'super_admin';
    return false;
};
const showLogin = (errorMsg = null) => {
    $('#loading-screen').style.display = 'none';
    $('#dashboard-container').style.display = 'none';
    $('#auth-container').style.display = 'flex';
    $('#auth-container').innerHTML = `
        <div class="auth-container">
            <div class="auth-card">
                <div class="auth-logo">
                    <div class="logo-icon">🏆</div>
                    <h1>SportDune</h1>
                    <p>Admin Dashboard</p>
                </div>
                <form id="login-form">
                    <div class="form-group">
                        <label class="form-label">Email</label>
                        <input type="email" class="form-input" id="login-email" placeholder="admin@sportdune.com" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Password</label>
                        <input type="password" class="form-input" id="login-password" placeholder="Enter password" required>
                    </div>
                    ${errorMsg ? `<div class="form-error" style="margin-bottom:12px;">${escapeHtml(errorMsg)}</div>` : ''}
                    <button type="submit" class="btn btn-primary" style="width:100%;" id="login-submit">Sign In</button>
                </form>
            </div>
        </div>`;
    $('#login-form')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = $('#login-submit');
        btn.disabled = true;
        btn.textContent = 'Signing in...';
        try {
            await login($('#login-email').value, $('#login-password').value);
        } catch (err) {
            let msg = 'Invalid email or password';
            if (err.message.includes('Invalid login')) msg = 'Invalid email or password';
            else if (err.message.includes('Email not confirmed')) msg = 'Please verify your email first';
            else msg = err.message;
            showLogin(msg);
        }
    });
};
const showDashboard = () => {
    $('#loading-screen').style.display = 'none';
    $('#auth-container').style.display = 'none';
    $('#dashboard-container').style.display = 'flex';
    const p = currentUser?.profile;
    if (p) {
        $('#user-name').textContent = p.full_name || p.email;
        $('#user-role').textContent = p.role;
        $('#user-avatar').textContent = (p.full_name || p.email).charAt(0).toUpperCase();
    }
    document.querySelectorAll('.admin-only').forEach(item => {
        item.style.display = checkRole('admin') ? '' : 'none';
    });
    $('#logout-btn').addEventListener('click', logout);
    initRouter();
};
$('#menu-toggle')?.addEventListener('click', () => $('#sidebar')?.classList.toggle('open'));
$('#sidebar-close')?.addEventListener('click', () => $('#sidebar')?.classList.remove('open'));
window.currentUser = currentUser;
window.checkRole = checkRole;
window.logout = logout;
if (supabase) { initAuth(); } else { console.error('[Auth] Supabase not initialized:', window.__supabaseInitError || 'No error set'); }
