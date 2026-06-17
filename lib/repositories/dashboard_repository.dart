import 'package:flutter/material.dart';
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

    double totalSales = 0;
    double totalPurchaseReceipts = 0;
    int invoicesLen = 0;
    int receiptsLen = 0;

    try {
      final results = await Future.wait([
        FrappeApi.getSalesInvoices(fromDate: thisMonthStart, toDate: today),
        FrappeApi.getPurchaseReceipts(fromDate: thisMonthStart, toDate: today),
      ]);

      final invoices  = results[0];
      final purchases = results[1];

      totalSales = invoices.fold<double>(
          0, (s, i) => s + _toDouble(i['grand_total']));
      totalPurchaseReceipts = purchases.fold<double>(
          0, (s, i) => s + _toDouble(i['grand_total']));
      invoicesLen  = invoices.length;
      receiptsLen = purchases.length;
    } catch (_) {}

    return [
      SummaryCardModel(
        title: 'Total Sales',
        value: _fmtCurrency(totalSales),
        subtitle: 'This month',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF5B5EA6),
        isPositiveTrend: true,
        trendLabel: '$invoicesLen invoices',
      ),
      SummaryCardModel(
        title: 'Total Purchase Receipts',
        value: _fmtCurrency(totalPurchaseReceipts),
        subtitle: 'This month',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFFF8C00),
        isPositiveTrend: false,
        trendLabel: '$receiptsLen receipts',
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
      return List.filled(7, 0);
    }
  }

  // ── Recent activity ────────────────────────────────────────────────────

  Future<List<ActivityModel>> getRecentActivity() async {
    try {
      final raw = await FrappeApi.getRecentActivity(limit: 10);
      return raw.map<ActivityModel>((item) {
        final source = item['_source']?.toString() ?? 'activity';
        final creation = item['creation']?.toString() ?? '';
        final timeAgo = _relativeTime(creation);

        if (source == 'activity') {
          final operation = item['operation']?.toString() ?? 'Activity';
          final refDoc = item['reference_doctype']?.toString() ?? '';
          final user = item['user']?.toString() ?? '';
          final shortUser = user.contains('@') ? user.split('@')[0] : user;

          return ActivityModel(
            title: refDoc.isNotEmpty ? '$operation — $refDoc' : operation,
            description: shortUser,
            timeAgo: timeAgo,
            icon: _iconForOperation(operation),
            iconColor: _colorForOperation(operation),
          );
        } else {
          // Comment
          final content = item['content']?.toString() ?? '';
          final refDoc = item['reference_doctype']?.toString() ?? '';
          final refName = item['reference_name']?.toString() ?? '';
          final owner = item['owner']?.toString() ?? '';
          final shortOwner = owner.contains('@') ? owner.split('@')[0] : owner;
          final cleanContent = content
              .replaceAll(RegExp(r'<[^>]*>'), '') // strip HTML
              .trim();

          return ActivityModel(
            title: refDoc.isNotEmpty ? '$refDoc: $refName' : 'Comment',
            description: cleanContent.length > 60
                ? '${cleanContent.substring(0, 60)}…'
                : (cleanContent.isEmpty ? shortOwner : cleanContent),
            timeAgo: timeAgo,
            icon: Icons.comment_rounded,
            iconColor: const Color(0xFF34A853),
          );
        }
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static IconData _iconForOperation(String op) {
    switch (op.toLowerCase()) {
      case 'login':  return Icons.login_rounded;
      case 'logout': return Icons.logout_rounded;
      case 'created': case 'save': return Icons.add_circle_outline_rounded;
      case 'submitted': return Icons.check_circle_outline_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.history_rounded;
    }
  }

  static Color _colorForOperation(String op) {
    switch (op.toLowerCase()) {
      case 'login':  return const Color(0xFF1A73E8);
      case 'logout': return const Color(0xFF9AA0A6);
      case 'created': case 'save': return const Color(0xFF34A853);
      case 'submitted': return const Color(0xFF34A853);
      case 'cancelled': return const Color(0xFFEA4335);
      default: return const Color(0xFFFBBC04);
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
