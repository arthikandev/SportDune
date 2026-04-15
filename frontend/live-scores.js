// SportDune – Live Scores Page Logic
document.addEventListener('DOMContentLoaded', function () {
  let activeSport = 'all';
  let activeStatus = 'live';

  const feed = document.getElementById('matchFeed');
  const emptyEl = document.getElementById('lsEmpty');
  const allGroups = feed ? Array.from(feed.querySelectorAll('.ls-league-group')) : [];

  // Sport sidebar buttons
  const sportBtns = document.querySelectorAll('.ls-sport-btn');
  const chipBtns = document.querySelectorAll('.ls-chip');

  // Status tabs
  const statusTabs = document.querySelectorAll('.ls-status-tab');

  // Date buttons
  const dateBtns = document.querySelectorAll('.ls-date-btn');

  function filterMatches() {
    let visibleCount = 0;

    allGroups.forEach(group => {
      const sport = group.dataset.sport;
      const status = group.dataset.status;

      const matchesSport = activeSport === 'all' || sport === activeSport;
      const matchesStatus = status === activeStatus;

      if (matchesSport && matchesStatus) {
        group.style.display = '';
        // Re-trigger animation
        group.style.animation = 'none';
        group.offsetHeight; // Force reflow
        group.style.animation = '';
        visibleCount++;
      } else {
        group.style.display = 'none';
      }
    });

    if (emptyEl) {
      emptyEl.style.display = visibleCount === 0 ? 'block' : 'none';
    }

    // Update tab counts
    statusTabs.forEach(tab => {
      const status = tab.dataset.status;
      let count = 0;
      allGroups.forEach(g => {
        if (g.dataset.status === status && (activeSport === 'all' || g.dataset.sport === activeSport)) {
          count += g.querySelectorAll('.ls-match').length;
        }
      });
      const countEl = tab.querySelector('.ls-tab-count');
      if (countEl) countEl.textContent = count;
    });
  }

  // Sport selection
  function selectSport(sport) {
    activeSport = sport;

    sportBtns.forEach(b => b.classList.toggle('active', b.dataset.sport === sport));
    chipBtns.forEach(b => b.classList.toggle('active', b.dataset.sport === sport));

    filterMatches();
  }

  sportBtns.forEach(btn => {
    btn.addEventListener('click', () => selectSport(btn.dataset.sport));
  });
  chipBtns.forEach(btn => {
    btn.addEventListener('click', () => selectSport(btn.dataset.sport));
  });

  // Status tab selection
  statusTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      activeStatus = tab.dataset.status;
      statusTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      filterMatches();
    });
  });

  // Date strip
  dateBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      dateBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // Simulated live time updates
  function updateLiveTimes() {
    const liveEls = document.querySelectorAll('.ls-match-live');
    liveEls.forEach(el => {
      const text = el.textContent.trim();
      const minuteMatch = text.match(/^(\d+)'$/);
      if (minuteMatch) {
        const current = parseInt(minuteMatch[1]);
        if (current < 90) {
          el.textContent = (current + 1) + "'";
        }
      }
    });
  }

  setInterval(updateLiveTimes, 60000); // Update every 60s

  // Initial filter
  filterMatches();

  // Match card click expand effect
  document.querySelectorAll('.ls-match').forEach(match => {
    match.addEventListener('click', () => {
      match.style.background = '#FFF0ED';
      setTimeout(() => { match.style.background = ''; }, 300);
    });
  });
});
