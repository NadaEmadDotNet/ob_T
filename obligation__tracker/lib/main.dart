import 'package:flutter/material.dart';
import 'package:obligation__tracker/pages/HomePage.dart';
import 'package:obligation__tracker/pages/LoginPage.dart';
import 'package:obligation__tracker/pages/RegisterPage.dart';
import 'package:obligation__tracker/pages/UserSettingPage.dart';
import 'package:obligation__tracker/theme/app_design.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nffstjkgclephibkgsao.supabase.co', // Replace with your URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mZnN0amtnY2xlcGhpYmtnc2FvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4NzEyMjYsImV4cCI6MjA4MTQ0NzIyNn0.l2Oj6lpzjbCfrsoqnbbQXLpvuduTeq7YTEv0B-aBhIw', // Replace with your key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obligation Tracker',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.teal,
          secondary: AppColors.aqua,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.cream,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.deepTeal,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.86),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.aqua, width: 1.5),
          ),
        ),
      ),

      home: const HomePage(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/settings': (context) => const UserSettingsPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}