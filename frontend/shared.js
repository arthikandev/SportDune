// SportDune – Shared JS
document.addEventListener('DOMContentLoaded', function () {
  // Mobile Nav
  const hamburger = document.getElementById('hamburger');
  const mobileNav = document.getElementById('mobileNav');
  if (hamburger && mobileNav) {
    hamburger.addEventListener('click', () => mobileNav.classList.toggle('open'));
  }

  // Intersection Observer animations
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
      }
    });
  }, { threshold: 0.08 });

  document.querySelectorAll('.article-card, .sidebar-widget, .score-card').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(16px)';
    el.style.transition = 'opacity 0.45s ease, transform 0.45s ease';
    observer.observe(el);
  });

  // Live Scores tabs
  const tabs = document.querySelectorAll('.score-tab');
  const panels = document.querySelectorAll('.scores-panel');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      panels.forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      const target = document.getElementById(tab.dataset.tab);
      if (target) target.classList.add('active');
    });
  });

  // Search functionality
  const searchInput = document.getElementById('searchInput');
  const searchResults = document.getElementById('searchResults');
  const emptyState = document.getElementById('emptyState');
  const defaultResults = document.getElementById('defaultResults');

  if (searchInput) {
    searchInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') performSearch();
    });
  }

  const searchSubmit = document.getElementById('searchSubmit');
  if (searchSubmit) searchSubmit.addEventListener('click', performSearch);

  function performSearch() {
    if (!searchInput) return;
    const q = searchInput.value.trim();
    if (!q) return;
    if (defaultResults) defaultResults.style.display = 'none';
    if (searchResults) searchResults.style.display = 'block';
    if (emptyState) emptyState.style.display = 'none';
    document.getElementById('searchQuery').textContent = q;
  }

  const filterBtns = document.querySelectorAll('.search-filter');
  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // --- News Card Clicks ---
  function slugify(text) {
    return text.toString().toLowerCase()
      .trim()
      .replace(/\s+/g, '-')           // Replace spaces with -
      .replace(/[^\w\-]+/g, '')       // Remove all non-word chars
      .replace(/\-\-+/g, '-')         // Replace multiple - with single -
      .replace(/^-+/, '')               // Trim - from start of text
      .replace(/-+$/, '');              // Trim - from end of text
  }

  const navigateToArticle = (el) => {
    let title = "";
    let category = "Sport News";
    let imageClass = "t1";

    if (el.classList.contains('article-card')) {
      title = el.querySelector('.card-title')?.innerText || "";
      category = el.querySelector('.card-tag')?.innerText || category;
      imageClass = Array.from(el.querySelector('.card-img')?.classList || []).find(c => /^t\d$/.test(c)) || "t1";
    } else if (el.classList.contains('trending-card')) {
      title = el.querySelector('.trending-card-title')?.innerText || "";
      imageClass = Array.from(el.querySelector('.trending-thumb')?.classList || []).find(c => /^t\d$/.test(c)) || "t1";
    } else if (el.classList.contains('slide-btn')) {
      const slide = el.closest('.slide');
      title = slide.querySelector('.slide-title')?.innerText || "";
      category = slide.querySelector('.slide-tag')?.innerText || category;
    }

    if (!title) return;

    const slug = slugify(title);
    const params = new URLSearchParams({
      s: slug,
      t: title,
      c: category,
      i: imageClass
    });
    window.location.href = `news-detail.html?${params.toString()}`;
  };

  document.addEventListener('click', (e) => {
    const card = e.target.closest('.article-card, .trending-card, .slide-btn');
    if (card) {
      e.preventDefault();
      navigateToArticle(card);
    }
  });
});
