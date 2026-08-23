// ============================================================
// lib/core/services/supabase_config.dart
//
// CARA PAKAI:
// 1. Buka: https://supabase.com/dashboard → pilih project kamu
// 2. Klik Settings → API
// 3. Salin "Project URL" → isi di supabaseUrl
// 4. Salin "anon public" key → isi di supabaseAnonKey
// ============================================================

class SupabaseConfig {
  // ⬇ GANTI dengan URL project Supabase kamu
  static const String supabaseUrl = 'https://pvwgcrbyserxlkpatkyr.supabase.co';

  // ⬇ Anon Key project Supabase
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2d2djcmJ5c2VyeGxrcGF0a3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0MDYzMzAsImV4cCI6MjEwMjk4MjMzMH0.9FWLHbq4o8cwIXKtItELKraSbdb-I_DVVa5_cAsPjkA';
}
