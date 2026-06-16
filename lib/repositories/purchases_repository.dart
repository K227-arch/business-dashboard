import '../services/frappe_api.dart';

// ── Period enum (mirrors SalesPeriod) ─────────────────────────────────────
enum PurchasesPeriod { today, thisWeek, thisMonth, thisYear, custom }

// ── Data models ────────────────────────────────────────────────────────────
class PurchaseItemModel {
  final String name;
  final int quantity;
  final double totalAmount;
  const PurchaseItemModel({
    required this.name,
    required this.quantity,
    required this.totalAmount,
  });
}

class DailyPurchasePoint {
  final String label;
  final double amount;
  const DailyPurchasePoint({required this.label, required this.amount});
}

class PurchasesSummary {
  final int receipts;
  final double totalSpend;
  final double averagePurchase;
  final double receiptsChange;
  final double totalSpendChange;
  final double averagePurchaseChange;
  final List<DailyPurchasePoint> chartData;
  final List<PurchaseItemModel> items;

  const PurchasesSummary({
    required this.receipts,
    required this.totalSpend,
    required this.averagePurchase,
    required this.receiptsChange,
    required this.totalSpendChange,
    required this.averagePurchaseChange,
    required this.chartData,
    required this.items,
  });
}

// ── Repository ─────────────────────────────────────────────────────────────
class PurchasesRepository {
  const PurchasesRepository();

  Future<PurchasesSummary> getPurchasesSummary({
    required PurchasesPeriod period,
    required DateTime date,
  }) async {
    final range = _dateRange(period, date);
    final fromDate = range.$1;
    final toDate = range.$2;

    try {
      final results = await Future.wait([
        FrappeApi.getPurchaseInvoices(fromDate: fromDate, toDate: toDate, limit: 500),
        FrappeApi.getPurchaseInvoiceItems(fromDate: fromDate, toDate: toDate, limit: 500),
      ]);

      final invoices = results[0];
      final itemsRaw = results[1];

      final receipts = invoices.length;
      final totalSpend = invoices.fold<double>(
          0, (s, i) => s + _toDouble(i['grand_total']));
      final averagePurchase = receipts == 0 ? 0.0 : totalSpend / receipts;
      final chartData = _buildChartData(invoices, period);

      final Map<String, _ItemAgg> agg = {};
      for (final item in itemsRaw) {
        final key = item['item_name']?.toString() ?? item['item_code']?.toString() ?? 'Unknown';
        final qty = _toDouble(item['qty']);
        final amt = _toDouble(item['amount']);
        agg.update(key, (e) => _ItemAgg(e.name, e.qty + qty, e.amount + amt),
            ifAbsent: () => _ItemAgg(key, qty, amt));
      }

      final items = agg.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
      final purchaseItems = items.take(20).map((a) => PurchaseItemModel(
            name: a.name.toUpperCase(),
            quantity: a.qty.toInt(),
            totalAmount: a.amount,
          )).toList();

      return PurchasesSummary(
        receipts: receipts,
        totalSpend: totalSpend,
        averagePurchase: averagePurchase,
        receiptsChange: 0,
        totalSpendChange: 0,
        averagePurchaseChange: 0,
        chartData: chartData,
        items: purchaseItems,
      );
    } catch (_) {
      return const PurchasesSummary(
        receipts: 0, totalSpend: 0, averagePurchase: 0,
        receiptsChange: 0, totalSpendChange: 0, averagePurchaseChange: 0,
        chartData: [], items: [],
      );
    }
  }

  // ── Chart bucketing ────────────────────────────────────────────────────

  List<DailyPurchasePoint> _buildChartData(
      List<dynamic> invoices, PurchasesPeriod period) {
    switch (period) {
      case PurchasesPeriod.today:
        return _bucketByHour(invoices);
      case PurchasesPeriod.thisWeek:
        return _bucketByWeekday(invoices);
      case PurchasesPeriod.thisMonth:
        return _bucketByWeek(invoices);
      case PurchasesPeriod.thisYear:
        return _bucketByMonth(invoices);
      case PurchasesPeriod.custom:
        return _bucketByWeekday(invoices);
    }
  }

