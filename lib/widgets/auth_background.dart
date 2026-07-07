import 'package:flutter/material.dart';

/// Widget reusable untuk background gambar + overlay gelap
/// yang dipakai di landing_page, login_page, dan signup_page.
class AuthBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;

  const AuthBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/alun_alun_sby.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(overlayOpacity)),
          SafeArea(child: child),
        ],
      ),
    );
  }
}