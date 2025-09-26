// lib/main_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADD THIS IMPORT
import 'bible_data.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'chapter_content_page.dart';
import 'chapter_selector_screen.dart';
class MainReaderScreen extends StatefulWidget {
  const MainReaderScreen({super.key});

  @override
  State<MainReaderScreen> createState() => _MainReaderScreenState();
}

class _MainReaderScreenState extends State<MainReaderScreen> {
  late PageController _pageController;
  int currentGlobalChapter = 1;
  final int totalChapters = BibleData.getTotalChapters();
  double _fontSize = 18.0;
  Set<int> loadedPages = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadSavedFontSize();
  }

  // Add this method to load saved font size
  Future<void> _loadSavedFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFontSize = prefs.getDouble('font_size');
      if (savedFontSize != null && mounted) {
        setState(() {
          _fontSize = savedFontSize;
        });
      }
    } catch (e) {
      print('Error loading font size: $e');
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

  void _navigateToChapter(int globalChapter) {
    if (globalChapter >= 1 && globalChapter <= totalChapters) {
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
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            // Left Arrow
            IconButton(
              onPressed: currentGlobalChapter > 1 ? _goToPreviousChapter : null,
              icon: Icon(
                Icons.chevron_left,
                color: currentGlobalChapter > 1 ? Colors.blue.shade700 : Colors.grey,
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
                    border: Border.all(color: Colors.blue.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blue.shade50,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${chapterInfo['shortName']} ${chapterInfo['chapterInBook']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        chapterInfo['arabicName'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
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
                color: currentGlobalChapter < totalChapters ? Colors.blue.shade700 : Colors.grey,
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
            icon: Icon(Icons.search, color: Colors.blue.shade700),
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
                  ),
                ),
              );
            },
            icon: Icon(Icons.settings, color: Colors.blue.shade700),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: totalChapters,
        onPageChanged: (index) {
          setState(() {
            currentGlobalChapter = index + 1;
          });
        },
        itemBuilder: (context, index) {
          final globalChapter = index + 1;
          final info = BibleData.getChapterInfo(globalChapter);
          
          return ChapterContentPage(
            key: ValueKey(globalChapter), // Important for proper widget management
            bookName: info['bookName'],
            shortName: info['shortName'],
            arabicName: info['arabicName'], // Pass Arabic name
            chapterNumber: info['chapterInBook'],
            bookIndex: info['bookIndex'],
            fontSize: _fontSize, // Pass font size to chapter
          );
        },
      ),
    );
  }
}
