import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/penitip_item.dart';

class PenitipService {
  static final _db = Supabase.instance.client;

  /// Ambil semua penitip aktif
  static Future<List<PenitipItem>> fetchAll() async {
    final data = await _db
        .from('penitips')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return (data as List)
        .map((row) => PenitipItem.fromJson(row))
        .toList();
  }

  /// Ambil satu penitip by id
  static Future<PenitipItem?> fetchById(String id) async {
    final data = await _db
        .from('penitips')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return PenitipItem.fromJson(data);
  }

  /// Tambah penitip baru
  static Future<PenitipItem> create(PenitipItem penitip) async {
    final data = await _db
        .from('penitips')
        .insert(penitip.toJson())
        .select()
        .single();

    return PenitipItem.fromJson(data);
  }

  /// Update data penitip
  static Future<PenitipItem> update(PenitipItem penitip) async {
    final data = await _db
        .from('penitips')
        .update(penitip.toJson())
        .eq('id', penitip.id)
        .select()
        .single();

    return PenitipItem.fromJson(data);
  }

  /// Soft-delete penitip (is_active = false)
  static Future<void> delete(String id) async {
    await _db
        .from('penitips')
        .update({'is_active': false})
        .eq('id', id);
  }
}
