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

/// Ringkasan penjualan untuk satu periode (range tanggal)
class PeriodSummary {
  final int totalRevenue;
  final int totalItemsSold;
  final int totalTransactions;
  final List<Map<String, dynamic>> topProducts;   // [{name, consignor, qty, revenue}]
  final List<Map<String, dynamic>> consignors;    // [{name, qty, revenue}]

  PeriodSummary({
    required this.totalRevenue,
    required this.totalItemsSold,
    required this.totalTransactions,
    required this.topProducts,
    required this.consignors,
  });
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

  /// Ambil ringkasan keuangan toko keseluruhan (dari transaksi kasir aktual)
  static Future<Map<String, int>> fetchOverallFinancialSummary() async {
    try {
      final txListRaw = await _db
          .from('transactions')
          .select('*, transaction_items(*)');
      final penitipNominals = await fetchPenitipNominals();

      final txList = (txListRaw as List).cast<Map<String, dynamic>>();

      if (txList.isNotEmpty) {
        final summary = _summarizeTransactions(txList, penitipNominals);

        int storeCommission = 0;
        int consignorPayout = 0;

        for (final c in summary.consignors) {
          final isOwn = c['is_own'] as bool? ?? false;
          final revenue = c['revenue'] as int? ?? 0;
          final qty = c['qty'] as int? ?? 0;
          final commissionNominal = (c['commission_nominal'] as int?) ?? 0;

          if (isOwn) {
            storeCommission += revenue; // 100% laba toko
          } else {
            final comm = commissionNominal > 0 ? commissionNominal * qty : 0;
            storeCommission += comm;
            consignorPayout += (revenue - comm);
          }
        }

        return {
          'gross': summary.totalRevenue,
          'commission': storeCommission,
          'netPayout': consignorPayout,
          'totalTransactions': summary.totalTransactions,
          'totalItemsSold': summary.totalItemsSold,
        };
      }

      // Fallback jika transactions kosong, coba ambil dari settlements
      final settlements = await fetchSettlements();
      if (settlements.isNotEmpty) {
        return {
          'gross': settlements.fold(0, (sum, s) => sum + s.grossRevenue),
          'commission': settlements.fold(0, (sum, s) => sum + s.commission),
          'netPayout': settlements.fold(0, (sum, s) => sum + s.netPayout),
          'totalTransactions': 0,
          'totalItemsSold': 0,
        };
      }

      return {
        'gross': 0,
        'commission': 0,
        'netPayout': 0,
        'totalTransactions': 0,
        'totalItemsSold': 0,
      };
    } catch (_) {
      return {
        'gross': 0,
        'commission': 0,
        'netPayout': 0,
        'totalTransactions': 0,
        'totalItemsSold': 0,
      };
    }
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

  /// Ambil semua transaksi dalam range tanggal tertentu
  static Future<List<Map<String, dynamic>>> fetchTransactionsByDateRange(
    String startIso,
    String endIso,
  ) async {
    final data = await _db
        .from('transactions')
        .select('*, transaction_items(*)')
        .gte('transaction_at', startIso)
        .lte('transaction_at', endIso)
        .order('transaction_at', ascending: true);

    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Hapus satu transaksi (dengan opsi pengembalian stok)
  static Future<void> deleteTransaction(
    String transactionId, {
    bool restoreStock = true,
  }) async {
    // 1. Ambil data transaksi beserta item-itemnya
    final txData = await _db
        .from('transactions')
        .select('*, transaction_items(*)')
        .eq('id', transactionId)
        .maybeSingle();

    if (txData == null) return;

    final receiptNumber = txData['receipt_number'] as String? ?? '-';
    final items = (txData['transaction_items'] as List?) ?? [];

    // 2. Kembalikan stok jika diminta
    if (restoreStock && items.isNotEmpty) {
      for (final item in items) {
        final productId = item['product_id'] as String?;
        final qty = (item['quantity'] as int?) ?? 0;
        if (productId != null && qty > 0) {
          try {
            final prod = await _db
                .from('products')
                .select('stock')
                .eq('id', productId)
                .maybeSingle();

            if (prod != null) {
              final currentStock = (prod['stock'] as int?) ?? 0;
              final newStock = currentStock + qty;

              await _db
                  .from('products')
                  .update({'stock': newStock})
                  .eq('id', productId);

              await _db.from('stock_movements').insert({
                'product_id': productId,
                'movement_type': 'adjustment',
                'quantity': qty,
                'reason': 'Pengembalian stok — pembatalan struk $receiptNumber',
              });
            }
          } catch (_) {
            // Lanjut jika produk gagal dipulihkan
          }
        }
      }
    }

    // 3. Hapus header transaksi (transaction_items akan ikut terhapus via CASCADE)
    await _db.from('transactions').delete().eq('id', transactionId);
  }

  /// Hapus semua transaksi pada tanggal tertentu (dengan opsi pemulihan stok)
  static Future<int> deleteTransactionsByDate(
    DateTime date, {
    bool restoreStock = true,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final txList = await _db
        .from('transactions')
        .select('*, transaction_items(*)')
        .gte('transaction_at', '${dateStr}T00:00:00')
        .lte('transaction_at', '${dateStr}T23:59:59');

    final transactions = (txList as List).cast<Map<String, dynamic>>();
    if (transactions.isEmpty) return 0;

    for (final tx in transactions) {
      final txId = tx['id'] as String;
      final receiptNumber = tx['receipt_number'] as String? ?? '-';
      final items = (tx['transaction_items'] as List?) ?? [];

      if (restoreStock && items.isNotEmpty) {
        for (final item in items) {
          final productId = item['product_id'] as String?;
          final qty = (item['quantity'] as int?) ?? 0;
          if (productId != null && qty > 0) {
            try {
              final prod = await _db
                  .from('products')
                  .select('stock')
                  .eq('id', productId)
                  .maybeSingle();

              if (prod != null) {
                final currentStock = (prod['stock'] as int?) ?? 0;
                final newStock = currentStock + qty;

                await _db
                    .from('products')
                    .update({'stock': newStock})
                    .eq('id', productId);

                await _db.from('stock_movements').insert({
                  'product_id': productId,
                  'movement_type': 'adjustment',
                  'quantity': qty,
                  'reason': 'Pengembalian stok — reset laporan tanggal $dateStr ($receiptNumber)',
                });
              }
            } catch (_) {}
          }
        }
      }

      await _db.from('transactions').delete().eq('id', txId);
    }

    return transactions.length;
  }

  /// Hitung ringkasan penjualan dari list transaksi
  /// [penitipNominals] = map nama penitip → commission_nominal (Rp/item)
  static PeriodSummary _summarizeTransactions(
      List<Map<String, dynamic>> txList,
      Map<String, int> penitipNominals) {
    int totalRevenue = 0;
    int totalItemsSold = 0;
    final Map<String, Map<String, dynamic>> productMap = {};

    for (final tx in txList) {
      final items = tx['transaction_items'] as List? ?? [];
      totalRevenue += (tx['total_amount'] as int? ?? 0);
      for (final item in items) {
        final name = item['product_name'] as String? ?? '-';
        final penitip = item['penitip_name'] as String? ?? '-';
        final qty = item['quantity'] as int? ?? 0;
        final subtotal = item['subtotal'] as int? ?? 0;
        totalItemsSold += qty;
        if (!productMap.containsKey(name)) {
          productMap[name] = {'penitip': penitip, 'qty': 0, 'revenue': 0};
        }
        productMap[name]!['qty'] =
            (productMap[name]!['qty'] as int) + qty;
        productMap[name]!['revenue'] =
            (productMap[name]!['revenue'] as int) + subtotal;
      }
    }

    // Top 3 produk berdasarkan qty terjual
    final sortedProducts = productMap.entries.toList()
      ..sort(
          (a, b) => (b.value['qty'] as int).compareTo(a.value['qty'] as int));
    final topProducts = sortedProducts.take(3).map((e) => {
          'name': e.key,
          'consignor': e.value['penitip'],
          'qty': e.value['qty'],
          'revenue': e.value['revenue'],
        }).toList();

    // Rekapitulasi per penitip
    // Produk sendiri: penitip_name kosong atau '-' → dikelompokkan sbg 'Dagangan Sendiri'
    const ownLabel = 'Dagangan Sendiri';
    final Map<String, Map<String, dynamic>> penitipMap = {};
    for (final entry in productMap.entries) {
      final rawP = entry.value['penitip'] as String;
      final p = (rawP.isEmpty || rawP == '-') ? ownLabel : rawP;
      if (!penitipMap.containsKey(p)) {
        penitipMap[p] = {'qty': 0, 'revenue': 0, 'is_own': p == ownLabel};
      }
      penitipMap[p]!['qty'] =
          (penitipMap[p]!['qty'] as int) + (entry.value['qty'] as int);
      penitipMap[p]!['revenue'] =
          (penitipMap[p]!['revenue'] as int) + (entry.value['revenue'] as int);
    }
    final consignors = penitipMap.entries
        .map((e) {
          final isOwn = e.value['is_own'] as bool? ?? false;
          // Produk sendiri tidak kena komisi
          final nominalPerItem = isOwn ? 0 : (penitipNominals[e.key] ?? 0);
          return {
            'name': e.key,
            'qty': e.value['qty'],
            'revenue': e.value['revenue'],
            'commission_nominal': nominalPerItem,
            'is_own': isOwn, // true = dagangan sendiri
          };
        })
        .toList();

    return PeriodSummary(
      totalRevenue: totalRevenue,
      totalItemsSold: totalItemsSold,
      totalTransactions: txList.length,
      topProducts: topProducts,
      consignors: consignors,
    );
  }

  /// Fetch map: nama penitip → commission_nominal (Rp per item) dari DB
  static Future<Map<String, int>> fetchPenitipNominals() async {
    try {
      final data = await _db
          .from('penitips')
          .select('name, commission_nominal');
      final Map<String, int> result = {};
      for (final row in (data as List)) {
        final name = row['name'] as String? ?? '';
        final nominal = (row['commission_nominal'] as int?) ?? 0;
        if (name.isNotEmpty) result[name] = nominal;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Ambil ringkasan laporan bulanan (per minggu sebagai chart bar)
  static Future<Map<String, dynamic>> fetchMonthlySummary(
      int year, int month) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);

    final results = await Future.wait([
      fetchTransactionsByDateRange(
        firstDay.toIso8601String(),
        lastDay.toIso8601String(),
      ),
      fetchPenitipNominals(),
    ]);
    final txList = results[0] as List<Map<String, dynamic>>;
    final penitipNominals = results[1] as Map<String, int>;

    final summary = _summarizeTransactions(txList, penitipNominals);

    // Buat data chart per minggu
    final List<Map<String, dynamic>> weeklyBars = [];
    for (int week = 1; week <= 4; week++) {
      final weekStart = DateTime(year, month, (week - 1) * 7 + 1);
      final weekEnd = week < 4
          ? DateTime(year, month, week * 7, 23, 59, 59)
          : lastDay;
      int weekRevenue = 0;
      for (final tx in txList) {
        final at = DateTime.parse(tx['transaction_at'] as String);
        if (!at.isBefore(weekStart) && !at.isAfter(weekEnd)) {
          weekRevenue += tx['total_amount'] as int? ?? 0;
        }
      }
      weeklyBars.add({
        'label': 'Mg $week',
        'value': weekRevenue / 1000.0, // dalam ribuan
        'tooltipText': 'Rp ${_formatRupiah(weekRevenue)}',
      });
    }

    return {
      'summary': summary,
      'chartBars': weeklyBars,
    };
  }

  /// Ambil ringkasan laporan tahunan (per bulan sebagai chart bar)
  static Future<Map<String, dynamic>> fetchYearlySummary(int year) async {
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31, 23, 59, 59);

    final results = await Future.wait([
      fetchTransactionsByDateRange(
        firstDay.toIso8601String(),
        lastDay.toIso8601String(),
      ),
      fetchPenitipNominals(),
    ]);
    final txList = results[0] as List<Map<String, dynamic>>;
    final penitipNominals = results[1] as Map<String, int>;

    final summary = _summarizeTransactions(txList, penitipNominals);

    // Data chart per bulan (Jan–Des)
    const monthLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final List<Map<String, dynamic>> monthlyBars = [];
    for (int m = 1; m <= 12; m++) {
      final mStart = DateTime(year, m, 1);
      final mEnd = DateTime(year, m + 1, 0, 23, 59, 59);
      int mRevenue = 0;
      for (final tx in txList) {
        final at = DateTime.parse(tx['transaction_at'] as String);
        if (!at.isBefore(mStart) && !at.isAfter(mEnd)) {
          mRevenue += tx['total_amount'] as int? ?? 0;
        }
      }
      monthlyBars.add({
        'label': monthLabels[m - 1],
        'value': mRevenue / 1000000.0, // dalam jutaan
        'tooltipText':
            'Rp ${(mRevenue / 1000000).toStringAsFixed(1)} Juta',
      });
    }

    return {
      'summary': summary,
      'chartBars': monthlyBars,
    };
  }

  /// Helper: format rupiah singkat untuk tooltip
  static String _formatRupiah(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} Juta';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}.000';
    }
    return value.toString();
  }
}
