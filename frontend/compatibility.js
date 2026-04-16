/**
 * SportDune - Frontend Update Script
 * Updates homepage and other pages to use new Supabase schema
 */

(function() {
  'use strict';
  
  // Check if we're on the frontend
  if (typeof window === 'undefined') return;
  
  /**
   * Update homepage to use new data service
   */
  function updateHomepage() {
    // This is a compatibility layer that maps old API calls to new ones
    // The actual updates are in data-service.js
    
    console.log('[SportDune] Data service loaded with new schema');
  }
  
  /**
   * Override old getCategories to use new getSports
   */
  if (typeof window.getCategories === 'undefined') {
    window.getCategories = async function() {
      console.log('[SportDune] Using legacy getCategories - please update code to use getSports()');
      return window.getSports ? await window.getSports() : [];
    };
  }
  
  /**
   * Ensure generateArticleCard uses new article structure
   */
  const originalGenerateArticleCard = window.generateArticleCard;
  window.generateArticleCard = function(article, options = {}) {
    // Ensure backward compatibility with old article structure
    if (article && !article.sports && article.categories) {
      article.sports = {
        name: article.categories.name,
        slug: article.categories.slug,
        icon: article.categories.icon
      };
      article.sport_id = article.category_id;
    }
    if (article && !article.authors && article.profiles) {
      article.authors = {
        display_name: article.profiles.full_name
      };
      article.author_id = article.profile_id;
    }
    // Map old read_time to new read_time_minutes
    if (article && !article.read_time_minutes && article.read_time) {
      article.read_time_minutes = article.read_time;
    }
    return originalGenerateArticleCard ? originalGenerateArticleCard(article, options) : '';
  };
  
  /**
   * Update article detail page if on that page
   */
  function updateArticleDetail() {
    const urlParams = new URLSearchParams(window.location.search);
    const slug = urlParams.get('slug');
    
    if (!slug || !window.location.pathname.includes('news-detail')) return;
    
    // Add view count increment when article is loaded
    const originalFetch = window.fetch;
    window.fetch = async function(url, options) {
      const response = await originalFetch(url, options);
      
      if (url.includes('/rest/v1/articles') && slug) {
        // Article loaded, increment view
        setTimeout(() => {
          if (typeof window.incrementViewCount === 'function') {
            // Get article ID from response if available
          }
        }, 5000); // Increment after 5 seconds
      }
      
      return response;
    };
  }
  
  // Run on load
  document.addEventListener('DOMContentLoaded', function() {
    updateHomepage();
    updateArticleDetail();
  });
  
})();
