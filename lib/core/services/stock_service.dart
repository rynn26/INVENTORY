import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/stock_item.dart';

class StockMovementRow {
  final String id;
  final String productId;
  final String movementType;
  final int quantity;
  final String? reason;
  final DateTime createdAt;

  StockMovementRow({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantity,
    this.reason,
    required this.createdAt,
  });

  factory StockMovementRow.fromJson(Map<String, dynamic> json) {
    return StockMovementRow(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      movementType: json['movement_type'] as String,
      quantity: json['quantity'] as int,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class StockService {
  static final _db = Supabase.instance.client;

  /// Ambil semua stok produk aktif
  static Future<List<StockItem>> fetchAll() async {
    final data = await _db
        .from('products')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return (data as List)
        .map((row) => StockItem.fromJson(row))
        .toList();
  }

  /// Titipan masuk: tambah stok + catat mutasi
  static Future<void> addStockIn({
    required String productId,
    required int qty,
    String? notes,
  }) async {
    // 1. Ambil stok saat ini
    final current = await _db
        .from('products')
        .select('stock')
        .eq('id', productId)
        .single();
    final currentStock = current['stock'] as int;

    // 2. Update stok
    await _db
        .from('products')
        .update({'stock': currentStock + qty})
        .eq('id', productId);

    // 3. Catat mutasi
    await _db.from('stock_movements').insert({
      'product_id': productId,
      'movement_type': 'stock_in',
      'quantity': qty,
      'reason': notes ?? 'Titipan masuk',
    });
  }

  /// Koreksi / sesuaikan stok manual
  static Future<void> adjustStock({
    required String productId,
    required int newStock,
    String? reason,
  }) async {
    // Ambil stok lama untuk hitung selisih
    final current = await _db
        .from('products')
        .select('stock')
        .eq('id', productId)
        .single();
    final oldStock = current['stock'] as int;
    final delta = newStock - oldStock;

    // Update produk
    await _db
        .from('products')
        .update({'stock': newStock})
        .eq('id', productId);

    // Catat mutasi
    await _db.from('stock_movements').insert({
      'product_id': productId,
      'movement_type': 'adjustment',
      'quantity': delta,
      'reason': reason ?? 'Koreksi stok manual',
    });
  }

  /// Retur sisa titipan ke penitip
  static Future<void> returnStock({
    required String productId,
    required int returnQty,
    String? reason,
  }) async {
    // 1. Ambil stok saat ini
    final current = await _db
        .from('products')
        .select('stock')
        .eq('id', productId)
        .single();
    final currentStock = current['stock'] as int;
    final newStock = (currentStock - returnQty).clamp(0, currentStock);

    // 2. Kurangi stok
    await _db
        .from('products')
        .update({'stock': newStock})
        .eq('id', productId);

    // 3. Catat mutasi retur
    await _db.from('stock_movements').insert({
      'product_id': productId,
      'movement_type': 'return',
      'quantity': -returnQty,
      'reason': reason ?? 'Retur ke penitip',
    });
  }

  /// Ambil riwayat mutasi stok suatu produk (10 terakhir)
  static Future<List<StockMovementRow>> fetchMovementLog(
      String productId) async {
    final data = await _db
        .from('stock_movements')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .limit(10);

    return (data as List)
        .map((row) => StockMovementRow.fromJson(row))
        .toList();
  }
}
