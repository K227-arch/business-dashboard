import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/purchases_repository.dart';

/// Purchases Screen — mirrors SalesScreen design with live Purchase Invoice data.
class PurchasesScreen extends StatefulWidget {
  final String baseUrl;
  const PurchasesScreen({super.key, required this.baseUrl});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _repo = const PurchasesRepository();

  PurchasesPeriod _period = PurchasesPeriod.today;
  DateTime _date = DateTime.now();
  PurchasesSummary? _liveSummary;
  bool _loading = true;
  String? _error;

  static const PurchasesSummary _emptySummary = PurchasesSummary(
    receipts: 0,
    totalSpend: 0,
    averagePurchase: 0,
    receiptsChange: 0,
    totalSpendChange: 0,
    averagePurchaseChange: 0,
    chartData: [],
    items: [],
  );

  PurchasesSummary get _summary => _liveSummary ?? _emptySummary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await _repo.getPurchasesSummary(period: _period, date: _date);
      if (mounted) setState(() => _liveSummary = data);
    } catch (e) {
      if (mounted && !kIsWeb) {
        setState(() => _error = 'Unable to load data. Tap refresh to retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevDate() {
    setState(() => _date = _date.subtract(const Duration(days: 1)));
    _load();
  }

  void _nextDate() {
    setState(() => _date = _date.add(const Duration(days: 1)));
    _load();
  }

  String get _dateLabel {
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${_date.day}  ${months[_date.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _PurchasesHeader(
            dateLabel: _dateLabel,
            onPrev: _prevDate,
            onNext: _nextDate,
            onFilterTap: _showPeriodSheet,
            period: _period,
            isLoading: _loading,
            onRefresh: _load,
            companyName: Uri.parse(widget.baseUrl).host,
          ),
          if (_error != null && !kIsWeb)
            Material(
              color: const Color(0xFFEA4335).withValues(alpha: 0.1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFEA4335), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFEA4335), fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry',
                          style: TextStyle(color: Color(0xFFEA4335))),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PurchasesSummaryCard(
                          summary: _summary, period: _period),
                      const SizedBox(height: 16),
                      _ItemsSection(items: _summary.items),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showPeriodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select period',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ..._periodOptions(setSheet),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _periodOptions(StateSetter setSheet) {
    final options = [
      (PurchasesPeriod.today, 'Today'),
      (PurchasesPeriod.thisWeek, 'This week'),
      (PurchasesPeriod.thisMonth, 'This month'),
      (PurchasesPeriod.thisYear, 'This year'),
      (PurchasesPeriod.custom, 'Custom period'),
    ];
    return options.map((opt) {
      final isSelected = _period == opt.$1;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: const Color(0xFF2B3A8C),
          size: 22,
        ),
        title: Text(opt.$2, style: Theme.of(context).textTheme.bodyLarge),
        onTap: () {
          setState(() => _period = opt.$1);
          setSheet(() {});
          Navigator.pop(context);
          _load();
        },
      );
    }).toList();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Header ────────────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _PurchasesHeader extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFilterTap;
  final PurchasesPeriod period;
  final bool isLoading;
  final VoidCallback onRefresh;
  final String companyName;

  const _PurchasesHeader({
    required this.dateLabel,
    required this.onPrev,
    required this.onNext,
    required this.onFilterTap,
    required this.period,
    required this.isLoading,
    required this.onRefresh,
    required this.companyName,
  });

  String get _periodLabel {
    switch (period) {
      case PurchasesPeriod.today:     return 'Today';
      case PurchasesPeriod.thisWeek:  return 'This week';
      case PurchasesPeriod.thisMonth: return 'This month';
      case PurchasesPeriod.thisYear:  return 'This year';
      case PurchasesPeriod.custom:    return 'Custom period';
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2B3A8C);
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Purchases',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(companyName,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                  onPressed: isLoading ? null : onRefresh,
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 22),
                  tooltip: 'Select period: $_periodLabel',
                  onPressed: onFilterTap,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 28),
                  onPressed: onPrev,
                ),
                Flexible(
                  child: Text(
                    dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 28),
                  onPressed: onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Summary card ──────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _PurchasesSummaryCard extends StatelessWidget {
  final PurchasesSummary summary;
  final PurchasesPeriod period;

  const _PurchasesSummaryCard(
      {required this.summary, required this.period});

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  String _fmtChange(double v) =>
      v >= 0 ? '+${v.toStringAsFixed(2)}%' : '${v.toStringAsFixed(2)}%';

  Color _changeColor(double v) =>
      // For purchases, spending MORE is negative (red), less is positive (green)
      v <= 0 ? const Color(0xFF34A853) : const Color(0xFFEA4335);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Purchases summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Divider(
              height: 20,
              color: scheme.onSurface.withValues(alpha: 0.1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RingStat(
                  value: summary.receipts.toString(),
                  rawValue: summary.receipts.toDouble(),
                  maxValue: summary.receipts.toDouble() > summary.averagePurchase
                      ? summary.receipts.toDouble()
                      : summary.averagePurchase,
                  label: 'Total Receipts',
                  change: _fmtChange(summary.receiptsChange),
                  changeColor: _changeColor(summary.receiptsChange),
                  ringColor: const Color(0xFFFF8C42),
                ),
                _RingStat(
                  value: _fmt(summary.averagePurchase),
                  rawValue: summary.averagePurchase,
                  maxValue: summary.receipts.toDouble() > summary.averagePurchase
                      ? summary.receipts.toDouble()
                      : summary.averagePurchase,
                  label: 'Total Purchases',
                  change: _fmtChange(summary.averagePurchaseChange),
                  changeColor: _changeColor(summary.averagePurchaseChange),
                  ringColor: const Color(0xFF1A73E8),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Ring stat ─────────────────────────────────────────────────────────────
class _RingStat extends StatelessWidget {
  final String value;
  final double rawValue;
  final double maxValue;
  final String label;
  final String change;
  final Color changeColor;
  final Color ringColor;

  const _RingStat({
    required this.value,
    required this.rawValue,
    required this.maxValue,
    required this.label,
    required this.change,
    required this.changeColor,
    required this.ringColor,
  });

  double get _fillRatio {
    if (maxValue <= 0) return 0.05;
    return (rawValue / maxValue).clamp(0.05, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: _fillRatio,
                  strokeWidth: 6,
                  backgroundColor: ringColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: value.length > 8 ? 7 : value.length > 5 ? 9 : 11,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          change,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: changeColor),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Items section ─────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _ItemsSection extends StatelessWidget {
  final List<PurchaseItemModel> items;
  const _ItemsSection({required this.items});

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalCost = items.fold<double>(0, (sum, item) => sum + item.totalAmount);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Center(
              child: Text(
                'Purchase Receipt Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          Divider(height: 1, color: scheme.onSurface.withValues(alpha: 0.08)),

          // ── Column headers ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('Item',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          )),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Qty',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          )),
                ),
                SizedBox(
                  width: 90,
                  child: Text('Cost',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          )),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.onSurface.withValues(alpha: 0.06)),

          // ── Item rows ──────────────────────────────────────────────
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No items for this period',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                      ),
                ),
              ),
            )
          else
            ...List.generate(items.length, (i) {
              final item = items[i];
              final unitCost = item.quantity > 0
                  ? item.totalAmount / item.quantity
                  : item.totalAmount;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        // Item name + unit cost
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_fmt(unitCost)} / unit',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.45),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Quantity
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                          ),
                        ),
                        // Line total
                        SizedBox(
                          width: 90,
                          child: Text(
                            _fmt(item.totalAmount),
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    color: scheme.onSurface.withValues(alpha: 0.05),
                  ),
                ],
              );
            }),

          // ── Total cost row ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cost',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
                Text(
                  _fmt(totalCost),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8C42),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
