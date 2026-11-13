import 'package:flutter/material.dart';
import 'package:memora/application/models/app_theme_mode.dart';

ThemeMode resolveAppThemeMode(AppThemeMode? mode) => switch (mode) {
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
  _ => ThemeMode.system,
};

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.lightBlue,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    appBarTheme: brightness == Brightness.light
        ? const AppBarTheme(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          )
        : AppBarTheme(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
    buttonTheme: const ButtonThemeData(alignedDropdown: true),
  );
}
