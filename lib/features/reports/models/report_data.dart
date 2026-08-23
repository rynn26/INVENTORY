enum ReportPeriod { daily, monthly, yearly }

class ReportData {
  final String periodTitle;
  final String periodSubtitle;
  final int totalRevenue;
  final int storeCommission;
  final int consignorPayout;
  final int totalItemsSold;
  final int totalTransactions;
  final List<ChartBarData> chartBars;
  final List<TopSoldItem> topProducts;
  final List<ConsignorSalesSummary> consignorSummaries;

  const ReportData({
    required this.periodTitle,
    required this.periodSubtitle,
    required this.totalRevenue,
    required this.storeCommission,
    required this.consignorPayout,
    required this.totalItemsSold,
    required this.totalTransactions,
    required this.chartBars,
    required this.topProducts,
    required this.consignorSummaries,
  });
}

class ChartBarData {
  final String label;
  final double value; // in thousands (k) or millions
  final String tooltipText;
  final bool isHighlight;

  const ChartBarData({
    required this.label,
    required this.value,
    required this.tooltipText,
    this.isHighlight = false,
  });
}

class TopSoldItem {
  final String name;
  final String consignor;
  final int quantity;
  final int revenue;

  const TopSoldItem({
    required this.name,
    required this.consignor,
    required this.quantity,
    required this.revenue,
  });
}

class ConsignorSalesSummary {
  final String name;
  final int itemsSold;
  final int grossAmount;
  final int commission;
  final int netAmount;

  const ConsignorSalesSummary({
    required this.name,
    required this.itemsSold,
    required this.grossAmount,
    required this.commission,
    required this.netAmount,
  });
}
