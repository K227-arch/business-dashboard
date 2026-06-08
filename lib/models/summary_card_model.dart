import 'package:flutter/material.dart';

/// Represents a single KPI summary card shown at the top of the dashboard.
class SummaryCardModel {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isPositiveTrend;
  final String trendLabel;

  const SummaryCardModel({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPositiveTrend,
    required this.trendLabel,
  });
}
