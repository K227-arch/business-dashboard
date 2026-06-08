import 'package:flutter/material.dart';
import '../models/summary_card_model.dart';

/// A KPI card displaying a metric title, value, trend, and icon.
class SummaryCard extends StatelessWidget {
  final SummaryCardModel data;
  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge + trend pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
                _TrendPill(
                  label: data.trendLabel,
                  isPositive: data.isPositiveTrend,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Value
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              data.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              data.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  final String label;
  final bool isPositive;
  const _TrendPill({required this.label, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color =
        isPositive ? const Color(0xFF34A853) : const Color(0xFFEA4335);
    final icon = isPositive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
