import 'transaction_model.dart';

class PurchaseModel {
  final String id;
  final String supplierName;
  final String description;
  final double total;
  final String date;
  final TransactionStatus status;

  const PurchaseModel({
    required this.id,
    required this.supplierName,
    required this.description,
    required this.total,
    required this.date,
    required this.status,
  });
}
