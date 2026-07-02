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
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // ── Per-tab filter state ────────────────────────────────────────────
  String _ageingWarehouseFilter = 'All';       // warehouse name or 'All'
  String _lowStockLevel = 'All';               // 'Critical', 'Low', 'All'
  String _topSellersPeriod = 'This Month';     // 'This Week', 'This Month', 'This Quarter'
  String _itemsSalesPeriod = 'This Month';     // 'This Week', 'This Month', 'This Quarter'
  String _alertTypeFilter = 'All';             // 'All', 'Stock Out', 'Expiry'

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getAgeingStock(),
        _repo.getLowStockItems(),
        _repo.getTopSellers(from: _periodStart(_topSellersPeriod), to: DateTime.now()),
        _repo.getItemsWithSales(from: _periodStart(_itemsSalesPeriod), to: DateTime.now()),
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

  DateTime _periodStart(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Quarter':
        final qMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, qMonth, 1);
      case 'This Month':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  /// Reload only sales-related tabs when period changes
  Future<void> _reloadSalesTabs() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getTopSellers(from: _periodStart(_topSellersPeriod), to: DateTime.now()),
        _repo.getItemsWithSales(from: _periodStart(_itemsSalesPeriod), to: DateTime.now()),
      ]);
      if (mounted) {
        setState(() {
          _topSellers = results[0] as List<TopSellerItem>;
          _itemsSales = results[1] as List<TopSellerItem>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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

            // ── Search bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: scheme.primary),
                  ),
                ),
              ),
            ),

            // ── Contextual filter chips per tab ───────────────────────
            _buildFilterChips(scheme),

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

  // ── Contextual filter chips builder ──────────────────────────────────
  Widget _buildFilterChips(ColorScheme scheme) {
    switch (_tab.index) {
      case 0: // Ageing Stock → filter by warehouse
        final warehouses = <String>{'All', ..._ageingStock.map((e) => e.warehouse)};
        return _chipRow(
          items: warehouses.toList(),
          selected: _ageingWarehouseFilter,
          onSelected: (v) => setState(() => _ageingWarehouseFilter = v),
          scheme: scheme,
        );
      case 1: // Low Stock → filter by severity
        return _chipRow(
          items: const ['All', 'Critical (≤2)', 'Low (≤5)'],
          selected: _lowStockLevel,
          onSelected: (v) => setState(() => _lowStockLevel = v),
          scheme: scheme,
        );
      case 2: // Top Sellers → filter by time period
        return _chipRow(
          items: const ['This Week', 'This Month', 'This Quarter'],
          selected: _topSellersPeriod,
          onSelected: (v) {
            setState(() => _topSellersPeriod = v);
            _reloadSalesTabs();
          },
          scheme: scheme,
        );
      case 3: // Items & Sales → filter by time period
        return _chipRow(
          items: const ['This Week', 'This Month', 'This Quarter'],
          selected: _itemsSalesPeriod,
          onSelected: (v) {
            setState(() => _itemsSalesPeriod = v);
            _reloadSalesTabs();
          },
          scheme: scheme,
        );
      case 4: // Alerts → filter by type
        return _chipRow(
          items: const ['All', 'Stock Out', 'Expiry'],
          selected: _alertTypeFilter,
          onSelected: (v) => setState(() => _alertTypeFilter = v),
          scheme: scheme,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _chipRow({
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelected,
    required ColorScheme scheme,
  }) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = items[i];
          final isActive = label == selected;
          return ChoiceChip(
            label: Text(label, style: TextStyle(fontSize: 11,
              color: isActive ? scheme.onPrimary : scheme.onSurface)),
            selected: isActive,
            selectedColor: scheme.primary,
            backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            onSelected: (_) => onSelected(label),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }

  // ── Filtered helpers ─────────────────────────────────────────────────
  List<StockItem> _filterStock(List<StockItem> list) {
    var filtered = list;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.itemCode.toLowerCase().contains(_searchQuery) ||
              e.warehouse.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return filtered;
  }

  List<TopSellerItem> _filterSellers(List<TopSellerItem> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((e) => e.itemName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<BatchItem> _filterBatches(List<BatchItem> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((e) =>
            e.item.toLowerCase().contains(_searchQuery) ||
            e.batchId.toLowerCase().contains(_searchQuery))
        .toList();
  }

  // ── 1. Ageing Stock ────────────────────────────────────────────────────
  Widget _buildAgeingTab() {
    var items = _filterStock(_ageingStock);
    // Apply warehouse filter
    if (_ageingWarehouseFilter != 'All') {
      items = items.where((e) => e.warehouse == _ageingWarehouseFilter).toList();
    }
    return _StockList(
      items: items,
      emptyMsg: _searchQuery.isNotEmpty || _ageingWarehouseFilter != 'All'
          ? 'No matching items'
          : 'No items in stock',
      colorFn: (item) => const Color(0xFF1A73E8),
    );
  }

  // ── 2. Low Stock ───────────────────────────────────────────────────────
  Widget _buildLowStockTab() {
    var items = _filterStock(_lowStock);
    // Apply severity filter
    if (_lowStockLevel == 'Critical (≤2)') {
      items = items.where((e) => e.actualQty <= 2).toList();
    } else if (_lowStockLevel == 'Low (≤5)') {
      items = items.where((e) => e.actualQty > 2 && e.actualQty <= 5).toList();
    }
    return _StockList(
      items: items,
      emptyMsg: _searchQuery.isNotEmpty || _lowStockLevel != 'All'
          ? 'No matching items'
          : 'No items running low',
      colorFn: (item) => item.actualQty <= 2
          ? const Color(0xFFEA4335)
          : const Color(0xFFFBBC04),
    );
  }

  // ── 3. Top Sellers ─────────────────────────────────────────────────────
  Widget _buildTopSellersTab() {
    final filtered = _filterSellers(_topSellers);
    if (filtered.isEmpty) {
      return Center(
          child: Text(_searchQuery.isNotEmpty
              ? 'No matching items'
              : 'No sales data this month'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final item = filtered[i];
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
    final filtered = _filterSellers(_itemsSales);
    if (filtered.isEmpty) {
      return Center(
          child: Text(_searchQuery.isNotEmpty
              ? 'No matching items'
              : 'No items with sales'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final item = filtered[i];
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
    final showStockOut = _alertTypeFilter == 'All' || _alertTypeFilter == 'Stock Out';
    final showExpiry = _alertTypeFilter == 'All' || _alertTypeFilter == 'Expiry';
    final filteredStockOut = showStockOut ? _filterStock(_stockOut) : <StockItem>[];
    final filteredExpiry = showExpiry ? _filterBatches(_expiryAlerts) : <BatchItem>[];

    if (filteredStockOut.isEmpty && filteredExpiry.isEmpty) {
      return Center(
          child: Text(_searchQuery.isNotEmpty || _alertTypeFilter != 'All'
              ? 'No matching alerts'
              : 'No alerts'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (filteredStockOut.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text('Stock Out (${filteredStockOut.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ...filteredStockOut.map((item) => Card(
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
        if (filteredExpiry.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 12),
            child: Text('Expiry Alerts (${filteredExpiry.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ...filteredExpiry.map((batch) => Card(
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
