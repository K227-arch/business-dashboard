import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../providers/theme_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/sales_chart.dart';
import '../widgets/activity_tile.dart';

/// Screen 1: Main Dashboard
class DashboardScreen extends StatelessWidget {
  final ThemeProvider themeProvider;
  const DashboardScreen({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: bgColor,
              surfaceTintColor: Colors.transparent,
              expandedHeight: 120,
              // Theme toggle action
              actions: [
                ListenableBuilder(
                  listenable: themeProvider,
                  builder: (_, __) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ThemeToggleButton(provider: themeProvider),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, Admin 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Monday, Jun 8 2026  •  Techwise Solutions',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                              ),
                            ],
                          ),
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionLabel(label: 'Overview'),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: MockData.summaryCards.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (_, i) =>
                        SummaryCard(data: MockData.summaryCards[i]),
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
                      child: Column(
                        children: List.generate(
                          MockData.recentActivity.length,
                          (i) => ActivityTile(
                            activity: MockData.recentActivity[i],
                            showDivider:
                                i < MockData.recentActivity.length - 1,
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

// ── Theme toggle button ────────────────────────────────────────────────────
class _ThemeToggleButton extends StatelessWidget {
  final ThemeProvider provider;
  const _ThemeToggleButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = provider.isDark;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            color: isDark ? Colors.amber : scheme.primary,
            size: 22,
          ),
        ),
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        onPressed: provider.toggle,
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────
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
