import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/purchases_repository.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _repo = const PurchasesRepository();

  List<PurchaseListItem> _liveData = [];
  bool _loading = true;
  String? _error;
  String? _activeFilter; // null = all, "Paid", "Unpaid", "Cancelled"

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getPurchaseList(limit: 100);
      if (mounted) setState(() => _liveData = data);
    } catch (e) {
      if (mounted && !kIsWeb) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PurchaseListItem> get _all => _liveData;

  List<PurchaseListItem> get _filtered {
    if (_activeFilter == null) return _all;
    return _all.where((p) => p.status == _activeFilter).toList();
  }

  double get _totalPurchases => _all.fold(0, (s, p) => s + p.total);

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: bgColor,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Purchases',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              actions: [
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
                  if (_error != null)
                    _ErrorBanner(message: _error!, onRetry: _load),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Total Purchases',
                          value: _formatAmount(_totalPurchases),
                          color: const Color(0xFFFF8C42),
                          icon: Icons.shopping_cart_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                          label: 'Paid',
                          isSelected: _activeFilter == 'Paid',
                          onTap: () => setState(() => _activeFilter = 'Paid'),
                          color: const Color(0xFF34A853),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Unpaid',
                          isSelected: _activeFilter == 'Unpaid',
                          onTap: () => setState(() => _activeFilter = 'Unpaid'),
                          color: const Color(0xFFFBBC04),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Overdue',
                          isSelected: _activeFilter == 'Overdue',
                          onTap: () => setState(() => _activeFilter = 'Overdue'),
                          color: const Color(0xFFFF8C42),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Cancelled',
                          isSelected: _activeFilter == 'Cancelled',
                          onTap: () => setState(() => _activeFilter = 'Cancelled'),
                          color: const Color(0xFFEA4335),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_filtered.length} purchase${_filtered.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                    ),
                  ),

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
                          'No purchases found.',
                          style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      ),
                    )
                  else
                    ..._filtered.map((p) => _PurchaseListTile(item: p)),

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
            _sheetOption('Paid', 'Paid'),
            _sheetOption('Unpaid', 'Unpaid'),
            _sheetOption('Overdue', 'Overdue'),
            _sheetOption('Cancelled', 'Cancelled'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption(String label, String? status) {
    final isSelected = _activeFilter == status;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: const Color(0xFFFF8C42),
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
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ))),
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

class _PurchaseListTile extends StatelessWidget {
  final PurchaseListItem item;
  const _PurchaseListTile({required this.item});

  Color get _statusColor {
    switch (item.status) {
      case 'Paid':       return const Color(0xFF34A853);
      case 'Overdue':    return const Color(0xFFEA4335);
      case 'Cancelled':  return const Color(0xFFEA4335);
      default:           return const Color(0xFFFBBC04); // Unpaid
    }
  }

  String get _statusLabel => item.status;

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_cart_rounded,
                color: Color(0xFFFF8C42),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.supplierName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.id,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.38),
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4, height: 4,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.date,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.38),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmt(item.total),
                  style: const TextStyle(
                    color: Color(0xFFFF8C42),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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
