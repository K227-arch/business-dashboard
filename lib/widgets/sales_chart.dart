import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

/// A bar chart showing weekly sales built with fl_chart.
/// Fully respects light/dark theme.
class SalesChart extends StatefulWidget {
  const SalesChart({super.key});

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = scheme.primary;

    // Adaptive colors
    final labelColor = scheme.onSurface.withValues(alpha: 0.5);
    final gridColor = scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.1);
    final bgRodColor = scheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.06);
    final tooltipBg = isDark ? const Color(0xFF2C2F36) : Colors.black87;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Sales',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jun 2 – Jun 8, 2026  •  in millions (UGX)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'This Week',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Bar chart ────────────────────────────────────────────────
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: 4.0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => tooltipBg,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        'UGX ${rod.toY.toStringAsFixed(1)}M',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = (response == null ||
                                response.spot == null)
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
                          if (i < 0 || i >= MockData.weekDays.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              MockData.weekDays[i],
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
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}M',
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 10,
                            ),
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
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  barGroups: List.generate(
                    MockData.weeklySales.length,
                    (i) {
                      final isTouched = _touchedIndex == i;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: MockData.weeklySales[i],
                            color: isTouched
                                ? primary
                                : primary.withValues(alpha: 0.65),
                            width: 22,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 4.0,
                              color: bgRodColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
