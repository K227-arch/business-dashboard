import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/transaction_model.dart';
import '../repositories/transactions_repository.dart';
import '../services/frappe_client.dart';
import '../widgets/transaction_tile.dart';

/// Screen 2: Transactions / Details Page
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _repo = const TransactionsRepository();

  List<TransactionModel>? _liveData;
  bool _loading = false;
  String? _error;
  TransactionStatus? _activeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!FrappeClient.isConnected) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getTransactions(limit: 100);
      if (mounted) setState(() => _liveData = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TransactionModel> get _all => _liveData ?? MockData.transactions;

  List<TransactionModel> get _filtered {
    if (_activeFilter == null) return _all;
    return _all.where((t) => t.status == _activeFilter).toList();
  }

  double get _totalCredits => _all
      .where((t) => t.type == TransactionType.credit)
      .fold(0, (s, t) => s + t.amount);

  double get _totalDebits => _all
      .where((t) => t.type == TransactionType.debit)
      .fold(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: bgColor,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Transactions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (FrappeClient.isConnected)
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    onPressed: _loading ? null : _load,
                    tooltip: 'Refresh',
                  ),
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
                  // ── Error banner ────────────────────────────────────
                  if (_error != null)
                    _ErrorBanner(message: _error!, onRetry: _load),

                  // ── Summary strip ───────────────────────────────────
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

                  // ── Filter chips ────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _activeFilter == null,
                          onTap: () => setState(() => _activeFilter = null),
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Completed',
                          isSelected:
                              _activeFilter == TransactionStatus.completed,
                          onTap: () => setState(() =>
                              _activeFilter = TransactionStatus.completed),
                          color: const Color(0xFF34A853),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Pending',
                          isSelected:
                              _activeFilter == TransactionStatus.pending,
                          onTap: () => setState(() =>
                              _activeFilter = TransactionStatus.pending),
                          color: const Color(0xFFFBBC04),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Failed',
                          isSelected:
                              _activeFilter == TransactionStatus.failed,
                          onTap: () => setState(() =>
                              _activeFilter = TransactionStatus.failed),
                          color: const Color(0xFFEA4335),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Count ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_filtered.length} transaction${_filtered.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                    ),
                  ),

                  // ── List ────────────────────────────────────────────
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No transactions found.',
                          style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      ),
                    )
                  else
                    ..._filtered.map((t) => TransactionTile(transaction: t)),

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
      backgroundColor: Theme.of(context).cardTheme.color,
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

// ── Error banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEA4335).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFEA4335).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEA4335), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFEA4335), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFFEA4335))),
          ),
        ],
      ),
    );
  }
}

// ── Mini stat card ────────────────────────────────────────────────────────────
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        )),
                Text(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? Theme.of(context).cardTheme.color ?? const Color(0xFF1E2128)
        : Colors.white;
    final unselectedBorder =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : unselectedBorder),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
