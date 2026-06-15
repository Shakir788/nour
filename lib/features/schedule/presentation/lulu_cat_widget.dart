import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum _LuluState { idle, walking, sleeping, eating, happy }

/// ✨ Lulu — built from real AI-generated cat assets
/// (assets/lulu/head.png, body.png, tail.png, eyes_closed.png, mouth_meow.png)
/// Walks around, sleeps, eats treats, and reacts to taps on head/body/tail.
class LuluPetWidget extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onFedHappy;

  const LuluPetWidget({
    super.key,
    this.width = 320,
    this.height = 220,
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
  bool _facingRight = true;
  bool _hasTreat = false;
  double _treatX = 0.5;
  Timer? _behaviorTimer;
  Timer? _eatTimer;
  final Random _rng = Random();
  String _reaction = '';

  // base size of the cat group (head+body), images are 2:3 aspect (1024x1536)
  static const double _catWidth = 130;
  static const double _catHeight = _catWidth * 1.5; // 195

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

  void _walkToRandomSpot() => _walkTo(0.1 + _rng.nextDouble() * 0.8);

  void _walkTo(double target) {
    setState(() {
      _facingRight = target > _posX;
      _state = _LuluState.walking;
    });

    final distance = (target - _posX).abs();
    _moveController.duration = Duration(milliseconds: (distance * 4000).clamp(800, 3000).toInt());
    _moveController.reset();

    final startX = _posX;
    void listener() {
      setState(() {
        _posX = startX + (target - startX) * _moveController.value;
      });
    }

    _moveController.addListener(listener);
    _moveController.forward().whenComplete(() {
      _moveController.removeListener(listener);
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

  void _showReaction(String emoji) {
    setState(() => _reaction = emoji);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _reaction = '');
    });
  }

  void _onHeadPet() {
    widget.onTap?.call();
    if (_state == _LuluState.sleeping) {
      setState(() => _state = _LuluState.idle);
      return;
    }
    setState(() => _state = _LuluState.happy);
    _showReaction('💕');
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _state == _LuluState.happy) setState(() => _state = _LuluState.idle);
    });
  }

  void _onBodyPet() {
    widget.onTap?.call();
    setState(() => _state = _LuluState.happy);
    _showReaction('😊');
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _state == _LuluState.happy) setState(() => _state = _LuluState.idle);
    });
  }

  void _onTailPet() {
    widget.onTap?.call();
    _showReaction('😾');
    _tailController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Treat 🐟
          if (_hasTreat)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _treatX * (widget.width - 30),
              bottom: 10,
              child: const Text("🐟", style: TextStyle(fontSize: 24)),
            ),

          // Lulu group
          AnimatedPositioned(
            duration: const Duration(milliseconds: 60),
            left: _posX * (widget.width - _catWidth),
            bottom: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([_bobController, _tailController]),
              builder: (context, child) {
                double bob = 0;
                double tiltAngle = 0;
                double squashX = 1.0;
                double squashY = 1.0;
                if (_state == _LuluState.walking) {
                  final wave = sin(_bobController.value * pi * 2);
                  bob = wave.abs() * 6; // hop up on each step
                  tiltAngle = wave * 0.06;
                  squashX = 1.0 + wave.abs() * 0.04;
                  squashY = 1.0 - wave.abs() * 0.04;
                } else if (_state == _LuluState.idle) {
                  bob = sin(_bobController.value * pi) * 2;
                }
                final tailAngle = sin(_tailController.value * pi * 2) * (_state == _LuluState.happy ? 0.35 : 0.12);

                final eyesClosed = _state == _LuluState.sleeping || _state == _LuluState.happy;
                final eating = _state == _LuluState.eating;

                return Transform.translate(
                  offset: Offset(0, -bob),
                  child: Transform.rotate(
                    angle: tiltAngle,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scaleX: squashX,
                      scaleY: squashY,
                      alignment: Alignment.bottomCenter,
                      child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(_facingRight ? 1.0 : -1.0, 1.0),
                      child: SizedBox(
                        width: _catWidth,
                        height: _catHeight + 60,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Soft floor shadow
                            Positioned(
                              bottom: 0,
                              left: _catWidth * 0.15,
                              child: Container(
                                width: _catWidth * 0.7,
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10)],
                                ),
                              ),
                            ),

                            // TAIL (behind body, to the right)
                            Positioned(
                              right: -_catWidth * 0.18,
                              bottom: _catHeight * 0.05,
                              child: Transform.rotate(
                                angle: tailAngle,
                                alignment: const Alignment(-0.6, 0.6), // pivot near base of tail
                                child: Image.asset('assets/lulu/tail.png', width: _catWidth * 0.6,
                                    errorBuilder: (c, e, s) => const SizedBox.shrink()),
                              ),
                            ),

                            // BODY
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Image.asset('assets/lulu/body.png', width: _catWidth,
                                  errorBuilder: (c, e, s) => const SizedBox.shrink()),
                            ),

                            // HEAD (overlaps top of body)
                            Positioned(
                              top: 0,
                              left: _catWidth * 0.10,
                              child: SizedBox(
                                width: _catWidth * 0.85,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset('assets/lulu/head.png', width: _catWidth * 0.85,
                                        errorBuilder: (c, e, s) => const SizedBox.shrink()),
                                                                        if (eyesClosed)
                                      Transform.translate(
                                        offset: Offset(0, -_catWidth * 0.02),
                                        child: Image.asset(
                                          'assets/lulu/eyes_closed.png',
                                          width: _catWidth * 0.55,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => const SizedBox.shrink(),
                                        ),
                                      ),
                                    if (eating)
                                      Image.asset('assets/lulu/mouth_meow.png', width: _catWidth * 0.85,
                                          errorBuilder: (c, e, s) => const SizedBox.shrink()),
                                  ],
                                ),
                              ),
                            ),

                            // Invisible tap zones
                            Positioned(
                              top: 0, left: _catWidth * 0.12, width: _catWidth * 0.76, height: _catHeight * 0.42,
                              child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _onHeadPet),
                            ),
                            Positioned(
                              top: _catHeight * 0.42, left: 0, width: _catWidth * 0.85, height: _catHeight * 0.6,
                              child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _onBodyPet),
                            ),
                            Positioned(
                              top: _catHeight * 0.15, right: -_catWidth * 0.15, width: _catWidth * 0.35, height: _catHeight * 0.6,
                              child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _onTailPet),
                            ),

                            // Floating reaction
                            if (_reaction.isNotEmpty)
                              Positioned(
                                top: -22,
                                left: _catWidth * 0.35,
                                child: Text(_reaction, style: const TextStyle(fontSize: 22)),
                              ),

                            // Sleeping Zzz
                            if (_state == _LuluState.sleeping)
                              Positioned(
                                top: 10,
                                right: -10,
                                child: Text("zzz", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF8D6E63).withOpacity(0.6))),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          ),

          // Treat Button
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: _giveTreat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
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