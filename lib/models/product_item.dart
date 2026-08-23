class ProductItem {
  final String id;
  final String name;
  final int price;
  final int stock;
  final String penitipName;
  final String imageUrl;
  final String category;
  final String? barcode;
  final String? description;

  const ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.penitipName,
    required this.imageUrl,
    required this.category,
    this.barcode,
    this.description,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 5;

  // ─── fromJson (Supabase row) ──────────────────────────────
  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      stock: json['stock'] as int,
      penitipName: json['penitip_name'] as String,
      imageUrl: (json['image_url'] as String?) ??
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
      category: (json['category'] as String?) ?? 'Lainnya',
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
    );
  }

  // ─── toJson (untuk insert/update Supabase) ────────────────
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'penitip_name': penitipName,
      'image_url': imageUrl,
      'category': category,
      if (barcode != null) 'barcode': barcode,
      if (description != null) 'description': description,
    };
  }

  ProductItem copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    String? penitipName,
    String? imageUrl,
    String? category,
    String? barcode,
    String? description,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      penitipName: penitipName ?? this.penitipName,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
    );
  }
}
