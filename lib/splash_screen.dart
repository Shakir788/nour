import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../main_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Staggered: bismillah, lulu, nour text
  late final AnimationController _bismillahController;
  late final AnimationController _luluController;
  late final AnimationController _nourController;

  // Lulu floating bob
  late final AnimationController _bobController;

  // Pink glow pulse
  late final AnimationController _glowController;

  // Petals
  late final AnimationController _petalController;
  late final List<_Petal> _petals;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // 1. Bismillah fade+slide in
    _bismillahController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    // 2. Lulu scale bounce in (after 600ms)
    _luluController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // 3. Nour text fade in (after 1200ms)
    _nourController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    // 4. Lulu gentle float loop
    _bobController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

    // 5. Glow pulse loop
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    // 6. Petals fall loop
    _petalController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // generate petals
    _petals = List.generate(14, (i) => _Petal(
      x: _rng.nextDouble(),
      startY: -0.05 - _rng.nextDouble() * 0.3,
      speed: 0.18 + _rng.nextDouble() * 0.25,
      size: 7.0 + _rng.nextDouble() * 10,
      phase: _rng.nextDouble(),
      swayAmp: 0.02 + _rng.nextDouble() * 0.03,
      swayFreq: 1.0 + _rng.nextDouble() * 2.0,
      rotation: _rng.nextDouble() * pi * 2,
      rotSpeed: (_rng.nextDouble() - 0.5) * 3,
      color: _rng.nextBool()
          ? const Color(0xFFFFB6C1).withOpacity(0.85)
          : const Color(0xFFFFC8D5).withOpacity(0.7),
    ));

    // Stagger the fade-ins
    _bismillahController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _luluController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _nourController.forward();
    });

    // Navigate after 4s
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainNav(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bismillahController.dispose();
    _luluController.dispose();
    _nourController.dispose();
    _bobController.dispose();
    _glowController.dispose();
    _petalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF5),
              Color(0xFFFFF5F7),
              Color(0xFFFFF0F5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ===== FALLING PETALS =====
            AnimatedBuilder(
              animation: _petalController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _PetalPainter(petals: _petals, progress: _petalController.value),
                );
              },
            ),

            // ===== MAIN CONTENT =====
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BISMILLAH — fade + slide down
                  AnimatedBuilder(
                    animation: _bismillahController,
                    builder: (context, child) {
                      final fade = CurvedAnimation(parent: _bismillahController, curve: Curves.easeOut);
                      final slide = Tween<double>(begin: -30, end: 0).animate(
                        CurvedAnimation(parent: _bismillahController, curve: Curves.easeOut),
                      );
                      return Opacity(
                        opacity: fade.value,
                        child: Transform.translate(
                          offset: Offset(0, slide.value),
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final glow = Tween<double>(begin: 20.0, end: 55.0).animate(
                          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPink.withOpacity(0.18),
                                blurRadius: glow.value,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/images/bismillah.png',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  AnimatedBuilder(
                    animation: _bismillahController,
                    builder: (context, _) => Opacity(
                      opacity: (_bismillahController.value - 0.5).clamp(0.0, 1.0) * 2,
                      child: Text(
                        "Au nom d'Allah, le Tout Miséricordieux...",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textLight.withOpacity(0.75),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  // LULU — scale bounce in + float
                  AnimatedBuilder(
                    animation: Listenable.merge([_luluController, _bobController]),
                    builder: (context, child) {
                      final scale = CurvedAnimation(
                        parent: _luluController,
                        curve: Curves.elasticOut,
                      );
                      final bob = Tween<double>(begin: -6, end: 6).animate(
                        CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
                      );
                      final glowSize = Tween<double>(begin: 30.0, end: 65.0).animate(
                        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
                      );

                      return Opacity(
                        opacity: _luluController.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, bob.value),
                          child: Transform.scale(
                            scale: scale.value,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPink.withOpacity(0.20),
                                    blurRadius: glowSize.value,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.8),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/lulu/lulu.png',
                      width: 145,
                      height: 145,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // NOUR text — fade in with letter spacing expand
                  AnimatedBuilder(
                    animation: _nourController,
                    builder: (context, _) {
                      final t = CurvedAnimation(parent: _nourController, curve: Curves.easeOut);
                      final letterSpacing = Tween<double>(begin: 8.0, end: 2.0).animate(t);
                      return Opacity(
                        opacity: t.value,
                        child: Column(
                          children: [
                            Text(
                              "Nour",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'serif',
                                color: const Color(0xFF2D3142),
                                letterSpacing: letterSpacing.value,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Decorative line under Nour
                            Container(
                              width: 60 * t.value,
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.primaryPink.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: (t.value - 0.5).clamp(0.0, 1.0) * 2,
                              child: Text(
                                "✨ Ton compagnon quotidien ✨",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight.withOpacity(0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== PETAL DATA =====
class _Petal {
  final double x;         // 0-1 start x position
  final double startY;    // start y (negative = above screen)
  final double speed;     // fall speed multiplier
  final double size;      // petal size
  final double phase;     // phase offset so they don't all start at same point
  final double swayAmp;   // horizontal sway amplitude
  final double swayFreq;  // sway frequency
  final double rotation;  // initial rotation
  final double rotSpeed;  // rotation speed
  final Color color;

  const _Petal({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.phase,
    required this.swayAmp,
    required this.swayFreq,
    required this.rotation,
    required this.rotSpeed,
    required this.color,
  });
}

// ===== PETAL PAINTER =====
class _PetalPainter extends CustomPainter {
  final List<_Petal> petals;
  final double progress; // 0-1, loops

  _PetalPainter({required this.petals, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      // Each petal loops individually using its phase
      final t = ((progress + p.phase) % 1.0);
      final y = (p.startY + t * p.speed * 5.5) * size.height;
      if (y > size.height + 20) continue;

      final x = (p.x + sin(t * pi * 2 * p.swayFreq) * p.swayAmp) * size.width;
      final angle = p.rotation + t * p.rotSpeed * pi * 2;

      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      _drawPetal(canvas, paint, p.size);
      canvas.restore();
    }
  }

  void _drawPetal(Canvas canvas, Paint paint, double size) {
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(-size * 0.5, -size * 0.4, -size * 0.6, -size * 1.0, 0, -size * 1.2)
      ..cubicTo(size * 0.6, -size * 1.0, size * 0.5, -size * 0.4, 0, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}