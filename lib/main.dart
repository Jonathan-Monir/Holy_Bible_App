// lib/main.dart
import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const HolyBibleApp());
}

class HolyBibleApp extends StatelessWidget {
  const HolyBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الكتاب المقدس ترجمة عربية باسم يهوه', // Changed title
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
