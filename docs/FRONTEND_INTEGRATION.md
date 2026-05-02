# SportDune Frontend Integration Guide

## Overview
The public frontend can fetch data from Supabase using the `SportDuneData` service in `data-service.js`.

## Setup
Add these scripts to your HTML pages:
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="compatibility.js"></script>
<script src="data-service.js"></script>
```

## Available Methods

### `SportDuneData.fetchSports()`
Returns all active sports ordered by nav_order.

### `SportDuneData.fetchLeagues(sportId?)`
Returns leagues, optionally filtered by sport.

### `SportDuneData.fetchArticles({ sportId?, limit?, status? })`
Returns published articles. Default: 20 articles.

### `SportDuneData.fetchArticleBySlug(slug)`
Returns a single article by its slug.

### `SportDuneData.fetchTrending()`
Returns active trending items with article data.

### `SportDuneData.fetchHomepageSections()`
Returns visible homepage sections with article IDs.

### `SportDuneData.fetchSettings()`
Returns public site settings as key-value pairs.

### `SportDuneData.searchArticles(query, limit?)`
Searches published articles by title.

## Caching
All methods cache results for 5 minutes to reduce database queries.

## Admin Dashboard
The admin dashboard is deployed at `/admin` and uses the same Supabase project with role-based access control.
