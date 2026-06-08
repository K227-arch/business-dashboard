import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_tile.dart';

/// Screen 2: Transactions / Details Page
/// Displays a filterable list of recent transactions.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionStatus? _activeFilter; // null = show all

  List<TransactionModel> get _filtered {
    if (_activeFilter == null) return MockData.transactions;
    return MockData.transactions
        .where((t) => t.status == _activeFilter)
        .toList();
  }

  // Quick stats derived from all transactions
  double get _totalCredits => MockData.transactions
      .where((t) => t.type == TransactionType.credit)
      .fold(0, (sum, t) => sum + t.amount);

  double get _totalDebits => MockData.transactions
      .where((t) => t.type == TransactionType.debit)
      .fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFFF6F8FD),
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Transactions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filter',
                  onPressed: _showFilterSheet,
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Summary strip ──────────────────────────────────────
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Total In',
                          value: _formatAmount(_totalCredits),
                          color: const Color(0xFF34A853),
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Total Out',
                          value: _formatAmount(_totalDebits),
                          color: const Color(0xFFEA4335),
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Filter chips ───────────────────────────────────────
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _activeFilter == null,
                        onTap: () => setState(() => _activeFilter = null),
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        isSelected: _activeFilter == TransactionStatus.completed,
                        onTap: () => setState(
                            () => _activeFilter = TransactionStatus.completed),
                        color: const Color(0xFF34A853),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        isSelected: _activeFilter == TransactionStatus.pending,
                        onTap: () => setState(
                            () => _activeFilter = TransactionStatus.pending),
                        color: const Color(0xFFFBBC04),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Failed',
                        isSelected: _activeFilter == TransactionStatus.failed,
                        onTap: () => setState(
                            () => _activeFilter = TransactionStatus.failed),
                        color: const Color(0xFFEA4335),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Count label ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_filtered.length} transaction${_filtered.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ),

                  // ── Transaction list ───────────────────────────────────
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No transactions found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...(_filtered
                        .map((t) => TransactionTile(transaction: t))
                        .toList()),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Status',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _sheetOption('All', null),
            _sheetOption('Completed', TransactionStatus.completed),
            _sheetOption('Pending', TransactionStatus.pending),
            _sheetOption('Failed', TransactionStatus.failed),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption(String label, TransactionStatus? status) {
    final isSelected = _activeFilter == status;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(label),
      onTap: () {
        setState(() => _activeFilter = status);
        Navigator.pop(context);
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return 'UGX ${(amount / 1000000).toStringAsFixed(2)}M';
    }
    return 'UGX ${(amount / 1000).toStringAsFixed(0)}K';
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
