import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

// ─────────────────────────────────────────────────────────────
// AUTOMATO — MINIMALIST BRUTALIST AGRICULTURAL THEME
//
// Philosophy:
//   • F9F5F0 warm off-white is the ONLY background — no dark cards
//   • 31511E olive is used ONLY for meaning (status, accents, CTAs)
//   • Typography does the heavy lifting — weight, size, tracking
//   • Borders are thick and raw (brutalist) not soft/rounded
//   • No gradients, no shadows, no glow — flat and honest
//   • Color is earned — it only appears when something matters
// ─────────────────────────────────────────────────────────────

class AppTheme {
  // ── Core palette ─────────────────────────────────────────────
  static const olive       = Color(0xFF31511E);
  static const oliveLight  = Color(0xFF4A7A2C);
  static const oliveFaint  = Color(0xFFEAEFE4);

  // ── Surfaces ─────────────────────────────────────────────────
  static const bg0  = Color(0xFFF9F5F0); // primary canvas
  static const bg1  = Color(0xFFF1EDE7); // card / section
  static const bg2  = Color(0xFFE8E3DB); // pressed / input
  static const bg3  = Color(0xFFDDD7CE); // chip / tag

  // ── Ink ───────────────────────────────────────────────────────
  static const ink       = Color(0xFF1A1A18); // primary text
  static const inkMid    = Color(0xFF4A4A45); // secondary
  static const inkFaint  = Color(0xFF8A8A82); // muted
  static const inkGhost  = Color(0xFFC4BFB8); // disabled

  // ── Status ────────────────────────────────────────────────────
  static const statusNormal  = Color(0xFF31511E);
  static const statusWarning = Color(0xFF8B4A00);
  static const statusAlert   = Color(0xFF7A1515);

  // ── Status surfaces ───────────────────────────────────────────
  static const normalSurface  = Color(0xFFEAEFE4);
  static const warningSurface = Color(0xFFF5EAE0);
  static const alertSurface   = Color(0xFFF5E4E4);

  // ── Structural ────────────────────────────────────────────────
  static const divider     = Color(0xFFD6D0C8);
  static const border      = Color(0xFF1A1A18);
  static const borderLight = Color(0xFFD6D0C8);

  // ── Aliases ───────────────────────────────────────────────────
  static const accent        = olive;
  static const textPrimary   = ink;
  static const textSecondary = inkMid;
  static const textMuted     = inkFaint;

  static ThemeData get darkTheme => ThemeData.light().copyWith(
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
            color: ink, fontSize: 17,
            fontWeight: FontWeight.w800, letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: ink, size: 22),
          actionsIconTheme: IconThemeData(color: inkMid),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: bg1, elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: borderLight, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bg0,
          selectedItemColor: ink,
          unselectedItemColor: inkGhost,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
        dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 1),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: borderLight)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: borderLight)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: ink, width: 1.5)),
          labelStyle: const TextStyle(color: inkMid, fontSize: 13),
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
          color: olive, linearTrackColor: bg2),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(color: ink, fontWeight: FontWeight.w900, letterSpacing: -2),
          titleLarge:    TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          titleMedium:   TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700),
          titleSmall:    TextStyle(color: inkMid, fontSize: 13, fontWeight: FontWeight.w600),
          bodyLarge:     TextStyle(color: ink, fontSize: 15, height: 1.5),
          bodyMedium:    TextStyle(color: inkMid, fontSize: 13, height: 1.5),
          bodySmall:     TextStyle(color: inkFaint, fontSize: 12, height: 1.4),
          labelLarge:    TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          labelSmall:    TextStyle(color: inkFaint, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ink, foregroundColor: bg0,
            elevation: 0, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: ink, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: bg2,
          selectedColor: oliveFaint,
          labelStyle: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600),
          side: const BorderSide(color: borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: ink,
          contentTextStyle: const TextStyle(color: bg0, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bg0,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: border, width: 1.5),
          ),
          titleTextStyle: const TextStyle(
              color: ink, fontSize: 16, fontWeight: FontWeight.w800),
          contentTextStyle:
              const TextStyle(color: inkMid, fontSize: 13, height: 1.5),
        ),
      );
}

// ── Status helpers ────────────────────────────────────────────
Color statusColor(SensorStatus s) {
  switch (s) {
    case SensorStatus.normal:  return AppTheme.statusNormal;
    case SensorStatus.warning: return AppTheme.statusWarning;
    case SensorStatus.alert:   return AppTheme.statusAlert;
  }
}

Color statusSurface(SensorStatus s) {
  switch (s) {
    case SensorStatus.normal:  return AppTheme.normalSurface;
    case SensorStatus.warning: return AppTheme.warningSurface;
    case SensorStatus.alert:   return AppTheme.alertSurface;
  }
}

String statusLabel(SensorStatus s) {
  switch (s) {
    case SensorStatus.normal:  return 'NORMAL';
    case SensorStatus.warning: return 'WARNING';
    case SensorStatus.alert:   return 'ALERT';
  }
}

Color healthColor(HealthStatus s) {
  switch (s) {
    case HealthStatus.healthy: return AppTheme.statusNormal;
    case HealthStatus.fair:    return AppTheme.statusWarning;
    case HealthStatus.poor:    return AppTheme.statusAlert;
  }
}

Color healthSurface(HealthStatus s) {
  switch (s) {
    case HealthStatus.healthy: return AppTheme.normalSurface;
    case HealthStatus.fair:    return AppTheme.warningSurface;
    case HealthStatus.poor:    return AppTheme.alertSurface;
  }
}