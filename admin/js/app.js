/**
 * SportDune Admin Dashboard
 * Main Application JavaScript
 */

// ================================================
// CONFIGURATION
// ================================================

const CONFIG = {
  SUPABASE_URL: 'https://pvmtcwqupalurwqlvdxy.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_fuqgloaY9Hi7mHi0HsH8DQ_fjvXS_E6',
  API_TIMEOUT: 30000,
  TOAST_DURATION: 5000,
};

// ================================================
// UTILITY FUNCTIONS
// ================================================

const Utils = {
  // Generate unique ID
  generateId() {
    return Math.random().toString(36).substr(2, 9);
  },

  // Format date
  formatDate(date, format = 'short') {
    if (!date) return '-';
    const d = new Date(date);
    if (format === 'short') {
      return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }
    if (format === 'time') {
      return d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    }
    if (format === 'datetime') {
      return `${d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} at ${d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}`;
    }
    return d.toLocaleDateString();
  },

  // Format number with commas
  formatNumber(num) {
    if (!num && num !== 0) return '-';
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  },

  // Truncate text
  truncate(text, length = 50) {
    if (!text) return '';
    if (text.length <= length) return text;
    return text.substring(0, length) + '...';
  },

  // Generate slug from text
  slugify(text) {
    return text
      .toString()
      .toLowerCase()
      .trim()
      .replace(/\s+/g, '-')
      .replace(/[^\w\-]+/g, '')
      .replace(/\-\-+/g, '-');
  },

  // Debounce function
  debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  },

  // Escape HTML
  escapeHtml(text) {
    if (!text) return '';
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
  },

  // Get initials from name
  getInitials(name) {
    if (!name) return '?';
    return name
      .split(' ')
      .map(word => word[0])
      .join('')
      .toUpperCase()
      .substring(0, 2);
  },

  // Parse JSON safely
  safeJson(str, defaultValue = null) {
    try {
      return JSON.parse(str);
    } catch {
      return defaultValue;
    }
  },
};

// ================================================
// API CLIENT
// ================================================

const API = {
  baseUrl: CONFIG.SUPABASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'apikey': CONFIG.SUPABASE_ANON_KEY,
  },

  // Get auth token
  getToken() {
    return localStorage.getItem('sportdune_token');
  },

  // Set auth headers
  getHeaders() {
    const headers = { ...this.headers };
    const token = this.getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  },

  // Make request
  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}/rest/v1/${endpoint}`;
    const config = {
      ...options,
      headers: {
        ...this.getHeaders(),
        ...options.headers,
      },
    };

    // Handle query parameters
    if (options.params) {
      const queryString = Object.entries(options.params)
        .filter(([_, v]) => v !== undefined && v !== null && v !== '')
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
        .join('&');
      if (queryString) {
        config.url = `${url}?${queryString}`;
      } else {
        config.url = url;
      }
    } else {
      config.url = url;
    }

    try {
      const response = await fetch(config.url, config);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || data.error?.message || 'Request failed');
      }

      return data;
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  },

  // GET request
  get(endpoint, params = {}) {
    return this.request(endpoint, { method: 'GET', params });
  },

  // POST request
  post(endpoint, data) {
    return this.request(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  // PATCH request
  patch(endpoint, data) {
    return this.request(endpoint, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  // PUT request
  put(endpoint, data) {
    return this.request(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },

  // DELETE request
  delete(endpoint) {
    return this.request(endpoint, { method: 'DELETE' });
  },

  // RPC call (for complex operations)
  rpc(functionName, params = {}) {
    return this.request(`rpc/${functionName}`, {
      method: 'POST',
      body: JSON.stringify(params),
    });
  },
};

// ================================================
// AUTHENTICATION
// ================================================

const Auth = {
  key: 'sportdune_user',

  // Get current user
  getUser() {
    const data = localStorage.getItem(this.key);
    return data ? Utils.safeJson(data) : null;
  },

  // Set user
  setUser(user) {
    localStorage.setItem(this.key, JSON.stringify(user));
  },

  // Clear user
  clearUser() {
    localStorage.removeItem(this.key);
    localStorage.removeItem('sportdune_token');
  },

  // Login
  async login(email, password) {
    try {
      // Call Supabase Auth
      const response = await fetch(`${CONFIG.SUPABASE_URL}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': CONFIG.SUPABASE_ANON_KEY,
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error_description || data.msg || 'Login failed');
      }

      // Store token
      localStorage.setItem('sportdune_token', data.access_token);

      // Get user profile
      const profile = await API.get(`profiles?id=eq.${data.user.id}&select=*`);

      if (profile && profile.length > 0) {
        const user = { ...data.user, ...profile[0] };
        this.setUser(user);
        return user;
      }

      throw new Error('Profile not found');
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  },

  // Logout
  async logout() {
    try {
      await fetch(`${CONFIG.SUPABASE_URL}/auth/v1/logout`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.getToken()}`,
          'apikey': CONFIG.SUPABASE_ANON_KEY,
        },
      });
    } catch (error) {
      console.error('Logout error:', error);
    }
    this.clearUser();
    Router.navigate('/');
  },

  // Get token
  getToken() {
    return localStorage.getItem('sportdune_token');
  },

  // Check if authenticated
  isAuthenticated() {
    return !!Auth.getToken() && !!this.getUser();
  },

  // Check if has role
  hasRole(...roles) {
    const user = this.getUser();
    if (!user) return false;
    return roles.includes(user.role);
  },

  // Require authentication
  requireAuth() {
    if (!this.isAuthenticated()) {
      Router.navigate('/');
      return false;
    }
    return true;
  },

  // Require specific role
  requireRole(...roles) {
    if (!this.requireAuth()) return false;
    if (!this.hasRole(...roles)) {
      Toast.show('error', 'Access Denied', 'You do not have permission to access this page');
      Router.navigate('/dashboard');
      return false;
    }
    return true;
  },
};

// ================================================
// TOAST NOTIFICATIONS
// ================================================

const Toast = {
  container: null,

  // Initialize
  init() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'toast-container';
      document.body.appendChild(this.container);
    }
  },

  // Show toast
  show(type, title, message = '') {
    this.init();

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
      <div class="toast-icon">
        ${this.getIcon(type)}
      </div>
      <div class="toast-content">
        <div class="toast-title">${Utils.escapeHtml(title)}</div>
        ${message ? `<div class="toast-message">${Utils.escapeHtml(message)}</div>` : ''}
      </div>
      <button class="toast-close" onclick="Toast.dismiss(this.parentElement)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M18 6L6 18M6 6l12 12"/>
        </svg>
      </button>
    `;

    this.container.appendChild(toast);

    // Auto dismiss
    setTimeout(() => {
      this.dismiss(toast);
    }, CONFIG.TOAST_DURATION);
  },

  // Dismiss toast
  dismiss(toast) {
    if (toast && toast.parentElement) {
      toast.style.animation = 'fadeIn 0.3s reverse';
      setTimeout(() => {
        if (toast.parentElement) {
          toast.parentElement.removeChild(toast);
        }
      }, 300);
    }
  },

  // Get icon for type
  getIcon(type) {
    const icons = {
      success: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6L9 17l-5-5"/></svg>',
      error: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M15 9l-6 6M9 9l6 6"/></svg>',
      warning: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 9v4M12 17h.01"/><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/></svg>',
      info: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>',
    };
    return icons[type] || icons.info;
  },

  // Convenience methods
  success(title, message = '') { this.show('success', title, message); },
  error(title, message = '') { this.show('error', title, message); },
  warning(title, message = '') { this.show('warning', title, message); },
  info(title, message = '') { this.show('info', title, message); },
};

// ================================================
// MODAL
// ================================================

const Modal = {
  activeModal: null,

  // Show modal
  show(options = {}) {
    const {
      title = '',
      content = '',
      footer = '',
      size = '',
      onClose = null,
    } = options;

    // Create backdrop
    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop';
    backdrop.innerHTML = `
      <div class="modal ${size ? 'modal-' + size : ''}">
        <div class="modal-header">
          <h3 class="modal-title">${Utils.escapeHtml(title)}</h3>
          <button class="modal-close" data-close>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M18 6L6 18M6 6l12 12"/>
            </svg>
          </button>
        </div>
        <div class="modal-body">${content}</div>
        ${footer ? `<div class="modal-footer">${footer}</div>` : ''}
      </div>
    `;

    // Close handlers
    backdrop.querySelector('[data-close]').addEventListener('click', () => this.hide());
    backdrop.addEventListener('click', (e) => {
      if (e.target === backdrop) this.hide();
    });

    document.body.appendChild(backdrop);
    this.activeModal = backdrop;

    // Animate in
    requestAnimationFrame(() => {
      backdrop.classList.add('active');
    });

    // Callback
    if (onClose) {
      this.activeModal._onClose = onClose;
    }

    return backdrop;
  },

  // Hide modal
  hide() {
    if (this.activeModal) {
      this.activeModal.classList.remove('active');
      if (this.activeModal._onClose) {
        this.activeModal._onClose();
      }
      setTimeout(() => {
        if (this.activeModal && this.activeModal.parentElement) {
          document.body.removeChild(this.activeModal);
        }
        this.activeModal = null;
      }, 200);
    }
  },

  // Confirm dialog
  confirm(options = {}) {
    const {
      title = 'Confirm',
      message = 'Are you sure?',
      confirmText = 'Confirm',
      cancelText = 'Cancel',
      type = 'warning',
      onConfirm = null,
      onCancel = null,
    } = options;

    const icons = {
      danger: '⚠️',
      warning: '⚠️',
      info: 'ℹ️',
    };

    const colors = {
      danger: 'btn-danger',
      warning: 'btn-warning',
      info: 'btn-primary',
    };

    return new Promise((resolve) => {
      const backdrop = document.createElement('div');
      backdrop.className = 'modal-backdrop confirm-dialog';
      backdrop.innerHTML = `
        <div class="modal">
          <div class="modal-body">
            <div class="confirm-dialog-icon ${type}">${icons[type]}</div>
            <h3 class="confirm-dialog-title">${Utils.escapeHtml(title)}</h3>
            <p class="confirm-dialog-message">${Utils.escapeHtml(message)}</p>
            <div class="flex gap-sm" style="justify-content: center;">
              <button class="btn btn-secondary" data-cancel>${cancelText}</button>
              <button class="btn ${colors[type]}" data-confirm>${confirmText}</button>
            </div>
          </div>
        </div>
      `;

      document.body.appendChild(backdrop);

      backdrop.querySelector('[data-cancel]').addEventListener('click', () => {
        document.body.removeChild(backdrop);
        if (onCancel) onCancel();
        resolve(false);
      });

      backdrop.querySelector('[data-confirm]').addEventListener('click', () => {
        document.body.removeChild(backdrop);
        if (onConfirm) onConfirm();
        resolve(true);
      });

      backdrop.addEventListener('click', (e) => {
        if (e.target === backdrop) {
          document.body.removeChild(backdrop);
          if (onCancel) onCancel();
          resolve(false);
        }
      });

      requestAnimationFrame(() => {
        backdrop.classList.add('active');
      });
    });
  },
};

