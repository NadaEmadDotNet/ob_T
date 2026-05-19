import 'package:flutter/material.dart';
import 'package:obligation__tracker/pages/LoginPage.dart';
import 'package:obligation__tracker/services/api_service.dart';
import 'package:obligation__tracker/theme/app_design.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.signup(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pushReplacement(context, premiumRoute(const LoginPage()));
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
                      child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.teal, size: 48),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text('Create account', style: TextStyle(color: AppColors.ink, fontSize: 30, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Build your personal obligation dashboard.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  Container(
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
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_rounded)),
                          validator: (value) => value == null || value.isEmpty ? 'Username is required' : null,
                        ),
                        const SizedBox(height: 16),
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
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _isConfirmPasswordHidden,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.verified_user_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                              onPressed: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                            ),
                          ),
                          validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 22),
                        PremiumButton(
                          expanded: true,
                          icon: _loading ? null : Icons.arrow_forward_rounded,
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Register'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, premiumRoute(const LoginPage())),
                    child: const Text('Already have an account? Login', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');
    if (!passwordRegex.hasMatch(value)) return 'Password must contain letters and numbers';
    return null;
  }
}