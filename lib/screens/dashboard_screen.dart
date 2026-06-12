import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../models/summary_card_model.dart';
import '../providers/theme_provider.dart';
import '../repositories/dashboard_repository.dart';
import '../widgets/activity_tile.dart';
import '../widgets/sales_chart.dart';
import '../widgets/summary_card.dart';

/// Screen 1: Main Dashboard — all data loaded live from Frappe ERPNext.
class DashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const DashboardScreen({super.key, required this.themeProvider});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = const DashboardRepository();

  List<SummaryCardModel> _cards = [];
  List<ActivityModel>    _activity = [];
  bool _loading = true;
  String? _error;

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
        _repo.getRecentActivity(),
      ]);
      if (mounted) {
        setState(() {
          _cards    = results[0] as List<SummaryCardModel>;
          _activity = results[1] as List<ActivityModel>;
        });
      }
    } catch (e) {
      // Suppress errors on web (CORS) — show empty UI with zeros
      if (mounted && !kIsWeb) setState(() => _error = e.toString());
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

                  // ── Recent activity ────────────────────────────────────
                  const _SectionLabel(label: 'Recent Activity'),
                  const SizedBox(height: 8),
                  _loading
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: _SkeletonList(count: 4),
                          ),
                        )
                      : _activity.isEmpty
                          ? _EmptyState(
                              icon: Icons.notifications_none_rounded,
                              message:
                                  'No recent activity.\nCommunications from ERPNext will appear here.',
                              onRefresh: _load,
                            )
                          : Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Column(
                                  children: List.generate(
                                    _activity.length,
                                    (i) => ActivityTile(
                                      activity: _activity[i],
                                      showDivider: i < _activity.length - 1,
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
              child: _Skeleton(height: 48))),
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
