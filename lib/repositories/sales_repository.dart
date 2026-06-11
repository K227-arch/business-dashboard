import '../data/mock_data.dart';
import '../models/sale_item_model.dart';
import '../services/frappe_api.dart';

/// Fetches Sales Invoice data for [SalesScreen].
/// Falls back to mock data when the Frappe API fails.
class SalesRepository {
  const SalesRepository();

  Future<SalesSummary> getSalesSummary({
    required SalesPeriod period,
    required DateTime date,
  }) async {
    try {
      return await _fetchLive(period, date);
    } catch (_) {
      return MockData.salesSummaries[period] ?? MockData.salesSummaries[SalesPeriod.today]!;
    }
  }

  Future<SalesSummary> _fetchLive(SalesPeriod period, DateTime date) async {
    final range = _dateRange(period, date);
    final fromDate = range.$1;
    final toDate   = range.$2;

    // Fetch invoices + items concurrently
    final results = await Future.wait([
      FrappeApi.getSalesInvoices(fromDate: fromDate, toDate: toDate, limit: 500),
      FrappeApi.getSalesInvoiceItems(limit: 500),
    ]);

    final invoices   = results[0];
    final itemsRaw   = results[1];

    // ── Compute summary metrics ──────────────────────────────────────────
    final receipts   = invoices.length;
    final netSales   = invoices.fold<double>(
        0, (s, i) => s + _toDouble(i['net_total']));
    final averageSale = receipts == 0 ? 0.0 : netSales / receipts;

    // ── Build hourly/daily chart data ────────────────────────────────────
    final hourlyData = _buildChartData(invoices, period);

    // ── Aggregate items ──────────────────────────────────────────────────
    final Map<String, _ItemAgg> agg = {};
    for (final item in itemsRaw) {
      final key  = item['item_name']?.toString() ?? item['item_code']?.toString() ?? 'Unknown';
      final qty  = _toDouble(item['qty']);
      final amt  = _toDouble(item['amount']);
      agg.update(
        key,
        (existing) => _ItemAgg(
          existing.name, existing.qty + qty, existing.amount + amt),
        ifAbsent: () => _ItemAgg(key, qty, amt),
      );
    }

    final items = agg.values
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final saleItems = items
        .take(20)
        .map((a) => SaleItemModel(
              name: a.name.toUpperCase(),
              quantity: a.qty.toInt(),
              totalAmount: a.amount,
            ))
        .toList();

    return SalesSummary(
      receipts: receipts,
      netSales: netSales,
      averageSale: averageSale,
      // Placeholder change % — would need prior period data for real %
      receiptsChange: 0,
      netSalesChange: 0,
      averageSaleChange: 0,
      hourlyData: hourlyData,
      items: saleItems,
    );
  }

  // ── Chart bucketing ────────────────────────────────────────────────────

  List<HourlySalePoint> _buildChartData(
      List<dynamic> invoices, SalesPeriod period) {
    switch (period) {
      case SalesPeriod.today:
        return _bucketByHour(invoices);
      case SalesPeriod.thisWeek:
        return _bucketByWeekday(invoices);
      case SalesPeriod.thisMonth:
        return _bucketByWeek(invoices);
      case SalesPeriod.thisYear:
        return _bucketByMonth(invoices);
      case SalesPeriod.custom:
        return _bucketByWeekday(invoices);
    }
  }

  List<HourlySalePoint> _bucketByHour(List<dynamic> invoices) {
    final buckets = <String, double>{};
    for (var h = 0; h < 24; h += 2) {
      buckets['${h.toString().padLeft(2, '0')}:00'] = 0;
    }
    for (final inv in invoices) {
      final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
      if (d != null) {
        final slot = '${(d.hour ~/ 2 * 2).toString().padLeft(2, '0')}:00';
        buckets[slot] = (buckets[slot] ?? 0) + _toDouble(inv['grand_total']) / 1000;
      }
    }
    return buckets.entries
        .map((e) => HourlySalePoint(hour: e.key, amount: e.value))
        .toList();
  }

  List<HourlySalePoint> _bucketByWeekday(List<dynamic> invoices) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final buckets = {for (var d in days) d: 0.0};
    for (final inv in invoices) {
      final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
      if (d != null) {
        final key = days[d.weekday - 1];
        buckets[key] = (buckets[key] ?? 0) + _toDouble(inv['grand_total']) / 1000;
      }
    }
    return days.map((d) => HourlySalePoint(hour: d, amount: buckets[d]!)).toList();
  }

  List<HourlySalePoint> _bucketByWeek(List<dynamic> invoices) {
    final buckets = {'W1': 0.0, 'W2': 0.0, 'W3': 0.0, 'W4': 0.0, 'W5': 0.0};
    for (final inv in invoices) {
      final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
      if (d != null) {
        final week = 'W${((d.day - 1) ~/ 7 + 1).clamp(1, 5)}';
        buckets[week] = (buckets[week] ?? 0) + _toDouble(inv['grand_total']) / 1000;
      }
    }
    return ['W1', 'W2', 'W3', 'W4', 'W5']
        .map((w) => HourlySalePoint(hour: w, amount: buckets[w]!))
        .toList();
  }

  List<HourlySalePoint> _bucketByMonth(List<dynamic> invoices) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final buckets = {for (var m in months) m: 0.0};
    for (final inv in invoices) {
      final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
      if (d != null) {
        final key = months[d.month - 1];
        buckets[key] = (buckets[key] ?? 0) + _toDouble(inv['grand_total']) / 1000;
      }
    }
    return months
        .map((m) => HourlySalePoint(hour: m, amount: buckets[m]!))
        .toList();
  }

  // ── Date range helpers ─────────────────────────────────────────────────

  (String, String) _dateRange(SalesPeriod period, DateTime date) {
    final d = date;
    switch (period) {
      case SalesPeriod.today:
        return (_ymd(d), _ymd(d));
      case SalesPeriod.thisWeek:
        final mon = d.subtract(Duration(days: d.weekday - 1));
        final sun = mon.add(const Duration(days: 6));
        return (_ymd(mon), _ymd(sun));
      case SalesPeriod.thisMonth:
        final start = DateTime(d.year, d.month, 1);
        final end   = DateTime(d.year, d.month + 1, 0);
        return (_ymd(start), _ymd(end));
      case SalesPeriod.thisYear:
        return ('${d.year}-01-01', '${d.year}-12-31');
      case SalesPeriod.custom:
        return (_ymd(d), _ymd(d));
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  static double _toDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;
}

class _ItemAgg {
  final String name;
  final double qty;
  final double amount;
  const _ItemAgg(this.name, this.qty, this.amount);
}
