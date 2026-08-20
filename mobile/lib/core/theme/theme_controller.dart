import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets the user switch between light and dark mode in a single action, and
/// persists the choice across app launches (FR-011, SC-006).
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _load();
  }

  static const _prefsKey = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void _load() {
    final stored = _prefs.getString(_prefsKey);
    _mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Switches directly between light and dark (the toggle exposed in
  /// Settings — SC-006 requires a single action).
  Future<void> toggle() async {
    final next = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _prefs.setString(
      _prefsKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}
