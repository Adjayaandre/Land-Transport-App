-- Jalankan jika role superadmin berubah setelah login / tambah driver.

CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'id', id,
    'nama_lengkap', nama_lengkap,
    'peran', peran,
    'aktif', aktif
  )
  INTO result
  FROM public.pengguna
  WHERE id = auth.uid();
  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;

CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.pengguna
    WHERE id = auth.uid() AND peran = 'superadmin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_superadmin() TO authenticated;

DROP POLICY IF EXISTS "Superadmin manage pengguna" ON public.pengguna;
CREATE POLICY "Superadmin manage pengguna"
  ON public.pengguna
  FOR ALL
  USING (public.is_superadmin())
  WITH CHECK (public.is_superadmin());

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.pengguna (id, nama_lengkap, peran, aktif)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nama_lengkap', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'peran', 'driver'),
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    nama_lengkap = EXCLUDED.nama_lengkap,
    peran = CASE
      WHEN public.pengguna.peran IN ('superadmin', 'admin') THEN public.pengguna.peran
      ELSE EXCLUDED.peran
    END,
    aktif = true;
  RETURN NEW;
END;
$$;

-- Pastikan akun superadmin Anda benar (ganti email):
-- UPDATE public.pengguna SET peran = 'superadmin'
-- WHERE id = (SELECT id FROM auth.users WHERE email = 'email-superadmin@anda.com');