  List<DailyPurchasePoint> _bucketByHour(List<dynamic> invoices) {
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
        .map((e) => DailyPurchasePoint(label: e.key, amount: e.value))
        .toList();
  }

  List<DailyPurchasePoint> _bucketByWeekday(List<dynamic> invoices) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final buckets = {for (var d in days) d: 0.0};
    for (final inv in invoices) {
      final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
      if (d != null) {
        final key = days[d.weekday - 1];
        buckets[key] = (buckets[key] ?? 0) + _toDouble(inv['grand_total']) / 1000;
      }
    }
    return days
        .map((d) => DailyPurchasePoint(label: d, amount: buckets[d]!))
        .toList();
  }

  List<DailyPurchasePoint> _bucketByWeek(List<dynamic> invoices) {
    final buckets = {'W1': 0.0, 'W2': 0.0, 'W3': 0.0, 'W4': 0.0, 'W5': 0.0};
    for (final inv in invoices) {
      final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
      if (d != null) {
        final week = 'W${((d.day - 1) ~/ 7 + 1).clamp(1, 5)}';
        buckets[week] = (buckets[week] ?? 0) + _toDouble(inv['grand_total']) / 1000;
      }
    }
    return ['W1', 'W2', 'W3', 'W4', 'W5']
        .map((w) => DailyPurchasePoint(label: w, amount: buckets[w]!))
        .toList();
  }

  List<DailyPurchasePoint> _bucketByMonth(List<dynamic> invoices) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final buckets = {for (var m in months) m: 0.0};
    for (final inv in invoices) {
      final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
      if (d != null) {
        final key = months[d.month - 1];
        buckets[key] = (buckets[key] ?? 0) + _toDouble(inv['grand_total']) / 1000;
      }
    }
    return months
        .map((m) => DailyPurchasePoint(label: m, amount: buckets[m]!))
        .toList();
  }

  // ── Date range helpers ─────────────────────────────────────────────────

  (String, String) _dateRange(PurchasesPeriod period, DateTime date) {
    final d = date;
    switch (period) {
      case PurchasesPeriod.today:
        return (_ymd(d), _ymd(d));
      case PurchasesPeriod.thisWeek:
        final mon = d.subtract(Duration(days: d.weekday - 1));
        final sun = mon.add(const Duration(days: 6));
        return (_ymd(mon), _ymd(sun));
      case PurchasesPeriod.thisMonth:
        final start = DateTime(d.year, d.month, 1);
        final end = DateTime(d.year, d.month + 1, 0);
        return (_ymd(start), _ymd(end));
      case PurchasesPeriod.thisYear:
        return ('${d.year}-01-01', '${d.year}-12-31');
      case PurchasesPeriod.custom:
        return (_ymd(d), _ymd(d));
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  static double _toDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

class _ItemAgg {
  final String name;
  final double qty;
  final double amount;
  const _ItemAgg(this.name, this.qty, this.amount);
}

// ── Lightweight list model for transactions screen ─────────────────────────
class PurchaseListItem {
  final String id;
  final String supplierName;
  final String description;
  final double total;
  final String date;
  final String status; // "Paid" | "Unpaid" | "Overdue" | "Cancelled"

  const PurchaseListItem({
    required this.id,
    required this.supplierName,
    required this.description,
    required this.total,
    required this.date,
    required this.status,
  });
}

extension PurchasesRepositoryList on PurchasesRepository {
  Future<List<PurchaseListItem>> getPurchaseList({
    String? fromDate,
    String? toDate,
    int limit = 100,
  }) async {
    try {
      final raw = await FrappeApi.getPurchaseInvoices(
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
      return raw.map<PurchaseListItem>((item) {
        return PurchaseListItem(
          id: item['name']?.toString() ?? '',
          supplierName: item['supplier_name']?.toString() ??
              item['supplier']?.toString() ??
              'Unknown',
          description: item['remarks']?.toString() ?? 'Purchase Invoice',
          total: PurchasesRepository._toDouble(item['grand_total']),
          date: PurchasesRepository._formatDate(
              item['posting_date']?.toString() ?? ''),
          status: item['status']?.toString() ?? 'Unpaid',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

