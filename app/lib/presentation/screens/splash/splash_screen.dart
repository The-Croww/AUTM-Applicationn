import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
// Place at: lib/presentation/screens/splash_screen.dart
//
// Usage in main.dart:
//   home: SplashScreen(onFinished: () => Navigator.pushReplacement(
//     context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
// ─────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const SplashScreen({super.key, this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Palette (extracted from photo) ─────────────────────────
  static const _bg = Color(0xFFF5F5F0);          // Cream/off-white
  static const _greenDark = Color(0xFF3D5A3D);     // Dark green (headline)
  static const _textDark = Color(0xFF1A1A1A);    // Near-black text
  static const _textMid = Color(0xFF4A4A4A);     // Mid grey (bottom tag)

  // ── Animation controllers ──────────────────────────────────
  late final AnimationController _textCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _bgCtrl;

  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _exitFade;
  late final Animation<double> _bgFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    await _exitCtrl.forward();
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _exitCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _exitFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image — FITS ANY SCREEN ────────────
           FadeTransition(
              opacity: _bgFade,
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.80,   // 75% of screen width
                  heightFactor: 0.60,  // 70% of screen height
                  child: Image.asset(
                    'assets/icon/AUTM-Bg.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ── Headline text (top-left) ────────────────────────
            Positioned(
              top: size.height * 0.18,
              left: 32,
              right: size.width * 0.30,
              child: SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automate the',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _greenDark,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'variables.',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _greenDark,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Accelerate the',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'vintage.',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Loading dots (centered, below text) ────────────
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: const Center(
                  child: _LoadingDots(color: _greenDark),
                ),
              ),
            ),

            // ── Bottom tagline ─────────────────────────────────
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: const Text(
                  'AuTomato: The Future of Farming',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textMid,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Smart background image widget — fills screen without distortion
// ─────────────────────────────────────────────────────────────
class _BackgroundImage extends StatelessWidget {
  final String imagePath;
  final Color bgColor;

  const _BackgroundImage({
    required this.imagePath,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final screenRatio = screenW / screenH;

        // AUTM-Bg.jpg is 750x1086 = 0.691 ratio (tall/portrait)
        const imageRatio = 750 / 1086; // ~0.691

        // If screen is wider than image (most phones), use BoxFit.cover
        // and align to bottom-right so the leaves show
        if (screenRatio > imageRatio) {
          // Screen is wider than image — cover and align bottom-right
          return Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.bottomRight,
            width: double.infinity,
            height: double.infinity,
          );
        } else {
          // Screen is taller than image — cover and align center
          return Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
          );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Animated loading dots — PRESERVED from original
// ─────────────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
          final opacity = math.sin(t * math.pi).clamp(0.2, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}