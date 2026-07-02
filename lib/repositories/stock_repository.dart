import '../services/frappe_client.dart';

/// Repository for all stock/inventory features:
/// 1. Ageing Stock Reports
/// 2. Items Running out of Stock
/// 3. Top Sellers
/// 4. Items and their Sales
/// 5. Stock Out & Expiry Alerts

class StockItem {
  final String itemCode;
  final double actualQty;
  final double projectedQty;
  final String warehouse;

  const StockItem({
    required this.itemCode,
    required this.actualQty,
    required this.projectedQty,
    required this.warehouse,
  });
}

class BatchItem {
  final String batchId;
  final String item;
  final String? expiryDate;
  final double batchQty;

  const BatchItem({
    required this.batchId,
    required this.item,
    this.expiryDate,
    required this.batchQty,
  });

  bool get isExpired {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    final exp = DateTime.tryParse(expiryDate!);
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    final exp = DateTime.tryParse(expiryDate!);
    if (exp == null) return false;
    return exp.isAfter(DateTime.now()) &&
        exp.isBefore(DateTime.now().add(const Duration(days: 30)));
  }
}

class TopSellerItem {
  final String itemName;
  final double totalQty;
  final double totalAmount;

  const TopSellerItem({
    required this.itemName,
    required this.totalQty,
    required this.totalAmount,
  });
}

class StockRepository {
  const StockRepository();

  // ── 1. Ageing Stock (items in stock with their age from last receipt) ──
  Future<List<StockItem>> getAgeingStock() async {
    try {
      final res = await FrappeClient.getList(
        doctype: 'Bin',
        fields: ['item_code', 'warehouse', 'actual_qty', 'projected_qty'],
        filters: [['actual_qty', '>', 0]],
        orderBy: 'actual_qty asc',
        limit: 1000,
      );
      final data = res['data'] as List<dynamic>? ?? [];
      return data.map((d) => StockItem(
            itemCode: d['item_code']?.toString() ?? '',
            actualQty: _toDouble(d['actual_qty']),
            projectedQty: _toDouble(d['projected_qty']),
            warehouse: d['warehouse']?.toString() ?? '',
          )).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 2. Items Running Out of Stock (qty <= 5) ──────────────────────────
  Future<List<StockItem>> getLowStockItems({double threshold = 5}) async {
    try {
      final res = await FrappeClient.getList(
        doctype: 'Bin',
        fields: ['item_code', 'warehouse', 'actual_qty', 'projected_qty'],
        filters: [
          ['actual_qty', '<=', threshold],
          ['actual_qty', '>', 0],
        ],
        orderBy: 'actual_qty asc',
        limit: 1000,
      );
      final data = res['data'] as List<dynamic>? ?? [];
      return data.map((d) => StockItem(
            itemCode: d['item_code']?.toString() ?? '',
            actualQty: _toDouble(d['actual_qty']),
            projectedQty: _toDouble(d['projected_qty']),
            warehouse: d['warehouse']?.toString() ?? '',
          )).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 3. Top Sellers (by qty sold this month) ────────────────────────────
  Future<List<TopSellerItem>> getTopSellers() async {
    try {
      final now = DateTime.now();
      final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Fetch all invoice items this month
      final invoices = await FrappeClient.getList(
        doctype: 'Sales Invoice',
        fields: ['name'],
        filters: [
          ['docstatus', '=', 1],
          ['posting_date', '>=', monthStart],
          ['posting_date', '<=', today],
        ],
        limit: 1000,
      );
      final invoiceList = invoices['data'] as List<dynamic>? ?? [];

      final Map<String, _Agg> agg = {};
      for (final inv in invoiceList) {
        try {
          final doc = await FrappeClient.getDoc(
            doctype: 'Sales Invoice',
            name: inv['name'].toString(),
          );
          final items = doc['data']?['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            final key = item['item_name']?.toString() ?? item['item_code']?.toString() ?? 'Unknown';
            final qty = _toDouble(item['qty']);
            final amt = _toDouble(item['amount']);
            agg.update(key, (e) => _Agg(e.qty + qty, e.amount + amt),
                ifAbsent: () => _Agg(qty, amt));
          }
        } catch (_) {}
      }

      final sorted = agg.entries.toList()
        ..sort((a, b) => b.value.qty.compareTo(a.value.qty));

      return sorted.take(20).map((e) => TopSellerItem(
            itemName: e.key,
            totalQty: e.value.qty,
            totalAmount: e.value.amount,
          )).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 4. Items with their sales (all items + qty sold) ───────────────────
  Future<List<TopSellerItem>> getItemsWithSales() async {
    // Same as top sellers but sorted by amount
    try {
      final topSellers = await getTopSellers();
      topSellers.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return topSellers;
    } catch (_) {
      return [];
    }
  }

  // ── 5. Stock Out & Expiry Alerts ───────────────────────────────────────
  Future<List<StockItem>> getStockOutItems() async {
    try {
      final res = await FrappeClient.getList(
        doctype: 'Bin',
        fields: ['item_code', 'warehouse', 'actual_qty', 'projected_qty'],
        filters: [['actual_qty', '<=', 0]],
        orderBy: 'item_code asc',
        limit: 1000,
      );
      final data = res['data'] as List<dynamic>? ?? [];
      return data.map((d) => StockItem(
            itemCode: d['item_code']?.toString() ?? '',
            actualQty: _toDouble(d['actual_qty']),
            projectedQty: _toDouble(d['projected_qty']),
            warehouse: d['warehouse']?.toString() ?? '',
          )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<BatchItem>> getExpiryAlerts() async {
    try {
      final now = DateTime.now();
      final soon = now.add(const Duration(days: 90));
      final res = await FrappeClient.getList(
        doctype: 'Batch',
        fields: ['name', 'item', 'expiry_date', 'batch_qty'],
        filters: [
          ['expiry_date', '<=', '${soon.year}-${soon.month.toString().padLeft(2, '0')}-${soon.day.toString().padLeft(2, '0')}'],
          ['batch_qty', '>', 0],
        ],
        orderBy: 'expiry_date asc',
        limit: 1000,
      );
      final data = res['data'] as List<dynamic>? ?? [];
      return data.map((d) => BatchItem(
            batchId: d['name']?.toString() ?? '',
            item: d['item']?.toString() ?? '',
            expiryDate: d['expiry_date']?.toString(),
            batchQty: _toDouble(d['batch_qty']),
          )).toList();
    } catch (_) {
      return [];
    }
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;
}

class _Agg {
  final double qty;
  final double amount;
  const _Agg(this.qty, this.amount);
}
