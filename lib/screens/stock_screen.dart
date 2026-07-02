import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/stock_repository.dart';

/// Stock & Inventory screen with 5 tabs:
/// 1. Ageing Stock  2. Low Stock  3. Top Sellers  4. Items & Sales  5. Alerts
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _repo = const StockRepository();

  List<StockItem> _ageingStock = [];
  List<StockItem> _lowStock = [];
  List<TopSellerItem> _topSellers = [];
  List<TopSellerItem> _itemsSales = [];
  List<StockItem> _stockOut = [];
  List<BatchItem> _expiryAlerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getAgeingStock(),
        _repo.getLowStockItems(),
        _repo.getTopSellers(),
        _repo.getItemsWithSales(),
        _repo.getStockOutItems(),
        _repo.getExpiryAlerts(),
      ]);
      if (mounted) {
        setState(() {
          _ageingStock  = results[0] as List<StockItem>;
          _lowStock     = results[1] as List<StockItem>;
          _topSellers   = results[2] as List<TopSellerItem>;
          _itemsSales   = results[3] as List<TopSellerItem>;
          _stockOut     = results[4] as List<StockItem>;
          _expiryAlerts = results[5] as List<BatchItem>;
        });
      }
    } catch (e) {
      if (mounted && !kIsWeb) debugPrint('Stock load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stock & Inventory',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                    onPressed: _loading ? null : _load,
                  ),
                ],
              ),
            ),

            // ── Tabs ──────────────────────────────────────────────────
            TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
              indicatorColor: scheme.primary,
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Ageing (${_ageingStock.length})'),
                Tab(text: 'Low Stock (${_lowStock.length})'),
                Tab(text: 'Top Sellers (${_topSellers.length})'),
                const Tab(text: 'Items & Sales'),
                Tab(text: 'Alerts (${_stockOut.length + _expiryAlerts.length})'),
              ],
            ),

            // ── Tab content ───────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _buildAgeingTab(),
                        _buildLowStockTab(),
                        _buildTopSellersTab(),
                        _buildItemsSalesTab(),
                        _buildAlertsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Ageing Stock ────────────────────────────────────────────────────
  Widget _buildAgeingTab() => _StockList(
        items: _ageingStock,
        emptyMsg: 'No items in stock',
        colorFn: (item) => const Color(0xFF1A73E8),
      );

  // ── 2. Low Stock ───────────────────────────────────────────────────────
  Widget _buildLowStockTab() => _StockList(
        items: _lowStock,
        emptyMsg: 'No items running low',
        colorFn: (item) => item.actualQty <= 2
            ? const Color(0xFFEA4335)
            : const Color(0xFFFBBC04),
      );

  // ── 3. Top Sellers ─────────────────────────────────────────────────────
  Widget _buildTopSellersTab() {
    if (_topSellers.isEmpty) {
      return const Center(child: Text('No sales data this month'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _topSellers.length,
      itemBuilder: (_, i) {
        final item = _topSellers[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF34A853).withValues(alpha: 0.12),
              child: Text('${i + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34A853))),
            ),
            title: Text(item.itemName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle:
                Text('Qty sold: ${item.totalQty.toStringAsFixed(0)}'),
            trailing: Text(
              _fmt(item.totalAmount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF34A853)),
            ),
          ),
        );
      },
    );
  }

  // ── 4. Items & Sales ───────────────────────────────────────────────────
  Widget _buildItemsSalesTab() {
    if (_itemsSales.isEmpty) {
      return const Center(child: Text('No items with sales'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _itemsSales.length,
      itemBuilder: (_, i) {
        final item = _itemsSales[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  const Color(0xFF1A73E8).withValues(alpha: 0.12),
              child: const Icon(Icons.inventory_2_rounded,
                  size: 18, color: Color(0xFF1A73E8)),
            ),
            title: Text(item.itemName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(
                'Qty: ${item.totalQty.toStringAsFixed(0)}  •  ${_fmt(item.totalAmount)}'),
          ),
        );
      },
    );
  }

  // ── 5. Alerts ──────────────────────────────────────────────────────────
  Widget _buildAlertsTab() {
    if (_stockOut.isEmpty && _expiryAlerts.isEmpty) {
      return const Center(child: Text('No alerts'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_stockOut.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text('Stock Out (${_stockOut.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ..._stockOut.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEA4335),
                    child: Icon(Icons.warning_rounded,
                        color: Colors.white, size: 18),
                  ),
                  title: Text(item.itemCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(item.warehouse),
                  trailing: const Text('OUT',
                      style: TextStyle(
                          color: Color(0xFFEA4335),
                          fontWeight: FontWeight.bold)),
                ),
              )),
        ],
        if (_expiryAlerts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 12),
            child: Text('Expiry Alerts (${_expiryAlerts.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ..._expiryAlerts.map((batch) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: batch.isExpired
                        ? const Color(0xFFEA4335)
                        : const Color(0xFFFBBC04),
                    child: Icon(
                        batch.isExpired
                            ? Icons.dangerous_rounded
                            : Icons.schedule_rounded,
                        color: Colors.white,
                        size: 18),
                  ),
                  title: Text(batch.item,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                      'Batch: ${batch.batchId}  •  Qty: ${batch.batchQty.toStringAsFixed(0)}'),
                  trailing: Text(
                    batch.expiryDate ?? 'N/A',
                    style: TextStyle(
                      color: batch.isExpired
                          ? const Color(0xFFEA4335)
                          : const Color(0xFFFBBC04),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}

// ── Stock list widget ────────────────────────────────────────────────────────
class _StockList extends StatelessWidget {
  final List<StockItem> items;
  final String emptyMsg;
  final Color Function(StockItem) colorFn;

  const _StockList({
    required this.items,
    required this.emptyMsg,
    required this.colorFn,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(emptyMsg));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = colorFn(item);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.inventory_rounded, size: 18, color: color),
            ),
            title: Text(item.itemCode,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis),
            subtitle: Text(item.warehouse, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.actualQty.toStringAsFixed(0)} in stock',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 12),
                ),
                Text(
                  'Proj: ${item.projectedQty.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
