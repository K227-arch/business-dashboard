import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../repositories/dashboard_repository.dart';

/// Weekly sales bar chart — data loaded live from Frappe ERPNext.
class SalesChart extends StatefulWidget {
  const SalesChart({super.key});

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  final _repo = const DashboardRepository();

  int? _touchedIndex;
  List<double> _sales = [];
  bool _loading = true;

  static const List<String> _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.getWeeklySales();
      if (mounted) setState(() => _sales = data);
    } catch (_) {
      // On error leave sales empty — chart shows flat zero bars
      if (mounted) setState(() => _sales = List.filled(7, 0));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = scheme.primary;

    final labelColor = scheme.onSurface.withValues(alpha: 0.5);
    final gridColor  = scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.1);
    final bgRodColor = scheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.06);
    final tooltipBg  = isDark ? const Color(0xFF2C2F36) : Colors.black87;

    // Max Y — at least 1 so chart doesn't look broken on zero data
    final maxVal = _sales.isEmpty ? 0.0 : _sales.reduce((a, b) => a > b ? a : b);
    final maxY   = maxVal == 0 ? 1.0 : (maxVal * 1.3);

    // Date range label for this week
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final label  = '${_fmtDate(monday)} – ${_fmtDate(sunday)}  •  UGX millions';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Sales',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.45),
                            ),
                      ),
                    ],
                  ),
                ),
                // Refresh button
                if (!_loading)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: _load,
                    tooltip: 'Refresh',
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Chart or empty state ─────────────────────────────────────
            if (_loading)
              const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (maxVal == 0)
              SizedBox(
                height: 140,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          size: 36,
                          color: scheme.onSurface.withValues(alpha: 0.15)),
                      const SizedBox(height: 8),
                      Text(
                        'No sales this week yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.35),
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => tooltipBg,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                          'UGX ${rod.toY.toStringAsFixed(2)}M',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      touchCallback: (event, response) {
                        setState(() {
                          _touchedIndex =
                              (response == null || response.spot == null)
                                  ? null
                                  : response.spot!.touchedBarGroupIndex;
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i < 0 || i >= _days.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _days[i],
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, _) {
                            if (value % (maxY / 4).roundToDouble() != 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '${value.toStringAsFixed(1)}M',
                              style: TextStyle(color: labelColor, fontSize: 9),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: gridColor, strokeWidth: 1),
                    ),
                    barGroups: List.generate(_sales.length, (i) {
                      final isTouched = _touchedIndex == i;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _sales[i],
                            color: isTouched
                                ? primary
                                : primary.withValues(alpha: 0.65),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: bgRodColor,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]}';
  }
}
