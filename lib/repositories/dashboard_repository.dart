import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/summary_card_model.dart';
import '../models/activity_model.dart';
import '../services/frappe_api.dart';

/// Fetches and shapes all data needed by [DashboardScreen].
class DashboardRepository {
  const DashboardRepository();

  // ── Summary cards ──────────────────────────────────────────────────────

  Future<List<SummaryCardModel>> getSummaryCards() async {
    final now = DateTime.now();
    final thisMonthStart =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';

    // Run all four queries concurrently
    final results = await Future.wait([
      FrappeApi.getSalesInvoices(fromDate: thisMonthStart, toDate: today),
      FrappeApi.getCustomers(),
      FrappeApi.getActiveSalesOrders(),
      FrappeApi.getPendingInvoices(),
    ]);

    final invoices   = results[0];
    final customers  = results[1];
    final orders     = results[2];
    final pending    = results[3];

    final totalSales = invoices.fold<double>(
        0, (s, i) => s + _toDouble(i['grand_total']));
    final newUsers   = customers.length;
    final activeProj = orders.length;
    final pendingOrd = pending.length;

    return [
      SummaryCardModel(
        title: 'Total Sales',
        value: _fmtCurrency(totalSales),
        subtitle: 'This month',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF1A73E8),
        isPositiveTrend: true,
        trendLabel: '${invoices.length} invoices',
      ),
      SummaryCardModel(
        title: 'Customers',
        value: newUsers.toString(),
        subtitle: 'Total registered',
        icon: Icons.people_rounded,
        color: const Color(0xFF34A853),
        isPositiveTrend: true,
        trendLabel: '$newUsers total',
      ),
      SummaryCardModel(
        title: 'Active Orders',
        value: activeProj.toString(),
        subtitle: 'In progress',
        icon: Icons.folder_open_rounded,
        color: const Color(0xFFFBBC04),
        isPositiveTrend: activeProj > 0,
        trendLabel: '$activeProj open',
      ),
      SummaryCardModel(
        title: 'Pending Invoices',
        value: pendingOrd.toString(),
        subtitle: 'Awaiting payment',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFEA4335),
        isPositiveTrend: false,
        trendLabel: '$pendingOrd unpaid',
      ),
    ];
  }

  // ── Weekly sales chart data ────────────────────────────────────────────

  /// Returns 7 doubles (Mon–Sun of current ISO week) in UGX millions.
  Future<List<double>> getWeeklySales() async {
    try {
      final now = DateTime.now();
      // Find Monday of current week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      final invoices = await FrappeApi.getSalesInvoices(
        fromDate: _ymd(monday),
        toDate: _ymd(sunday),
        limit: 500,
      );

      // Bucket by weekday (1=Mon…7=Sun)
      final buckets = List<double>.filled(7, 0);
      for (final inv in invoices) {
        final d = DateTime.tryParse(inv['posting_date']?.toString() ?? '');
        if (d != null) {
          final idx = d.weekday - 1; // 0=Mon
          if (idx >= 0 && idx < 7) {
            buckets[idx] += _toDouble(inv['grand_total']) / 1000000;
          }
        }
      }
      return buckets;
    } catch (_) {
      return MockData.weeklySales;
    }
  }

  // ── Recent activity ────────────────────────────────────────────────────

  Future<List<ActivityModel>> getRecentActivity() async {
    try {
      final raw = await FrappeApi.getRecentActivity(limit: 8);
      if (raw.isEmpty) return MockData.recentActivity;
      return raw.map<ActivityModel>((item) {
        final subject = item['subject']?.toString() ?? 'Activity';
        final content = item['content']?.toString() ?? '';
        final creation = item['creation']?.toString() ?? '';
        final timeAgo = _relativeTime(creation);

        return ActivityModel(
          title: subject.length > 60 ? '${subject.substring(0, 60)}…' : subject,
          description: content.length > 80
              ? '${content.substring(0, 80)}…'
              : (content.isEmpty ? 'No details' : content),
          timeAgo: timeAgo,
          icon: Icons.notifications_rounded,
          iconColor: const Color(0xFF1A73E8),
        );
      }).toList();
    } catch (_) {
      return MockData.recentActivity;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static double _toDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  static String _fmtCurrency(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  static String _relativeTime(String isoString) {
    final d = DateTime.tryParse(isoString);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
