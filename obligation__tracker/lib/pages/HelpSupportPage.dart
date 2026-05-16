import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    final Color gradientTop = const Color(0xFFAEECE2); 
    final Color gradientBottom = const Color(0xFFF9F7E8); 
    final Color primaryTextColor = const Color(0xFF4B4532);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientTop, gradientBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كرت معلومات الاتصال
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                    ),
                    const SizedBox(height: 15),
                    _buildContactItem(Icons.email_outlined, 'support@obligationstracker.com', primaryTextColor),
                    const SizedBox(height: 12),
                    _buildContactItem(Icons.phone_outlined, '01065396292', primaryTextColor),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // قسم الأسئلة الشائعة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  'Frequently Asked Questions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
              ),

              // السؤال الأول
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q1: How do I reset my password?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A1: Go to the login page and click on "Forgot Password". Follow the instructions to reset your password.',
                      style: TextStyle(fontSize: 15, color: primaryTextColor.withOpacity(0.8), height: 1.4),
                    ),
                  ],
                ),
              ),

              // السؤال الثاني
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q2: How do I contact support?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A2: You can reach us via email or phone as listed above. Our team is available 24/7.',
                      style: TextStyle(fontSize: 15, color: primaryTextColor.withOpacity(0.8), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة بناء الكرت الزجاجي العريض
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  // دالة لبناء بنود الاتصال (إيميل - تليفون) مع أيقونة
  Widget _buildContactItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}