import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:obligation__tracker/pages/HomePage.dart';
import 'package:obligation__tracker/pages/LoginPage.dart';
import 'package:obligation__tracker/pages/RegisterPage.dart';
import 'package:obligation__tracker/pages/UserSettingPage.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase (requires platform config or firebase_options.dart)
 // try {
   // await FirebaseService.initialize();
 // } catch (e) {
   // if (kDebugMode) print('Firebase init warning: $e');
 // }

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
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
      ),

      home: const HomePage(), 
      
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/settings': (context) => const UserSettingsPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }}