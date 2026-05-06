// ═══════════════════════════════════════════════════════════════
// main.dart — App entry point
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'presentation/theme/app_theme.dart';
import 'presentation/providers/app_state.dart';

import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/camera_screen.dart';
import 'presentation/screens/control_screen.dart';
import 'presentation/screens/analytics_screen.dart';
import 'presentation/screens/alerts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Future: initialize Firebase here ──────────────────────────
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                 Colors.transparent,
    statusBarIconBrightness:        Brightness.dark,
    systemNavigationBarColor:       AppTheme.bg0,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AuTOMATOApp(),
    ),
  );
}

class AuTOMATOApp extends StatelessWidget {
  const AuTOMATOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                  'AuTOMATO',
      debugShowCheckedModeBanner: false,
      theme:                  AppTheme.darkTheme,
      home:                   const HomeShell(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _titles = ['Dashboard', 'Camera', 'Alerts', 'Control'];

  Widget _screen(int i) {
    switch (i) {
      case 0: return const DashboardScreen();
      case 1: return const CameraScreen();
      case 2: return const AlertsScreen();
      case 3: return const ControlScreen();
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final alertCount = state.alertCount;

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
          title: Text(
          'automato',
          style: GoogleFonts.sora(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.olive,
            letterSpacing: -1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: AppTheme.inkMid),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: List.generate(4, _screen),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex:         _index,
          onTap:                (i) => setState(() => _index = i),
          type:                 BottomNavigationBarType.fixed,
          showSelectedLabels:   true,
          showUnselectedLabels: true,
          selectedItemColor:    AppTheme.olive,
          unselectedItemColor:  AppTheme.inkMid,
          backgroundColor:      AppTheme.bg0,
          elevation:            0,
          selectedLabelStyle:   const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon:       Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label:      'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon:       Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label:      'Camera',
            ),
            // ── Alerts tab with live badge ───────────────────────
            BottomNavigationBarItem(
              label: 'Alerts',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (alertCount > 0)
                    Positioned(
                      right: -6, top: -6,
                      child: _Badge(count: alertCount),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications,
                      color: alertCount > 0 ? AppTheme.statusAlert : null),
                  if (alertCount > 0)
                    Positioned(
                      right: -6, top: -6,
                      child: _Badge(count: alertCount),
                    ),
                ],
              ),
            ),
            const BottomNavigationBarItem(
              icon:       Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label:      'Control',
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration:  BoxDecoration(
        color:  AppTheme.statusAlert,
        shape:  BoxShape.circle,
        border: Border.all(color: AppTheme.bg0, width: 1.5),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color:      AppTheme.bg0,
            fontSize:   9,
            fontWeight: FontWeight.w900,
            height:     1,
          ),
        ),
      ),
    );
  }
}