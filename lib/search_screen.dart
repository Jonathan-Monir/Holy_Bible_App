// lib/search_screen.dart
import 'package:flutter/material.dart';
import 'bible_data.dart';

class SearchScreen extends StatefulWidget {
  final Function(int) onChapterSelected;

  const SearchScreen({
    super.key,
    required this.onChapterSelected,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    List<SearchResult> results = [];
    
    for (int bookIndex = 0; bookIndex < BibleData.books.length; bookIndex++) {
      final book = BibleData.books[bookIndex];
      final totalChapters = book['chapters'] as int;
      
      for (int chapter = 1; chapter <= totalChapters; chapter++) {
        try {
          final content = await BibleData.getChapterContent(bookIndex, chapter);
          
          if (BibleData.searchMatch(content, query)) {
            final lines = content.split('\n');
            for (String line in lines) {
              if (BibleData.searchMatch(line, query)) {
                results.add(SearchResult(
                  bookIndex: bookIndex,
                  bookName: book['name'],
                  arabicName: book['arabicName'],
                  chapterNumber: chapter,
                  verseText: line.trim(),
                ));
              }
            }
          }
        } catch (e) {
          print('Error searching in ${book['name']} $chapter: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  int _getGlobalChapter(int bookIndex, int chapterInBook) {
    int globalChapter = 1;
    for (int i = 0; i < bookIndex; i++) {
      globalChapter += BibleData.books[i]['chapters'] as int;
    }
    return globalChapter + chapterInBook - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Bible'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search in Bible...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: _performSearch,
            ),
          ),
          if (_isSearching)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(
                        '${result.bookName} ${result.chapterNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.arabicName,
                            style: const TextStyle(fontSize: 12),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.verseText,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                      onTap: () {
                        final globalChapter = _getGlobalChapter(
                          result.bookIndex,
                          result.chapterNumber,
                        );
                        widget.onChapterSelected(globalChapter);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Enter search term',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SearchResult {
  final int bookIndex;
  final String bookName;
  final String arabicName;
  final int chapterNumber;
  final String verseText;

  SearchResult({
    required this.bookIndex,
    required this.bookName,
    required this.arabicName,
    required this.chapterNumber,
    required this.verseText,
  });
}
