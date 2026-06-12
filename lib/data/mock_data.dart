import 'package:flutter/material.dart';
import '../models/summary_card_model.dart';
import '../models/activity_model.dart';
import '../models/purchase_model.dart';
import '../models/transaction_model.dart';
import '../models/sale_item_model.dart';

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

  // ── Purchases ─────────────────────────────────────────────────────────────

  static const List<PurchaseModel> purchases = [
    PurchaseModel(
      id: 'PUR-001',
      supplierName: 'Uganda Breweries Ltd',
      description: 'Stock order — beverages & spirits',
      total: 8400000,
      date: 'Jun 11, 2026',
      status: TransactionStatus.completed,
    ),
    PurchaseModel(
      id: 'PUR-002',
      supplierName: 'Royal Vendors Ltd',
      description: 'Office supplies & stationery',
      total: 320000,
      date: 'Jun 10, 2026',
      status: TransactionStatus.completed,
    ),
    PurchaseModel(
      id: 'PUR-003',
      supplierName: 'Fresh Foods Suppliers',
      description: 'Perishable goods — weekly order',
      total: 2150000,
      date: 'Jun 9, 2026',
      status: TransactionStatus.pending,
    ),
    PurchaseModel(
      id: 'PUR-004',
      supplierName: 'Techware Solutions',
      description: 'IT equipment — 10 workstations',
      total: 12500000,
      date: 'Jun 8, 2026',
      status: TransactionStatus.completed,
    ),
    PurchaseModel(
      id: 'PUR-005',
      supplierName: 'Jinja Logistics',
      description: 'Freight & delivery charges — May',
      total: 560000,
      date: 'Jun 7, 2026',
      status: TransactionStatus.completed,
    ),
    PurchaseModel(
      id: 'PUR-006',
      supplierName: 'Green Gardens Produce',
      description: 'Fresh vegetables & herbs',
      total: 890000,
      date: 'Jun 6, 2026',
      status: TransactionStatus.failed,
    ),
    PurchaseModel(
      id: 'PUR-007',
      supplierName: 'Prime Packaging Ltd',
      description: 'Custom branded packaging',
      total: 1450000,
      date: 'Jun 5, 2026',
      status: TransactionStatus.pending,
    ),
    PurchaseModel(
      id: 'PUR-008',
      supplierName: 'Nile Water Works',
      description: 'Water bottles — bulk order',
      total: 600000,
      date: 'Jun 4, 2026',
      status: TransactionStatus.completed,
    ),
  ];

  // ── Sales page data ────────────────────────────────────────────────────────

  static final Map<SalesPeriod, SalesSummary> salesSummaries = {
    SalesPeriod.today: const SalesSummary(
      receipts: 12,
      netSales: 663000,
      averageSale: 55250,
      receiptsChange: 1800,
      netSalesChange: 363.64,
      averageSaleChange: -75.60,
      hourlyData: [
        HourlySalePoint(hour: '0:00', amount: 0),
        HourlySalePoint(hour: '2:00', amount: 0),
        HourlySalePoint(hour: '4:00', amount: 0),
        HourlySalePoint(hour: '6:00', amount: 0),
        HourlySalePoint(hour: '8:00', amount: 20),
        HourlySalePoint(hour: '10:00', amount: 45),
        HourlySalePoint(hour: '12:00', amount: 38),
        HourlySalePoint(hour: '14:00', amount: 52),
        HourlySalePoint(hour: '16:00', amount: 80),
        HourlySalePoint(hour: '18:00', amount: 115),
        HourlySalePoint(hour: '20:00', amount: 260),
        HourlySalePoint(hour: '22:00', amount: 53),
      ],
      items: [
        SaleItemModel(name: 'CHICKEN WITH CHIPS', quantity: 7, totalAmount: 119000),
        SaleItemModel(name: 'ROLEX', quantity: 23, totalAmount: 115000),
        SaleItemModel(name: 'BEEF STEW', quantity: 5, totalAmount: 95000),
        SaleItemModel(name: 'SODAS', quantity: 30, totalAmount: 90000),
        SaleItemModel(name: 'CHAPATI', quantity: 40, totalAmount: 80000),
        SaleItemModel(name: 'EGG SANDWICH', quantity: 12, totalAmount: 72000),
        SaleItemModel(name: 'WATER BOTTLE', quantity: 50, totalAmount: 50000),
        SaleItemModel(name: 'MANDAZI', quantity: 60, totalAmount: 42000),
      ],
    ),
    SalesPeriod.thisWeek: const SalesSummary(
      receipts: 85,
      netSales: 4250000,
      averageSale: 50000,
      receiptsChange: 12.5,
      netSalesChange: 18.3,
      averageSaleChange: 5.1,
      hourlyData: [
        HourlySalePoint(hour: 'Mon', amount: 520),
        HourlySalePoint(hour: 'Tue', amount: 680),
        HourlySalePoint(hour: 'Wed', amount: 430),
        HourlySalePoint(hour: 'Thu', amount: 750),
        HourlySalePoint(hour: 'Fri', amount: 890),
        HourlySalePoint(hour: 'Sat', amount: 620),
        HourlySalePoint(hour: 'Sun', amount: 360),
      ],
      items: [
        SaleItemModel(name: 'CHICKEN WITH CHIPS', quantity: 48, totalAmount: 816000),
        SaleItemModel(name: 'BEEF STEW', quantity: 35, totalAmount: 665000),
        SaleItemModel(name: 'ROLEX', quantity: 140, totalAmount: 700000),
        SaleItemModel(name: 'SODAS', quantity: 200, totalAmount: 600000),
        SaleItemModel(name: 'CHAPATI', quantity: 280, totalAmount: 560000),
        SaleItemModel(name: 'EGG SANDWICH', quantity: 90, totalAmount: 540000),
        SaleItemModel(name: 'WATER BOTTLE', quantity: 350, totalAmount: 350000),
        SaleItemModel(name: 'MANDAZI', quantity: 400, totalAmount: 280000),
      ],
    ),
    SalesPeriod.thisMonth: const SalesSummary(
      receipts: 342,
      netSales: 17100000,
      averageSale: 50000,
      receiptsChange: 8.2,
      netSalesChange: 12.5,
      averageSaleChange: -3.8,
      hourlyData: [
        HourlySalePoint(hour: 'W1', amount: 3800),
        HourlySalePoint(hour: 'W2', amount: 4200),
        HourlySalePoint(hour: 'W3', amount: 4900),
        HourlySalePoint(hour: 'W4', amount: 4200),
      ],
      items: [
        SaleItemModel(name: 'CHICKEN WITH CHIPS', quantity: 192, totalAmount: 3264000),
        SaleItemModel(name: 'BEEF STEW', quantity: 140, totalAmount: 2660000),
        SaleItemModel(name: 'ROLEX', quantity: 560, totalAmount: 2800000),
        SaleItemModel(name: 'SODAS', quantity: 800, totalAmount: 2400000),
        SaleItemModel(name: 'CHAPATI', quantity: 1100, totalAmount: 2200000),
        SaleItemModel(name: 'EGG SANDWICH', quantity: 360, totalAmount: 2160000),
        SaleItemModel(name: 'WATER BOTTLE', quantity: 1400, totalAmount: 1400000),
        SaleItemModel(name: 'MANDAZI', quantity: 1600, totalAmount: 1120000),
      ],
    ),
    SalesPeriod.thisYear: const SalesSummary(
      receipts: 4104,
      netSales: 205200000,
      averageSale: 50000,
      receiptsChange: 23.4,
      netSalesChange: 31.2,
      averageSaleChange: 6.3,
      hourlyData: [
        HourlySalePoint(hour: 'Jan', amount: 14000),
        HourlySalePoint(hour: 'Feb', amount: 16500),
        HourlySalePoint(hour: 'Mar', amount: 18200),
        HourlySalePoint(hour: 'Apr', amount: 15800),
        HourlySalePoint(hour: 'May', amount: 19600),
        HourlySalePoint(hour: 'Jun', amount: 17100),
        HourlySalePoint(hour: 'Jul', amount: 0),
        HourlySalePoint(hour: 'Aug', amount: 0),
        HourlySalePoint(hour: 'Sep', amount: 0),
        HourlySalePoint(hour: 'Oct', amount: 0),
        HourlySalePoint(hour: 'Nov', amount: 0),
        HourlySalePoint(hour: 'Dec', amount: 0),
      ],
      items: [
        SaleItemModel(name: 'CHICKEN WITH CHIPS', quantity: 2300, totalAmount: 39100000),
        SaleItemModel(name: 'ROLEX', quantity: 6700, totalAmount: 33500000),
        SaleItemModel(name: 'BEEF STEW', quantity: 1680, totalAmount: 31920000),
        SaleItemModel(name: 'SODAS', quantity: 9600, totalAmount: 28800000),
        SaleItemModel(name: 'CHAPATI', quantity: 13200, totalAmount: 26400000),
        SaleItemModel(name: 'EGG SANDWICH', quantity: 4320, totalAmount: 25920000),
        SaleItemModel(name: 'WATER BOTTLE', quantity: 16800, totalAmount: 16800000),
        SaleItemModel(name: 'MANDAZI', quantity: 19200, totalAmount: 13440000),
      ],
    ),
  };
}
