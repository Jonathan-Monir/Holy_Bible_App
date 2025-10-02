// lib/main_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'bible_data.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'chapter_content_page.dart';
import 'chapter_selector_screen.dart';
import 'theme_provider.dart';

class MainReaderScreen extends StatefulWidget {
  final int? initialChapter;
  const MainReaderScreen({super.key, this.initialChapter});

  @override
  State<MainReaderScreen> createState() => _MainReaderScreenState();
}

class _MainReaderScreenState extends State<MainReaderScreen> {
  late PageController _pageController;
  int currentGlobalChapter = 1;
  final int totalChapters = BibleData.getTotalChapters();
  double _fontSize = 18.0;
  String _fontFamily = 'Amiri';
  bool _removeDiacritics = false;
  Set<int> loadedPages = {};

  @override
  void initState() {
    super.initState();
    currentGlobalChapter = widget.initialChapter ?? 1;
    _pageController = PageController(initialPage: currentGlobalChapter - 1);
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedFontSize = prefs.getDouble('font_size');
      final savedFontFamily = prefs.getString('font_family');
      final savedRemoveDiacritics = prefs.getBool('remove_diacritics');
      
      if (mounted) {
        setState(() {
          if (savedFontSize != null) _fontSize = savedFontSize;
          if (savedFontFamily != null) _fontFamily = savedFontFamily;
          if (savedRemoveDiacritics != null) _removeDiacritics = savedRemoveDiacritics;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPreviousChapter() {
    if (currentGlobalChapter > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextChapter() {
    if (currentGlobalChapter < totalChapters) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToChapter(int globalChapter) async {
    if (globalChapter >= 1 && globalChapter <= totalChapters) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_chapter', globalChapter);
      setState(() {
        currentGlobalChapter = globalChapter;
      });
      _pageController.jumpToPage(globalChapter - 1);
    }
  }

  void _showChapterSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterSelectorScreen(
          currentChapter: currentGlobalChapter,
          onChapterSelected: _navigateToChapter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterInfo = BibleData.getChapterInfo(currentGlobalChapter);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          children: [
            // Left Arrow
            IconButton(
              onPressed: currentGlobalChapter > 1 ? _goToPreviousChapter : null,
              icon: Icon(
                Icons.chevron_left,
                color: currentGlobalChapter > 1 
                    ? Theme.of(context).primaryColor
                    : themeProvider.secondaryTextColor.withOpacity(0.3),
                size: 28,
              ),
            ),
            
            // Chapter Info Rectangle
            Expanded(
              child: GestureDetector(
                onTap: _showChapterSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${chapterInfo['shortName']} ${chapterInfo['chapterInBook']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        chapterInfo['arabicName'],
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.secondaryTextColor,
                          fontFamily: 'Amiri',
                        ),
                        textDirection: TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Right Arrow
            IconButton(
              onPressed: currentGlobalChapter < totalChapters ? _goToNextChapter : null,
              icon: Icon(
                Icons.chevron_right,
                color: currentGlobalChapter < totalChapters 
                    ? Theme.of(context).primaryColor
                    : themeProvider.secondaryTextColor.withOpacity(0.3),
                size: 28,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    onChapterSelected: _navigateToChapter,
                  ),
                ),
              );
            },
            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    currentFontSize: _fontSize,
                    onFontSizeChanged: (newSize) {
                      setState(() {
                        _fontSize = newSize;
                      });
                    },
                    currentFontFamily: _fontFamily,
                    onFontFamilyChanged: (newFont) {
                      setState(() {
                        _fontFamily = newFont;
                      });
                    },
                    removeDiacritics: _removeDiacritics,
                    onRemoveDiacriticsChanged: (value) {
                      setState(() {
                        _removeDiacritics = value;
                      });
                    },
                  ),
                ),
              );
            },
            icon: Icon(Icons.settings, color: Theme.of(context).primaryColor),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: totalChapters,
        onPageChanged: (index) async {
          final newChapter = index + 1;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('last_chapter', newChapter);
          setState(() {
            currentGlobalChapter = newChapter;
          });
        },
        itemBuilder: (context, index) {
          final globalChapter = index + 1;
          final info = BibleData.getChapterInfo(globalChapter);
          
          return ChapterContentPage(
            key: ValueKey('$globalChapter-$_fontFamily-$_removeDiacritics'),
            bookName: info['bookName'],
            shortName: info['shortName'],
            arabicName: info['arabicName'],
            chapterNumber: info['chapterInBook'],
            bookIndex: info['bookIndex'],
            fontSize: _fontSize,
            fontFamily: _fontFamily,
            removeDiacritics: _removeDiacritics,
          );
        },
      ),
    );
  }
}
