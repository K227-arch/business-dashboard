import 'package:flutter/material.dart';

/// Holds the current [ThemeMode] and notifies listeners when it changes.
/// Uses simple [ChangeNotifier] — no extra packages needed.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
