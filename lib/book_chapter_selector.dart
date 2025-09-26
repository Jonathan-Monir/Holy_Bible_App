// lib/book_chapter_selector.dart
import 'package:flutter/material.dart';
import 'bible_data.dart';

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
