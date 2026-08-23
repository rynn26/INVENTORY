class StatSummary {
  final int todayRevenue;
  final int itemsSold;
  final int transactions;
  final int remainingStock;

  const StatSummary({
    required this.todayRevenue,
    required this.itemsSold,
    required this.transactions,
    required this.remainingStock,
  });
}

class TopProduct {
  final int rank;
  final String name;
  final int soldCount;
  final int price;

  const TopProduct({
    required this.rank,
    required this.name,
    required this.soldCount,
    required this.price,
  });
}

class HourlySales {
  final String timeLabel;
  final double amount;
  final bool isCurrent;

  const HourlySales({
    required this.timeLabel,
    required this.amount,
    this.isCurrent = false,
  });
}
