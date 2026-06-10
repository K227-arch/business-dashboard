import 'package:flutter/material.dart';
import '../services/frappe_client.dart';

/// Displays live connection status to the Frappe / ERPNext backend.
/// Shows server URL, logged-in user, ping latency, and available record counts.
class FrappeStatusCard extends StatefulWidget {
  const FrappeStatusCard({super.key});

  @override
  State<FrappeStatusCard> createState() => _FrappeStatusCardState();
}

class _FrappeStatusCardState extends State<FrappeStatusCard> {
  // ── State ──────────────────────────────────────────────────────────────
  _Status _status = _Status.checking;
  String _loggedInUser = '';
  int _pingMs = 0;
  final Map<String, int> _counts = {};
  String? _error;

  static const List<String> _doctypes = [
    'Sales Invoice',
    'Payment Entry',
    'Customer',
    'Sales Order',
    'Item',
  ];

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _status = _Status.checking;
      _error = null;
      _counts.clear();
    });

    try {
      // ── 1. Ping ──────────────────────────────────────────────────────
      final sw = Stopwatch()..start();
      final alive = await FrappeClient.ping();
      sw.stop();
      if (!alive) throw Exception('Server unreachable');

      // ── 2. Logged-in user ────────────────────────────────────────────
      final userRes = await FrappeClient.callMethod(
        method: 'frappe.auth.get_logged_user',
      );
      final user = userRes['message']?.toString() ?? 'Unknown';

      // ── 3. Record counts for each doctype ────────────────────────────
      final counts = <String, int>{};
      for (final dt in _doctypes) {
        try {
          final res = await FrappeClient.getList(
            doctype: dt,
            fields: ['name'],
            limit: 500,
          );
          final data = res['data'] as List<dynamic>? ?? [];
          counts[dt] = data.length;
        } catch (_) {
          counts[dt] = -1; // no permission or not installed
        }
      }

      if (mounted) {
        setState(() {
          _status = _Status.connected;
          _loggedInUser = user;
          _pingMs = sw.elapsedMilliseconds;
          _counts.addAll(counts);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _Status.failed;
          _error = e.toString();
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _headerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_headerIcon, color: _headerColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ERPNext Backend',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        FrappeClient.baseUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Refresh button
                IconButton(
                  icon: _status == _Status.checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          size: 20),
                  onPressed:
                      _status == _Status.checking ? null : _check,
                  tooltip: 'Re-check connection',
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: scheme.onSurface.withValues(alpha: 0.08)),
            const SizedBox(height: 14),

            // ── Body ───────────────────────────────────────────────────
            if (_status == _Status.checking)
              _buildChecking()
            else if (_status == _Status.failed)
              _buildFailed()
            else
              _buildConnected(scheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildChecking() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Connecting to ERPNext…'),
          ],
        ),
      );

  Widget _buildFailed() => Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEA4335), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'Connection failed',
              style: const TextStyle(color: Color(0xFFEA4335), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _buildConnected(ColorScheme scheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status pills ──────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Pill(
              label: '● Connected',
              color: const Color(0xFF34A853),
              isDark: isDark,
            ),
            _Pill(
              label: '⚡ ${_pingMs}ms',
              color: _pingMs < 300
                  ? const Color(0xFF34A853)
                  : const Color(0xFFFBBC04),
              isDark: isDark,
            ),
            _Pill(
              label: '👤 $_loggedInUser',
              color: const Color(0xFF1A73E8),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Record counts ─────────────────────────────────────────────
        Text(
          'Live Data from Frappe',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 8),
        ..._doctypes.map((dt) {
          final count = _counts[dt] ?? 0;
          final hasData = count > 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  hasData
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: hasData
                      ? const Color(0xFF34A853)
                      : scheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasData
                        ? const Color(0xFF34A853).withValues(alpha: 0.12)
                        : scheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count < 0
                        ? 'N/A'
                        : count == 0
                            ? 'No records'
                            : '$count record${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hasData
                          ? const Color(0xFF34A853)
                          : scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),
        // ── Frappe info ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFF1A73E8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Frappe ERPNext manages Sales, Accounting, Inventory & HR. '
                  'This dashboard reads live business data via its REST API.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF1A73E8),
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Color get _headerColor {
    switch (_status) {
      case _Status.checking:
        return const Color(0xFF1A73E8);
      case _Status.connected:
        return const Color(0xFF34A853);
      case _Status.failed:
        return const Color(0xFFEA4335);
    }
  }

  IconData get _headerIcon {
    switch (_status) {
      case _Status.checking:
        return Icons.cloud_sync_rounded;
      case _Status.connected:
        return Icons.cloud_done_rounded;
      case _Status.failed:
        return Icons.cloud_off_rounded;
    }
  }
}

// ── Status enum ────────────────────────────────────────────────────────────
enum _Status { checking, connected, failed }

// ── Pill widget ────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _Pill({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
