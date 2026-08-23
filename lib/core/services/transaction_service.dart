import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cart_item.dart';

class TransactionResult {
  final String id;
  final String receiptNumber;
  final int totalAmount;
  final int amountPaid;
  final int changeAmount;
  final String paymentMethod;
  final DateTime transactionAt;

  TransactionResult({
    required this.id,
    required this.receiptNumber,
    required this.totalAmount,
    required this.amountPaid,
    required this.changeAmount,
    required this.paymentMethod,
    required this.transactionAt,
  });

  factory TransactionResult.fromJson(Map<String, dynamic> json) {
    return TransactionResult(
      id: json['id'] as String,
      receiptNumber: json['receipt_number'] as String,
      totalAmount: json['total_amount'] as int,
      amountPaid: json['amount_paid'] as int,
      changeAmount: json['change_amount'] as int,
      paymentMethod: json['payment_method'] as String,
      transactionAt: DateTime.parse(json['transaction_at'] as String),
    );
  }
}

class SettlementRow {
  final String id;
  final String settlementCode;
  final String penitipName;
  final String phoneNumber;
  final int totalSoldQty;
  final int grossRevenue;
  final int commission;
  final int netPayout;
  final int commissionRate;
  bool isPaid;

  SettlementRow({
    required this.id,
    required this.settlementCode,
    required this.penitipName,
    required this.phoneNumber,
    required this.totalSoldQty,
    required this.grossRevenue,
    required this.commission,
    required this.netPayout,
    required this.commissionRate,
    this.isPaid = false,
  });

  factory SettlementRow.fromJson(Map<String, dynamic> json) {
    return SettlementRow(
      id: json['id'] as String,
      settlementCode: json['settlement_code'] as String,
      penitipName: json['penitip_name'] as String,
      phoneNumber: json['phone_number'] as String? ?? '',
      totalSoldQty: json['total_sold_qty'] as int,
      grossRevenue: json['gross_revenue'] as int,
      commission: json['commission'] as int,
      netPayout: json['net_payout'] as int,
      commissionRate: json['commission_rate'] as int,
      isPaid: json['is_paid'] as bool,
    );
  }
}

class TodaySummary {
  final int totalTransactions;
  final int totalRevenue;
  final int totalItemsSold;

  TodaySummary({
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalItemsSold,
  });

  factory TodaySummary.fromJson(Map<String, dynamic> json) {
    return TodaySummary(
      totalTransactions: (json['total_transactions'] as int?) ?? 0,
      totalRevenue: (json['total_revenue'] as int?) ?? 0,
      totalItemsSold: (json['total_items_sold'] as int?) ?? 0,
    );
  }
}

class TransactionService {
  static final _db = Supabase.instance.client;

  /// Simpan transaksi kasir beserta item-itemnya
  static Future<TransactionResult> createTransaction({
    required List<CartItem> items,
    required int totalAmount,
    required int amountPaid,
    required String paymentMethod, // 'tunai' | 'qris' | 'transfer'
    String cashierName = 'Kasir',
  }) async {
    final changeAmount = amountPaid - totalAmount;

    // Generate nomor struk: TRX-YYYYMMDD-XXXXXX
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randPart = (now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    final receiptNumber = 'TRX-$datePart-$randPart';

    // 1. Insert header transaksi
    final txData = await _db
        .from('transactions')
        .insert({
          'receipt_number': receiptNumber,
          'total_amount': totalAmount,
          'amount_paid': amountPaid,
          'change_amount': changeAmount,
          'payment_method': paymentMethod,
          'cashier_name': cashierName,
        })
        .select()
        .single();

    final transactionId = txData['id'] as String;

    // 2. Insert item-item transaksi
    final itemsPayload = items
        .map((item) => {
              'transaction_id': transactionId,
              'product_id': item.id,
              'product_name': item.name,
              'penitip_name': item.penitipName ?? '-',
              'unit_price': item.price,
              'quantity': item.quantity,
              'subtotal': item.totalPrice,
            })
        .toList();

    await _db.from('transaction_items').insert(itemsPayload);

    // 3. Kurangi stok tiap produk & catat mutasi
    for (final item in items) {
      // Ambil stok saat ini
      final current = await _db
          .from('products')
          .select('stock')
          .eq('id', item.id)
          .single();
      final currentStock = current['stock'] as int;
      final newStock = (currentStock - item.quantity).clamp(0, currentStock);

      await _db
          .from('products')
          .update({'stock': newStock})
          .eq('id', item.id);

      await _db.from('stock_movements').insert({
        'product_id': item.id,
        'movement_type': 'sold',
        'quantity': -item.quantity,
        'reason': 'Terjual via kasir — struk $receiptNumber',
      });
    }

    return TransactionResult.fromJson(txData);
  }

  /// Ambil ringkasan transaksi hari ini (untuk dashboard)
  static Future<TodaySummary> fetchTodaySummary() async {
    final data = await _db.from('v_today_summary').select().single();
    return TodaySummary.fromJson(data);
  }

  /// Ambil daftar settlement / bagi hasil
  static Future<List<SettlementRow>> fetchSettlements() async {
    final data = await _db
        .from('settlements')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => SettlementRow.fromJson(row))
        .toList();
  }

  /// Tandai settlement sebagai sudah dibayar
  static Future<void> markSettlementPaid(String settlementId) async {
    await _db.from('settlements').update({
      'is_paid': true,
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementId);
  }

  /// Ambil transaksi hari ini (untuk laporan harian)
  static Future<List<Map<String, dynamic>>> fetchTodayTransactions() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final data = await _db
        .from('transactions')
        .select('*, transaction_items(*)')
        .gte('transaction_at', '${today}T00:00:00')
        .lte('transaction_at', '${today}T23:59:59')
        .order('transaction_at', ascending: false);

    return (data as List).cast<Map<String, dynamic>>();
  }
}
