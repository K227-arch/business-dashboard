import 'package:flutter/material.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BusinessDashboardApp());
}

// ── Shared seed color ──────────────────────────────────────────────────────
const Color _seedColor = Color(0xFF1A73E8);

// ── Light theme ────────────────────────────────────────────────────────────
final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
    surface: const Color(0xFFF6F8FD),
    onSurface: const Color(0xFF1A1C1E),
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF6F8FD),
  cardTheme: CardThemeData(
    elevation: 2,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Color(0xFFF6F8FD),
    surfaceTintColor: Colors.transparent,
    foregroundColor: Color(0xFF1A1C1E),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFF1A73E8).withValues(alpha: 0.15),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey.withValues(alpha: 0.15),
    thickness: 1,
  ),
);

// ── Dark theme ─────────────────────────────────────────────────────────────
final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
    surface: const Color(0xFF1A1C1E),
    onSurface: const Color(0xFFE2E2E5),
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF111318),
  cardTheme: CardThemeData(
    elevation: 2,
    color: const Color(0xFF1E2128),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Color(0xFF111318),
    surfaceTintColor: Colors.transparent,
    foregroundColor: Color(0xFFE2E2E5),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF1E2128),
    indicatorColor: const Color(0xFF1A73E8).withValues(alpha: 0.25),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.white.withValues(alpha: 0.08),
    thickness: 1,
  ),
);

// ── App root ───────────────────────────────────────────────────────────────
class BusinessDashboardApp extends StatefulWidget {
  const BusinessDashboardApp({super.key});

  @override
  State<BusinessDashboardApp> createState() => _BusinessDashboardAppState();
}

class _BusinessDashboardAppState extends State<BusinessDashboardApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Business Dashboard',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeProvider.mode,
          home: MainShell(themeProvider: _themeProvider),
        );
      },
    );
  }
}

// ── Shell with BottomNavigationBar ─────────────────────────────────────────
class MainShell extends StatefulWidget {
  final ThemeProvider themeProvider;
  const MainShell({super.key, required this.themeProvider});

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

    final List<Widget> screens = [
      DashboardScreen(themeProvider: widget.themeProvider),
      const SalesScreen(),
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
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
