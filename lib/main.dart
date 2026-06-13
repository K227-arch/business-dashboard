import 'package:flutter/material.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/credentials_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BusinessDashboardApp());
}

const Color _seedColor = Color(0xFF1A73E8);

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

class BusinessDashboardApp extends StatefulWidget {
  const BusinessDashboardApp({super.key});

  @override
  State<BusinessDashboardApp> createState() => _BusinessDashboardAppState();
}

class _BusinessDashboardAppState extends State<BusinessDashboardApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    _authProvider.tryRestoreSession();
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    _authProvider.dispose();
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
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    return ListenableBuilder(
      listenable: _authProvider,
      builder: (context, _) {
        if (_authProvider.status == AuthStatus.uninitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        switch (_authProvider.status) {
          case AuthStatus.uninitialized:
          case AuthStatus.needsUrl:
            return LoginScreen(auth: _authProvider);
          case AuthStatus.needsLogin:
            return CredentialsScreen(auth: _authProvider);
          case AuthStatus.authenticated:
            return MainShell(
              authProvider: _authProvider,
              themeProvider: _themeProvider,
            );
        }
      },
    );
  }
}
