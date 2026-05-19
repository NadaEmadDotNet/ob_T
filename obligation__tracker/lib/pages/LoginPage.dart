import 'package:flutter/material.dart';
import 'package:obligation__tracker/pages/Obligation_Screen.dart';
import 'package:obligation__tracker/pages/RegisterPage.dart';
import 'package:obligation__tracker/services/api_service.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword(String email) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password reset is not available in the local API yet.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: resetEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (resetEmailController.text.isNotEmpty) {
                _resetPassword(resetEmailController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, premiumRoute(const ObligationsScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(24, 86, 24, 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 28 * (1 - value)), child: child),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: 'app-logo',
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.88),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withOpacity(0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.teal, size: 48),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text('Welcome back', style: TextStyle(color: AppColors.ink, fontSize: 30, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue tracking your obligations.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  _GlassPanel(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
                          validator: (value) => value == null || value.isEmpty ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isPasswordHidden,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                              onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');
                            if (!passwordRegex.hasMatch(value)) return 'Password must contain letters and numbers';
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        PremiumButton(
                          expanded: true,
                          icon: _loading ? null : Icons.login_rounded,
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.push(context, premiumRoute(const RegisterPage())),
                    child: const Text("Don't have an account? Register", style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepTeal.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}