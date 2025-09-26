// lib/chapter_selector_screen.dart
import 'package:flutter/material.dart';
import 'bible_data.dart';
import 'book_chapter_selector.dart';

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
  
  // Old Testament books (Genesis to Malachi)
  static const int oldTestamentCount = 39;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set initial tab based on current chapter
    final currentBookIndex = BibleData.getChapterInfo(widget.currentChapter)['bookIndex'];
    if (currentBookIndex >= oldTestamentCount) {
      _tabController.index = 1; // New Testament
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
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final bookIndex = startIndex + index;
        final bookName = book['name'];
        final arabicName = book['arabicName'];
        final chapters = book['chapters'] as int;
        
        // Check if this is the current book
        final currentBookIndex = BibleData.getChapterInfo(widget.currentChapter)['bookIndex'];
        final isCurrentBook = bookIndex == currentBookIndex;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isCurrentBook ? 4 : 1,
          color: isCurrentBook ? Colors.blue.shade50 : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrentBook ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.menu_book,
                  color: isCurrentBook ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
            title: Text(
              bookName,
              style: TextStyle(
                fontWeight: isCurrentBook ? FontWeight.bold : FontWeight.w500,
                color: isCurrentBook ? Colors.blue.shade800 : Colors.black87,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabicName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 2),
                Text(
                  '$chapters ${chapters == 1 ? 'chapter' : 'chapters'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isCurrentBook ? Colors.blue : Colors.grey.shade400,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookChapterSelector(
                    bookIndex: bookIndex,
                    bookName: bookName,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Book'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.library_books, size: 18),
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
                  Icon(Icons.auto_stories, size: 18),
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
          labelColor: Colors.blue.shade800,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue,
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
                color: Colors.grey.shade50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 28,
                      color: Colors.brown.shade600,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Old Testament',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    Text(
                      'العهد القديم',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.brown.shade600,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'Genesis to Malachi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
                color: Colors.grey.shade50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: 28,
                      color: Colors.indigo.shade600,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'New Testament',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    Text(
                      'العهد الجديد',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo.shade600,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'Matthew to Revelation',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
