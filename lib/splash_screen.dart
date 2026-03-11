// lib/splash_screen.dart
import 'main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chapter_selector_screen.dart';
import 'main_reader_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }
  Future<void> _showCopyrightIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('copyright_seen') ?? false;
    if (seen || !mounted) return;

    await prefs.setBool('copyright_seen', true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Legal Notice & Copyright',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'إشعار قانوني وحقوق الطبع والنشر',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontFamily: 'Amiri',
                ),
                textDirection: TextDirection.rtl,
              ),
              const Divider(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // English section
                      const Text(
                        'App Software & Original Content',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Copyright © 2026 Ivraym Barsoum. All rights reserved. The software, user interface design, branding, and technical architecture of this application are the exclusive property of Ivraym Barsoum and are protected by Canadian and international copyright laws.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Scripture Text',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'The Arabic translation of the Holy Scriptures contained in this application is protected by copyright law in Canada (registration number: 1241349 in 2026). All rights are reserved by the original copyright holder. No part of the scripture text may be extracted, redistributed, or used in any other digital or print format without the express written consent of the copyright owner.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Credits',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'For the glory of Yahweh and the advancement of His Word.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Divider(height: 20),
                      // Arabic section
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'برمجيات التطبيق والمحتوى الأصلي',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Amiri'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'حقوق الطبع والنشر © 2026 إفرايم بشرى برسوم. جميع الحقوق محفوظة. إن البرمجيات، وتصميم واجهة المستخدم، والعلامة التجارية، والبنية التقنية لهذا التطبيق هي ملكية حصرية لـ إفرايم بشرى برسوم، وهي محمية بموجب قوانين حقوق النشر الكندية والدولية.',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontSize: 12, fontFamily: 'Amiri'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'نص الأسفار المقدسة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Amiri'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'إن الترجمة العربية للأسفار المقدسة الواردة في هذا التطبيق محمية بموجب قانون حقوق النشر في كندا (رقم التسجيل 1241349). جميع حقوق النص محفوظة لمالك حقوق الطبع والنشر الأصلي إفرايم بشرى برسوم. لا يجوز استخراج نص الأسفار المقدسة أو إعادة توزيعه أو استخدامه في أي تنسيق رقمي أو مطبوع آخر دون موافقة كتابية صريحة من مالك حقوق الطبع والنشر.',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontSize: 12, fontFamily: 'Amiri'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'تقدير',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Amiri'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'لمجد يهوه وإعلاء كلمته.',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontSize: 12, fontFamily: 'Amiri'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('I Agree / أوافق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _navigateToHome() async {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      await _showCopyrightIfFirstTime();

      if (!mounted) return;

      // Show app open ad after splash
      appOpenAdManager.showAdIfAvailable();

      final prefs = await SharedPreferences.getInstance();
      final lastChapter = prefs.getInt('last_chapter');

      if (lastChapter != null && lastChapter > 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainReaderScreen(initialChapter: lastChapter),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterSelectorScreen(
              currentChapter: 1,
              onChapterSelected: (chapter) {},
            ),
          ),
        );
      }
    }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'الكتاب المقدس',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Amiri',
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              const Text(
                'Holy Bible',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
