import 'package:flutter/material.dart';
import '../models/summary_card_model.dart';
import '../models/activity_model.dart';
import '../models/transaction_model.dart';

/// Central source of all static mock data used across the app.
class MockData {
  MockData._(); // prevent instantiation

  // ── Summary Cards ─────────────────────────────────────────────────────────

  static const List<SummaryCardModel> summaryCards = [
    SummaryCardModel(
      title: 'Total Sales',
      value: 'UGX 8,450,000',
      subtitle: 'This month',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF1A73E8),
      isPositiveTrend: true,
      trendLabel: '+12.5%',
    ),
    SummaryCardModel(
      title: 'New Users',
      value: '1,284',
      subtitle: 'Last 30 days',
      icon: Icons.person_add_alt_1_rounded,
      color: Color(0xFF34A853),
      isPositiveTrend: true,
      trendLabel: '+8.2%',
    ),
    SummaryCardModel(
      title: 'Active Projects',
      value: '37',
      subtitle: 'In progress',
      icon: Icons.folder_open_rounded,
      color: Color(0xFFFBBC04),
      isPositiveTrend: false,
      trendLabel: '-3 this week',
    ),
    SummaryCardModel(
      title: 'Pending Orders',
      value: '156',
      subtitle: 'Awaiting fulfillment',
      icon: Icons.hourglass_top_rounded,
      color: Color(0xFFEA4335),
      isPositiveTrend: false,
      trendLabel: '+21 today',
    ),
  ];

  // ── Weekly Sales Chart Data (Mon–Sun) ──────────────────────────────────────

  /// Sales values in millions of UGX for the current week.
  static const List<double> weeklySales = [
    1.2, 1.8, 0.9, 2.4, 1.6, 3.1, 2.0,
  ];

  static const List<String> weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  // ── Recent Activity Feed ───────────────────────────────────────────────────

  static const List<ActivityModel> recentActivity = [
    ActivityModel(
      title: 'New order received',
      description: 'Order #ORD-00892 from Kampala branch',
      timeAgo: '2 min ago',
      icon: Icons.shopping_cart_rounded,
      iconColor: Color(0xFF1A73E8),
    ),
    ActivityModel(
      title: 'Payment confirmed',
      description: 'UGX 320,000 from Nakawa client',
      timeAgo: '15 min ago',
      icon: Icons.check_circle_rounded,
      iconColor: Color(0xFF34A853),
    ),
    ActivityModel(
      title: 'New user registered',
      description: 'Sarah Namukasa joined via mobile app',
      timeAgo: '1 hr ago',
      icon: Icons.person_rounded,
      iconColor: Color(0xFF9C27B0),
    ),
    ActivityModel(
      title: 'Project milestone reached',
      description: 'ERP Phase 2 design approved',
      timeAgo: '3 hrs ago',
      icon: Icons.flag_rounded,
      iconColor: Color(0xFFFBBC04),
    ),
    ActivityModel(
      title: 'Low stock alert',
      description: 'Item SKU-4421 below reorder level',
      timeAgo: '5 hrs ago',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFEA4335),
    ),
    ActivityModel(
      title: 'Report generated',
      description: 'Monthly sales report for May 2026',
      timeAgo: 'Yesterday',
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF00BCD4),
    ),
  ];

  // ── Transactions ───────────────────────────────────────────────────────────

  static const List<TransactionModel> transactions = [
    TransactionModel(
      id: 'TXN-001',
      customerName: 'Acacia Supermarket',
      description: 'Inventory restock payment',
      amount: 1250000,
      date: 'Jun 8, 2026',
      status: TransactionStatus.completed,
      type: TransactionType.credit,
    ),
    TransactionModel(
      id: 'TXN-002',
      customerName: 'Brian Ssekandi',
      description: 'Subscription renewal – Pro Plan',
      amount: 85000,
      date: 'Jun 8, 2026',
      status: TransactionStatus.completed,
      type: TransactionType.credit,
    ),
    TransactionModel(
      id: 'TXN-003',
      customerName: 'Techwise Solutions',
      description: 'Cloud hosting invoice',
      amount: 320000,
      date: 'Jun 7, 2026',
      status: TransactionStatus.pending,
      type: TransactionType.debit,
    ),
    TransactionModel(
      id: 'TXN-004',
      customerName: 'Pearl Engineering Ltd',
      description: 'ERP system licence fee',
      amount: 2400000,
      date: 'Jun 7, 2026',
      status: TransactionStatus.completed,
      type: TransactionType.credit,
    ),
    TransactionModel(
      id: 'TXN-005',
      customerName: 'Grace Nakato',
      description: 'Freelance design invoice',
      amount: 450000,
      date: 'Jun 6, 2026',
      status: TransactionStatus.completed,
      type: TransactionType.debit,
    ),
    TransactionModel(
      id: 'TXN-006',
      customerName: 'Kampala Hardware',
      description: 'Bulk purchase – office supplies',
      amount: 178000,
      date: 'Jun 6, 2026',
      status: TransactionStatus.failed,
      type: TransactionType.debit,
    ),
    TransactionModel(
      id: 'TXN-007',
      customerName: 'Nile Breweries Ltd',
      description: 'Quarterly partnership payment',
      amount: 5600000,
      date: 'Jun 5, 2026',
      status: TransactionStatus.completed,
      type: TransactionType.credit,
    ),
    TransactionModel(
      id: 'TXN-008',
      customerName: 'Moses Tumwine',
      description: 'Mobile app subscription',
      amount: 35000,
      date: 'Jun 5, 2026',
      status: TransactionStatus.pending,
      type: TransactionType.credit,
    ),
    TransactionModel(
      id: 'TXN-009',
      customerName: 'Jinja Logistics',
      description: 'Delivery services – May invoice',
      amount: 690000,
      date: 'Jun 4, 2026',
      status: TransactionStatus.completed,
      type: TransactionType.debit,
    ),
    TransactionModel(
      id: 'TXN-010',
      customerName: 'Stanbic Bank Uganda',
      description: 'Payment gateway fees',
      amount: 122000,
      date: 'Jun 3, 2026',
      status: TransactionStatus.completed,
      type: TransactionType.debit,
    ),
  ];
}
