import '../models/transaction_model.dart';
import '../services/frappe_api.dart';

/// Fetches Payment Entry data for [TransactionsScreen].
class TransactionsRepository {
  const TransactionsRepository();

  Future<List<TransactionModel>> getTransactions({
    String? fromDate,
    String? toDate,
    int limit = 50,
  }) async {
    final raw = await FrappeApi.getPaymentEntries(
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
    );

    return raw.map<TransactionModel>((item) {
      final paymentType = item['payment_type']?.toString() ?? 'Receive';
      final isReceive = paymentType == 'Receive';

      return TransactionModel(
        id: item['name']?.toString() ?? '',
        customerName: item['party_name']?.toString() ??
            item['party']?.toString() ??
            'Unknown',
        description: item['remarks']?.toString() ??
            (isReceive ? 'Payment received' : 'Payment made'),
        amount: _toDouble(item['paid_amount']),
        date: _formatDate(item['posting_date']?.toString() ?? ''),
        status: TransactionStatus.completed, // submitted PE = completed
        type: isReceive ? TransactionType.credit : TransactionType.debit,
      );
    }).toList();
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
