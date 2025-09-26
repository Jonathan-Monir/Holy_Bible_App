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
      title: 'Holy Bible',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