// ================================================
// ROUTER
// ================================================

const Router = {
  routes: {},
  currentRoute: null,

  // Register route
  register(path, handler) {
    this.routes[path] = handler;
  },

  // Navigate to path
  navigate(path) {
    history.pushState(null, '', path);
    this.handleRoute();
  },

  // Handle current route
  handleRoute() {
    const path = window.location.pathname;
    const search = window.location.search;

    // Find matching route
    let handler = this.routes[path];

    if (!handler) {
      // Try dynamic routes
      for (const route in this.routes) {
        const pattern = route.replace(/:(\w+)/g, '([^/]+)');
        const regex = new RegExp(`^${pattern}$`);
        if (regex.test(path)) {
          const params = path.match(regex).slice(1);
          handler = () => this.routes[route](...params);
          break;
        }
      }
    }

    if (handler) {
      this.currentRoute = path;
      handler();
    } else {
      // 404
      this.navigate('/dashboard');
    }
  },

  // Initialize router
  init() {
    window.addEventListener('popstate', () => this.handleRoute());
    this.handleRoute();
    window.__routerInitialized = true;
  },
};

// ================================================
// SIDEBAR NAVIGATION
// ================================================

const Sidebar = {
  init() {
    // Handle nav clicks
    document.querySelectorAll('.nav-item[data-page]').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const page = item.dataset.page;
        Router.navigate(`/${page}`);
      });
    });

    // Update active state based on current route
    this.updateActiveState();
  },

  updateActiveState() {
    const path = window.location.pathname;
    document.querySelectorAll('.nav-item[data-page]').forEach(item => {
      const page = item.dataset.page;
      const expectedPath = `/${page}`;
      if (path === expectedPath || path.startsWith(`${expectedPath}/`)) {
        item.classList.add('active');
      } else {
        item.classList.remove('active');
      }
    });
  },

  // Update user info in sidebar
  updateUser(user) {
    const avatarEl = document.querySelector('.sidebar-user-avatar');
    const nameEl = document.querySelector('.sidebar-user-name');
    const roleEl = document.querySelector('.sidebar-user-role');

    if (avatarEl) {
      avatarEl.textContent = Utils.getInitials(user.full_name || user.email);
    }
    if (nameEl) {
      nameEl.textContent = user.full_name || user.email;
    }
    if (roleEl) {
      roleEl.textContent = (user.role || 'viewer').replace('_', ' ');
    }
  },
};

// ================================================
// DATA TABLES
// ================================================

const DataTable = {
  // Create table element
  create(options = {}) {
    const {
      columns = [],
      data = [],
      keyField = 'id',
      actions = [],
      onRowClick = null,
      selectable = false,
      emptyMessage = 'No data found',
      loading = false,
    } = options;

    const table = document.createElement('div');
    table.className = 'card';
    table.innerHTML = `
      <div class="table-container">
        <table class="table">
          <thead>
            <tr>
              ${selectable ? '<th width="40"><input type="checkbox" class="table-checkbox" data-select-all></th>' : ''}
              ${columns.map(col => `<th>${col.title}</th>`).join('')}
              ${actions.length ? '<th width="120">Actions</th>' : ''}
            </tr>
          </thead>
          <tbody>
            ${this.renderBody(columns, data, keyField, actions, selectable, emptyMessage, loading)}
          </tbody>
        </table>
      </div>
    `;

    // Bind events
    if (selectable) {
      table.querySelector('[data-select-all]')?.addEventListener('change', (e) => {
        table.querySelectorAll('[data-select-row]').forEach(cb => {
          cb.checked = e.target.checked;
        });
      });
    }

    return table;
  },

  // Render table body
  renderBody(columns, data, keyField, actions, selectable, emptyMessage, loading) {
    if (loading) {
      return `
        <tr>
          <td colspan="${columns.length + (selectable ? 1 : 0) + (actions.length ? 1 : 0)}" class="text-center p-xl">
            <div class="spinner" style="margin: 0 auto;"></div>
          </td>
        </tr>
      `;
    }

    if (!data || data.length === 0) {
      return `
        <tr>
          <td colspan="${columns.length + (selectable ? 1 : 0) + (actions.length ? 1 : 0)}" class="text-center p-xl">
            <div class="empty-state">
              <div class="empty-state-icon">📭</div>
              <div class="empty-state-title">${emptyMessage}</div>
            </div>
          </td>
        </tr>
      `;
    }

    return data.map(item => `
      <tr data-key="${item[keyField]}">
        ${selectable ? `<td><input type="checkbox" class="table-checkbox" data-select-row="${item[keyField]}"></td>` : ''}
        ${columns.map(col => {
          const value = this.getNestedValue(item, col.field);
          return `<td>${col.render ? col.render(value, item) : this.formatValue(value, col.format)}</td>`;
        }).join('')}
        ${actions.length ? `
          <td>
            <div class="table-actions">
              ${actions.map(action => `
                <button class="btn btn-icon btn-ghost btn-sm" data-action="${action.action}" data-id="${item[keyField]}" title="${action.label}">
                  ${action.icon || action.label}
                </button>
              `).join('')}
            </div>
          </td>
        ` : ''}
      </tr>
    `).join('');
  },

  // Get nested value from object
  getNestedValue(obj, path) {
    return path.split('.').reduce((o, k) => (o ? o[k] : null), obj);
  },

  // Format value
  formatValue(value, format) {
    if (value === null || value === undefined) return '-';
    if (format === 'date') return Utils.formatDate(value);
    if (format === 'datetime') return Utils.formatDate(value, 'datetime');
    if (format === 'number') return Utils.formatNumber(value);
    if (format === 'truncate') return Utils.truncate(value, 50);
    if (format === 'boolean') return value ? 'Yes' : 'No';
    return Utils.escapeHtml(value);
  },
};

// ================================================
// PAGE HANDLERS
// ================================================

