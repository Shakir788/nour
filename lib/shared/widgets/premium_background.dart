import 'package:flutter/material.dart';
// ✨ Naya helper import karna hai yahan
import '../../../core/utils/cat_behavior_helper.dart'; 

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        image: DecorationImage(
          // ✨ Yahan purane CatHelper ki jagah CatBehaviorHelper likhna hai
          image: NetworkImage(CatBehaviorHelper.getCatBackground()),
          fit: BoxFit.cover,
          opacity: 0.15, 
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.4),
              const Color(0xFFFFF0F5).withOpacity(0.6),
              const Color(0xFFE6E6FA).withOpacity(0.4),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}