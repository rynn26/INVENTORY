import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_item.dart';

class ProductService {
  static final _db = Supabase.instance.client;

  /// Ambil semua produk aktif dari Supabase
  static Future<List<ProductItem>> fetchAll() async {
    final data = await _db
        .from('products')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return (data as List)
        .map((row) => ProductItem.fromJson(row))
        .toList();
  }

  /// Cari produk berdasarkan barcode
  static Future<ProductItem?> findByBarcode(String barcode) async {
    final data = await _db
        .from('products')
        .select()
        .eq('barcode', barcode)
        .eq('is_active', true)
        .maybeSingle();

    if (data == null) return null;
    return ProductItem.fromJson(data);
  }

  /// Tambah produk baru dari ProductItem
  static Future<ProductItem> create(ProductItem product) async {
    final data = await _db
        .from('products')
        .insert(product.toJson())
        .select()
        .single();

    return ProductItem.fromJson(data);
  }

  /// Tambah produk baru dari field individual (digunakan oleh AddProductModal)
  static Future<ProductItem> createFromFields({
    required String name,
    required int price,
    required int stock,
    required String penitipName,
    String category = 'Lainnya',
    String imageUrl = '',
    String? penitipId,
    String? barcode,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'price': price,
      'stock': stock,
      'penitip_name': penitipName,
      'category': category,
      'image_url': imageUrl.isEmpty ? null : imageUrl,
    };
    if (penitipId != null) payload['penitip_id'] = penitipId;
    if (barcode != null) payload['barcode'] = barcode;
    if (description != null) payload['description'] = description;

    final data = await _db
        .from('products')
        .insert(payload)
        .select()
        .single();

    return ProductItem.fromJson(data);
  }

  /// Update data produk
  static Future<ProductItem> update(ProductItem product) async {
    final data = await _db
        .from('products')
        .update(product.toJson())
        .eq('id', product.id)
        .select()
        .single();

    return ProductItem.fromJson(data);
  }

  /// Soft-delete produk (is_active = false)
  static Future<void> delete(String id) async {
    await _db
        .from('products')
        .update({'is_active': false})
        .eq('id', id);
  }

  /// Decrement stok (fetch dulu lalu update)
  static Future<void> decrementStock(String id, int qty) async {
    final current = await _db
        .from('products')
        .select('stock')
        .eq('id', id)
        .single();
    final newStock =
        ((current['stock'] as int) - qty).clamp(0, 999999);
    await _db
        .from('products')
        .update({'stock': newStock})
        .eq('id', id);
  }
}
