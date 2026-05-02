const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => ctx.querySelectorAll(sel);
const el = (tag, attrs = {}, children = []) => {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
        if (k === 'className') node.className = v;
        else if (k === 'textContent') node.textContent = v;
        else if (k === 'innerHTML') node.innerHTML = v;
        else if (k === 'onclick' && typeof v === 'function') node.addEventListener('click', v);
        else if (k.startsWith('on') && typeof v === 'function') node.addEventListener(k.slice(2).toLowerCase(), v);
        else if (v !== undefined && v !== null && v !== false) node.setAttribute(k, v);
    }
    for (const child of children) {
        if (typeof child === 'string') node.appendChild(document.createTextNode(child));
        else if (child) node.appendChild(child);
    }
    return node;
};
const escapeHtml = (str) => { if (!str) return ''; const d = document.createElement('div'); d.textContent = str; return d.innerHTML; };
const slugify = (text) => text.toLowerCase().replace(/[^\w\s-]/g, '').replace(/[\s_]+/g, '-').replace(/^-+|-+$/g, '');
const formatDate = (d) => { if (!d) return '—'; const dt = new Date(d); return dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }); };
const formatDateTime = (d) => { if (!d) return '—'; const dt = new Date(d); return dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }); };
const debounce = (fn, ms = 300) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };
const showToast = (message, type = 'success') => {
    const container = $('#toast-container');
    if (!container) return;
    const toast = el('div', { className: `toast toast-${type}`, textContent: message });
    container.appendChild(toast);
    setTimeout(() => { toast.style.opacity = '0'; toast.style.transform = 'translateX(100%)'; toast.style.transition = '0.3s ease'; setTimeout(() => toast.remove(), 300); }, 3500);
};
const showModal = (title, bodyHtml, footerHtml = '') => {
    $('#modal-title').textContent = title;
    $('#modal-body').innerHTML = bodyHtml;
    if (footerHtml) $('#modal-footer').innerHTML = footerHtml;
    else $('#modal-footer').innerHTML = '';
    $('#modal-overlay').style.display = 'flex';
};
const hideModal = () => { $('#modal-overlay').style.display = 'none'; };
$('#modal-close')?.addEventListener('click', hideModal);
$('#modal-overlay')?.addEventListener('click', (e) => { if (e.target === $('#modal-overlay')) hideModal(); });
const confirmAction = (message) => new Promise((resolve) => {
    showModal('Confirm', `<p>${message}</p>`,
        `<button class="btn btn-secondary" onclick="window._confirmResolve(false)">Cancel</button>
         <button class="btn btn-danger" onclick="window._confirmResolve(true)">Confirm</button>`);
    window._confirmResolve = (v) => { hideModal(); resolve(v); };
});
const loading = (show) => { $('#loading-screen').style.display = show ? 'flex' : 'none'; };
const showError = (msg, details = '') => {
    $('#loading-screen').style.display = 'none';
    $('#auth-container').style.display = 'none';
    $('#dashboard-container').style.display = 'none';
    $('#error-screen').style.display = 'flex';
    $('#error-message').textContent = msg;
    if (details) $('#error-details').textContent = details;
    console.error('[SportDune Admin]', msg, details);
};
const statusBadge = (status) => {
    const cls = status === 'published' ? 'badge-published' : status === 'draft' ? 'badge-draft' : status === 'scheduled' ? 'badge-scheduled' : 'badge-archived';
    return `<span class="badge ${cls}">${status}</span>`;
};
const roleBadge = (role) => `<span class="badge badge-role">${role}</span>`;
const activeBadge = (active) => `<span class="badge ${active ? 'badge-active' : 'badge-inactive'}">${active ? 'Active' : 'Inactive'}</span>`;
