-- ============================================================
-- TitipKasir — Supabase SQL Schema (FINAL - VERIFIED)
-- Jalankan seluruh file ini di: Supabase Dashboard > SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. TABEL PENITIP (Mitra Penitip Makanan)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.penitips (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  phone_number    TEXT,
  commission_rate INT NOT NULL DEFAULT 10,
  address         TEXT,
  notes           TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. TABEL PRODUCTS (Produk / Makanan Titipan)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.products (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  price         INT NOT NULL CHECK (price >= 0),
  stock         INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  penitip_id    UUID REFERENCES public.penitips(id) ON DELETE SET NULL,
  penitip_name  TEXT NOT NULL DEFAULT '',
  image_url     TEXT,
  category      TEXT NOT NULL DEFAULT 'Lainnya',
  barcode       TEXT UNIQUE,
  description   TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. TABEL STOCK_MOVEMENTS (Log Mutasi Stok)
-- ============================================================
-- Buat ENUM dulu hanya jika belum ada
DO $$ BEGIN
  CREATE TYPE stock_movement_type AS ENUM ('stock_in', 'adjustment', 'sold', 'return');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.stock_movements (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id    UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  movement_type stock_movement_type NOT NULL,
  quantity      INT NOT NULL,  -- positif = masuk, negatif = keluar
  reason        TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 4. TABEL TRANSACTIONS (Header Transaksi Kasir)
-- ============================================================
DO $$ BEGIN
  CREATE TYPE payment_method_type AS ENUM ('tunai', 'qris', 'transfer');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.transactions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  receipt_number  TEXT NOT NULL UNIQUE,
  total_amount    INT NOT NULL CHECK (total_amount >= 0),
  amount_paid     INT NOT NULL CHECK (amount_paid >= 0),
  change_amount   INT NOT NULL DEFAULT 0 CHECK (change_amount >= 0),
  payment_method  payment_method_type NOT NULL DEFAULT 'tunai',
  cashier_name    TEXT DEFAULT 'Kasir',
  notes           TEXT,
  transaction_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 5. TABEL TRANSACTION_ITEMS (Detail Item per Transaksi)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.transaction_items (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id  UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
  product_id      UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name    TEXT NOT NULL,
  penitip_name    TEXT NOT NULL,
  unit_price      INT NOT NULL CHECK (unit_price >= 0),
  quantity        INT NOT NULL CHECK (quantity > 0),
  subtotal        INT NOT NULL CHECK (subtotal >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 6. TABEL SETTLEMENTS (Rekap Bagi Hasil per Penitip)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.settlements (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  settlement_code TEXT NOT NULL UNIQUE,
  penitip_id      UUID REFERENCES public.penitips(id) ON DELETE SET NULL,
  penitip_name    TEXT NOT NULL,
  phone_number    TEXT,
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  total_sold_qty  INT NOT NULL DEFAULT 0 CHECK (total_sold_qty >= 0),
  gross_revenue   INT NOT NULL DEFAULT 0 CHECK (gross_revenue >= 0),
  commission_rate INT NOT NULL DEFAULT 10 CHECK (commission_rate BETWEEN 0 AND 100),
  commission      INT NOT NULL DEFAULT 0 CHECK (commission >= 0),
  net_payout      INT NOT NULL DEFAULT 0 CHECK (net_payout >= 0),
  is_paid         BOOLEAN NOT NULL DEFAULT FALSE,
  paid_at         TIMESTAMPTZ,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TRIGGERS — auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop dulu sebelum create agar tidak error jika dijalankan ulang
DROP TRIGGER IF EXISTS set_penitips_updated_at ON public.penitips;
DROP TRIGGER IF EXISTS set_products_updated_at ON public.products;
DROP TRIGGER IF EXISTS set_settlements_updated_at ON public.settlements;

CREATE TRIGGER set_penitips_updated_at
  BEFORE UPDATE ON public.penitips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_settlements_updated_at
  BEFORE UPDATE ON public.settlements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- INDEXES (performance)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_products_penitip_id       ON public.products(penitip_id);
CREATE INDEX IF NOT EXISTS idx_products_category         ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_barcode          ON public.products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_is_active        ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON public.stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_created_at ON public.stock_movements(created_at);
CREATE INDEX IF NOT EXISTS idx_tx_items_transaction_id   ON public.transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_tx_items_product_id       ON public.transaction_items(product_id);
CREATE INDEX IF NOT EXISTS idx_transactions_at           ON public.transactions(transaction_at);
CREATE INDEX IF NOT EXISTS idx_settlements_penitip_id    ON public.settlements(penitip_id);
CREATE INDEX IF NOT EXISTS idx_settlements_is_paid       ON public.settlements(is_paid);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE public.penitips          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements       ENABLE ROW LEVEL SECURITY;

-- Drop dulu agar tidak error jika dijalankan ulang
DROP POLICY IF EXISTS "Allow all anon" ON public.penitips;
DROP POLICY IF EXISTS "Allow all anon" ON public.products;
DROP POLICY IF EXISTS "Allow all anon" ON public.stock_movements;
DROP POLICY IF EXISTS "Allow all anon" ON public.transactions;
DROP POLICY IF EXISTS "Allow all anon" ON public.transaction_items;
DROP POLICY IF EXISTS "Allow all anon" ON public.settlements;

CREATE POLICY "Allow all anon" ON public.penitips          FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow all anon" ON public.products          FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow all anon" ON public.stock_movements   FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow all anon" ON public.transactions      FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow all anon" ON public.transaction_items FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow all anon" ON public.settlements       FOR ALL TO anon USING (TRUE) WITH CHECK (TRUE);

-- ============================================================
-- STORAGE BUCKET (Gambar Produk)
-- ============================================================
-- Buat bucket 'product-images' jika belum ada
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  TRUE,             -- public bucket (bisa diakses tanpa auth)
  5242880,          -- max 5MB per file
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- RLS storage: izinkan anon upload & baca
DROP POLICY IF EXISTS "Allow anon upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon read"   ON storage.objects;
DROP POLICY IF EXISTS "Allow anon delete" ON storage.objects;

CREATE POLICY "Allow anon read" ON storage.objects
  FOR SELECT TO anon
  USING (bucket_id = 'product-images');

CREATE POLICY "Allow anon upload" ON storage.objects
  FOR INSERT TO anon
  WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Allow anon delete" ON storage.objects
  FOR DELETE TO anon
  USING (bucket_id = 'product-images');

-- ============================================================
-- VIEWS
-- ============================================================

-- View produk aktif
DROP VIEW IF EXISTS public.v_active_products;
CREATE VIEW public.v_active_products AS
SELECT
  p.*,
  CASE
    WHEN p.stock <= 0 THEN 'habis'
    WHEN p.stock <= 5 THEN 'menipis'
    ELSE 'aman'
  END AS stock_status
FROM public.products p
WHERE p.is_active = TRUE
ORDER BY p.name;

-- View ringkasan transaksi hari ini (FIX: subquery agar tidak double-count)
DROP VIEW IF EXISTS public.v_today_summary;
CREATE VIEW public.v_today_summary AS
SELECT
  COUNT(t.id)::INT                  AS total_transactions,
  COALESCE(SUM(t.total_amount), 0)::INT AS total_revenue,
  COALESCE((
    SELECT SUM(ti2.quantity)
    FROM public.transaction_items ti2
    JOIN public.transactions t2 ON ti2.transaction_id = t2.id
    WHERE t2.transaction_at::DATE = CURRENT_DATE
  ), 0)::INT AS total_items_sold
FROM public.transactions t
WHERE t.transaction_at::DATE = CURRENT_DATE;

-- ============================================================
-- SEED DATA (data awal contoh)
-- ============================================================
INSERT INTO public.penitips (id, name, phone_number, commission_rate, notes) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Bu Siti',    '081234567890', 10, 'Antar jam 06.30 pagi setiap hari'),
  ('00000000-0000-0000-0000-000000000002', 'Bu Ani',     '082345678901', 10, NULL),
  ('00000000-0000-0000-0000-000000000003', 'Pak Budi',   '083456789012', 10, NULL),
  ('00000000-0000-0000-0000-000000000004', 'Dapur Mama', '084567890123', 10, 'Makanan berat, ready jam 11.00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.products (id, name, price, stock, penitip_id, penitip_name, image_url, category, barcode) VALUES
  ('10000000-0000-0000-0000-000000000001', 'Risol Mayo',      5000,  24, '00000000-0000-0000-0000-000000000001', 'Bu Siti',    'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=400&q=80', 'Gorengan',             'TK-2026-001'),
  ('10000000-0000-0000-0000-000000000002', 'Donat Coklat',    3500,  3,  '00000000-0000-0000-0000-000000000003', 'Pak Budi',   'https://images.unsplash.com/photo-1527515862127-a4fc05baf7a5?auto=format&fit=crop&w=400&q=80', 'Kue Basah',            'TK-2026-002'),
  ('10000000-0000-0000-0000-000000000003', 'Brownies Lumer',  12000, 0,  '00000000-0000-0000-0000-000000000002', 'Bu Ani',     'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=400&q=80', 'Kue Basah',            'TK-2026-003'),
  ('10000000-0000-0000-0000-000000000004', 'Rice Bowl Ayam',  10000, 12, '00000000-0000-0000-0000-000000000004', 'Dapur Mama', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80', 'Nasi / Makanan Berat', 'TK-2026-004'),
  ('10000000-0000-0000-0000-000000000005', 'Lemper Ayam',     3500,  15, '00000000-0000-0000-0000-000000000001', 'Bu Siti',    'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80', 'Kue Basah',            'TK-2026-005'),
  ('10000000-0000-0000-0000-000000000006', 'Kue Lapis Legit', 6000,  4,  '00000000-0000-0000-0000-000000000003', 'Pak Budi',   'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=400&q=80', 'Kue Kering',           'TK-2026-006')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.settlements (settlement_code, penitip_id, penitip_name, phone_number, period_start, period_end, total_sold_qty, gross_revenue, commission_rate, commission, net_payout, is_paid) VALUES
  ('SET-202608-01', '00000000-0000-0000-0000-000000000001', 'Bu Siti',  '081234567890', '2026-08-01', '2026-08-22', 37, 185000, 10, 18500, 166500, FALSE),
  ('SET-202608-02', '00000000-0000-0000-0000-000000000002', 'Bu Ani',   '082345678901', '2026-08-01', '2026-08-22', 24, 120000, 10, 12000, 108000, TRUE),
  ('SET-202608-03', '00000000-0000-0000-0000-000000000003', 'Pak Budi', '083456789012', '2026-08-01', '2026-08-22', 31, 310000, 10, 31000, 279000, FALSE)
ON CONFLICT (settlement_code) DO NOTHING;
