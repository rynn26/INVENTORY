-- ============================================================
-- TitipKasir — ADDENDUM: Tabel Profil User (Kasir & Admin)
-- Jalankan file ini di Supabase Dashboard > SQL Editor
-- (terpisah dari supabase_schema.sql utama)
-- ============================================================

-- ============================================================
-- TABEL PROFILES (terhubung ke auth.users Supabase)
-- ============================================================
DO $$ BEGIN
  CREATE TYPE user_role_type AS ENUM ('kasir', 'admin');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name    TEXT NOT NULL DEFAULT '',
  role         user_role_type NOT NULL DEFAULT 'kasir',
  phone_number TEXT,
  avatar_url   TEXT,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger: auto-insert baris profiles saat user baru dibuat di auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role user_role_type := 'kasir';
  v_name TEXT := '';
BEGIN
  -- Ambil full_name dari metadata (aman walau null)
  BEGIN
    v_name := COALESCE(NEW.raw_user_meta_data->>'full_name', '');
  EXCEPTION WHEN OTHERS THEN
    v_name := '';
  END;

  -- Ambil role dari metadata, fallback ke 'kasir' jika tidak valid
  BEGIN
    v_role := (COALESCE(NEW.raw_user_meta_data->>'role', 'kasir'))::user_role_type;
  EXCEPTION WHEN OTHERS THEN
    v_role := 'kasir';
  END;

  INSERT INTO public.profiles (id, full_name, role)
  VALUES (NEW.id, v_name, v_role)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- RLS — profiles
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all anon" ON public.profiles;
CREATE POLICY "Allow all anon" ON public.profiles
  FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Allow authenticated" ON public.profiles;
CREATE POLICY "Allow authenticated" ON public.profiles
  FOR ALL TO authenticated USING (TRUE) WITH CHECK (TRUE);

-- ============================================================
-- SEED: Buat akun kasir & admin awal
-- CATATAN: Akun harus dibuat manual di Supabase Dashboard
--   Authentication > Users > Add User
--   Email: kasir@titipkasir.app | Password: kasir123
--   Email: admin@titipkasir.app | Password: admin123
-- Setelah itu jalankan INSERT berikut dengan UUID yang sesuai:
-- ============================================================

-- CONTOH (ganti UUID dengan UUID asli dari tab Authentication > Users):
-- INSERT INTO public.profiles (id, full_name, role) VALUES
--   ('<UUID-kasir>', 'Kasir Utama', 'kasir'),
--   ('<UUID-admin>', 'Administrator', 'admin')
-- ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, role = EXCLUDED.role;
