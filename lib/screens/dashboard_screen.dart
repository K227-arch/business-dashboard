import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/summary_card_model.dart';
import '../providers/theme_provider.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/stock_repository.dart';
import '../widgets/sales_chart.dart';
import '../widgets/summary_card.dart';

/// Screen 1: Main Dashboard — all data loaded live from Frappe ERPNext.
class DashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String userName;
  final String baseUrl;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.themeProvider,
    required this.userName,
    required this.baseUrl,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = const DashboardRepository();
  final _stockRepo = const StockRepository();

  List<SummaryCardModel> _cards = [];
  bool _loading = true;
  String? _error;

  // Stock overview data
  List<StockItem> _ageingStock = [];
  List<StockItem> _lowStock = [];
  List<TopSellerItem> _topSellers = [];
  List<TopSellerItem> _itemsSales = [];
  List<StockItem> _stockOut = [];
  List<BatchItem> _expiryAlerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.getSummaryCards(),
        _stockRepo.getAgeingStock(),
        _stockRepo.getLowStockItems(),
        _stockRepo.getTopSellers(),
        _stockRepo.getItemsWithSales(),
        _stockRepo.getStockOutItems(),
        _stockRepo.getExpiryAlerts(),
      ]);
      if (mounted) {
        setState(() {
          _cards        = results[0] as List<SummaryCardModel>;
          _ageingStock  = results[1] as List<StockItem>;
          _lowStock     = results[2] as List<StockItem>;
          _topSellers   = results[3] as List<TopSellerItem>;
          _itemsSales   = results[4] as List<TopSellerItem>;
          _stockOut     = results[5] as List<StockItem>;
          _expiryAlerts = results[6] as List<BatchItem>;
        });
      }
    } catch (e) {
      if (mounted && !kIsWeb) debugPrint('[Dashboard] load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: bgColor,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hello, ${widget.userName} 👋',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Uri.parse(widget.baseUrl).host,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Refresh button
                IconButton(
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : _load,
                  tooltip: 'Refresh from ERPNext',
                ),
                ListenableBuilder(
                  listenable: widget.themeProvider,
                  builder: (_, __) =>
                      _ThemeToggleButton(provider: widget.themeProvider),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'logout') widget.onLogout();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              Uri.parse(widget.baseUrl).host,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 18, color: Color(0xFFEA4335)),
                            SizedBox(width: 10),
                            Text('Log out',
                                style: TextStyle(color: Color(0xFFEA4335))),
                          ],
                        ),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Error banner ─────────────────────────────────────────────
            if (_error != null)
              SliverToBoxAdapter(
                child: _ErrorBanner(message: _error!, onRetry: _load),
              ),

            // ── Body ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),

                  // ── KPI cards ──────────────────────────────────────────
                  const _SectionLabel(label: 'Overview'),
                  const SizedBox(height: 8),
                  _loading
                      ? const _SkeletonGrid()
                      : _cards.isEmpty
                          ? _EmptyState(
                              icon: Icons.dashboard_outlined,
                              message:
                                  'No data yet.\nAdd records in ERPNext to see live KPIs.',
                              onRefresh: _load,
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _cards.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                              itemBuilder: (_, i) =>
                                  SummaryCard(data: _cards[i]),
                            ),

                  const SizedBox(height: 24),

                  // ── Sales chart ────────────────────────────────────────
                  const _SectionLabel(label: 'Sales Performance'),
                  const SizedBox(height: 8),
                  const SalesChart(),

                  const SizedBox(height: 24),

                  // ── Stock Overview sections ─────────────────────────────
                  _buildStockSection(
                    label: 'Ageing Stock',
                    icon: Icons.access_time_rounded,
                    color: const Color(0xFF1A73E8),
                    count: _ageingStock.length,
                    child: _buildAgeingList(),
                  ),
                  const SizedBox(height: 16),

                  _buildStockSection(
                    label: 'Items Running Out of Stock',
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFFFBBC04),
                    count: _lowStock.length,
                    child: _buildLowStockList(),
                  ),
                  const SizedBox(height: 16),

                  _buildStockSection(
                    label: 'Top Sellers',
                    icon: Icons.star_rounded,
                    color: const Color(0xFF34A853),
                    count: _topSellers.length,
                    child: _buildTopSellersList(),
                  ),
                  const SizedBox(height: 16),

                  _buildStockSection(
                    label: 'Items & Corresponding Sales',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF6C63FF),
                    count: _itemsSales.length,
                    child: _buildItemsSalesList(),
                  ),
                  const SizedBox(height: 16),

                  _buildStockSection(
                    label: 'Stock Out & Expiry Alerts',
                    icon: Icons.warning_rounded,
                    color: const Color(0xFFEA4335),
                    count: _stockOut.length + _expiryAlerts.length,
                    child: _buildAlertsList(),
                  ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stock section wrapper ──────────────────────────────────────────────
  Widget _buildStockSection({
    required String label,
    required IconData icon,
    required Color color,
    required int count,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  // ── 1. Ageing Stock list (top 5) ──────────────────────────────────────
  Widget _buildAgeingList() {
    if (_loading) return const _MiniSkeleton();
    if (_ageingStock.isEmpty) {
      return const _MiniEmpty(msg: 'No items in stock');
    }
    final items = _ageingStock.take(5).toList();
    return Column(
      children: items.map((item) => _StockTile(
            title: item.itemCode,
            subtitle: item.warehouse,
            trailing: '${item.actualQty.toStringAsFixed(0)} in stock',
            color: const Color(0xFF1A73E8),
          )).toList(),
    );
  }

  // ── 2. Low Stock list (top 5) ─────────────────────────────────────────
  Widget _buildLowStockList() {
    if (_loading) return const _MiniSkeleton();
    if (_lowStock.isEmpty) {
      return const _MiniEmpty(msg: 'No items running low');
    }
    final items = _lowStock.take(5).toList();
    return Column(
      children: items.map((item) {
        final color = item.actualQty <= 2
            ? const Color(0xFFEA4335)
            : const Color(0xFFFBBC04);
        return _StockTile(
          title: item.itemCode,
          subtitle: item.warehouse,
          trailing: '${item.actualQty.toStringAsFixed(0)} left',
          color: color,
        );
      }).toList(),
    );
  }

  // ── 3. Top Sellers list (top 5) ───────────────────────────────────────
  Widget _buildTopSellersList() {
    if (_loading) return const _MiniSkeleton();
    if (_topSellers.isEmpty) {
      return const _MiniEmpty(msg: 'No sales data');
    }
    final items = _topSellers.take(5).toList();
    return Column(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return _StockTile(
          title: '${i + 1}. ${item.itemName}',
          subtitle: 'Qty: ${item.totalQty.toStringAsFixed(0)}',
          trailing: _fmt(item.totalAmount),
          color: const Color(0xFF34A853),
        );
      }).toList(),
    );
  }

  // ── 4. Items & Sales list (top 5) ─────────────────────────────────────
  Widget _buildItemsSalesList() {
    if (_loading) return const _MiniSkeleton();
    if (_itemsSales.isEmpty) {
      return const _MiniEmpty(msg: 'No items with sales');
    }
    final items = _itemsSales.take(5).toList();
    return Column(
      children: items.map((item) => _StockTile(
            title: item.itemName,
            subtitle: 'Qty: ${item.totalQty.toStringAsFixed(0)}',
            trailing: _fmt(item.totalAmount),
            color: const Color(0xFF6C63FF),
          )).toList(),
    );
  }

  // ── 5. Alerts list (top 5 each) ──────────────────────────────────────
  Widget _buildAlertsList() {
    if (_loading) return const _MiniSkeleton();
    if (_stockOut.isEmpty && _expiryAlerts.isEmpty) {
      return const _MiniEmpty(msg: 'No alerts');
    }
    return Column(
      children: [
        ..._stockOut.take(3).map((item) => _StockTile(
              title: item.itemCode,
              subtitle: item.warehouse,
              trailing: 'STOCK OUT',
              color: const Color(0xFFEA4335),
            )),
        ..._expiryAlerts.take(3).map((batch) => _StockTile(
              title: batch.item,
              subtitle: 'Batch: ${batch.batchId}',
              trailing: batch.expiryDate ?? 'N/A',
              color: batch.isExpired
                  ? const Color(0xFFEA4335)
                  : const Color(0xFFFBBC04),
            )),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}

// ── Stock tile for overview ──────────────────────────────────────────────────
class _StockTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;

  const _StockTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(trailing,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _MiniSkeleton extends StatelessWidget {
  const _MiniSkeleton();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
          child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  final String msg;
  const _MiniEmpty({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(msg,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4))),
      ),
    );
  }
}

// ── Theme toggle ────────────────────────────────────────────────────────────
class _ThemeToggleButton extends StatelessWidget {
  final ThemeProvider provider;
  const _ThemeToggleButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = provider.isDark;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: IconButton(
        key: ValueKey(isDark),
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDark ? Colors.amber.shade300 : scheme.primary,
          size: 20,
        ),
        tooltip: isDark ? 'Light mode' : 'Dark mode',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onPressed: provider.toggle,
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRefresh;
  const _EmptyState(
      {required this.icon, required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 40, color: scheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEA4335).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFEA4335).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEA4335), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFFEA4335), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFFEA4335))),
          ),
        ],
      ),
    );
  }
}

// ── Skeletons ─────────────────────────────────────────────────────────────────
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (_, __) => const _Skeleton(height: double.infinity),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
