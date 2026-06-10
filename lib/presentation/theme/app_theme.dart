import 'package:flutter/material.dart';
import '../../domain/models/sensor_data.dart';

// ─────────────────────────────────────────────────────────────
// AUTOMATO — REFINED NEO-BRUTALIST AGRICULTURAL THEME
// Inspired by sajon.co & warm brutalism
//
// Philosophy:
//   • F9F5F0 warm off-white is the primary canvas background
//   • 31511E olive is used for core brand presence and semantic normal status
//   • Typography is high-contrast, bold, and editorially tracked
//   • Borders are thick, honest, and structural (2px for focus/active, 1px for passive)
//   • Interactive elements use hard offset shadows to feel highly tactile
// ─────────────────────────────────────────────────────────────

class AppTheme {
  // ── Core Palette ─────────────────────────────────────────────
  static const olive = Color(0xFF31511E);
  static const oliveLight = Color(0xFF4A7A2C);
  static const oliveFaint = Color(0xFFEAEFE4);

  // ── Surfaces ─────────────────────────────────────────────────
  static const bg0 = Color(0xFFF9F5F0); // Primary canvas
  static const bg1 = Color(0xFFF1EDE7); // Card / Section background
  static const bg2 = Color(0xFFE8E3DB); // Pressed / Input background
  static const bg3 = Color(0xFFDDD7CE); // Chip / Tag / Drag track

  // ── Ink ───────────────────────────────────────────────────────
  static const ink = Color(0xFF1A1A18);      // Primary text & borders
  static const inkMid = Color(0xFF4A4A45);   // Secondary text
  static const inkFaint = Color(0xFF8A8A82); // Muted text
  static const inkGhost = Color(0xFFC4BFB8); // Disabled text / Outlines

  // ── Status Colors ────────────────────────────────────────────
  static const statusNormal = Color(0xFF31511E);
  static const statusWarning = Color(0xFF8B4A00);
  static const statusAlert = Color(0xFF7A1515);

  // ── Status Surfaces ──────────────────────────────────────────
  static const normalSurface = Color(0xFFEAEFE4);
  static const warningSurface = Color(0xFFF5EAE0);
  static const alertSurface = Color(0xFFF5E4E4);

  // ── Structural ────────────────────────────────────────────────
  static const divider = Color(0xFFD6D0C8);
  static const border = Color(0xFF1A1A18);
  static const borderLight = Color(0xFFD6D0C8);

  // ── Aliases ───────────────────────────────────────────────────
  static const accent = olive;
  static const textPrimary = ink;
  static const textSecondary = inkMid;
  static const textMuted = inkFaint;

  // ── Brutalist Hard Shadows ────────────────────────────────────
  static const List<BoxShadow> hardShadowSm = [
    BoxShadow(
      color: ink,
      offset: Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> hardShadowMd = [
    BoxShadow(
      color: ink,
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> hardShadowLg = [
    BoxShadow(
      color: ink,
      offset: Offset(6, 6),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  // ── Light / Default Theme ─────────────────────────────────────
  static ThemeData get theme => ThemeData.light().copyWith(
        scaffoldBackgroundColor: bg0,
        primaryColor: olive,
        colorScheme: const ColorScheme.light(
          primary: olive,
          secondary: inkMid,
          surface: bg1,
          error: statusAlert,
          onPrimary: bg0,
          onSurface: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg0,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: ink, size: 22),
          actionsIconTheme: IconThemeData(color: inkMid),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: bg1,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border, width: 2),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bg0,
          selectedItemColor: ink,
          unselectedItemColor: inkGhost,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1.5,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg1,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: olive, width: 2.5),
          ),
          labelStyle: const TextStyle(color: inkMid, fontSize: 13, fontWeight: FontWeight.w600),
          hintStyle: const TextStyle(color: inkGhost, fontSize: 13),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? bg0 : inkFaint),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? olive : bg3),
          trackOutlineColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? olive : borderLight),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: olive,
          linearTrackColor: bg2,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: ink,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
          titleLarge: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          titleSmall: TextStyle(
            color: inkMid,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(
            color: ink,
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: inkMid,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          bodySmall: TextStyle(
            color: inkFaint,
            fontSize: 11,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          labelSmall: TextStyle(
            color: inkFaint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: bg0,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: ink, width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: ink, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: bg2,
          selectedColor: oliveFaint,
          labelStyle: const TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.bold),
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: ink,
          contentTextStyle: const TextStyle(color: bg0, fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: border, width: 2),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bg0,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border, width: 2.5),
          ),
          titleTextStyle: const TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
          contentTextStyle: const TextStyle(
            color: inkMid,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );

  // Backward compatibility alias for the light-configured brutalist theme
  static ThemeData get darkTheme => theme;
}

// ── Status Helpers ────────────────────────────────────────────
Color statusColor(SensorStatus s) {
  switch (s) {
    case SensorStatus.normal:
      return AppTheme.statusNormal;
    case SensorStatus.warning:
      return AppTheme.statusWarning;
    case SensorStatus.alert:
      return AppTheme.statusAlert;
  }
}

Color statusSurface(SensorStatus s) {
  switch (s) {
    case SensorStatus.normal:
      return AppTheme.normalSurface;
    case SensorStatus.warning:
      return AppTheme.warningSurface;
    case SensorStatus.alert:
      return AppTheme.alertSurface;
  }
}

String statusLabel(SensorStatus s) {
  switch (s) {
    case SensorStatus.normal:
      return 'NORMAL';
    case SensorStatus.warning:
      return 'WARNING';
    case SensorStatus.alert:
      return 'ALERT';
  }
}

Color healthColor(HealthStatus s) {
  switch (s) {
    case HealthStatus.healthy:
      return AppTheme.statusNormal;
    case HealthStatus.fair:
      return AppTheme.statusWarning;
    case HealthStatus.poor:
      return AppTheme.statusAlert;
  }
}

Color healthSurface(HealthStatus s) {
  switch (s) {
    case HealthStatus.healthy:
      return AppTheme.normalSurface;
    case HealthStatus.fair:
      return AppTheme.warningSurface;
    case HealthStatus.poor:
      return AppTheme.alertSurface;
  }
}
