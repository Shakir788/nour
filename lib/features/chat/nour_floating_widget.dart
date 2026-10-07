import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'nour_screen.dart'; 

class NourFloatingWidget extends StatefulWidget {
  const NourFloatingWidget({super.key});

  @override
  State<NourFloatingWidget> createState() => _NourFloatingWidgetState();
}

class _NourFloatingWidgetState extends State<NourFloatingWidget> {
  bool _showGreeting = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showGreeting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedOpacity(
          opacity: _showGreeting ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500), 
          child: _showGreeting
              ? Container(
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent, // ✨ Indigo theme
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(4), 
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigoAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Hello, I'm Nour ✨",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ✨ Main Floating Button (Nour's Button)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NourScreen()),
            );
          },
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.indigoAccent, Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigoAccent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
            ),
            child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}