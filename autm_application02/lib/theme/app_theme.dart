import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class AppTheme {
  // Threads-style: pure black/white, no brand color
  static const accent = Color(0xFFFFFFFF);       // white — primary interactive

  // Background layers (true black stack)
  static const bg0 = Color(0xFF000000);           // scaffold — pure black
  static const bg1 = Color(0xFF101010);           // card
  static const bg2 = Color(0xFF1A1A1A);           // elevated card
  static const bg3 = Color(0xFF242424);           // chip / input

  // Text
  static const textPrimary   = Color(0xFFFFFFFF); // pure white
  static const textSecondary = Color(0xFF8E8E8E); // Threads muted gray
  static const textMuted     = Color(0xFF4E4E4E); // dimmed

  // Status — minimal color, desaturated feel
  static const statusNormal  = Color(0xFF4CAF50); // keep green for "good"
  static const statusWarning = Color(0xFFE0A030); // amber, toned down
  static const statusAlert   = Color(0xFFE53935); // red, not neon

  // Threads divider — very subtle
  static const divider = Color(0xFF1E1E1E);

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bg0,
        primaryColor: accent,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: textSecondary,
          surface: bg1,
          error: statusAlert,
        ),
        cardTheme: CardThemeData(
          color: bg1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: divider),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg0,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bg0,
          selectedItemColor: textPrimary,    // white when selected
          unselectedItemColor: textMuted,    // dim gray when not
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: false,         // Threads hides labels
          showUnselectedLabels: false,
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? textPrimary
                : textMuted,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? textSecondary
                : bg3,
          ),
        ),
      );
}

// Status helpers
Color statusColor(SensorStatus status) {
  switch (status) {
    case SensorStatus.normal:  return AppTheme.statusNormal;
    case SensorStatus.warning: return AppTheme.statusWarning;
    case SensorStatus.alert:   return AppTheme.statusAlert;
  }
}

String statusLabel(SensorStatus status) {
  switch (status) {
    case SensorStatus.normal:  return 'NORMAL';
    case SensorStatus.warning: return 'WARNING';
    case SensorStatus.alert:   return 'ALERT';
  }
}