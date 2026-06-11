import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sale_item_model.dart';
import '../repositories/sales_repository.dart';

/// Screen 3: Sales Page
/// Loads live data from ERPNext when configured; falls back to mock data.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _repo = const SalesRepository();

  SalesPeriod _period = SalesPeriod.today;
  DateTime    _date   = DateTime.now();
  SalesSummary? _liveSummary;
  bool   _loading = true;
  String? _error;

  // Empty summary — shown when Frappe returns no data
  static const SalesSummary _emptySummary = SalesSummary(
    receipts: 0, netSales: 0, averageSale: 0,
    receiptsChange: 0, netSalesChange: 0, averageSaleChange: 0,
    hourlyData: [], items: [],
  );

  SalesSummary get _summary => _liveSummary ?? _emptySummary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getSalesSummary(period: _period, date: _date);
      if (mounted) setState(() => _liveSummary = data);
    } catch (e) {
      if (mounted && !kIsWeb) setState(() => _error = e.toString());
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
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${_date.day}  ${months[_date.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _SalesHeader(
            dateLabel: _dateLabel,
            onPrev: _prevDate,
            onNext: _nextDate,
            onFilterTap: _showPeriodSheet,
            period: _period,
            isLoading: _loading,
            onRefresh: _load,
          ),
          if (_error != null && !kIsWeb)
            Material(
              color: const Color(0xFFEA4335).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFEA4335), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFEA4335), fontSize: 12))),
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
                      _SalesSummaryCard(summary: _summary, period: _period),
                      const SizedBox(height: 16),
                      _ItemsSection(items: _summary.items),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Period bottom sheet ───────────────────────────────────────────────────
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
      (SalesPeriod.today, 'Today'),
      (SalesPeriod.thisWeek, 'This week'),
      (SalesPeriod.thisMonth, 'This month'),
      (SalesPeriod.thisYear, 'This year'),
      (SalesPeriod.custom, 'Custom period'),
    ];
    return options.map((opt) {
      final isSelected = _period == opt.$1;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: const Color(0xFF2B3A8C),
          size: 22,
        ),
        title: Text(opt.$2,
            style: Theme.of(context).textTheme.bodyLarge),
        onTap: () {
          setState(() => _period = opt.$1);
          setSheet(() {});
          Navigator.pop(context);
          _load(); // reload with new period
        },
      );
    }).toList();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Header widget ─────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _SalesHeader extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFilterTap;
  final SalesPeriod period;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _SalesHeader({
    required this.dateLabel,
    required this.onPrev,
    required this.onNext,
    required this.onFilterTap,
    required this.period,
    required this.isLoading,
    required this.onRefresh,
  });

  String get _periodLabel {
    switch (period) {
      case SalesPeriod.today:      return 'Today';
      case SalesPeriod.thisWeek:   return 'This week';
      case SalesPeriod.thisMonth:  return 'This month';
      case SalesPeriod.thisYear:   return 'This year';
      case SalesPeriod.custom:     return 'Custom period';
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Centered column: title + subtitle + date row ──────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Techwise Solutions',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 28),
                      onPressed: onPrev,
                    ),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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

            // ── Filter icon: top-right, independent ───────────────────
            Positioned(
              top: 0,
              right: 8,
              child: Row(
                children: [
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
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Sales summary card ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _SalesSummaryCard extends StatelessWidget {
  final SalesSummary summary;
  final SalesPeriod period;

  const _SalesSummaryCard({required this.summary, required this.period});

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  String _fmtChange(double v) =>
      v >= 0 ? '+${v.toStringAsFixed(2)}%' : '${v.toStringAsFixed(2)}%';

  Color _changeColor(double v) =>
      v >= 0 ? const Color(0xFF34A853) : const Color(0xFFEA4335);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card title ─────────────────────────────────────────────
            Center(
              child: Text(
                'Sales summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Divider(
              height: 20,
              color: scheme.onSurface.withValues(alpha: 0.1),
            ),

            // ── Three ring stats ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RingStat(
                  value: summary.receipts.toString(),
                  label: 'Receipts',
                  change: _fmtChange(summary.receiptsChange),
                  changeColor: _changeColor(summary.receiptsChange),
                  ringColor: const Color(0xFFFF8C42), // orange
                ),
                _RingStat(
                  value: _fmt(summary.netSales),
                  label: 'Net sales',
                  change: _fmtChange(summary.netSalesChange),
                  changeColor: _changeColor(summary.netSalesChange),
                  ringColor: const Color(0xFF34A853), // green
                ),
                _RingStat(
                  value: _fmt(summary.averageSale),
                  label: 'Average sale',
                  change: _fmtChange(summary.averageSaleChange),
                  changeColor: _changeColor(summary.averageSaleChange),
                  ringColor: const Color(0xFF1A73E8), // blue
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Bar chart ──────────────────────────────────────────────
            _SalesBarChart(data: summary.hourlyData, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Ring stat widget ───────────────────────────────────────────────────────
class _RingStat extends StatelessWidget {
  final String value;
  final String label;
  final String change;
  final Color changeColor;
  final Color ringColor;

  const _RingStat({
    required this.value,
    required this.label,
    required this.change,
    required this.changeColor,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Ring
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.72,
                  strokeWidth: 5,
                  backgroundColor: ringColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Dot at top
              Positioned(
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ringColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Centre value
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: value.length > 6 ? 9 : 12,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          change,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: changeColor,
          ),
        ),
      ],
    );
  }
}

// ── Bar chart ──────────────────────────────────────────────────────────────
class _SalesBarChart extends StatelessWidget {
  final List<HourlySalePoint> data;
  final bool isDark;

  const _SalesBarChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const barColor = Color(0xFF34A853);
    final labelColor = scheme.onSurface.withValues(alpha: 0.5);
    final gridColor = scheme.onSurface.withValues(alpha: 0.08);

    final maxY = data.isEmpty ? 0 : data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final yMax = maxY == 0 ? 8.0 : (maxY * 1.2).ceilToDouble();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF2C2F36) : Colors.black87,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                'UGX ${rod.toY.toStringAsFixed(0)}K',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: data.length > 8 ? 2 : 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[i].hour,
                      style: TextStyle(color: labelColor, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  String label;
                  if (value >= 1000) {
                    label = 'UGX${(value / 1000).toStringAsFixed(0)}K';
                  } else {
                    label = 'UGX${value.toStringAsFixed(0)}';
                  }
                  return Text(
                    label,
                    style: TextStyle(color: labelColor, fontSize: 8),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: labelColor, width: 1),
              left: BorderSide(color: labelColor, width: 1),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridColor, strokeWidth: 1),
            getDrawingVerticalLine: (_) =>
                FlLine(color: gridColor, strokeWidth: 1),
          ),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].amount,
                  color: barColor,
                  width: data.length > 8 ? 8 : 14,
          borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Items section ──────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _ItemsSection extends StatelessWidget {
  final List<SaleItemModel> items;
  const _ItemsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Center(
              child: Text(
                'Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          Divider(height: 1, color: scheme.onSurface.withValues(alpha: 0.08)),
          ...List.generate(items.length, (i) {
            final item = items[i];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Placeholder avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.08),
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.35),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Name + quantity
                      Expanded(
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
                            ),
                            Text(
                              'x ${item.quantity}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        scheme.onSurface.withValues(alpha: 0.5),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      Text(
                        _fmt(item.totalAmount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    color: scheme.onSurface.withValues(alpha: 0.06),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}
