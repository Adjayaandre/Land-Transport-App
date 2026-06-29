-- ============================================================
-- GANTI email di baris 6, lalu jalankan SEMUA script ini
-- ============================================================

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

DO $$
DECLARE
  v_email text := 'GANTI_DENGAN_EMAIL_SUPERADMIN_ANDA@example.com';
  v_id uuid;
  v_nama text;
BEGIN
  SELECT id, COALESCE(raw_user_meta_data->>'nama_lengkap', split_part(email, '@', 1))
  INTO v_id, v_nama
  FROM auth.users
  WHERE lower(email) = lower(v_email);

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'Email tidak ditemukan di auth.users: %', v_email;
  END IF;

  -- Sinkronkan pengguna (id HARUS sama dengan auth.users)
  INSERT INTO public.pengguna (id, nama_lengkap, peran, aktif)
  VALUES (v_id, v_nama, 'superadmin', true)
  ON CONFLICT (id) DO UPDATE
  SET peran = 'superadmin', aktif = true, nama_lengkap = EXCLUDED.nama_lengkap;

  -- Backup role di metadata auth (jika RPC gagal)
  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb)
    || jsonb_build_object('nama_lengkap', v_nama, 'peran', 'superadmin')
  WHERE id = v_id;
END $$;

-- Cek hasil (harus muncul peran = superadmin):
-- SELECT u.email, u.id AS auth_id, p.id AS pengguna_id, p.peran
-- FROM auth.users u
-- LEFT JOIN public.pengguna p ON p.id = u.id
-- WHERE lower(u.email) = lower('GANTI_DENGAN_EMAIL_SUPERADMIN_ANDA@example.com');
