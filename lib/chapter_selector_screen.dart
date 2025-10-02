// lib/chapter_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bible_data.dart';
import 'book_chapter_selector.dart';
import 'theme_provider.dart';

class ChapterSelectorScreen extends StatefulWidget {
  final int currentChapter;
  final Function(int) onChapterSelected;

  const ChapterSelectorScreen({
    super.key,
    required this.currentChapter,
    required this.onChapterSelected,
  });

  @override
  State<ChapterSelectorScreen> createState() => _ChapterSelectorScreenState();
}

class _ChapterSelectorScreenState extends State<ChapterSelectorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  static const int oldTestamentCount = 39;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final currentBookIndex = BibleData.getChapterInfo(widget.currentChapter)['bookIndex'];
    if (currentBookIndex >= oldTestamentCount) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get oldTestamentBooks {
    return BibleData.books.take(oldTestamentCount).toList();
  }

  List<Map<String, dynamic>> get newTestamentBooks {
    return BibleData.books.skip(oldTestamentCount).toList();
  }

  Widget _buildBooksList(List<Map<String, dynamic>> books, int startIndex) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final bookIndex = startIndex + index;
        final arabicName = book['arabicName'];
        final chapters = book['chapters'] as int;
        
        final currentBookIndex = BibleData.getChapterInfo(widget.currentChapter)['bookIndex'];
        final isCurrentBook = bookIndex == currentBookIndex;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isCurrentBook ? 4 : 1,
          color: isCurrentBook 
              ? Theme.of(context).primaryColor.withOpacity(0.15) 
              : Theme.of(context).cardColor,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrentBook 
                    ? Theme.of(context).primaryColor 
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.menu_book,
                  color: isCurrentBook 
                      ? Colors.white 
                      : Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
            ),
            title: Text(
              arabicName,
              style: TextStyle(
                fontWeight: isCurrentBook ? FontWeight.bold : FontWeight.w500,
                color: isCurrentBook 
                    ? Theme.of(context).primaryColor 
                    : themeProvider.primaryTextColor,
                fontSize: 16,
                fontFamily: 'Amiri',
              ),
              textDirection: TextDirection.rtl,
            ),
            subtitle: Text(
              '$chapters ${chapters == 1 ? 'chapter' : 'chapters'}',
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.secondaryTextColor,
              ),
            ),
            trailing: Icon(
              Icons.chevron_left,
              color: isCurrentBook 
                  ? Theme.of(context).primaryColor 
                  : themeProvider.secondaryTextColor,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookChapterSelector(
                    bookIndex: bookIndex,
                    bookName: arabicName,
                    totalChapters: chapters,
                    currentChapter: widget.currentChapter,
                    onChapterSelected: widget.onChapterSelected,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Book',
          style: TextStyle(color: themeProvider.primaryTextColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.library_books, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Old Testament',
                          style: TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${oldTestamentBooks.length} books',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_stories, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'New Testament',
                          style: TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${newTestamentBooks.length} books',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: themeProvider.secondaryTextColor,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Old Testament
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey.shade50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 28,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.brown.shade300
                          : Colors.brown.shade600,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Old Testament',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.brown.shade300
                            : Colors.brown.shade800,
                      ),
                    ),
                    Text(
                      'العهد القديم',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.brown.shade300
                            : Colors.brown.shade600,
                        fontFamily: 'Amiri',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'Genesis to Malachi',
                      style: TextStyle(
                        fontSize: 11,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBooksList(oldTestamentBooks, 0),
              ),
            ],
          ),
          
          // New Testament
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey.shade50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: 28,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.indigo.shade300
                          : Colors.indigo.shade600,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'New Testament',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.indigo.shade300
                            : Colors.indigo.shade800,
                      ),
                    ),
                    Text(
                      'العهد الجديد',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.indigo.shade300
                            : Colors.indigo.shade600,
                        fontFamily: 'Amiri',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'Matthew to Revelation',
                      style: TextStyle(
                        fontSize: 11,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBooksList(newTestamentBooks, oldTestamentCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
