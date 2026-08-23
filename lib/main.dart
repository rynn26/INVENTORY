import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // ── Inisialisasi Supabase ──────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey, // ignore: deprecated_member_use
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TitipKasirApp());
}

class TitipKasirApp extends StatelessWidget {
  const TitipKasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TitipKasir',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

