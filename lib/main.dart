// main.dart
import 'package:flutter/material.dart';
import 'bible_data.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMainApp();
  }

  _navigateToMainApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainReaderScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book,
                size: 80,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Holy Bible',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class MainReaderScreen extends StatefulWidget {
  const MainReaderScreen({super.key});

  @override
  State<MainReaderScreen> createState() => _MainReaderScreenState();
}

class _MainReaderScreenState extends State<MainReaderScreen> {
  late PageController _pageController;
  int currentGlobalChapter = 1; // Start with Genesis 1
  final int totalChapters = BibleData.getTotalChapters();
  double _fontSize = 18.0; // Default font size
  
  // Keep track of loaded pages to avoid unnecessary loading
  Set<int> loadedPages = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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
              icon: const Icon(Icons.chevron_left),
            ),
            
            // Chapter Info Rectangle
            Expanded(
              child: GestureDetector(
                onTap: _showChapterSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${chapterInfo['shortName']} ${chapterInfo['chapterInBook']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Right Arrow
            IconButton(
              onPressed: currentGlobalChapter < totalChapters ? _goToNextChapter : null,
              icon: const Icon(Icons.chevron_right),
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
            icon: const Icon(Icons.search),
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
            icon: const Icon(Icons.settings),
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

class ChapterContentPage extends StatefulWidget {
  final String bookName;
  final String shortName;
  final String arabicName;
  final int chapterNumber;
  final int bookIndex;
  final double fontSize;

  const ChapterContentPage({
    super.key,
    required this.bookName,
    required this.shortName,
    required this.arabicName,
    required this.chapterNumber,
    required this.bookIndex,
    required this.fontSize,
  });

  @override
  State<ChapterContentPage> createState() => _ChapterContentPageState();
}

class _ChapterContentPageState extends State<ChapterContentPage> {
  String chapterContent = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapterContent();
  }

  Future<void> _loadChapterContent() async {
    try {
      final content = await BibleData.getChapterContent(widget.bookIndex, widget.chapterNumber);
      if (mounted) {
        setState(() {
          chapterContent = content;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          chapterContent = 'Error loading chapter: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter Header
          Text(
            '${widget.bookName} ${widget.chapterNumber}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Chapter Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      // Main content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            alignment: chapterContent.contains(RegExp(r'[\u0600-\u06FF]'))
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: SelectableText(
                              chapterContent,
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                height: 1.8,
                                fontFamily: 'serif',
                              ),
                              textDirection: chapterContent.contains(RegExp(r'[\u0600-\u06FF]'))
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              textAlign: chapterContent.contains(RegExp(r'[\u0600-\u06FF]'))
                                  ? TextAlign.right
                                  : TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                      
                      // Footer
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${widget.arabicName} - افرايم بشرى برسوم (ترجمة فانديك منحقة باسم يَهْوِه)',
                          style: TextStyle(
                            fontSize: widget.fontSize * 0.8,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ChapterSelectorScreen extends StatelessWidget {
  final int currentChapter;
  final Function(int) onChapterSelected;

  const ChapterSelectorScreen({
    super.key,
    required this.currentChapter,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Book'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: BibleData.books.length,
        itemBuilder: (context, bookIndex) {
          final book = BibleData.books[bookIndex];
          final bookName = book['name'];
          final chapters = book['chapters'] as int;
          
          return ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(bookName),
            subtitle: Text('$chapters chapters'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookChapterSelector(
                    bookIndex: bookIndex,
                    bookName: bookName,
                    totalChapters: chapters,
                    currentChapter: currentChapter,
                    onChapterSelected: onChapterSelected,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookChapterSelector extends StatelessWidget {
  final int bookIndex;
  final String bookName;
  final int totalChapters;
  final int currentChapter;
  final Function(int) onChapterSelected;

  const BookChapterSelector({
    super.key,
    required this.bookIndex,
    required this.bookName,
    required this.totalChapters,
    required this.currentChapter,
    required this.onChapterSelected,
  });

  int _getGlobalChapterNumber(int chapterInBook) {
    int globalChapter = 1;
    for (int i = 0; i < bookIndex; i++) {
      globalChapter += BibleData.books[i]['chapters'] as int;
    }
    return globalChapter + chapterInBook - 1;
  }

  int _getCurrentChapterInBook() {
    final info = BibleData.getChapterInfo(currentChapter);
    if (info['bookIndex'] == bookIndex) {
      return info['chapterInBook'];
    }
    return -1; // Not in current book
  }

  @override
  Widget build(BuildContext context) {
    final currentChapterInBook = _getCurrentChapterInBook();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(bookName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Chapter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: totalChapters,
                itemBuilder: (context, index) {
                  final chapterNumber = index + 1;
                  final isCurrentChapter = chapterNumber == currentChapterInBook;
                  final globalChapter = _getGlobalChapterNumber(chapterNumber);
                  
                  return GestureDetector(
                    onTap: () {
                      onChapterSelected(globalChapter);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrentChapter ? Colors.blue : Colors.white,
                        border: Border.all(
                          color: isCurrentChapter ? Colors.blue : Colors.grey.shade300,
                          width: isCurrentChapter ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          if (isCurrentChapter)
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          chapterNumber.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentChapter ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
