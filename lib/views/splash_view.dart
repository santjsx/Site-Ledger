import 'package:flutter/material.dart';
import 'dashboard_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // Navigate to Dashboard after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardView(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Beautiful premium dark gradient background
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF020617), // Slate 950 / Obsidian
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glowing Premium Mic Icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00F2FE).withValues(alpha: 0.08),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic_none_rounded,
                          size: 72,
                          color: Color(0xFF00F2FE), // Glowing cyan
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Text branding
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'సైట్ వాయిస్ లెడ్జర్',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'నోటి మాటలతో సైట్ ఖర్చులు రాసుకోండి',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Minimal Loading indicator
                      SizedBox(
                        width: 40,
                        height: 2,
                        child: LinearProgressIndicator(
                          color: const Color(0xFF00F2FE),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
