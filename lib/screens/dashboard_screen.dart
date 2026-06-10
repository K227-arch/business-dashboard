import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/activity_model.dart';
import '../models/summary_card_model.dart';
import '../providers/theme_provider.dart';
import '../repositories/dashboard_repository.dart';
import '../services/frappe_client.dart';
import '../widgets/activity_tile.dart';
import '../widgets/sales_chart.dart';
import '../widgets/summary_card.dart';

/// Screen 1: Main Dashboard
/// Loads live data from ERPNext when configured; falls back to mock data.
class DashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const DashboardScreen({super.key, required this.themeProvider});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = const DashboardRepository();

  List<SummaryCardModel>? _cards;
  List<ActivityModel>?    _activity;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!FrappeClient.isConnected) return; // stay on mock data

    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.getSummaryCards(),
        _repo.getRecentActivity(),
      ]);
      if (mounted) {
        setState(() {
          _cards    = results[0] as List<SummaryCardModel>;
          _activity = results[1] as List<ActivityModel>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SummaryCardModel> get _displayCards =>
      _cards ?? MockData.summaryCards;

  List<ActivityModel> get _displayActivity =>
      _activity ?? MockData.recentActivity;

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
              toolbarHeight: 72,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hello, Admin 👋',
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
                          'Techwise Solutions',
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
                // Live / mock indicator
                if (FrappeClient.isConnected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text('Live',
                          style: TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: Color(0xFF34A853),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                // Refresh button
                if (FrappeClient.isConnected)
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    onPressed: _loading ? null : _load,
                    tooltip: 'Refresh',
                  ),
                ListenableBuilder(
                  listenable: widget.themeProvider,
                  builder: (_, __) =>
                      _ThemeToggleButton(provider: widget.themeProvider),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Error banner ─────────────────────────────────────────────
            if (_error != null)
              SliverToBoxAdapter(
                child: _ErrorBanner(
                    message: _error!, onRetry: _load),
              ),

            // ── Body ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),
                  const _SectionLabel(label: 'Overview'),
                  const SizedBox(height: 8),
                  _loading
                      ? const _SkeletonGrid()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _displayCards.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                          ),
                          itemBuilder: (_, i) =>
                              SummaryCard(data: _displayCards[i]),
                        ),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Sales Performance'),
                  const SizedBox(height: 8),
                  const SalesChart(),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Recent Activity'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: _loading
                          ? const _SkeletonList(count: 4)
                          : Column(
                              children: List.generate(
                                _displayActivity.length,
                                (i) => ActivityTile(
                                  activity: _displayActivity[i],
                                  showDivider:
                                      i < _displayActivity.length - 1,
                                ),
                              ),
                            ),
                    ),
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
        border: Border.all(
            color: const Color(0xFFEA4335).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEA4335), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFEA4335), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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

// ── Skeleton loaders ──────────────────────────────────────────────────────────
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
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, __) => const _Skeleton(height: double.infinity),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  final int count;
  const _SkeletonList({required this.count});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: _Skeleton(height: 48),
        ),
      ),
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
