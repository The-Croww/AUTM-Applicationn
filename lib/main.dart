import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'data/mock/mock_repositories.dart';
import 'data/firebase/firebased_repositories.dart';   // ← FirebaseAuthRepository
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/app_state.dart';
import 'services/notification_service.dart';

import 'presentation/screens/splash_screen.dart'   as splash;
import 'presentation/screens/login_screen.dart'    as login;
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/camera_screen.dart';
import 'presentation/screens/control_screen.dart';
import 'presentation/screens/analytics_screen.dart';
import 'presentation/screens/alerts_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

// ── Shared auth repo instance (used in logout too) ────────────
final _authRepo = FirebaseAuthRepository();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Firebase ───────────────────────────────────────
  await Firebase.initializeApp();

  // ── Wire repositories ─────────────────────────────────────────
  final sensorRepo = MockSensorRepository();
  final deviceRepo = MockDeviceRepository();
  final alertRepo  = MockAlertRepository(sensorRepo.sensorStream);
  final systemRepo = MockSystemRepository();
  final cameraRepo = MockCameraRepository();

  await NotificationService.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.dark,
    systemNavigationBarColor:          AppTheme.bg0,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        sensorRepository: sensorRepo,
        deviceRepository: deviceRepo,
        alertRepository:  alertRepo,
        systemRepository: systemRepo,
        cameraRepository: cameraRepo,
      ),
      child: const AuTOMATOApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
class AuTOMATOApp extends StatelessWidget {
  const AuTOMATOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:               _navigatorKey,
      title:                      'AuTOMATO',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.darkTheme,
      home:                       const _AppEntry(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _AppEntry — Splash → (auto-login check) → Login OR Dashboard
// ─────────────────────────────────────────────────────────────
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  static Route _fade(Widget page) => PageRouteBuilder(
        pageBuilder:        (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  // Called after splash finishes — routes to Dashboard if already
  // signed in, otherwise shows LoginScreen.
  void _onSplashFinished(BuildContext context) {
    final alreadySignedIn = _authRepo.currentUser != null;

    if (alreadySignedIn) {
      // Skip login — go straight to dashboard
      _navigatorKey.currentState?.pushReplacement(_fade(const HomeShell()));
    } else {
      Navigator.of(context).pushReplacement(
        _fade(
          login.LoginScreen(
            authRepository:       _authRepo,          // ← passed in
            onLoginSuccess:       () => _navigatorKey.currentState
                ?.pushReplacement(_fade(const HomeShell())),
            onNavigateToRegister: () { /* wire later */ },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return splash.SplashScreen(
      onFinished: () => _onSplashFinished(context),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HomeShell — unchanged except logout now calls signOut()
// ─────────────────────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Widget _screen(int i) {
    switch (i) {
      case 0:  return const DashboardScreen();
      case 1:  return const CameraScreen();
      case 2:  return const AlertsScreen();
      case 3:  return const ControlScreen();
      default: return const DashboardScreen();
    }
  }

  Future<void> _logout() async {
    await _authRepo.signOut();                        // ← real sign-out
    _navigatorKey.currentState?.pushAndRemoveUntil(
      _AppEntry._fade(
        login.LoginScreen(
          authRepository:       _authRepo,
          onLoginSuccess:       () => _navigatorKey.currentState
              ?.pushReplacement(_AppEntry._fade(const HomeShell())),
          onNavigateToRegister: () {},
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state      = context.watch<AppState>();
    final alertCount = state.alertCount;

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'automato',
          style: GoogleFonts.sora(
            fontSize:      28,
            fontWeight:    FontWeight.w800,
            color:         AppTheme.olive,
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
      drawer: Drawer(
        backgroundColor: AppTheme.bg0,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 0, 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.divider, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('automato',
                        style: GoogleFonts.sora(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppTheme.olive, letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 4),
                    Text('Smart Greenhouse',
                        style: TextStyle(
                          fontSize: 13, color: AppTheme.inkFaint,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppTheme.statusAlert),
                      title: Text('Log out',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: AppTheme.statusAlert,
                          )),
                      onTap: _logout,                 // ← calls real signOut
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: List.generate(4, _screen)),
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
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
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
            BottomNavigationBarItem(
              label: 'Alerts',
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_outlined),
                if (alertCount > 0)
                  Positioned(right: -6, top: -6, child: _Badge(count: alertCount)),
              ]),
              activeIcon: Stack(clipBehavior: Clip.none, children: [
                Icon(Icons.notifications,
                    color: alertCount > 0 ? AppTheme.statusAlert : null),
                if (alertCount > 0)
                  Positioned(right: -6, top: -6, child: _Badge(count: alertCount)),
              ]),
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

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: AppTheme.statusAlert, shape: BoxShape.circle,
        border: Border.all(color: AppTheme.bg0, width: 1.5),
      ),
      child: Center(
        child: Text(count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: AppTheme.bg0, fontSize: 9,
              fontWeight: FontWeight.w900, height: 1,
            )),
      ),
    );
  }
}