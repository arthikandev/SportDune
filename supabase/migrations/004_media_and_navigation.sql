-- ================================================
-- MEDIA TABLE for file uploads
-- ================================================

CREATE TABLE IF NOT EXISTS public.media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    type TEXT NOT NULL,
    size INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_created ON public.media(created_at DESC);

-- ================================================
-- NAVIGATION SETTINGS
-- ================================================

INSERT INTO public.site_settings (key, value, description, is_public)
VALUES ('navigation', '[]', 'Website navigation menu', false)
ON CONFLICT (key) DO NOTHING;
