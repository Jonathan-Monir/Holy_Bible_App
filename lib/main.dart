// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'splash_screen.dart';
import 'theme_provider.dart';
import 'app_open_ad_manager.dart';

final AppOpenAdManager appOpenAdManager = AppOpenAdManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  // Load the app open ad as early as possible
  appOpenAdManager.loadAd();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const HolyBibleApp(),
    ),
  );
}

class HolyBibleApp extends StatelessWidget {
  const HolyBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'الكتاب المقدس ترجمة عربية باسم يهوه',
          theme: themeProvider.themeData,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
