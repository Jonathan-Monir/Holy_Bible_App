// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'splash_screen.dart';
import 'theme_provider.dart';
import 'app_open_ad_manager.dart';

final AppOpenAdManager appOpenAdManager = AppOpenAdManager();
final AppLifecycleReactor appLifecycleReactor = AppLifecycleReactor(
  appOpenAdManager: appOpenAdManager,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MobileAds.instance.initialize();
    print('✅ MobileAds initialized');
    appOpenAdManager.loadAd();
    appLifecycleReactor.listenToAppStateChanges();
  } catch (e) {
    print('❌ AdMob initialization failed: $e');
  }
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
