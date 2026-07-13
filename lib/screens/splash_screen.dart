// lib/screens/splash_screen.dart
//
// MortgagePro Global — Splash Screen
// Matches: Design/sp_updated.html exactly
// Aesthetic: Premium Dark Navy Blue & Gold · Elite Fintech

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Colour tokens (mirror CSS :root variables) ──────────────────────────
  static const Color _bgMain = Color(0xFF082A73);
  static const Color _bgGradientTop = Color(0xFF123F9A);
  static const Color _bgGradientBottom = Color(0xFF051E5A);
  static const Color _cardBg = Color(0xFF2A4A8D);
  static const Color _gold = Color(0xFFF4C430);
  static const Color _goldBar = Color(0xFFF4D03F);
  static const Color _goldGlow = Color(0xFFFFD84D);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFC8D0E0);
  static const Color _textMuted = Color(0xFFAAB3C5);
  static const Color _trackBg = Color(0xFF5B6B8F);

  // ── Animation controllers ────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final AnimationController _loadController;

  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _loadFill;

  @override
  void initState() {
    super.initState();

    // Logo: 0.8 s, delay 0.3 s (cubic-bezier(0.15,1,0.3,1) ≈ easeOutExpo)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutExpo),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.12), // translateY(-8px) at ~64px height
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutExpo),
    );

    // Loading bar: 3.2 s, delay 1.1 s (same curve)
    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _loadFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadController, curve: Curves.easeOutExpo),
    );

    // Start with the HTML-specified delays
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _loadController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1329), // outer body bg
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // ── Background gradient ────────────────────────────────────
                _buildBackground(),

                // ── Aurora glow ────────────────────────────────────────────
                _buildAurora(),

                // ── Subtle financial chart line ────────────────────────────
                _buildChartLine(),

                // ── Flag watermarks (opacity 0.12) ─────────────────────────
                _buildFlagWatermarks(),

                // ── World-map ghost ────────────────────────────────────────
                _buildWorldMapGhost(),

                // ── Main content ───────────────────────────────────────────
                _buildContent(),

                // ── Version tag ────────────────────────────────────────────
                _buildVersionTag(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
          colors: [_bgGradientTop, _bgMain, _bgGradientBottom],
        ),
      ),
      foregroundDecoration: BoxDecoration(
        // bg-base: radial glow at 50% 35%
        gradient: RadialGradient(
          center: const Alignment(0, -0.3), // ~50% x, 35% y
          radius: 0.7,
          colors: [
            const Color(0xFFF4C430).withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ── Aurora ────────────────────────────────────────────────────────────────
  Widget _buildAurora() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.0), // top centre
              radius: 1.4,
              colors: [
                const Color(0xFF123F9A).withValues(alpha: 0.30),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
      ),
    );
  }

  // ── Financial chart SVG path ──────────────────────────────────────────────
  Widget _buildChartLine() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.45,
          child: CustomPaint(
            painter: _ChartLinePainter(),
          ),
        ),
      ),
    );
  }

  // ── Watermark flags (text-based, small, scattered) ────────────────────────
  Widget _buildFlagWatermarks() {
    const double opacity = 0.12;
    const TextStyle style = TextStyle(fontSize: 28);

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Stack(
            children: [
              // wmf-us: top 12%, left 5%
              Positioned(
                top: _pct(0.12),
                left: _pct(0.05),
                child: const Text('🇺🇸', style: style),
              ),
              // wmf-ca: top 22%, right 5%
              Positioned(
                top: _pct(0.22),
                right: _pct(0.05),
                child: const Text('🇨🇦', style: style),
              ),
              // wmf-uk: top 40%, left 4%
              Positioned(
                top: _pct(0.40),
                left: _pct(0.04),
                child: const Text('🇬🇧', style: style),
              ),
              // wmf-eu: top 35%, right 6%
              Positioned(
                top: _pct(0.35),
                right: _pct(0.06),
                child: const Text('🇪🇺', style: style),
              ),
              // wmf-nz: top 56%, right 4%
              Positioned(
                top: _pct(0.56),
                right: _pct(0.04),
                child: const Text('🇳🇿', style: style),
              ),
              // wmf-in: top 66%, left 5%
              Positioned(
                top: _pct(0.66),
                left: _pct(0.05),
                child: const Text('🇮🇳', style: style),
              ),
              // wmf-au: top 78%, right 6%
              Positioned(
                top: _pct(0.78),
                right: _pct(0.06),
                child: const Text('🇦🇺', style: style),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── World-map ghost (simulated with styled container + opacity) ───────────
  Widget _buildWorldMapGhost() {
    return Positioned.fill(
      child: IgnorePointer(
        child: FractionallySizedBox(
          widthFactor: 0.9,
          heightFactor: 0.5,
          alignment: const FractionalOffset(0.5, 0.46), // translate -54%
          child: Opacity(
            opacity: 0.22,
            child: CustomPaint(
              painter: _WorldMapDotsPainter(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    return Positioned.fill(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo mark
            _buildLogoMark(),

            const SizedBox(height: 0), // logo has margin-bottom: 24px via padding

            // Wordmark
            _buildWordmark(),

            // Tagline
            _buildTagline(),

            // Flags row
            _buildFlagsRow(),

            // Loading bar
            _buildLoadingBar(),
          ],
        ),
      ),
    );
  }

  // ── Logo mark ─────────────────────────────────────────────────────────────
  Widget _buildLogoMark() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (_, child) {
        return FadeTransition(
          opacity: _logoOpacity,
          child: SlideTransition(
            position: _logoSlide,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardBg, _bgGradientBottom],
            ),
            border: Border.all(
              color: const Color(0xFFF4C430).withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.home_rounded,
              color: _gold,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }

  // ── Wordmark ──────────────────────────────────────────────────────────────
  Widget _buildWordmark() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (_, child) => FadeTransition(opacity: _logoOpacity, child: child),
      child: Column(
        children: [
          // "MortgagePro"
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: _textPrimary,
                fontFamily: 'sans-serif',
              ),
              children: [
                TextSpan(text: 'Mortgage'),
                TextSpan(
                  text: 'Pro',
                  style: TextStyle(color: _gold),
                ),
              ],
            ),
          ),

          // "GLOBAL"
          const SizedBox(height: 6),
          const Text(
            'G L O B A L',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 6.0,
              color: _gold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tagline ───────────────────────────────────────────────────────────────
  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (_, child) => FadeTransition(opacity: _logoOpacity, child: child),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Text(
          'Your world of mortgages,\ncalculated with precision',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
            height: 1.55,
          ),
        ),
      ),
    );
  }

  // ── Flag pills ────────────────────────────────────────────────────────────
  Widget _buildFlagsRow() {
    const flags = [
      ('USA', '🇺🇸'),
      ('CAN', '🇨🇦'),
      ('GBR', '🇬🇧'),
      ('AUS', '🇦🇺'),
      ('NZL', '🇳🇿'),
      ('IND', '🇮🇳'),
      ('EUR', '🇪🇺'),
    ];

    return AnimatedBuilder(
      animation: _logoController,
      builder: (_, child) => FadeTransition(opacity: _logoOpacity, child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: flags
              .map((f) => _FlagPill(code: f.$1, emoji: f.$2))
              .toList(),
        ),
      ),
    );
  }

  // ── Loading bar ───────────────────────────────────────────────────────────
  Widget _buildLoadingBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _loadFill,
              builder: (_, __) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          width: double.infinity,
                          color: _trackBg,
                        ),
                        // Fill
                        FractionallySizedBox(
                          widthFactor: _loadFill.value,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_goldBar, _goldGlow],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Version tag ───────────────────────────────────────────────────────────
  Widget _buildVersionTag() {
    return const Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Center(
          child: Text(
            'REO TECHNOLOGIES · Version 1.0.9',
            style: TextStyle(
              fontSize: 8.5,
              letterSpacing: 1.0,
              color: _textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper: convert fraction of screen height to logical pixels ───────────
  double _pct(double fraction) {
    // Use MediaQuery at build time; for positioned children we need context.
    // We'll use LayoutBuilder indirection via MediaQuery in the watermark build.
    // Since we're inside Positioned.fill we approximate via fraction of
    // MediaQueryData from the nearest context. We compute lazily here:
    return MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).size.height * fraction;
  }
}

// ── Painters ─────────────────────────────────────────────────────────────────

/// Draws the subtle financial-chart bezier line from the HTML SVG.
/// Original path: M -20 740 Q 60 720 120 640 T 260 550 T 380 340 T 460 210
/// in a 420×896 viewBox. We scale to fit any screen.
class _ChartLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 420;
    final sy = size.height / 896;

    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * sx
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(-20 * sx, 740 * sy)
      ..quadraticBezierTo(60 * sx, 720 * sy, 120 * sx, 640 * sy)
      ..quadraticBezierTo(190 * sx, 560 * sy, 260 * sx, 550 * sy)
      ..quadraticBezierTo(320 * sx, 540 * sy, 380 * sx, 340 * sy)
      ..quadraticBezierTo(420 * sx, 260 * sy, 460 * sx, 210 * sy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws a minimal dot-grid resembling a world-map silhouette ghost.
/// Approximates the faint world-map watermark in the HTML (opacity 0.22).
class _WorldMapDotsPainter extends CustomPainter {
  // Normalised dot positions [x, y] in 0..1 space (rough continent clusters)
  static const List<List<double>> _dots = [
    // North America
    [0.10, 0.20], [0.12, 0.22], [0.14, 0.24], [0.16, 0.26], [0.14, 0.28],
    [0.18, 0.22], [0.20, 0.25], [0.22, 0.27],
    // Europe
    [0.44, 0.18], [0.46, 0.20], [0.48, 0.22], [0.50, 0.20], [0.52, 0.22],
    [0.46, 0.24], [0.48, 0.26],
    // Africa
    [0.47, 0.34], [0.49, 0.38], [0.51, 0.42], [0.49, 0.46], [0.51, 0.50],
    [0.47, 0.44],
    // Asia
    [0.58, 0.18], [0.62, 0.20], [0.66, 0.22], [0.70, 0.20], [0.74, 0.22],
    [0.60, 0.28], [0.64, 0.28], [0.68, 0.28], [0.72, 0.28],
    [0.60, 0.34], [0.64, 0.32], [0.68, 0.32],
    // Australia
    [0.74, 0.56], [0.78, 0.58], [0.82, 0.56], [0.80, 0.54], [0.76, 0.54],
    // South America
    [0.26, 0.40], [0.28, 0.44], [0.30, 0.48], [0.28, 0.52], [0.26, 0.56],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const double r = 2.0;
    for (final d in _dots) {
      canvas.drawCircle(Offset(d[0] * size.width, d[1] * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Flag Pill widget ──────────────────────────────────────────────────────────
class _FlagPill extends StatelessWidget {
  const _FlagPill({required this.code, required this.emoji});

  final String code;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x732A4A8D), // --white-card
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Text(
        '$code $emoji',
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
