import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    final Color gradientTop = const Color(0xFFAEECE2); 
    final Color gradientBottom = const Color(0xFFF9F7E8); 
    final Color primaryTextColor = const Color(0xFF4B4532);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(
          'About ObligationsTracker',
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
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About ObligationsTracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ObligationsTracker is a simple and effective app designed to help you keep track of your financial obligations.',
                      style: TextStyle(fontSize: 16, color: primaryTextColor, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Whether it\'s bills, subscriptions, or loans, the app ensures you never miss a payment.',
                      style: TextStyle(fontSize: 16, color: primaryTextColor, height: 1.5),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Features:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    _buildFeatureItem('Track all obligations in one place', primaryTextColor),
                    _buildFeatureItem('Get reminders for upcoming payments', primaryTextColor),
                    _buildFeatureItem('Simple and user-friendly interface', primaryTextColor),
                    _buildFeatureItem('Secure and reliable', primaryTextColor),
                    const SizedBox(height: 25),
                    Text(
                      'Get Started:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create an account or log in to start managing your obligations easily and efficiently.',
                      style: TextStyle(fontSize: 16, color: primaryTextColor, height: 1.5),
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

  
  Widget _buildFeatureItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}