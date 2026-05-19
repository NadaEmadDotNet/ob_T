import 'package:flutter/material.dart';
import 'package:obligation__tracker/pages/LoginPage.dart';
import 'package:obligation__tracker/pages/RegisterPage.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final drift = _controller.value;
          return Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFAEECE4), Color(0xFFF8EEDC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Positioned(
                top: 64 + (drift * 18),
                right: 22,
                child: _FloatingBubble(size: 86, color: Colors.white.withOpacity(0.24)),
              ),
              Positioned(
                left: 22,
                bottom: 130 + (drift * 16),
                child: _FloatingBubble(size: 118, color: AppColors.aqua.withOpacity(0.16)),
              ),
              ClipPath(
                clipper: TopWaveClipper(),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.20), Colors.white.withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 760),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(offset: Offset(0, 32 * (1 - value)), child: child),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -8 * drift),
                            child: Hero(
                              tag: 'app-logo',
                              child: Container(
                                padding: const EdgeInsets.all(34),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.88),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.deepTeal.withOpacity(0.16),
                                      blurRadius: 30,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.receipt_long_rounded, size: 78, color: AppColors.teal),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Obligation Tracker',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'A polished space for payments, due dates, reminders, and priority flow.',
                            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.45, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              _FeaturePill(icon: Icons.auto_graph_rounded, label: 'Live analytics'),
                              _FeaturePill(icon: Icons.priority_high_rounded, label: 'Priority color'),
                              _FeaturePill(icon: Icons.bolt_rounded, label: 'Fast actions'),
                            ],
                          ),
                          const SizedBox(height: 34),
                          PremiumButton(
                            expanded: true,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => Navigator.push(context, premiumRoute(const RegisterPage())),
                            child: const Text('Get Started'),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, premiumRoute(const LoginPage())),
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.teal,
                                backgroundColor: Colors.white.withOpacity(0.88),
                                side: const BorderSide(color: AppColors.teal, width: 1.4),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _FloatingBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.66),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.teal, size: 17),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.45, size.width * 0.5, size.height * 0.55);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.65, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}