-- Jalankan sekali di Supabase SQL Editor.
-- Membuat profil pengguna otomatis saat akun Auth baru dibuat (signUp / admin.createUser).

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
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user gagal: %', SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Izinkan superadmin mengelola baris pengguna (driver).
ALTER TABLE public.pengguna ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Superadmin manage pengguna" ON public.pengguna;
CREATE POLICY "Superadmin manage pengguna"
  ON public.pengguna
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.pengguna AS p
      WHERE p.id = auth.uid() AND p.peran = 'superadmin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pengguna AS p
      WHERE p.id = auth.uid() AND p.peran = 'superadmin'
    )
  );

DROP POLICY IF EXISTS "Users read own profile" ON public.pengguna;
CREATE POLICY "Users read own profile"
  ON public.pengguna
  FOR SELECT
  USING (auth.uid() = id);
