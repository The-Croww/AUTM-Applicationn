import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/repositories/repositories.dart';

// ─────────────────────────────────────────────────────────────
// Place at: lib/presentation/screens/login_screen.dart
// ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onNavigateToRegister;
  final AuthRepository? authRepository;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.onNavigateToRegister,
    this.authRepository,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Palette ────────────────────────────────────────────────
  static const _bg = Color(0xFFF9F5F0);
  static const _green = Color(0xFF006400);
  static const _textDark = Color(0xFF1E1E1E);
  static const _textMid = Color(0xFF6B6B6B);
  static const _errorRed = Color(0xFFD94F3D);

  // ── State ──────────────────────────────────────────────────
  bool _googleLoading = false;
  String? _errorMsg;

  // ── Fade-in animation ─────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Google sign-in ─────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
      _errorMsg = null;
    });

    try {
      final success =
          await widget.authRepository?.signInWithGoogle() ?? false;

      if (!mounted) return;

      setState(() {
        _googleLoading = false;
      });

      if (success) {
        widget.onLoginSuccess?.call();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _googleLoading = false;
        _errorMsg = 'Google sign-in failed.';
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBanner(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    28,
                    8,
                    28,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 5),

                      // ── Error message ─────────────────────
                      if (_errorMsg != null) ...[
                        _ErrorBanner(
                          message: _errorMsg!,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Sign-in text ──────────────────────
                      const Text(
                        'Sign in to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textMid,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Google Sign-In ────────────────────
                      _GoogleSignInButton(
                        loading: _googleLoading,
                        onTap: _handleGoogleSignIn,
                      ),

                      const SizedBox(height: 16),

                      // ── Create Account button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: widget.onNavigateToRegister,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF006400),
                            side: const BorderSide(
                              color: Color(0xFF006400),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Register ──────────────────────────
                      _buildRegisterLink(),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Brand banner ───────────────────────────────────────────
  Widget _buildBanner() {
  return SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.only(top: 40),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Image.asset(
          'assets/images/Top Log Picture.jpg',
          width: double.infinity,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
    ),
  );
}

  // ── Register link ──────────────────────────────────────────
  Widget _buildRegisterLink() {
    return GestureDetector(
      onTap: widget.onNavigateToRegister,
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: _textMid,
          ),
          children: [
            TextSpan(
              text: "Need help signing in? ",
            ),
            TextSpan(
              text: 'Help!',
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Continue with Google
// ─────────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleSignInButton({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006400),
          disabledBackgroundColor:
              const Color(0xFF006400).withValues(alpha: 0.7),
          foregroundColor: const Color.fromARGB(255, 216, 215, 215),
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? const SizedBox(
                  key: ValueKey('google_loader'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF4285F4),
                  ),
                )
              : Row(
                  key: const ValueKey('google_label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon/Google-Logo.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 33,
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 255, 255, 255),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD94F3D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD94F3D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD94F3D),
            size: 16,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFD94F3D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}