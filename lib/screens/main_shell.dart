import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  const MainShell({
    super.key,
    required this.authProvider,
    required this.themeProvider,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeProvider.isDark;
    final scheme = Theme.of(context).colorScheme;

    final userName = widget.authProvider.userName.isNotEmpty
        ? widget.authProvider.userName
        : 'User';
    final baseUrl = widget.authProvider.baseUrl;

    final List<Widget> screens = [
      DashboardScreen(
        themeProvider: widget.themeProvider,
        userName: userName,
        baseUrl: baseUrl,
      ),
      SalesScreen(baseUrl: baseUrl),
      const TransactionsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: isDark ? const Color(0xFF1E2128) : Colors.white,
        indicatorColor: scheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Purchases',
          ),
        ],
      ),
    );
  }
}
