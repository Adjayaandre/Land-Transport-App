-- ============================================================
-- FIX: "Failed to create user: Database error creating new user"
-- Jalankan SEMUA di Supabase SQL Editor
-- ============================================================

-- 1. Pastikan kolom aktif ada
ALTER TABLE public.pengguna
  ADD COLUMN IF NOT EXISTS aktif boolean NOT NULL DEFAULT true;

-- 2. Hapus baris pengguna yatim (auth sudah dihapus)
DELETE FROM public.pengguna p
WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id);

-- 3. Tambah nilai enum jika kolom peran pakai enum (abaikan error jika bukan enum)
DO $$
BEGIN
  ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'superadmin';
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  ALTER TYPE public.peran ADD VALUE IF NOT EXISTS 'superadmin';
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

-- 4. Perbaiki trigger — tidak gagalkan pembuatan user auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_nama text;
  v_peran text;
BEGIN
  v_nama := COALESCE(
    NEW.raw_user_meta_data->>'nama_lengkap',
    split_part(NEW.email, '@', 1)
  );
  v_peran := COALESCE(NEW.raw_user_meta_data->>'peran', 'driver');

  INSERT INTO public.pengguna (id, nama_lengkap, peran, aktif)
  VALUES (NEW.id, v_nama, v_peran, true)
  ON CONFLICT (id) DO UPDATE SET
    nama_lengkap = EXCLUDED.nama_lengkap,
    peran = CASE
      WHEN public.pengguna.peran IN ('superadmin', 'admin')
        THEN public.pengguna.peran
      ELSE EXCLUDED.peran
    END,
    aktif = true;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user gagal untuk %: %', NEW.email, SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- SETELAH trigger diperbaiki:
-- A) Buat user superadmin di Supabase Dashboard → Authentication → Users
-- B) Jalankan sync (ganti email baris 75):
-- ============================================================

/*
DO $$
DECLARE
  v_email text := 'email-superadmin@anda.com';
  v_id uuid;
  v_nama text;
BEGIN
  SELECT id, COALESCE(raw_user_meta_data->>'nama_lengkap', split_part(email, '@', 1))
  INTO v_id, v_nama FROM auth.users WHERE lower(email) = lower(v_email);

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'User belum dibuat di Authentication';
  END IF;

  INSERT INTO public.pengguna (id, nama_lengkap, peran, aktif)
  VALUES (v_id, v_nama, 'superadmin', true)
  ON CONFLICT (id) DO UPDATE
  SET peran = 'superadmin', aktif = true;

  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb)
    || jsonb_build_object('nama_lengkap', v_nama, 'peran', 'superadmin')
  WHERE id = v_id;
END $$;
*/
