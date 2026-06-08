/// Represents a single transaction record displayed on the Transactions screen.
class TransactionModel {
  final String id;
  final String customerName;
  final String description;
  final double amount;
  final String date;
  final TransactionStatus status;
  final TransactionType type;

  const TransactionModel({
    required this.id,
    required this.customerName,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
  });
}

enum TransactionStatus { completed, pending, failed }

enum TransactionType { credit, debit }
