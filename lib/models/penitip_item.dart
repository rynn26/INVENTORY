class PenitipItem {
  final String id;
  final String name;
  final int totalProducts;
  final int totalItems;
  final int totalRevenue;
  final String? phoneNumber;
  final int commissionRate;
  final String? address;
  final String? notes;

  const PenitipItem({
    required this.id,
    required this.name,
    required this.totalProducts,
    required this.totalItems,
    required this.totalRevenue,
    this.phoneNumber,
    this.commissionRate = 10,
    this.address,
    this.notes,
  });

  // ─── fromJson (Supabase row) ──────────────────────────────
  factory PenitipItem.fromJson(Map<String, dynamic> json) {
    return PenitipItem(
      id: json['id'] as String,
      name: json['name'] as String,
      // Data agregat disimpan di Supabase jika ada, default 0
      totalProducts: (json['total_products'] as int?) ?? 0,
      totalItems: (json['total_items'] as int?) ?? 0,
      totalRevenue: (json['total_revenue'] as int?) ?? 0,
      phoneNumber: json['phone_number'] as String?,
      commissionRate: (json['commission_rate'] as int?) ?? 10,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
    );
  }

  // ─── toJson (untuk insert/update Supabase) ────────────────
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'commission_rate': commissionRate,
      'address': address,
      'notes': notes,
    };
  }

  PenitipItem copyWith({
    String? id,
    String? name,
    int? totalProducts,
    int? totalItems,
    int? totalRevenue,
    String? phoneNumber,
    int? commissionRate,
    String? address,
    String? notes,
  }) {
    return PenitipItem(
      id: id ?? this.id,
      name: name ?? this.name,
      totalProducts: totalProducts ?? this.totalProducts,
      totalItems: totalItems ?? this.totalItems,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      commissionRate: commissionRate ?? this.commissionRate,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }
}
