/**
 * SportDune - Supabase Client Configuration
 * 
 * This file initializes the Supabase client for frontend integration.
 * Replace the placeholder values with your actual Supabase credentials.
 */

// Supabase Configuration
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY';

/**
 * Create and export Supabase client instance
 * Use this in your frontend JavaScript files
 */
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    storageKey: 'sportdune-auth',
    storage: {
      getItem: (key) => {
        try {
          return localStorage.getItem(key);
        } catch {
          return null;
        }
      },
      setItem: (key, value) => {
        try {
          localStorage.setItem(key, value);
        } catch {
          // Ignore storage errors
        }
      },
      removeItem: (key) => {
        try {
          localStorage.removeItem(key);
        } catch {
          // Ignore storage errors
        }
      }
    }
  }
});

/**
 * Authentication helper functions
 */
export const auth = {
  /**
   * Sign up a new user
   */
  async signUp(email, password, metadata = {}) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata,
        emailRedirectTo: `${window.location.origin}/admin/`
      }
    });
    return { data, error };
  },

  /**
   * Sign in with email and password
   */
  async signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    return { data, error };
  },

  /**
   * Sign in with OAuth provider (Google, GitHub, etc.)
   */
  async signInWithOAuth(provider) {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/admin/`
      }
    });
    return { data, error };
  },

  /**
   * Sign out current user
   */
  async signOut() {
    const { error } = await supabase.auth.signOut();
    return { error };
  },

  /**
   * Get current session
   */
  async getSession() {
    const { data, error } = await supabase.auth.getSession();
    return { data, error };
  },

  /**
   * Get current user
   */
  async getUser() {
    const { data, error } = await supabase.auth.getUser();
    return { data, error };
  },

  /**
   * Send password reset email
   */
  async resetPassword(email) {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/admin/reset-password`
    });
    return { data, error };
  },

  /**
   * Update user password
   */
  async updatePassword(newPassword) {
    const { data, error } = await supabase.auth.updateUser({
      password: newPassword
    });
    return { data, error };
  },

  /**
   * Update user metadata
   */
  async updateMetadata(metadata) {
    const { data, error } = await supabase.auth.updateUser({
      data: metadata
    });
    return { data, error };
  },

  /**
   * Listen to auth state changes
   */
  onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback);
  }
};

/**
 * Articles API helper
 */
export const articles = {
  /**
   * Get all published articles
   */
  async getAll(limit = 20, offset = 0) {
    const { data, error } = await supabase
      .from('articles')
      .select(`
        *,
        category:categories(name, slug, icon),
        author:profiles(full_name, avatar_url)
      `)
      .eq('status', 'published')
      .order('published_at', { ascending: false })
      .range(offset, offset + limit - 1);
    return { data, error };
  },

  /**
   * Get articles by category
   */
  async getByCategory(categorySlug, limit = 20, offset = 0) {
    const { data: category } = await supabase
      .from('categories')
      .select('id')
      .eq('slug', categorySlug)
      .single();

    if (!category) return { data: null, error: 'Category not found' };

    const { data, error } = await supabase
      .from('articles')
      .select(`
        *,
        category:categories(name, slug, icon),
        author:profiles(full_name, avatar_url)
      `)
      .eq('category_id', category.id)
      .eq('status', 'published')
      .order('published_at', { ascending: false })
      .range(offset, offset + limit - 1);
    return { data, error };
  },

  /**
   * Get single article by slug
   */
  async getBySlug(slug) {
    const { data, error } = await supabase
      .from('articles')
      .select(`
        *,
        category:categories(name, slug, icon),
        author:profiles(full_name, avatar_url, bio),
        tags:article_tags(tag:tags(name, slug))
      `)
      .eq('slug', slug)
      .eq('status', 'published')
      .single();
    return { data, error };
  },

  /**
   * Get featured articles
   */
  async getFeatured(limit = 6) {
    const { data, error } = await supabase
      .from('articles')
      .select(`
        *,
        category:categories(name, slug, icon)
      `)
      .eq('status', 'published')
      .eq('is_featured', true)
      .order('published_at', { ascending: false })
      .limit(limit);
    return { data, error };
  },

  /**
   * Get trending articles (most views)
   */
  async getTrending(limit = 10) {
    const { data, error } = await supabase
      .from('articles')
      .select(`
        *,
        category:categories(name, slug, icon)
      `)
      .eq('status', 'published')
      .order('view_count', { ascending: false })
      .limit(limit);
    return { data, error };
  },

  /**
   * Search articles
   */
  async search(query, limit = 20) {
    const { data, error } = await supabase
      .from('articles')
      .select(`
        *,
        category:categories(name, slug, icon)
      `)
      .eq('status', 'published')
      .or(`title.ilike.%${query}%,excerpt.ilike.%${query}%,content.ilike.%${query}%`)
      .order('published_at', { ascending: false })
      .limit(limit);
    return { data, error };
  }
};

