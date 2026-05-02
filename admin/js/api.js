const api = {
    async fetchAll(table, opts = {}) {
        let q = supabase.from(table).select(opts.select || '*', { count: opts.count });
        if (opts.order) q = q.order(opts.order.column, { ascending: opts.order.ascending !== false });
        if (opts.limit) q = q.limit(opts.limit);
        if (opts.filter) {
            for (const [k, v] of Object.entries(opts.filter)) {
                q = q.eq(k, v);
            }
        }
        const { data, error, count } = await q;
        if (error) throw error;
        return opts.count ? { data, count } : data;
    },
    async fetchOne(table, id) {
        const { data, error } = await supabase.from(table).select('*').eq('id', id).single();
        if (error) throw error;
        return data;
    },
    async insert(table, row) {
        const { data, error } = await supabase.from(table).insert(row).select().single();
        if (error) throw error;
        return data;
    },
    async update(table, id, row) {
        const { data, error } = await supabase.from(table).update(row).eq('id', id).select().single();
        if (error) throw error;
        return data;
    },
    async remove(table, id) {
        const { error } = await supabase.from(table).delete().eq('id', id);
        if (error) throw error;
    },
    async searchArticles(query, filters = {}) {
        let q = supabase.from('articles').select('*, authors(display_name), sports(name, emoji), leagues(name)');
        if (query) q = q.ilike('title', `%${query}%`);
        if (filters.sport_id) q = q.eq('sport_id', filters.sport_id);
        if (filters.status) q = q.eq('status', filters.status);
        q = q.order('created_at', { ascending: false });
        if (filters.limit) q = q.limit(filters.limit);
        const { data, error } = await q;
        if (error) throw error;
        return data;
    },
    async uploadMedia(file) {
        const cfg = window.SPORTDUNE_ADMIN_CONFIG;
        const ext = file.name.split('.').pop();
        const path = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
        const { data: uploadData, error: uploadError } = await supabase.storage.from(cfg.MEDIA_BUCKET).upload(path, file, { contentType: file.type });
        if (uploadError) throw uploadError;
        const { data: { publicUrl } } = supabase.storage.from(cfg.MEDIA_BUCKET).getPublicUrl(path);
        const asset = await this.insert('media_assets', {
            filename: file.name,
            url: publicUrl,
            storage_path: path,
            file_type: file.type,
            file_size: file.size,
            uploaded_by: currentUser?.id
        });
        return { ...asset, publicUrl };
    },
    async deleteMedia(assetId) {
        const asset = await this.fetchOne('media_assets', assetId);
        if (asset.storage_path) {
            const cfg = window.SPORTDUNE_ADMIN_CONFIG;
            await supabase.storage.from(cfg.MEDIA_BUCKET).remove([asset.storage_path]);
        }
        await this.remove('media_assets', assetId);
    },
    async logAudit(action, entityType, entityId, oldValues, newValues, summary) {
        try {
            await this.insert('audit_logs', { action, entity_type: entityType, entity_id: entityId, old_values: oldValues, new_values: newValues, changes_summary: summary });
        } catch (e) { console.warn('Audit log failed:', e); }
    }
};
