import '../models/purchase_model.dart';
import '../models/transaction_model.dart';
import '../services/frappe_api.dart';

class PurchasesRepository {
  const PurchasesRepository();

  Future<List<PurchaseModel>> getPurchases({
    String? fromDate,
    String? toDate,
    int limit = 50,
  }) async {
    try {
      final raw = await FrappeApi.getPurchaseInvoices(
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );

      return raw.map<PurchaseModel>((item) {
        final statusStr = item['status']?.toString() ?? '';
        return PurchaseModel(
          id: item['name']?.toString() ?? '',
          supplierName: item['supplier_name']?.toString() ??
              item['supplier']?.toString() ??
              'Unknown',
          description: item['remarks']?.toString() ?? 'Purchase Invoice',
          total: _toDouble(item['grand_total']),
          date: _formatDate(item['posting_date']?.toString() ?? ''),
          status: _mapStatus(statusStr),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static TransactionStatus _mapStatus(String s) {
    switch (s) {
      case 'Paid':
        return TransactionStatus.completed;
      case 'Unpaid':
      case 'Overdue':
        return TransactionStatus.pending;
      case 'Cancelled':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

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
