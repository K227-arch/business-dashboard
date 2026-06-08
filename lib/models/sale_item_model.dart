/// Represents a single sold item in the Items list on the Sales page.
class SaleItemModel {
  final String name;
  final int quantity;
  final double totalAmount;
  final String? imageUrl; // null = show placeholder avatar

  const SaleItemModel({
    required this.name,
    required this.quantity,
    required this.totalAmount,
    this.imageUrl,
  });
}

/// Represents a daily sales snapshot for the "hourly" bar chart.
class HourlySalePoint {
  final String hour; // e.g. "0:00", "10:00", "20:00"
  final double amount; // in UGX thousands

  const HourlySalePoint({required this.hour, required this.amount});
}

/// Aggregated summary for a given period.
class SalesSummary {
  final int receipts;
  final double netSales;
  final double averageSale;
  final double receiptsChange; // % vs previous period
  final double netSalesChange;
  final double averageSaleChange;
  final List<HourlySalePoint> hourlyData;
  final List<SaleItemModel> items;

  const SalesSummary({
    required this.receipts,
    required this.netSales,
    required this.averageSale,
    required this.receiptsChange,
    required this.netSalesChange,
    required this.averageSaleChange,
    required this.hourlyData,
    required this.items,
  });
}

enum SalesPeriod { today, thisWeek, thisMonth, thisYear, custom }
