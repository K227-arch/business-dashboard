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
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> _shortDays = [
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
      if (mounted) setState(() => _sales = List.filled(7, 0));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtAmount(double val) {
    if (val <= 0) return 'No sales';
    if (val >= 1) return 'UGX ${val.toStringAsFixed(2)}M';
    return 'UGX ${(val * 1000).toStringAsFixed(0)}K';
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final primary = scheme.primary; // SalesPlus purple

    final labelColor  = scheme.onSurface.withValues(alpha: 0.5);
    final gridColor   = scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.1);
    final bgRodColor  = scheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.06);

    final maxVal = _sales.isEmpty ? 0.0 : _sales.reduce((a, b) => a > b ? a : b);
    final maxY   = maxVal == 0 ? 1.0 : (maxVal * 1.3);

    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekLabel = '${_fmtDate(monday)} – ${_fmtDate(sunday)}  •  UGX millions';

    // Info shown below chart when a bar is touched
    final touched = _touchedIndex != null && _touchedIndex! < _sales.length;
    final touchedDay    = touched ? _days[_touchedIndex!] : null;
    final touchedAmount = touched ? _sales[_touchedIndex!] : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
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
                        weekLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.45),
                            ),
                      ),
                    ],
                  ),
                ),
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
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Hover info banner ──────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: touched
                  ? Container(
                      key: ValueKey(_touchedIndex),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: primary.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart_rounded,
                              color: primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              touchedDay!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            _fmtAmount(touchedAmount!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: touchedAmount > 0
                                  ? primary
                                  : scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      key: const ValueKey('hint'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Tap a bar to see daily sales',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.35),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // ── Chart or empty state ───────────────────────────────────────
            if (_loading)
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (maxVal == 0)
              SizedBox(
                height: 150,
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
                height: 150,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: BarTouchTooltipData(
                        // Hide the built-in floating tooltip — we use the banner above
                        getTooltipColor: (_) => Colors.transparent,
                        tooltipRoundedRadius: 0,
                        tooltipPadding: EdgeInsets.zero,
                        getTooltipItem: (_, __, ___, ____) => null,
                      ),
                      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                        setState(() {
                          if (event is FlTapUpEvent ||
                              event is FlPanEndEvent ||
                              event is FlLongPressEnd) {
                            // Keep the selection visible after lift
                            if (response?.spot != null) {
                              _touchedIndex =
                                  response!.spot!.touchedBarGroupIndex;
                            }
                          } else if (event is FlPointerExitEvent) {
                            _touchedIndex = null;
                          } else if (response?.spot != null) {
                            _touchedIndex =
                                response!.spot!.touchedBarGroupIndex;
                          }
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
                            if (i < 0 || i >= _shortDays.length) {
                              return const SizedBox.shrink();
                            }
                            final isTouched = _touchedIndex == i;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _shortDays[i],
                                style: TextStyle(
                                  color: isTouched
                                      ? primary
                                      : labelColor,
                                  fontSize: 11,
                                  fontWeight: isTouched
                                      ? FontWeight.bold
                                      : FontWeight.w500,
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
                              style:
                                  TextStyle(color: labelColor, fontSize: 9),
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
                                : primary.withValues(alpha: 0.55),
                            width: isTouched ? 18 : 16,
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