/**
 * Categories API helper
 */
export const categories = {
  /**
   * Get all active categories
   */
  async getAll() {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order');
    return { data, error };
  },

  /**
   * Get category by slug
   */
  async getBySlug(slug) {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('slug', slug)
      .single();
    return { data, error };
  }
};

/**
 * Live Scores API helper
 */
export const liveScores = {
  /**
   * Get all live matches
   */
  async getAll() {
    const { data, error } = await supabase
      .from('live_matches')
      .select('*')
      .order('match_date', { ascending: true });
    return { data, error };
  },

  /**
   * Get matches by sport
   */
  async getBySport(sport) {
    const { data, error } = await supabase
      .from('live_matches')
      .select('*')
      .eq('sport', sport)
      .order('match_date', { ascending: true });
    return { data, error };
  },

  /**
   * Get live matches only
   */
  async getLive() {
    const { data, error } = await supabase
      .from('live_matches')
      .select('*')
      .eq('status', 'live')
      .order('match_date', { ascending: true });
    return { data, error };
  }
};

/**
 * Analytics helper
 */
export const analytics = {
  /**
   * Track page view
   */
  async trackPageView(pageData) {
    const { visitor_id } = await supabase.auth.getSession();
    const sessionId = crypto.randomUUID();
    
    const { error } = await supabase
      .from('page_views')
      .insert({
        ...pageData,
        visitor_id: visitorId?.data?.session?.user?.id || null,
        session_id: sessionId,
        user_agent: navigator.userAgent,
        device_type: /mobile/i.test(navigator.userAgent) ? 'mobile' : 'desktop'
      });
    return { error };
  }
};

/**
 * Admin API helper (requires admin role)
 */
export const admin = {
  /**
   * Check if current user is admin
   */
  async isAdmin() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    return profile?.role === 'admin' || profile?.role === 'super_admin';
  },

  /**
   * Get all articles (including drafts)
   */
  async getAllArticles(limit = 50, offset = 0) {
    const { data, error } = await supabase
      .from('articles')
      .select(`
        *,
        category:categories(name, slug),
        author:profiles(full_name)
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);
    return { data, error };
  },

  /**
   * Create article
   */
  async createArticle(articleData) {
    // Generate slug
    const slug = articleData.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const { data: { user } } = await supabase.auth.getUser();

    const { data, error } = await supabase
      .from('articles')
      .insert({
        ...articleData,
        slug,
        author_id: user.id,
        published_at: articleData.status === 'published' ? new Date().toISOString() : null
      })
      .select()
      .single();
    return { data, error };
  },

  /**
   * Update article
   */
  async updateArticle(id, articleData) {
    const { data, error } = await supabase
      .from('articles')
      .update({
        ...articleData,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();
    return { data, error };
  },

  /**
   * Delete article
   */
  async deleteArticle(id) {
    const { error } = await supabase
      .from('articles')
      .delete()
      .eq('id', id);
    return { error };
  },

  /**
   * Get all users
   */
  async getAllUsers() {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false });
    return { data, error };
  },

  /**
   * Update user role
   */
  async updateUserRole(userId, role) {
    const { data, error } = await supabase
      .from('profiles')
      .update({ role, updated_at: new Date().toISOString() })
      .eq('id', userId);
    return { data, error };
  },

  /**
   * Get dashboard stats
   */
  async getStats() {
    const [articles, users, pageViews] = await Promise.all([
      supabase.from('articles').select('*', { count: 'exact', head: true }),
      supabase.from('profiles').select('*', { count: 'exact', head: true }),
      supabase.from('page_views').select('*', { count: 'exact', head: true })
    ]);

    return {
      articles: articles.count || 0,
      users: users.count || 0,
      pageViews: pageViews.count || 0
    };
  }
};

export default supabase;
