enum StockStatus { aman, menipis, habis }

class StockItem {
  final String id;
  final String name;
  final int price;
  int availableStock;
  final String? imageUrl;
  final String category;
  final String penitipName;
  int initialStock;
  int stockInToday;
  int stockSoldToday;
  int stockReturnedToday;

  StockItem({
    required this.id,
    required this.name,
    required this.price,
    required this.availableStock,
    this.imageUrl,
    this.category = 'Makanan',
    this.penitipName = '',
    this.initialStock = 0,
    this.stockInToday = 0,
    this.stockSoldToday = 0,
    this.stockReturnedToday = 0,
  });

  StockStatus get status {
    if (availableStock <= 0) return StockStatus.habis;
    if (availableStock <= 5) return StockStatus.menipis;
    return StockStatus.aman;
  }

  String get statusLabel {
    switch (status) {
      case StockStatus.aman:
        return 'Aman';
      case StockStatus.menipis:
        return 'Menipis';
      case StockStatus.habis:
        return 'Habis';
    }
  }

  // ─── fromJson (Supabase row) ──────────────────────────────
  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      availableStock: json['stock'] as int,
      imageUrl: json['image_url'] as String?,
      category: (json['category'] as String?) ?? 'Makanan',
      penitipName: (json['penitip_name'] as String?) ?? '',
      initialStock: (json['stock'] as int), // snapshot saat fetch
    );
  }

  // ─── toJson (untuk update Supabase) ──────────────────────
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'stock': availableStock,
      'image_url': imageUrl,
      'category': category,
      'penitip_name': penitipName,
    };
  }

  StockItem copyWith({
    String? id,
    String? name,
    int? price,
    int? availableStock,
    String? imageUrl,
    String? category,
    String? penitipName,
    int? initialStock,
    int? stockInToday,
    int? stockSoldToday,
    int? stockReturnedToday,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      availableStock: availableStock ?? this.availableStock,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      penitipName: penitipName ?? this.penitipName,
      initialStock: initialStock ?? this.initialStock,
      stockInToday: stockInToday ?? this.stockInToday,
      stockSoldToday: stockSoldToday ?? this.stockSoldToday,
      stockReturnedToday: stockReturnedToday ?? this.stockReturnedToday,
    );
  }
}