const Pages = {
  // Login Page
  login() {
    const app = document.getElementById('app');
    
    if (Auth.isAuthenticated()) {
      Router.navigate('/dashboard');
      return;
    }

    app.innerHTML = `
      <div class="login-page">
        <div class="login-card animate-slide-in">
          <div class="login-logo">
            <div class="login-logo-icon">⚽</div>
            <div class="login-logo-text">SportDune</div>
          </div>
          <h1 class="login-title">Admin Login</h1>
          <p class="login-subtitle">Sign in to manage your sports content</p>
          
          <div class="login-error" id="login-error"></div>
          
          <form id="login-form">
            <div class="form-group">
              <label class="form-label">Email</label>
              <input type="email" class="form-input" id="login-email" placeholder="admin@sportdune.com" required>
            </div>
            <div class="form-group">
              <label class="form-label">Password</label>
              <input type="password" class="form-input" id="login-password" placeholder="Enter your password" required>
            </div>
            <button type="submit" class="btn btn-primary w-full" id="login-btn">
              Sign In
            </button>
          </form>
        </div>
      </div>
    `;

    const form = document.getElementById('login-form');
    const errorEl = document.getElementById('login-error');
    const btn = document.getElementById('login-btn');

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('login-email').value;
      const password = document.getElementById('login-password').value;

      btn.disabled = true;
      btn.innerHTML = '<div class="spinner spinner-sm"></div> Signing in...';
      errorEl.classList.remove('show');

      try {
        await Auth.login(email, password);
        Toast.success('Welcome back!', 'Login successful');
        Router.navigate('/dashboard');
      } catch (error) {
        errorEl.textContent = error.message || 'Login failed. Please check your credentials.';
        errorEl.classList.add('show');
      } finally {
        btn.disabled = false;
        btn.textContent = 'Sign In';
      }
    });
  },

  // Dashboard Page
  dashboard() {
    if (!Auth.requireAuth()) return;

    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content">
            <div class="page-header">
              <div>
                <h1 class="page-title">Dashboard</h1>
                <p class="page-subtitle">Welcome back! Here's what's happening today.</p>
              </div>
              <button class="btn btn-primary" onclick="Pages.quickArticle()">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 5v14M5 12h14"/>
                </svg>
                New Article
              </button>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-4 mb-xl">
              <div class="stat-card">
                <div class="stat-card-icon primary">📰</div>
                <div class="stat-card-content">
                  <div class="stat-card-value" id="stat-articles">-</div>
                  <div class="stat-card-label">Total Articles</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-card-icon success">✅</div>
                <div class="stat-card-content">
                  <div class="stat-card-value" id="stat-published">-</div>
                  <div class="stat-card-label">Published</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-card-icon info">⚽</div>
                <div class="stat-card-content">
                  <div class="stat-card-value" id="stat-sports">-</div>
                  <div class="stat-card-label">Sports</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-card-icon warning">🏆</div>
                <div class="stat-card-content">
                  <div class="stat-card-value" id="stat-leagues">-</div>
                  <div class="stat-card-label">Leagues</div>
                </div>
              </div>
            </div>

            <div class="grid" style="grid-template-columns: 2fr 1fr;">
              <!-- Recent Articles -->
              <div class="card">
                <div class="card-header">
                  <h3 class="card-title">Recent Articles</h3>
                  <a href="/articles" class="btn btn-ghost btn-sm">View All</a>
                </div>
                <div class="card-body p-0">
                  <div class="table-container">
                    <table class="table">
                      <thead>
                        <tr>
                          <th>Title</th>
                          <th>Sport</th>
                          <th>Status</th>
                          <th>Date</th>
                        </tr>
                      </thead>
                      <tbody id="recent-articles">
                        <tr><td colspan="4" class="text-center p-lg"><div class="spinner"></div></td></tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>

              <!-- Quick Stats -->
              <div class="card">
                <div class="card-header">
                  <h3 class="card-title">Quick Stats</h3>
                </div>
                <div class="card-body">
                  <div class="mb-lg">
                    <div class="flex justify-between mb-sm">
                      <span class="text-sm">Draft Articles</span>
                      <span class="text-sm font-medium" id="stat-drafts">-</span>
                    </div>
                    <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div class="h-full bg-gray-400" id="drafts-bar" style="width: 0%"></div>
                    </div>
                  </div>
                  <div class="mb-lg">
                    <div class="flex justify-between mb-sm">
                      <span class="text-sm">Live Matches</span>
                      <span class="text-sm font-medium" id="stat-matches">-</span>
                    </div>
                    <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div class="h-full bg-success" id="matches-bar" style="width: 0%"></div>
                    </div>
                  </div>
                  <div class="mb-lg">
                    <div class="flex justify-between mb-sm">
                      <span class="text-sm">Featured Content</span>
                      <span class="text-sm font-medium" id="stat-featured">-</span>
                    </div>
                    <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div class="h-full bg-primary" id="featured-bar" style="width: 0%"></div>
                    </div>
                  </div>
                  <div>
                    <div class="flex justify-between mb-sm">
                      <span class="text-sm">Trending Now</span>
                      <span class="text-sm font-medium" id="stat-trending">-</span>
                    </div>
                    <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div class="h-full bg-warning" id="trending-bar" style="width: 0%"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadDashboardStats();
  },

  // Load dashboard statistics
  async loadDashboardStats() {
    try {
      // Get stats from API
      const [articles, sports, leagues, matches] = await Promise.all([
        API.get('articles', { select: 'id,status,sport_id,title,created_at,sports(name)' }),
        API.get('sports', { select: 'id' }),
        API.get('leagues', { select: 'id' }),
        API.get('live_matches', { select: 'id,status' }),
      ]);

      const totalArticles = articles?.length || 0;
      const publishedArticles = articles?.filter(a => a.status === 'published').length || 0;
      const draftArticles = articles?.filter(a => a.status === 'draft').length || 0;

      // Update stats
      document.getElementById('stat-articles').textContent = Utils.formatNumber(totalArticles);
      document.getElementById('stat-published').textContent = Utils.formatNumber(publishedArticles);
      document.getElementById('stat-sports').textContent = Utils.formatNumber(sports?.length || 0);
      document.getElementById('stat-leagues').textContent = Utils.formatNumber(leagues?.length || 0);
      document.getElementById('stat-drafts').textContent = draftArticles;
      document.getElementById('stat-matches').textContent = matches?.filter(m => m.status === 'live').length || 0;
      document.getElementById('stat-featured').textContent = '-';
      document.getElementById('stat-trending').textContent = articles?.filter(a => a.is_trending).length || 0;

      // Progress bars
      if (totalArticles > 0) {
        document.getElementById('drafts-bar').style.width = `${(draftArticles / totalArticles) * 100}%`;
      }

      // Recent articles
      const recentArticles = articles?.slice(0, 5) || [];
      document.getElementById('recent-articles').innerHTML = recentArticles.length > 0
        ? recentArticles.map(article => `
          <tr>
            <td><a href="/articles/${article.id}" class="font-medium">${Utils.truncate(article.title, 40)}</a></td>
            <td>${article.sports?.name || '-'}</td>
            <td><span class="status-badge ${article.status}">${article.status}</span></td>
            <td class="text-gray-500">${Utils.formatDate(article.created_at)}</td>
          </tr>
        `).join('')
        : '<tr><td colspan="4" class="text-center text-gray-500 p-lg">No articles yet</td></tr>';

    } catch (error) {
      console.error('Failed to load dashboard stats:', error);
      Toast.error('Error', 'Failed to load statistics');
    }
  },

  // Articles Page
  articles() {
    if (!Auth.requireAuth()) return;

    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content-full">
            <div class="page-header">
              <div>
                <h1 class="page-title">Articles</h1>
                <p class="page-subtitle">Manage your news articles and content</p>
              </div>
              <div class="flex gap-sm">
                <button class="btn btn-secondary" onclick="Pages.exportArticles()">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12"/>
                  </svg>
                  Export
                </button>
                <button class="btn btn-primary" onclick="Router.navigate('/articles/new')">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 5v14M5 12h14"/>
                  </svg>
                  New Article
                </button>
              </div>
            </div>

            <div class="card">
              <div class="card-header">
                <div class="filters-bar">
                  <div class="search-input">
                    <svg class="search-input-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
                    </svg>
                    <input type="text" class="form-input" placeholder="Search articles..." id="article-search">
                  </div>
                  <select class="filter-select" id="filter-sport">
                    <option value="">All Sports</option>
                  </select>
                  <select class="filter-select" id="filter-status">
                    <option value="">All Status</option>
                    <option value="draft">Draft</option>
                    <option value="pending_review">Pending Review</option>
                    <option value="published">Published</option>
                    <option value="archived">Archived</option>
                  </select>
                  <select class="filter-select" id="filter-featured">
                    <option value="">All Articles</option>
                    <option value="featured">Featured</option>
                    <option value="trending">Trending</option>
                  </select>
                </div>
              </div>
              <div class="table-container">
                <table class="table" id="articles-table">
                  <thead>
                    <tr>
                      <th width="40"><input type="checkbox" class="table-checkbox"></th>
                      <th>Title</th>
                      <th>Sport</th>
                      <th>Status</th>
                      <th>Author</th>
                      <th>Views</th>
                      <th>Date</th>
                      <th width="120">Actions</th>
                    </tr>
                  </thead>
                  <tbody id="articles-list">
                    <tr><td colspan="8" class="text-center p-xl"><div class="spinner" style="margin: 0 auto;"></div></td></tr>
                  </tbody>
                </table>
              </div>
              <div class="card-footer flex justify-between items-center">
                <div class="text-sm text-gray-500" id="articles-count">0 articles</div>
                <div class="pagination" id="articles-pagination"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadArticles();

    // Bind filters
    document.getElementById('article-search')?.addEventListener('input', 
      Utils.debounce(() => this.loadArticles(), 300)
    );
    document.querySelectorAll('.filter-select').forEach(select => {
      select.addEventListener('change', () => this.loadArticles());
    });
  },

  // Load articles
  async loadArticles(page = 1) {
    const search = document.getElementById('article-search')?.value || '';
    const sport = document.getElementById('filter-sport')?.value || '';
    const status = document.getElementById('filter-status')?.value || '';
    const featured = document.getElementById('filter-featured')?.value || '';
    const perPage = 20;

    try {
      let query = `articles?select=*,sports(name),authors(display_name)&order=created_at.desc&limit=${perPage}&offset=${(page - 1) * perPage}`;
      
      if (search) query += `&title=ilike.*${search}*`;
      if (sport) query += `&sport_id=eq.${sport}`;
      if (status) query += `&status=eq.${status}`;
      if (featured === 'featured') query += `&is_featured=eq.true`;
      if (featured === 'trending') query += `&is_trending=eq.true`;

      const data = await API.get(query);
      const tbody = document.getElementById('articles-list');

      if (!data || data.length === 0) {
        tbody.innerHTML = `
          <tr>
            <td colspan="8" class="text-center p-xl">
              <div class="empty-state">
                <div class="empty-state-icon">📝</div>
                <div class="empty-state-title">No articles found</div>
                <div class="empty-state-message">Create your first article to get started</div>
                <button class="btn btn-primary mt-md" onclick="Router.navigate('/articles/new')">Create Article</button>
              </div>
            </td>
          </tr>
        `;
        return;
      }

      tbody.innerHTML = data.map(article => `
        <tr>
          <td><input type="checkbox" class="table-checkbox"></td>
          <td>
            <div class="font-medium">${Utils.truncate(article.title, 50)}</div>
            <div class="text-xs text-gray-500">${article.slug}</div>
          </td>
          <td>${article.sports?.name || '-'}</td>
          <td>
            <span class="status-badge ${article.status}">${article.status.replace('_', ' ')}</span>
            ${article.is_featured ? '<span class="badge badge-primary ml-xs">Featured</span>' : ''}
            ${article.is_trending ? '<span class="badge badge-warning ml-xs">Trending</span>' : ''}
          </td>
          <td>${article.authors?.display_name || '-'}</td>
          <td>${Utils.formatNumber(article.view_count)}</td>
          <td class="text-gray-500">${Utils.formatDate(article.created_at)}</td>
          <td>
            <div class="table-actions">
              <button class="btn btn-icon btn-ghost btn-sm" title="Edit" onclick="Router.navigate('/articles/${article.id}/edit')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="btn btn-icon btn-ghost btn-sm" title="Preview" onclick="window.open('/article/${article.slug}', '_blank')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                  <circle cx="12" cy="12" r="3"/>
                </svg>
              </button>
              <button class="btn btn-icon btn-ghost btn-sm" title="Delete" onclick="Pages.deleteArticle('${article.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
                </svg>
              </button>
            </div>
          </td>
        </tr>
      `).join('');

      document.getElementById('articles-count').textContent = `${data.length} articles`;

    } catch (error) {
      console.error('Failed to load articles:', error);
      Toast.error('Error', 'Failed to load articles');
    }
  },

  // Delete article
  async deleteArticle(id) {
    const confirmed = await Modal.confirm({
      title: 'Delete Article',
      message: 'Are you sure you want to delete this article? This action cannot be undone.',
      type: 'danger',
      confirmText: 'Delete',
    });

    if (confirmed) {
      try {
        await API.delete(`articles?id=eq.${id}`);
        Toast.success('Deleted', 'Article deleted successfully');
        this.loadArticles();
      } catch (error) {
        Toast.error('Error', 'Failed to delete article');
      }
    }
  },

  // Article Editor
  articleEditor(id = null) {
    if (!Auth.requireAuth()) return;

    const app = document.getElementById('app');
    const isNew = !id || id === 'new';

    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content-full">
            <div class="page-header">
              <div class="flex items-center gap-md">
                <button class="btn btn-ghost" onclick="Router.navigate('/articles')">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 12H5M12 19l-7-7 7-7"/>
                  </svg>
                </button>
                <div>
                  <h1 class="page-title">${isNew ? 'New Article' : 'Edit Article'}</h1>
                  <p class="page-subtitle" id="editor-subtitle">Create a new article</p>
                </div>
              </div>
              <div class="flex gap-sm">
                <button class="btn btn-outline" onclick="Pages.previewArticle()">Preview</button>
                <button class="btn btn-secondary" onclick="Pages.saveArticle('draft')">Save Draft</button>
                <button class="btn btn-primary" onclick="Pages.saveArticle('published')">Publish</button>
              </div>
            </div>

            <div class="grid" style="grid-template-columns: 2fr 1fr;">
              <!-- Main Content -->
              <div class="card">
                <div class="card-body">
                  <div class="form-group">
                    <label class="form-label">Title</label>
                    <input type="text" class="form-input" id="article-title" placeholder="Enter article title" required>
                  </div>
                  <div class="form-group">
                    <label class="form-label">Slug</label>
                    <input type="text" class="form-input" id="article-slug" placeholder="article-url-slug">
                    <p class="form-hint">Leave empty to auto-generate from title</p>
                  </div>
                  <div class="form-group">
                    <label class="form-label">Excerpt</label>
                    <textarea class="form-textarea" id="article-excerpt" rows="2" placeholder="Brief description for article cards"></textarea>
                  </div>
                  <div class="form-group">
                    <label class="form-label">Content</label>
                    <textarea class="form-textarea" id="article-content" rows="20" placeholder="Write your article content here..."></textarea>
                  </div>
                </div>
              </div>

              <!-- Sidebar -->
              <div class="space-y-lg">
                <!-- Publish Settings -->
                <div class="card">
                  <div class="card-header">
                    <h3 class="card-title">Publish</h3>
                  </div>
                  <div class="card-body">
                    <div class="form-group">
                      <label class="form-label">Status</label>
                      <select class="form-select" id="article-status">
                        <option value="draft">Draft</option>
                        <option value="pending_review">Pending Review</option>
                        <option value="published">Published</option>
                        <option value="archived">Archived</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Publish Date</label>
                      <input type="datetime-local" class="form-input" id="article-published-at">
                    </div>
                  </div>
                </div>

                <!-- Classification -->
                <div class="card">
                  <div class="card-header">
                    <h3 class="card-title">Classification</h3>
                  </div>
                  <div class="card-body">
                    <div class="form-group">
                      <label class="form-label">Sport</label>
                      <select class="form-select" id="article-sport">
                        <option value="">Select Sport</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label class="form-label">League</label>
                      <select class="form-select" id="article-league" disabled>
                        <option value="">Select League</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Article Type</label>
                      <select class="form-select" id="article-type">
                        <option value="news">News</option>
                        <option value="analysis">Analysis</option>
                        <option value="interview">Interview</option>
                        <option value="feature">Feature</option>
                        <option value="opinion">Opinion</option>
                        <option value="preview">Preview</option>
                        <option value="report">Report</option>
                      </select>
                    </div>
                  </div>
                </div>

                <!-- Media -->
                <div class="card">
                  <div class="card-header">
                    <h3 class="card-title">Featured Image</h3>
                  </div>
                  <div class="card-body">
                    <div class="image-preview" id="image-preview">
                      <div class="image-preview-placeholder">No image</div>
                    </div>
                    <input type="hidden" id="article-image-url">
                    <button class="btn btn-outline w-full mt-md" onclick="Pages.uploadImage()">
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12"/>
                      </svg>
                      Upload Image
                    </button>
                  </div>
                </div>

                <!-- Options -->
                <div class="card">
                  <div class="card-header">
                    <h3 class="card-title">Options</h3>
                  </div>
                  <div class="card-body">
                    <label class="form-check mb-sm">
                      <input type="checkbox" class="form-check-input" id="article-featured">
                      <span class="form-check-label">Featured Article</span>
                    </label>
                    <label class="form-check mb-sm">
                      <input type="checkbox" class="form-check-input" id="article-trending">
                      <span class="form-check-label">Trending</span>
                    </label>
                    <label class="form-check mb-sm">
                      <input type="checkbox" class="form-check-input" id="article-pinned">
                      <span class="form-check-label">Pin to Top</span>
                    </label>
                    <label class="form-check">
                      <input type="checkbox" class="form-check-input" id="article-breaking">
                      <span class="form-check-label">Breaking News</span>
                    </label>
                  </div>
                </div>

                <!-- SEO -->
                <div class="card">
                  <div class="card-header">
                    <h3 class="card-title">SEO</h3>
                  </div>
                  <div class="card-body">
                    <div class="form-group">
                      <label class="form-label">Meta Title</label>
                      <input type="text" class="form-input" id="article-meta-title" placeholder="SEO title">
                    </div>
                    <div class="form-group mb-0">
                      <label class="form-label">Meta Description</label>
                      <textarea class="form-textarea" id="article-meta-description" rows="2" placeholder="SEO description"></textarea>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();

    // Auto-generate slug
    document.getElementById('article-title')?.addEventListener('input', (e) => {
      const slugInput = document.getElementById('article-slug');
      if (!slugInput.value) {
        slugInput.value = Utils.slugify(e.target.value);
      }
    });

    // Load sports for dropdown
    this.loadSportDropdown();

    // Load article if editing
    if (!isNew) {
      this.loadArticleForEdit(id);
    }
  },

  // Load sport dropdown
  async loadSportDropdown() {
    try {
      const sports = await API.get('sports?select=id,name&order=name.asc&is_active=eq.true');
      const select = document.getElementById('article-sport');
      
      if (sports && select) {
        sports.forEach(sport => {
          const option = document.createElement('option');
          option.value = sport.id;
          option.textContent = sport.name;
          select.appendChild(option);
        });

        // Load leagues when sport changes
        select.addEventListener('change', () => this.loadLeagueDropdown(select.value));
      }
    } catch (error) {
      console.error('Failed to load sports:', error);
    }
  },

  // Load league dropdown
  async loadLeagueDropdown(sportId) {
    const select = document.getElementById('article-league');
    select.innerHTML = '<option value="">Loading...</option>';
    select.disabled = !sportId;

    if (!sportId) {
      select.innerHTML = '<option value="">Select League</option>';
      return;
    }

    try {
      const leagues = await API.get(`leagues?select=id,name&sport_id=eq.${sportId}&order=name.asc&is_active=eq.true`);
      select.innerHTML = '<option value="">Select League</option>';
      
      if (leagues) {
        leagues.forEach(league => {
          const option = document.createElement('option');
          option.value = league.id;
          option.textContent = league.name;
          select.appendChild(option);
        });
      }
    } catch (error) {
      console.error('Failed to load leagues:', error);
      select.innerHTML = '<option value="">Error loading leagues</option>';
    }
  },

  // Load article for editing
  async loadArticleForEdit(id) {
    try {
      const article = await API.get(`articles?id=eq.${id}&select=*`);
      
      if (article && article.length > 0) {
        const a = article[0];
        document.getElementById('editor-subtitle').textContent = `Editing: ${a.title}`;
        
        document.getElementById('article-title').value = a.title || '';
        document.getElementById('article-slug').value = a.slug || '';
        document.getElementById('article-excerpt').value = a.excerpt || '';
        document.getElementById('article-content').value = a.content || '';
        document.getElementById('article-status').value = a.status || 'draft';
        document.getElementById('article-type').value = a.type || 'news';
        document.getElementById('article-featured').checked = a.is_featured || false;
        document.getElementById('article-trending').checked = a.is_trending || false;
        document.getElementById('article-pinned').checked = a.is_pinned || false;
        document.getElementById('article-breaking').checked = a.is_breaking || false;
        document.getElementById('article-meta-title').value = a.meta_title || '';
        document.getElementById('article-meta-description').value = a.meta_description || '';
        
        if (a.sport_id) {
          document.getElementById('article-sport').value = a.sport_id;
          await this.loadLeagueDropdown(a.sport_id);
          if (a.league_id) {
            document.getElementById('article-league').value = a.league_id;
          }
        }
        
        if (a.featured_image_url) {
          document.getElementById('article-image-url').value = a.featured_image_url;
          document.getElementById('image-preview').innerHTML = `<img src="${a.featured_image_url}" alt="">`;
        }

        // Store article ID for saving
        window.editingArticleId = id;
      }
    } catch (error) {
      console.error('Failed to load article:', error);
      Toast.error('Error', 'Failed to load article');
    }
  },

  // Save article
  async saveArticle(status = 'draft') {
    const title = document.getElementById('article-title').value;
    if (!title) {
      Toast.error('Error', 'Title is required');
      return;
    }

    const data = {
      title,
      slug: document.getElementById('article-slug').value || Utils.slugify(title),
      excerpt: document.getElementById('article-excerpt').value,
      content: document.getElementById('article-content').value,
      status: status,
      type: document.getElementById('article-type').value,
      sport_id: document.getElementById('article-sport').value || null,
      league_id: document.getElementById('article-league').value || null,
      is_featured: document.getElementById('article-featured').checked,
      is_trending: document.getElementById('article-trending').checked,
      is_pinned: document.getElementById('article-pinned').checked,
      is_breaking: document.getElementById('article-breaking').checked,
      meta_title: document.getElementById('article-meta-title').value,
      meta_description: document.getElementById('article-meta-description').value,
      featured_image_url: document.getElementById('article-image-url').value || null,
    };

    if (status === 'published') {
      data.published_at = new Date().toISOString();
    }

    try {
      if (window.editingArticleId) {
        await API.patch(`articles?id=eq.${window.editingArticleId}`, data);
        Toast.success('Updated', 'Article saved successfully');
      } else {
        const result = await API.post('articles', data);
        Toast.success('Created', 'Article created successfully');
        window.editingArticleId = result.id;
      }
      
      Router.navigate('/articles');
    } catch (error) {
      console.error('Failed to save article:', error);
      Toast.error('Error', 'Failed to save article');
    }
  },

  // Sports Page
  sports() {
    if (!Auth.requireRole('super_admin', 'admin')) return;

    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content-full">
            <div class="page-header">
              <div>
                <h1 class="page-title">Sports</h1>
                <p class="page-subtitle">Manage sports categories and sections</p>
              </div>
              <button class="btn btn-primary" onclick="Pages.sportModal()">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 5v14M5 12h14"/>
                </svg>
                Add Sport
              </button>
            </div>

            <div class="card">
              <div class="table-container">
                <table class="table">
                  <thead>
                    <tr>
                      <th>Sport</th>
                      <th>Icon</th>
                      <th>Slug</th>
                      <th>Nav Placement</th>
                      <th>Leagues</th>
                      <th>Articles</th>
                      <th>Status</th>
                      <th width="120">Actions</th>
                    </tr>
                  </thead>
                  <tbody id="sports-list">
                    <tr><td colspan="8" class="text-center p-xl"><div class="spinner" style="margin: 0 auto;"></div></td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadSports();
  },

  // Load sports
  async loadSports() {
    try {
      const sports = await API.get('sports?select=*,leagues(id),articles(id)&order=nav_order.asc');

      const tbody = document.getElementById('sports-list');
      if (!sports || sports.length === 0) {
        tbody.innerHTML = `
          <tr>
            <td colspan="8" class="text-center p-xl">
              <div class="empty-state">
                <div class="empty-state-icon">⚽</div>
                <div class="empty-state-title">No sports yet</div>
                <div class="empty-state-message">Add your first sport to get started</div>
              </div>
            </td>
          </tr>
        `;
        return;
      }

      tbody.innerHTML = sports.map(sport => `
        <tr>
          <td>
            <div class="font-medium">${sport.name}</div>
            <div class="text-xs text-gray-500">${sport.description || ''}</div>
          </td>
          <td class="text-xl">${sport.icon || '⚽'}</td>
          <td><code class="text-sm">${sport.slug}</code></td>
          <td>
            <span class="badge ${sport.nav_placement === 'top' ? 'badge-primary' : 'badge-gray'}">
              ${sport.nav_placement === 'top' ? 'Top Nav' : 'Dropdown'}
            </span>
          </td>
          <td>${sport.leagues?.length || 0}</td>
          <td>${sport.articles?.length || 0}</td>
          <td>
            <span class="badge ${sport.is_active ? 'badge-success' : 'badge-gray'}">
              ${sport.is_active ? 'Active' : 'Inactive'}
            </span>
          </td>
          <td>
            <div class="table-actions">
              <button class="btn btn-icon btn-ghost btn-sm" title="Edit" onclick="Pages.sportModal('${sport.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="btn btn-icon btn-ghost btn-sm" title="Leagues" onclick="Router.navigate('/leagues?sport=${sport.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/>
                </svg>
              </button>
              <button class="btn btn-icon btn-ghost btn-sm" title="Delete" onclick="Pages.deleteSport('${sport.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
                </svg>
              </button>
            </div>
          </td>
        </tr>
      `).join('');

    } catch (error) {
      console.error('Failed to load sports:', error);
      Toast.error('Error', 'Failed to load sports');
    }
  },

  // Sport Modal
  async sportModal(id = null) {
    const isEdit = !!id;
    let sport = { name: '', slug: '', icon: '', description: '', nav_placement: 'dropdown', is_active: true, show_in_nav: true };

    if (isEdit) {
      try {
        const data = await API.get(`sports?id=eq.${id}&select=*`);
        if (data && data.length > 0) {
          sport = data[0];
        }
      } catch (error) {
        Toast.error('Error', 'Failed to load sport');
        return;
      }
    }

    Modal.show({
      title: isEdit ? 'Edit Sport' : 'Add Sport',
      content: `
        <form id="sport-form">
          <div class="form-row">
            <div class="form-group">
              <label class="form-label required">Name</label>
              <input type="text" class="form-input" id="sport-name" value="${sport.name}" required>
            </div>
            <div class="form-group">
              <label class="form-label">Icon</label>
              <input type="text" class="form-input" id="sport-icon" value="${sport.icon}" placeholder="⚽">
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Slug</label>
            <input type="text" class="form-input" id="sport-slug" value="${sport.slug}">
            <p class="form-hint">Leave empty to auto-generate from name</p>
          </div>
          <div class="form-group">
            <label class="form-label">Description</label>
            <textarea class="form-textarea" id="sport-description" rows="2">${sport.description || ''}</textarea>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Nav Placement</label>
              <select class="form-select" id="sport-placement">
                <option value="dropdown" ${sport.nav_placement === 'dropdown' ? 'selected' : ''}>Dropdown</option>
                <option value="top" ${sport.nav_placement === 'top' ? 'selected' : ''}>Top Navigation</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Status</label>
              <select class="form-select" id="sport-active">
                <option value="true" ${sport.is_active ? 'selected' : ''}>Active</option>
                <option value="false" ${!sport.is_active ? 'selected' : ''}>Inactive</option>
              </select>
            </div>
          </div>
          <label class="form-check">
            <input type="checkbox" class="form-check-input" id="sport-nav" ${sport.show_in_nav ? 'checked' : ''}>
            <span class="form-check-label">Show in Navigation</span>
          </label>
        </form>
      `,
      footer: `
        <button class="btn btn-secondary" data-close>Cancel</button>
        <button class="btn btn-primary" onclick="Pages.saveSport('${id || ''}')">${isEdit ? 'Update' : 'Create'} Sport</button>
      `,
    });

    // Auto-generate slug
    document.getElementById('sport-name')?.addEventListener('input', (e) => {
      const slugInput = document.getElementById('sport-slug');
      if (!slugInput.value || slugInput.dataset.auto === 'true') {
        slugInput.value = Utils.slugify(e.target.value);
        slugInput.dataset.auto = 'true';
      }
    });
  },

  // Save sport
  async saveSport(id) {
    const name = document.getElementById('sport-name').value;
    if (!name) {
      Toast.error('Error', 'Name is required');
      return;
    }

    const data = {
      name,
      slug: document.getElementById('sport-slug').value || Utils.slugify(name),
      icon: document.getElementById('sport-icon').value,
      description: document.getElementById('sport-description').value,
      nav_placement: document.getElementById('sport-placement').value,
      is_active: document.getElementById('sport-active').value === 'true',
      show_in_nav: document.getElementById('sport-nav').checked,
    };

    try {
      if (id) {
        await API.patch(`sports?id=eq.${id}`, data);
        Toast.success('Updated', 'Sport updated successfully');
      } else {
        await API.post('sports', data);
        Toast.success('Created', 'Sport created successfully');
      }
      Modal.hide();
      this.loadSports();
    } catch (error) {
      console.error('Failed to save sport:', error);
      Toast.error('Error', 'Failed to save sport');
    }
  },

  // Delete sport
  async deleteSport(id) {
    const confirmed = await Modal.confirm({
      title: 'Delete Sport',
      message: 'Are you sure? This will also delete all leagues and articles under this sport.',
      type: 'danger',
      confirmText: 'Delete',
    });

    if (confirmed) {
      try {
        await API.delete(`sports?id=eq.${id}`);
        Toast.success('Deleted', 'Sport deleted successfully');
        this.loadSports();
      } catch (error) {
        Toast.error('Error', 'Failed to delete sport');
      }
    }
  },

  // Leagues Page
  leagues() {
    if (!Auth.requireRole('super_admin', 'admin')) return;

    const app = document.getElementById('app');
    const sportFilter = new URLSearchParams(window.location.search).get('sport') || '';

    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content-full">
            <div class="page-header">
              <div>
                <h1 class="page-title">Leagues</h1>
                <p class="page-subtitle">Manage leagues and competitions</p>
              </div>
              <button class="btn btn-primary" onclick="Pages.leagueModal()">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 5v14M5 12h14"/>
                </svg>
                Add League
              </button>
            </div>

            <div class="filters-bar">
              <select class="filter-select" id="filter-sport" onchange="Pages.loadLeagues()">
                <option value="">All Sports</option>
              </select>
              <select class="filter-select" id="filter-status" onchange="Pages.loadLeagues()">
                <option value="">All Status</option>
                <option value="true">Active</option>
                <option value="false">Inactive</option>
              </select>
            </div>

            <div class="card">
              <div class="table-container">
                <table class="table">
                  <thead>
                    <tr>
                      <th>League</th>
                      <th>Sport</th>
                      <th>Slug</th>
                      <th>Order</th>
                      <th>Articles</th>
                      <th>Status</th>
                      <th width="120">Actions</th>
                    </tr>
                  </thead>
                  <tbody id="leagues-list">
                    <tr><td colspan="7" class="text-center p-xl"><div class="spinner" style="margin: 0 auto;"></div></td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadSportFilter();
    this.loadLeagues();
  },

  // Load sport filter
  async loadSportFilter() {
    try {
      const sports = await API.get('sports?select=id,name&order=name.asc&is_active=eq.true');
      const select = document.getElementById('filter-sport');
      
      if (sports && select) {
        sports.forEach(sport => {
          const option = document.createElement('option');
          option.value = sport.id;
          option.textContent = sport.name;
          select.appendChild(option);
        });
      }
    } catch (error) {
      console.error('Failed to load sports:', error);
    }
  },

  // Load leagues
  async loadLeagues() {
    const sportId = document.getElementById('filter-sport')?.value || '';
    const isActive = document.getElementById('filter-status')?.value || '';

    try {
      let query = 'leagues?select=*,sports(name),articles(id)&order=display_order.asc';
      if (sportId) query += `&sport_id=eq.${sportId}`;
      if (isActive) query += `&is_active=eq.${isActive}`;

      const leagues = await API.get(query);
      const tbody = document.getElementById('leagues-list');

      if (!leagues || leagues.length === 0) {
        tbody.innerHTML = `
          <tr>
            <td colspan="7" class="text-center p-xl">
              <div class="empty-state">
                <div class="empty-state-icon">🏆</div>
                <div class="empty-state-title">No leagues found</div>
              </div>
            </td>
          </tr>
        `;
        return;
      }

      tbody.innerHTML = leagues.map(league => `
        <tr>
          <td>
            <div class="font-medium">${league.name}</div>
            <div class="text-xs text-gray-500">${league.short_name || league.slug}</div>
          </td>
          <td>${league.sports?.name || '-'}</td>
          <td><code class="text-sm">${league.slug}</code></td>
          <td>${league.display_order}</td>
          <td>${league.articles?.length || 0}</td>
          <td>
            <span class="badge ${league.is_active ? 'badge-success' : 'badge-gray'}">
              ${league.is_active ? 'Active' : 'Inactive'}
            </span>
          </td>
          <td>
            <div class="table-actions">
              <button class="btn btn-icon btn-ghost btn-sm" title="Edit" onclick="Pages.leagueModal('${league.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="btn btn-icon btn-ghost btn-sm" title="Delete" onclick="Pages.deleteLeague('${league.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
                </svg>
              </button>
            </div>
          </td>
        </tr>
      `).join('');

    } catch (error) {
      console.error('Failed to load leagues:', error);
      Toast.error('Error', 'Failed to load leagues');
    }
  },

  // League Modal
  async leagueModal(id = null) {
    const isEdit = !!id;
    let league = { name: '', slug: '', short_name: '', icon: '', description: '', sport_id: '', display_order: 0, is_active: true };

    if (isEdit) {
      try {
        const data = await API.get(`leagues?id=eq.${id}&select=*`);
        if (data && data.length > 0) {
          league = data[0];
        }
      } catch (error) {
        Toast.error('Error', 'Failed to load league');
        return;
      }
    }

    const sports = await API.get('sports?select=id,name&order=name.asc&is_active=eq.true');

    Modal.show({
      title: isEdit ? 'Edit League' : 'Add League',
      size: 'lg',
      content: `
        <form id="league-form">
          <div class="form-row">
            <div class="form-group">
              <label class="form-label required">Name</label>
              <input type="text" class="form-input" id="league-name" value="${league.name}" required>
            </div>
            <div class="form-group">
              <label class="form-label">Short Name</label>
              <input type="text" class="form-input" id="league-short" value="${league.short_name || ''}" placeholder="e.g., PL, UCL">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label required">Sport</label>
              <select class="form-select" id="league-sport" required>
                <option value="">Select Sport</option>
                ${sports?.map(s => `<option value="${s.id}" ${s.id === league.sport_id ? 'selected' : ''}>${s.name}</option>`).join('') || ''}
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Display Order</label>
              <input type="number" class="form-input" id="league-order" value="${league.display_order}" min="0">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Slug</label>
              <input type="text" class="form-input" id="league-slug" value="${league.slug}">
            </div>
            <div class="form-group">
              <label class="form-label">Icon</label>
              <input type="text" class="form-input" id="league-icon" value="${league.icon || ''}" placeholder="🏆">
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Description</label>
            <textarea class="form-textarea" id="league-description" rows="2">${league.description || ''}</textarea>
          </div>
          <label class="form-check">
            <input type="checkbox" class="form-check-input" id="league-active" ${league.is_active ? 'checked' : ''}>
            <span class="form-check-label">Active</span>
          </label>
        </form>
      `,
      footer: `
        <button class="btn btn-secondary" data-close>Cancel</button>
        <button class="btn btn-primary" onclick="Pages.saveLeague('${id || ''}')">${isEdit ? 'Update' : 'Create'} League</button>
      `,
    });

    document.getElementById('league-name')?.addEventListener('input', (e) => {
      const slugInput = document.getElementById('league-slug');
      if (!slugInput.value) {
        slugInput.value = Utils.slugify(e.target.value);
      }
    });
  },

  // Save league
  async saveLeague(id) {
    const name = document.getElementById('league-name').value;
    const sportId = document.getElementById('league-sport').value;

    if (!name || !sportId) {
      Toast.error('Error', 'Name and Sport are required');
      return;
    }

    const data = {
      name,
      slug: document.getElementById('league-slug').value || Utils.slugify(name),
      short_name: document.getElementById('league-short').value,
      icon: document.getElementById('league-icon').value,
      description: document.getElementById('league-description').value,
      sport_id: sportId,
      display_order: parseInt(document.getElementById('league-order').value) || 0,
      is_active: document.getElementById('league-active').checked,
    };

    try {
      if (id) {
        await API.patch(`leagues?id=eq.${id}`, data);
        Toast.success('Updated', 'League updated successfully');
      } else {
        await API.post('leagues', data);
        Toast.success('Created', 'League created successfully');
      }
      Modal.hide();
      this.loadLeagues();
    } catch (error) {
      console.error('Failed to save league:', error);
      Toast.error('Error', 'Failed to save league');
    }
  },

  // Delete league
  async deleteLeague(id) {
    const confirmed = await Modal.confirm({
      title: 'Delete League',
      message: 'Are you sure? This will also delete all articles under this league.',
      type: 'danger',
      confirmText: 'Delete',
    });

    if (confirmed) {
      try {
        await API.delete(`leagues?id=eq.${id}`);
        Toast.success('Deleted', 'League deleted successfully');
        this.loadLeagues();
      } catch (error) {
        Toast.error('Error', 'Failed to delete league');
      }
    }
  },

  // Live Scores Page
  liveScores() {
    if (!Auth.requireAuth()) return;

    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content-full">
            <div class="page-header">
              <div>
                <h1 class="page-title">Live Scores</h1>
                <p class="page-subtitle">Manage live match scores and results</p>
              </div>
              <div class="flex gap-sm">
                <button class="btn btn-secondary" onclick="Pages.syncLiveScores()">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M23 4v6h-6M1 20v-6h6"/>
                    <path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/>
                  </svg>
                  Sync Scores
                </button>
                <button class="btn btn-primary" onclick="Pages.matchModal()">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 5v14M5 12h14"/>
                  </svg>
                  Add Match
                </button>
              </div>
            </div>

            <div class="filters-bar">
              <select class="filter-select" id="filter-sport" onchange="Pages.loadMatches()">
                <option value="">All Sports</option>
              </select>
              <select class="filter-select" id="filter-status" onchange="Pages.loadMatches()">
                <option value="">All Status</option>
                <option value="live">Live</option>
                <option value="scheduled">Scheduled</option>
                <option value="finished">Finished</option>
              </select>
              <input type="date" class="form-input" id="filter-date" onchange="Pages.loadMatches()" style="width: auto;">
            </div>

            <div class="card">
              <div class="table-container">
                <table class="table">
                  <thead>
                    <tr>
                      <th>Match</th>
                      <th>Sport</th>
                      <th>League</th>
                      <th>Score</th>
                      <th>Status</th>
                      <th>Date/Time</th>
                      <th width="120">Actions</th>
                    </tr>
                  </thead>
                  <tbody id="matches-list">
                    <tr><td colspan="7" class="text-center p-xl"><div class="spinner" style="margin: 0 auto;"></div></td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadSportFilter();
    this.loadMatches();
  },

  // Load matches
  async loadMatches() {
    const sportId = document.getElementById('filter-sport')?.value || '';
    const status = document.getElementById('filter-status')?.value || '';
    const date = document.getElementById('filter-date')?.value || '';

    try {
      let query = 'live_matches?select=*,sports(name),leagues(name)&order=match_date.desc,match_time.desc';
      if (sportId) query += `&sport_id=eq.${sportId}`;
      if (status) query += `&status=eq.${status}`;
      if (date) query += `&match_date=eq.${date}`;

      const matches = await API.get(query);
      const tbody = document.getElementById('matches-list');

      if (!matches || matches.length === 0) {
        tbody.innerHTML = `
          <tr>
            <td colspan="7" class="text-center p-xl">
              <div class="empty-state">
                <div class="empty-state-icon">🏟️</div>
                <div class="empty-state-title">No matches found</div>
              </div>
            </td>
          </tr>
        `;
        return;
      }

      tbody.innerHTML = matches.map(match => `
        <tr>
          <td>
            <div class="font-medium">${match.team_a_name} vs ${match.team_b_name}</div>
            <div class="text-xs text-gray-500">${match.venue || 'TBD'}</div>
          </td>
          <td>${match.sports?.name || '-'}</td>
          <td>${match.leagues?.name || '-'}</td>
          <td>
            <span class="font-bold text-lg">${match.team_a_score} - ${match.team_b_score}</span>
          </td>
          <td>
            <span class="status-badge ${match.status}">${match.status}${match.minute_played ? ` (${match.minute_played}')` : ''}</span>
          </td>
          <td>
            <div>${Utils.formatDate(match.match_date)}</div>
            <div class="text-xs text-gray-500">${match.match_time || ''}</div>
          </td>
          <td>
            <div class="table-actions">
              <button class="btn btn-icon btn-ghost btn-sm" title="Quick Score" onclick="Pages.quickScore('${match.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 20h9M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/>
                </svg>
              </button>
              <button class="btn btn-icon btn-ghost btn-sm" title="Edit" onclick="Pages.matchModal('${match.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="btn btn-icon btn-ghost btn-sm" title="Delete" onclick="Pages.deleteMatch('${match.id}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
                </svg>
              </button>
            </div>
          </td>
        </tr>
      `).join('');

    } catch (error) {
      console.error('Failed to load matches:', error);
      Toast.error('Error', 'Failed to load matches');
    }
  },

  // Match Modal
  async matchModal(id = null) {
    const isEdit = !!id;
    let match = {
      sport_id: '', league_id: '', team_a_name: '', team_b_name: '',
      team_a_score: 0, team_b_score: 0, status: 'scheduled',
      match_date: '', match_time: '', venue: '', round: '', is_featured: false
    };

    if (isEdit) {
      try {
        const data = await API.get(`live_matches?id=eq.${id}&select=*`);
        if (data && data.length > 0) {
          match = { ...match, ...data[0] };
        }
      } catch (error) {
        Toast.error('Error', 'Failed to load match');
        return;
      }
    }

    const sports = await API.get('sports?select=id,name&order=name.asc&is_active=eq.true');

    Modal.show({
      title: isEdit ? 'Edit Match' : 'Add Match',
      size: 'lg',
      content: `
        <form id="match-form">
          <div class="form-row">
            <div class="form-group">
              <label class="form-label required">Sport</label>
              <select class="form-select" id="match-sport" required onchange="Pages.loadLeaguesForMatch(this.value)">
                <option value="">Select Sport</option>
                ${sports?.map(s => `<option value="${s.id}" ${s.id === match.sport_id ? 'selected' : ''}>${s.name}</option>`).join('') || ''}
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">League</label>
              <select class="form-select" id="match-league">
                <option value="">Select League</option>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label required">Team A</label>
              <input type="text" class="form-input" id="match-team-a" value="${match.team_a_name}" required>
            </div>
            <div class="form-group">
              <label class="form-label required">Team B</label>
              <input type="text" class="form-input" id="match-team-b" value="${match.team_b_name}" required>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Team A Score</label>
              <input type="number" class="form-input" id="match-score-a" value="${match.team_a_score}" min="0">
            </div>
            <div class="form-group">
              <label class="form-label">Team B Score</label>
              <input type="number" class="form-input" id="match-score-b" value="${match.team_b_score}" min="0">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label required">Date</label>
              <input type="date" class="form-input" id="match-date" value="${match.match_date}" required>
            </div>
            <div class="form-group">
              <label class="form-label">Time</label>
              <input type="time" class="form-input" id="match-time" value="${match.match_time || ''}">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Status</label>
              <select class="form-select" id="match-status">
                <option value="scheduled" ${match.status === 'scheduled' ? 'selected' : ''}>Scheduled</option>
                <option value="live" ${match.status === 'live' ? 'selected' : ''}>Live</option>
                <option value="halftime" ${match.status === 'halftime' ? 'selected' : ''}>Halftime</option>
                <option value="finished" ${match.status === 'finished' ? 'selected' : ''}>Finished</option>
                <option value="postponed" ${match.status === 'postponed' ? 'selected' : ''}>Postponed</option>
                <option value="cancelled" ${match.status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Round</label>
              <input type="text" class="form-input" id="match-round" value="${match.round || ''}" placeholder="e.g., Round 15, Semi-final">
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Venue</label>
            <input type="text" class="form-input" id="match-venue" value="${match.venue || ''}">
          </div>
          <label class="form-check">
            <input type="checkbox" class="form-check-input" id="match-featured" ${match.is_featured ? 'checked' : ''}>
            <span class="form-check-label">Featured Match</span>
          </label>
        </form>
      `,
      footer: `
        <button class="btn btn-secondary" data-close>Cancel</button>
        <button class="btn btn-primary" onclick="Pages.saveMatch('${id || ''}')">${isEdit ? 'Update' : 'Create'} Match</button>
      `,
    });

    if (match.sport_id) {
      this.loadLeaguesForMatch(match.sport_id, match.league_id);
    }
  },

  // Load leagues for match
  async loadLeaguesForMatch(sportId, selectedLeagueId = null) {
    const select = document.getElementById('match-league');
    select.innerHTML = '<option value="">Loading...</option>';

    if (!sportId) {
      select.innerHTML = '<option value="">Select League</option>';
      return;
    }

    try {
      const leagues = await API.get(`leagues?select=id,name&sport_id=eq.${sportId}&order=name.asc&is_active=eq.true`);
      select.innerHTML = '<option value="">Select League</option>';
      
      if (leagues) {
        leagues.forEach(league => {
          const option = document.createElement('option');
          option.value = league.id;
          option.textContent = league.name;
          if (league.id === selectedLeagueId) option.selected = true;
          select.appendChild(option);
        });
      }
    } catch (error) {
      console.error('Failed to load leagues:', error);
    }
  },

  // Save match
  async saveMatch(id) {
    const teamA = document.getElementById('match-team-a').value;
    const teamB = document.getElementById('match-team-b').value;
    const sportId = document.getElementById('match-sport').value;
    const date = document.getElementById('match-date').value;

    if (!teamA || !teamB || !date) {
      Toast.error('Error', 'Team A, Team B, and Date are required');
      return;
    }

    const data = {
      sport_id: sportId,
      league_id: document.getElementById('match-league').value || null,
      team_a_name: teamA,
      team_b_name: teamB,
      team_a_score: parseInt(document.getElementById('match-score-a').value) || 0,
      team_b_score: parseInt(document.getElementById('match-score-b').value) || 0,
      status: document.getElementById('match-status').value,
      match_date: date,
      match_time: document.getElementById('match-time').value || null,
      venue: document.getElementById('match-venue').value,
      round: document.getElementById('match-round').value,
      is_featured: document.getElementById('match-featured').checked,
    };

    try {
      if (id) {
        await API.patch(`live_matches?id=eq.${id}`, data);
        Toast.success('Updated', 'Match updated successfully');
      } else {
        await API.post('live_matches', data);
        Toast.success('Created', 'Match created successfully');
      }
      Modal.hide();
      this.loadMatches();
    } catch (error) {
      console.error('Failed to save match:', error);
      Toast.error('Error', 'Failed to save match');
    }
  },

  // Quick score update
  async quickScore(id) {
    const data = await API.get(`live_matches?id=eq.${id}&select=*`);
    if (!data || !data[0]) return;

    const match = data[0];

    Modal.show({
      title: 'Quick Score Update',
      content: `
        <div class="text-center mb-lg">
          <div class="text-2xl font-bold mb-sm">${match.team_a_name}</div>
          <div class="text-4xl font-bold mb-sm">
            <input type="number" class="form-input" id="quick-score-a" value="${match.team_a_score}" min="0" style="width: 80px; text-align: center; display: inline;">
            <span class="mx-md">-</span>
            <input type="number" class="form-input" id="quick-score-b" value="${match.team_b_score}" min="0" style="width: 80px; text-align: center; display: inline;">
          </div>
          <div class="text-2xl font-bold mt-sm">${match.team_b_name}</div>
        </div>
        <div class="form-group">
          <label class="form-label">Minute Played</label>
          <input type="number" class="form-input" id="quick-minute" value="${match.minute_played || 0}" min="0" max="120">
        </div>
        <div class="form-group">
          <label class="form-label">Status</label>
          <select class="form-select" id="quick-status">
            <option value="live" ${match.status === 'live' ? 'selected' : ''}>Live</option>
            <option value="halftime" ${match.status === 'halftime' ? 'selected' : ''}>Halftime</option>
            <option value="finished" ${match.status === 'finished' ? 'selected' : ''}>Finished</option>
          </select>
        </div>
      `,
      footer: `
        <button class="btn btn-secondary" data-close>Cancel</button>
        <button class="btn btn-primary" onclick="Pages.updateQuickScore('${id}')">Update Score</button>
      `,
    });
  },

  // Update quick score
  async updateQuickScore(id) {
    try {
      await API.patch(`live_matches?id=eq.${id}`, {
        team_a_score: parseInt(document.getElementById('quick-score-a').value) || 0,
        team_b_score: parseInt(document.getElementById('quick-score-b').value) || 0,
        minute_played: parseInt(document.getElementById('quick-minute').value) || null,
        status: document.getElementById('quick-status').value,
      });
      Toast.success('Updated', 'Score updated successfully');
      Modal.hide();
      this.loadMatches();
    } catch (error) {
      Toast.error('Error', 'Failed to update score');
    }
  },

  // Delete match
  async deleteMatch(id) {
    const confirmed = await Modal.confirm({
      title: 'Delete Match',
      message: 'Are you sure you want to delete this match?',
      type: 'danger',
      confirmText: 'Delete',
    });

    if (confirmed) {
      try {
        await API.delete(`live_matches?id=eq.${id}`);
        Toast.success('Deleted', 'Match deleted successfully');
        this.loadMatches();
      } catch (error) {
        Toast.error('Error', 'Failed to delete match');
      }
    }
  },

  // Users Page
  users() {
    if (!Auth.requireRole('super_admin', 'admin')) return;

    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content-full">
            <div class="page-header">
              <div>
                <h1 class="page-title">Users</h1>
                <p class="page-subtitle">Manage admin users and permissions</p>
              </div>
            </div>

            <div class="card">
              <div class="table-container">
                <table class="table">
                  <thead>
                    <tr>
                      <th>User</th>
                      <th>Role</th>
                      <th>Status</th>
                      <th>Last Login</th>
                      <th>Created</th>
                      <th width="120">Actions</th>
                    </tr>
                  </thead>
                  <tbody id="users-list">
                    <tr><td colspan="6" class="text-center p-xl"><div class="spinner" style="margin: 0 auto;"></div></td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadUsers();
  },

  // Load users
  async loadUsers() {
    try {
      const users = await API.get('profiles?select=*&order=created_at.desc');
      const tbody = document.getElementById('users-list');

      if (!users || users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center p-xl text-gray-500">No users found</td></tr>';
        return;
      }

      const roleColors = {
        super_admin: 'badge-danger',
        admin: 'badge-warning',
        editor: 'badge-primary',
        author: 'badge-success',
        viewer: 'badge-gray',
      };

      tbody.innerHTML = users.map(user => `
        <tr>
          <td>
            <div class="flex items-center gap-sm">
              <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white text-sm font-medium">
                ${Utils.getInitials(user.full_name || user.email)}
              </div>
              <div>
                <div class="font-medium">${user.full_name || 'No name'}</div>
                <div class="text-xs text-gray-500">${user.email}</div>
              </div>
            </div>
          </td>
          <td><span class="badge ${roleColors[user.role] || 'badge-gray'}">${(user.role || 'viewer').replace('_', ' ')}</span></td>
          <td>
            <span class="badge ${user.is_active ? 'badge-success' : 'badge-gray'}">
              ${user.is_active ? 'Active' : 'Inactive'}
            </span>
          </td>
          <td>${user.last_login_at ? Utils.formatDate(user.last_login_at, 'datetime') : 'Never'}</td>
          <td>${Utils.formatDate(user.created_at)}</td>
          <td>
            <div class="table-actions">
              <button class="btn btn-icon btn-ghost btn-sm" title="Change Role" onclick="Pages.changeRole('${user.id}', '${user.role}')">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                </svg>
              </button>
            </div>
          </td>
        </tr>
      `).join('');

    } catch (error) {
      console.error('Failed to load users:', error);
      Toast.error('Error', 'Failed to load users');
    }
  },

  // Change role
  async changeRole(userId, currentRole) {
    const roles = ['super_admin', 'admin', 'editor', 'author', 'viewer'];

    Modal.show({
      title: 'Change User Role',
      content: `
        <div class="space-y-sm">
          ${roles.map(role => `
            <label class="form-check" style="padding: var(--spacing-sm); border: 1px solid var(--border-color); border-radius: var(--border-radius); cursor: pointer;">
              <input type="radio" name="user-role" value="${role}" ${role === currentRole ? 'checked' : ''}>
              <span class="form-check-label" style="margin-left: var(--spacing-sm);">
                <strong>${role.replace('_', ' ')}</strong>
                <div class="text-xs text-gray-500">${this.getRoleDescription(role)}</div>
              </span>
            </label>
          `).join('')}
        </div>
      `,
      footer: `
        <button class="btn btn-secondary" data-close>Cancel</button>
        <button class="btn btn-primary" onclick="Pages.saveRole('${userId}')">Update Role</button>
      `,
    });
  },

  getRoleDescription(role) {
    const descriptions = {
      super_admin: 'Full system access',
      admin: 'Manage content and users',
      editor: 'Edit and publish content',
      author: 'Create own content',
      viewer: 'Read-only access',
    };
    return descriptions[role] || '';
  },

  // Save role
  async saveRole(userId) {
    const newRole = document.querySelector('input[name="user-role"]:checked')?.value;
    if (!newRole) {
      Toast.error('Error', 'Please select a role');
      return;
    }

    try {
      await API.patch(`profiles?id=eq.${userId}`, { role: newRole });
      Toast.success('Updated', 'User role updated successfully');
      Modal.hide();
      this.loadUsers();
    } catch (error) {
      Toast.error('Error', 'Failed to update role');
    }
  },

  // Settings Page
  settings() {
    if (!Auth.requireRole('super_admin', 'admin')) return;

    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content">
            <div class="page-header">
              <div>
                <h1 class="page-title">Settings</h1>
                <p class="page-subtitle">Configure site settings and preferences</p>
              </div>
              <button class="btn btn-primary" onclick="Pages.saveSettings()">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/>
                  <path d="M17 21v-8H7v8M7 3v5h8"/>
                </svg>
                Save Settings
              </button>
            </div>

            <div class="tabs">
              <button class="tab active" data-tab="general">General</button>
              <button class="tab" data-tab="social">Social</button>
              <button class="tab" data-tab="content">Content</button>
              <button class="tab" data-tab="seo">SEO</button>
            </div>

            <div class="card" id="settings-general">
              <div class="card-header">
                <h3 class="card-title">General Settings</h3>
              </div>
              <div class="card-body">
                <div class="form-group">
                  <label class="form-label">Site Name</label>
                  <input type="text" class="form-input" id="setting-site_name">
                </div>
                <div class="form-group">
                  <label class="form-label">Tagline</label>
                  <input type="text" class="form-input" id="setting-site_tagline">
                </div>
                <div class="form-group">
                  <label class="form-label">Contact Email</label>
                  <input type="email" class="form-input" id="setting-contact_email">
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadSettings();
  },

  // Load settings
  async loadSettings() {
    try {
      const settings = await API.get('site_settings?select=key,value');
      
      if (settings) {
        settings.forEach(setting => {
          const input = document.getElementById(`setting-${setting.key}`);
          if (input) {
            const value = Utils.safeJson(setting.value, setting.value);
            input.value = value;
          }
        });
      }
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
  },

  // Save settings
  async saveSettings() {
    const settingsMap = {
      site_name: document.getElementById('setting-site_name')?.value,
      site_tagline: document.getElementById('setting-site_tagline')?.value,
      contact_email: document.getElementById('setting-contact_email')?.value,
    };

    try {
      for (const [key, value] of Object.entries(settingsMap)) {
        if (value !== undefined) {
          await API.rpc('update_setting', { p_key: key, p_value: JSON.stringify(value) });
        }
      }
      Toast.success('Saved', 'Settings saved successfully');
    } catch (error) {
      console.error('Failed to save settings:', error);
      Toast.error('Error', 'Failed to save settings');
    }
  },

  // Audit Logs Page
  auditLogs() {
    if (!Auth.requireRole('super_admin', 'admin')) return;

    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="admin-layout">
        ${SidebarHTML}
        <div class="admin-main">
          ${HeaderHTML}
          <div class="admin-content-full">
            <div class="page-header">
              <div>
                <h1 class="page-title">Audit Logs</h1>
                <p class="page-subtitle">Track all system activities</p>
              </div>
            </div>

            <div class="filters-bar">
              <select class="filter-select" id="filter-action" onchange="Pages.loadAuditLogs()">
                <option value="">All Actions</option>
                <option value="create">Create</option>
                <option value="update">Update</option>
                <option value="delete">Delete</option>
                <option value="login">Login</option>
                <option value="publish">Publish</option>
              </select>
              <select class="filter-select" id="filter-entity" onchange="Pages.loadAuditLogs()">
                <option value="">All Types</option>
                <option value="articles">Articles</option>
                <option value="sports">Sports</option>
                <option value="leagues">Leagues</option>
                <option value="profiles">Users</option>
              </select>
            </div>

            <div class="card">
              <div class="table-container">
                <table class="table">
                  <thead>
                    <tr>
                      <th>Timestamp</th>
                      <th>User</th>
                      <th>Action</th>
                      <th>Entity</th>
                      <th>Details</th>
                    </tr>
                  </thead>
                  <tbody id="audit-list">
                    <tr><td colspan="5" class="text-center p-xl"><div class="spinner" style="margin: 0 auto;"></div></td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    Sidebar.init();
    Header.init();
    this.loadAuditLogs();
  },

  // Load audit logs
  async loadAuditLogs() {
    const action = document.getElementById('filter-action')?.value || '';
    const entity = document.getElementById('filter-entity')?.value || '';

    try {
      let query = 'audit_logs?select=*&order=created_at.desc&limit=100';
      if (action) query += `&action=ilike.*${action}*`;
      if (entity) query += `&entity_type=eq.${entity}`;

      const logs = await API.get(query);
      const tbody = document.getElementById('audit-list');

      if (!logs || logs.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="text-center p-xl text-gray-500">No audit logs found</td></tr>';
        return;
      }

      const actionColors = {
        create: 'badge-success',
        update: 'badge-primary',
        delete: 'badge-danger',
        login: 'badge-info',
        publish: 'badge-warning',
      };

      tbody.innerHTML = logs.map(log => `
        <tr>
          <td class="text-sm">${Utils.formatDate(log.created_at, 'datetime')}</td>
          <td>
            <div class="text-sm">${log.user_email || 'System'}</div>
            ${log.user_role ? `<div class="text-xs text-gray-500">${log.user_role}</div>` : ''}
          </td>
          <td><span class="badge ${actionColors[log.action] || 'badge-gray'}">${log.action}</span></td>
          <td>
            <div class="text-sm">${log.entity_type || '-'}</div>
            ${log.entity_id ? `<code class="text-xs">${log.entity_id.substring(0, 8)}...</code>` : ''}
          </td>
          <td class="text-sm text-gray-500">${log.changes_summary || '-'}</td>
        </tr>
      `).join('');

    } catch (error) {
      console.error('Failed to load audit logs:', error);
      Toast.error('Error', 'Failed to load audit logs');
    }
  },

  // Logout
  logout() {
    Auth.logout();
  },

  // Quick article
  quickArticle() {
    Router.navigate('/articles/new');
  },

  // Preview article
  previewArticle() {
    const slug = document.getElementById('article-slug')?.value;
    if (slug) {
      window.open(`/article/${slug}`, '_blank');
    } else {
      Toast.warning('Save first', 'Please save the article before previewing');
    }
  },

  // Upload image
  async uploadImage() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';

    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (!file) return;

      // For demo, we'll just use a placeholder URL
      // In production, you'd upload to Supabase Storage
      const imageUrl = URL.createObjectURL(file);
      
      document.getElementById('article-image-url').value = imageUrl;
      document.getElementById('image-preview').innerHTML = `<img src="${imageUrl}" alt="Preview">`;
      Toast.success('Uploaded', 'Image selected successfully');
    };

    input.click();
  },

  // Export articles
  exportArticles() {
    Toast.info('Coming soon', 'Export functionality will be available soon');
  },

  // Sync live scores
  syncLiveScores() {
    Toast.info('Coming soon', 'Score sync will be available soon');
  },
};

// ================================================
// HTML TEMPLATES
// ================================================

const SidebarHTML = `
  <aside class="admin-sidebar">
    <div class="sidebar-header">
      <a href="/dashboard" class="sidebar-logo">
        <span class="sidebar-logo-icon">⚽</span>
        <span>SportDune</span>
      </a>
    </div>
    <nav class="sidebar-nav">
      <div class="nav-section">
        <div class="nav-section-title">Main</div>
        <a class="nav-item" data-page="dashboard">
          <span class="nav-item-icon">📊</span>
          Dashboard
        </a>
      </div>
      <div class="nav-section">
        <div class="nav-section-title">Content</div>
        <a class="nav-item" data-page="articles">
          <span class="nav-item-icon">📰</span>
          Articles
        </a>
        <a class="nav-item" data-page="sports">
          <span class="nav-item-icon">⚽</span>
          Sports
        </a>
        <a class="nav-item" data-page="leagues">
          <span class="nav-item-icon">🏆</span>
          Leagues
        </a>
        <a class="nav-item" data-page="live-scores">
          <span class="nav-item-icon">🏟️</span>
          Live Scores
          <span class="nav-item-badge">LIVE</span>
        </a>
      </div>
      <div class="nav-section">
        <div class="nav-section-title">Management</div>
        <a class="nav-item" data-page="users">
          <span class="nav-item-icon">👥</span>
          Users
        </a>
        <a class="nav-item" data-page="settings">
          <span class="nav-item-icon">⚙️</span>
          Settings
        </a>
        <a class="nav-item" data-page="audit-logs">
          <span class="nav-item-icon">📋</span>
          Audit Logs
        </a>
      </div>
    </nav>
    <div class="sidebar-footer">
      <div class="sidebar-user" onclick="Pages.logout()">
        <div class="sidebar-user-avatar" id="sidebar-avatar">?</div>
        <div class="sidebar-user-info">
          <div class="sidebar-user-name" id="sidebar-name">Loading...</div>
          <div class="sidebar-user-role" id="sidebar-role">-</div>
        </div>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--color-gray-400);">
          <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/>
        </svg>
      </div>
    </div>
  </aside>
`;

const HeaderHTML = `
  <header class="admin-header">
    <div class="header-left">
      <button class="header-btn" onclick="document.querySelector('.admin-sidebar').classList.toggle('open')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M3 12h18M3 6h18M3 18h18"/>
        </svg>
      </button>
      <div class="header-search">
        <svg class="header-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
        </svg>
        <input type="text" class="header-search-input" placeholder="Search articles, sports...">
      </div>
    </div>
    <div class="header-right">
      <button class="header-btn" title="Notifications">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0"/>
        </svg>
        <span class="header-btn-badge"></span>
      </button>
      <a href="/" target="_blank" class="header-btn" title="View Site">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6M15 3h6v6M10 14L21 3"/>
        </svg>
      </a>
      <div class="header-user">
        <div class="header-user-avatar" id="header-avatar">?</div>
        <span class="header-user-name" id="header-name">User</span>
      </div>
    </div>
  </header>
`;

// ================================================
// INITIALIZATION
// ================================================

document.addEventListener('DOMContentLoaded', () => {
  // Register routes
  Router.register('/', Pages.login);
  Router.register('/dashboard', Pages.dashboard);
  Router.register('/articles', Pages.articles);
  Router.register('/articles/new', () => Pages.articleEditor('new'));
  Router.register('/articles/:id/edit', (id) => Pages.articleEditor(id));
  Router.register('/sports', Pages.sports);
  Router.register('/leagues', Pages.leagues);
  Router.register('/live-scores', Pages.liveScores);
  Router.register('/users', Pages.users);
  Router.register('/settings', Pages.settings);
  Router.register('/audit-logs', Pages.auditLogs);

  // Initialize router
  Router.init();

  // Update user info in sidebar/header if authenticated
  if (Auth.isAuthenticated()) {
    const user = Auth.getUser();
    Sidebar.updateUser(user);
    
    const setUserInfo = () => {
      const avatar = document.getElementById('sidebar-avatar') || document.getElementById('header-avatar');
      const name = document.getElementById('sidebar-name') || document.getElementById('header-name');
      const role = document.getElementById('sidebar-role');
      
      if (avatar) avatar.textContent = Utils.getInitials(user.full_name || user.email);
      if (name) name.textContent = user.full_name || user.email;
      if (role) role.textContent = (user.role || 'viewer').replace('_', ' ');
    };
    
    setUserInfo();
  }
});

// Export for global access
window.Pages = Pages;
window.Router = Router;
window.Auth = Auth;
window.Toast = Toast;
window.Modal = Modal;
window.API = API;
window.Utils = Utils;
window.Sidebar = Sidebar;
