-- ================================================
-- SPORTDUNE - STORAGE SETUP
-- Create storage buckets for media
-- ================================================

-- Note: Run this in Supabase Dashboard > Storage > New Bucket
-- Or use the Supabase CLI: supabase storage create

-- Bucket: media (for article images and media assets)
-- Public: true
-- File size limit: 10MB
-- Allowed MIME types: image/*, video/*, application/pdf

-- ================================================
-- STORAGE POLICIES
-- ================================================

-- Allow public read access to media
CREATE POLICY "Public read access to media"
ON storage.objects FOR SELECT
USING (bucket_id = 'media');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload media"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'media' AND auth.role() = 'authenticated');

-- Allow users to update their own uploads
CREATE POLICY "Users can update own media"
ON storage.objects FOR UPDATE
USING (bucket_id = 'media' AND auth.uid() = owner);

-- Allow admins to delete any media
CREATE POLICY "Admins can delete media"
ON storage.objects FOR DELETE
USING (bucket_id = 'media' AND (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('super_admin', 'admin')
    AND is_active = true
  )
));
