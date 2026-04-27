import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/control_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/alerts_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.bg0,
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
      title: 'AuTOMATO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
      title: Text(
        'automato',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w800, // or FontWeight.w700 / w800
          fontSize: 28,
          letterSpacing: -1,
          color: AppTheme.olive,
        ),
      ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
        actions: [
          // Analytics icon in AppBar (swapped from notifications)
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: AppTheme.inkMid),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
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
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: AppTheme.olive,
          unselectedItemColor: AppTheme.inkMid,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: AppTheme.bg0,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Camera',
            ),
            // Notifications in bottom nav (swapped from analytics) with badge
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              if (state.alertCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.statusAlert,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bg0, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        state.alertCount > 99 ? '99+' : '${state.alertCount}',
                        style: const TextStyle(
                          color: AppTheme.bg0,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          activeIcon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications, color: AppTheme.statusAlert),
              if (state.alertCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.statusAlert,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bg0, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        state.alertCount > 99 ? '99+' : '${state.alertCount}',
                        style: const TextStyle(
                          color: AppTheme.bg0,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: 'Alerts',
        ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'Control',
            ),
          ],
        ),
      ),
    );
  }
}