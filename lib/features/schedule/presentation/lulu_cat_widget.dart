import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum _LuluState { idle, walking, sleeping, eating, happy }

class LuluPetWidget extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onFedHappy;

  const LuluPetWidget({
    super.key,
    this.width = 320,
    this.height = 150,
    this.onTap,
    this.onFedHappy,
  });

  @override
  State<LuluPetWidget> createState() => _LuluPetWidgetState();
}

class _LuluPetWidgetState extends State<LuluPetWidget> with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final AnimationController _tailController;
  late final AnimationController _moveController;

  _LuluState _state = _LuluState.idle;
  double _posX = 0.5;
  double _targetX = 0.5;
  bool _facingRight = true;
  bool _hasTreat = false;
  double _treatX = 0.5;
  Timer? _behaviorTimer;
  Timer? _eatTimer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _tailController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _moveController = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _scheduleNextBehavior();
  }

  @override
  void dispose() {
    _bobController.dispose();
    _tailController.dispose();
    _moveController.dispose();
    _behaviorTimer?.cancel();
    _eatTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextBehavior() {
    _behaviorTimer?.cancel();
    final delay = Duration(seconds: 4 + _rng.nextInt(5));
    _behaviorTimer = Timer(delay, _doRandomBehavior);
  }

  void _doRandomBehavior() {
    if (_hasTreat || _state == _LuluState.eating) {
      _scheduleNextBehavior();
      return;
    }

    final roll = _rng.nextDouble();
    if (roll < 0.45) {
      _walkToRandomSpot();
    } else if (roll < 0.65) {
      _sleepFor(const Duration(seconds: 5));
    } else {
      setState(() => _state = _LuluState.happy);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _state == _LuluState.happy) setState(() => _state = _LuluState.idle);
      });
    }
    _scheduleNextBehavior();
  }

  void _walkToRandomSpot() {
    final newTarget = 0.1 + _rng.nextDouble() * 0.8;
    _walkTo(newTarget);
  }

  void _walkTo(double target) {
    setState(() {
      _facingRight = target > _posX;
      _targetX = target;
      _state = _LuluState.walking;
    });

    final distance = (target - _posX).abs();
    _moveController.duration = Duration(milliseconds: (distance * 4000).clamp(800, 3000).toInt());
    _moveController.reset();

    final startX = _posX;
    _moveController.addListener(() {
      setState(() {
        _posX = startX + (target - startX) * _moveController.value;
      });
    });

    _moveController.forward().whenComplete(() {
      _moveController.removeListener(() {});
      if (!mounted) return;
      setState(() {
        _posX = target;
        if (_hasTreat) {
          _eatTreat();
        } else {
          _state = _LuluState.idle;
        }
      });
    });
  }

  void _sleepFor(Duration d) {
    setState(() => _state = _LuluState.sleeping);
    Future.delayed(d, () {
      if (mounted && _state == _LuluState.sleeping) setState(() => _state = _LuluState.idle);
    });
  }

  void _giveTreat() {
    if (_hasTreat || _state == _LuluState.eating) return;
    setState(() {
      _hasTreat = true;
      _treatX = 0.1 + _rng.nextDouble() * 0.8;
    });
    _walkTo(_treatX);
  }

  void _eatTreat() {
    setState(() => _state = _LuluState.eating);
    _eatTimer?.cancel();
    _eatTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _hasTreat = false;
        _state = _LuluState.happy;
      });
      widget.onFedHappy?.call();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _state == _LuluState.happy) setState(() => _state = _LuluState.idle);
      });
    });
  }

  void _onCatTap() {
    widget.onTap?.call();
    if (_state == _LuluState.sleeping) {
      setState(() => _state = _LuluState.idle);
      return;
    }
    setState(() => _state = _LuluState.happy);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _state == _LuluState.happy) setState(() => _state = _LuluState.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    const catSize = 90.0;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Premium Treat 🐟
          if (_hasTreat)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _treatX * (widget.width - 30),
              bottom: 10,
              child: const Text("🐟", style: TextStyle(fontSize: 24)), 
            ),

          // ☁️ Soft Cloud Lulu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 60),
            left: _posX * (widget.width - catSize),
            bottom: 5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onCatTap,
              child: AnimatedBuilder(
                animation: Listenable.merge([_bobController, _tailController]),
                builder: (context, child) {
                  double bob = 0;
                  double tiltAngle = 0;
                  if (_state == _LuluState.walking) {
                    bob = sin(_bobController.value * pi * 2) * 4;
                    tiltAngle = sin(_bobController.value * pi * 2) * 0.05;
                  } else if (_state == _LuluState.idle) {
                    bob = sin(_bobController.value * pi) * 2; 
                  }
                  
                  final tailAngle = sin(_tailController.value * pi * 2) * (_state == _LuluState.happy ? 0.4 : 0.15);

                  return Transform.translate(
                    offset: Offset(0, -bob),
                    child: Transform.rotate(
                      angle: tiltAngle,
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: const Size(catSize, catSize),
                        painter: _AestheticLuluPainter(
                          state: _state,
                          tailAngle: tailAngle,
                          isFacingRight: _facingRight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Soft Sleeping Zzz
          if (_state == _LuluState.sleeping)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: _posX * (widget.width - catSize) + catSize - (_facingRight ? 15 : 25),
              bottom: catSize - 15,
              child: Text("zzz", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF8D6E63).withOpacity(0.6))),
            ),

          // Soft Happy Sparkle
          if (_state == _LuluState.happy)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: _posX * (widget.width - catSize) + catSize - (_facingRight ? 15 : 25),
              bottom: catSize - 10,
              child: const Text("✨", style: TextStyle(fontSize: 18)),
            ),

          // Minimalist Treat Button
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: _giveTreat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: const Color(0xFFFFB6C1).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("🐟", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text("Nourrir", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF5D4037))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✨ SOFT AESTHETIC CLOUD CAT PAINTER ✨
class _AestheticLuluPainter extends CustomPainter {
  final _LuluState state;
  final double tailAngle;
  final bool isFacingRight;

  // Premium Soft Palette
  final Color baseColor = const Color(0xFFFFFFFF); // Pure White
  final Color shadowColor = const Color(0xFFF0E6EA); // Very soft warm grey/pink for depth
  final Color featureColor = const Color(0xFF6D4C41); // Soft Warm Brown for eyes/mouth (NO harsh black)
  final Color pinkAccent = const Color(0xFFFFC0CB); // Soft pastel pink

  _AestheticLuluPainter({
    required this.state,
    required this.tailAngle,
    required this.isFacingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    if (!isFacingRight) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final furPaint = Paint()..color = baseColor..style = PaintingStyle.fill;
    
    // 3D shading paint
    final shadingPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4); // Soft blur for 3D feel

    // Floor Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.95), width: w * 0.6, height: h * 0.1),
      Paint()..color = Colors.black.withOpacity(0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ===== TAIL (Soft and thick) =====
    canvas.save();
    canvas.translate(w * 0.25, h * 0.8);
    canvas.rotate(tailAngle);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-w * 0.2, -h * 0.1, -w * 0.1, -h * 0.35);
    
    canvas.drawPath(tailPath, Paint()..color = shadowColor..style = PaintingStyle.stroke..strokeWidth = w * 0.16..strokeCap = StrokeCap.round); // Shadow
    canvas.drawPath(tailPath, Paint()..color = baseColor..style = PaintingStyle.stroke..strokeWidth = w * 0.14..strokeCap = StrokeCap.round); // Fur
    canvas.restore();

    // ===== BODY (Soft blob) =====
    final bodyRect = Rect.fromLTWH(w * 0.2, h * 0.45, w * 0.6, h * 0.45);
    final bodyPath = Path()..addRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.25)));
    canvas.drawPath(bodyPath, furPaint);
    canvas.drawPath(bodyPath, shadingPaint); // Inner soft shadow

    // Legs (Paws without borders)
    canvas.drawOval(Rect.fromLTWH(w * 0.25, h * 0.82, w * 0.16, h * 0.12), furPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.55, h * 0.82, w * 0.16, h * 0.12), furPaint);

    // ===== HEAD (Rounded seamless) =====
    final headRect = Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.65, h * 0.55);
    final headPath = Path()..addOval(headRect);

    // Ears (Soft rounded triangles)
    final leftEar = Path()
      ..moveTo(w * 0.28, h * 0.25)
      ..quadraticBezierTo(w * 0.32, h * 0.05, w * 0.45, h * 0.15)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.6, h * 0.15)
      ..quadraticBezierTo(w * 0.72, h * 0.05, w * 0.78, h * 0.25)
      ..close();
    
    canvas.drawPath(leftEar, furPaint);
    canvas.drawPath(rightEar, furPaint);
    canvas.drawPath(leftEar, shadingPaint);
    canvas.drawPath(rightEar, shadingPaint);

    // Inner Ears
    canvas.drawPath(Path()..moveTo(w*0.32, h*0.2)..quadraticBezierTo(w*0.35, h*0.12, w*0.4, h*0.16)..close(), Paint()..color=pinkAccent.withOpacity(0.7));
    canvas.drawPath(Path()..moveTo(w*0.65, h*0.16)..quadraticBezierTo(w*0.7, h*0.12, w*0.73, h*0.2)..close(), Paint()..color=pinkAccent.withOpacity(0.7));

    // Head Fill (drawn over body/ears for seamless look)
    canvas.drawPath(headPath, furPaint);
    canvas.drawPath(headPath, shadingPaint);

    // ===== SOFT FEATURES =====
    final featureStroke = Paint()..color = featureColor..style = PaintingStyle.stroke..strokeWidth = w * 0.02..strokeCap = StrokeCap.round;

    // Soft Blush
    canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.42, w * 0.12, h * 0.06), Paint()..color = pinkAccent.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawOval(Rect.fromLTWH(w * 0.62, h * 0.42, w * 0.12, h * 0.06), Paint()..color = pinkAccent.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Eyes
    final eyesClosed = state == _LuluState.sleeping || state == _LuluState.happy;
    if (eyesClosed) {
      // Gentle closed eyes  ◡  ◡
      canvas.drawArc(Rect.fromLTWH(w * 0.38, h * 0.38, w * 0.08, h * 0.04), pi, pi, false, featureStroke);
      canvas.drawArc(Rect.fromLTWH(w * 0.58, h * 0.38, w * 0.08, h * 0.04), pi, pi, false, featureStroke);
    } else {
      // Soft round eyes
      canvas.drawCircle(Offset(w * 0.42, h * 0.38), w * 0.035, Paint()..color = featureColor);
      canvas.drawCircle(Offset(w * 0.62, h * 0.38), w * 0.035, Paint()..color = featureColor);
      // Delicate catchlight
      canvas.drawCircle(Offset(w * 0.43, h * 0.37), w * 0.01, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.63, h * 0.37), w * 0.01, Paint()..color = Colors.white);
    }

    // Mouth / Nose
    if (state == _LuluState.eating) {
      // Tiny soft open mouth
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.52, h * 0.46), width: w * 0.05, height: h * 0.06), Paint()..color = featureColor);
    } else {
      // Tiny delicate 'w' mouth
      final mouth = Path()
        ..moveTo(w * 0.48, h * 0.44)
        ..quadraticBezierTo(w * 0.50, h * 0.47, w * 0.52, h * 0.44)
        ..quadraticBezierTo(w * 0.54, h * 0.47, w * 0.56, h * 0.44);
      canvas.drawPath(mouth, featureStroke..strokeWidth = w * 0.015);
      // Tiny pink nose
      canvas.drawCircle(Offset(w * 0.52, h * 0.43), w * 0.012, Paint()..color = pinkAccent);
    }

    canvas.restore(); 
  }

  @override
  bool shouldRepaint(covariant _AestheticLuluPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.tailAngle != tailAngle || oldDelegate.isFacingRight != isFacingRight;
}