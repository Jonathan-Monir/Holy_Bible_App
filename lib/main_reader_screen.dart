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
  
  // Cache for storing built pages
  final Map<int, Widget> _pageCache = {};
  // Add this after _pageCache declaration
  final Set<int> _preloadedChapters = {};
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    currentGlobalChapter = widget.initialChapter ?? 1;
    _pageController = PageController(
      initialPage: currentGlobalChapter - 1,
      keepPage: true,
    );
    _loadSavedSettings();
    
    // START PRELOADING IMMEDIATELY
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAdjacentPages(currentGlobalChapter);
    });
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

  // Clear cache when settings change
  void _onSettingsChanged() {
    setState(() {
      _pageCache.clear();
    });
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
                      _onSettingsChanged();
                    },
                    currentFontFamily: _fontFamily,
                    onFontFamilyChanged: (newFont) {
                      setState(() {
                        _fontFamily = newFont;
                      });
                      _onSettingsChanged();
                    },
                    removeDiacritics: _removeDiacritics,
                    onRemoveDiacriticsChanged: (value) {
                      setState(() {
                        _removeDiacritics = value;
                      });
                      _onSettingsChanged();
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
        allowImplicitScrolling: true,
        pageSnapping: true,  // ADD THIS LINE - ensures instant snap to page
        physics: const PageScrollPhysics(),  // ADD THIS LINE - removes bounce/momentum, makes it feel more instant
        onPageChanged: (index) async {
          final newChapter = index + 1;
          
          SharedPreferences.getInstance().then((prefs) {
            prefs.setInt('last_chapter', newChapter);
          });
          
          setState(() {
            currentGlobalChapter = newChapter;
          });
          
          // Trigger preloading of new adjacent chapters
          _preloadAdjacentPages(newChapter);
        },
        itemBuilder: (context, index) {
          final globalChapter = index + 1;
          
          // Use cached page if available and settings haven't changed
          final cacheKey = globalChapter;
          if (_pageCache.containsKey(cacheKey)) {
            return _pageCache[cacheKey]!;
          }
          
          // Build new page
          final info = BibleData.getChapterInfo(globalChapter);
          final page = ChapterContentPage(
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
          
          // Cache the page
          _pageCache[cacheKey] = page;
          
          // Limit cache size to prevent memory issues
          if (_pageCache.length > 10) {
            final keysToRemove = _pageCache.keys
                .where((key) => (key - currentGlobalChapter).abs() > 5)
                .toList();
            for (var key in keysToRemove) {
              _pageCache.remove(key);
            }
          }
          
          return page;
        },
      ),
    );
  }

  // Preload adjacent chapters in background
  void _preloadAdjacentPages(int currentChapter) async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      // Preload range: current -2 to +2 (5 chapters total)
      final chapstersToPreload = <int>[];
      for (int offset = -2; offset <= 2; offset++) {
        final chapterNum = currentChapter + offset;
        if (chapterNum >= 1 && 
            chapterNum <= totalChapters && 
            !_preloadedChapters.contains(chapterNum)) {
          chapstersToPreload.add(chapterNum);
        }
      }

      // Preload in order of priority: current, +1, -1, +2, -2
      final priorityOrder = [
        currentChapter,
        currentChapter + 1,
        currentChapter - 1,
        currentChapter + 2,
        currentChapter - 2,
      ];

      for (final chapterNum in priorityOrder) {
        if (!chapstersToPreload.contains(chapterNum)) continue;
        
        final info = BibleData.getChapterInfo(chapterNum);
        
        // Preload the content in background (this triggers caching in BibleData)
        BibleData.getChapterContent(info['bookIndex'], info['chapterInBook']).ignore();
        BibleData.getChapterFootnotes(info['bookIndex'], info['chapterInBook']).ignore();
        
        _preloadedChapters.add(chapterNum);
      }
    } finally {
      _isPreloading = false;
    }
  }
}
