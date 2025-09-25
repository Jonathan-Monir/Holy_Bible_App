// search_screen.dart
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

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
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

    try {
      // Search through all books
      for (int bookIndex = 0; bookIndex < BibleData.books.length; bookIndex++) {
        final book = BibleData.books[bookIndex];
        final bookName = book['name'];
        final totalChapters = book['chapters'] as int;

        try {
          // Try to load and search in this book
          for (int chapter = 1; chapter <= totalChapters; chapter++) {
            final content = await BibleData.getChapterContent(bookIndex, chapter);
            
            // Skip if content is placeholder or error message (file not found)
            if (content.contains('غير متوفر') || 
                content.contains('not available') ||
                content.contains('غير موجود') ||
                content.contains('will be added') ||
                content.contains('سيتم إضافته قريباً')) {
              continue;
            }

            // Use the new tashkeel-insensitive search
            if (BibleData.searchMatch(content, query)) {
              
              // Find the specific verse containing the search term
              final lines = content.split('\n');
              for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
                final line = lines[lineIndex];
                if (BibleData.searchMatch(line, query)) {
                  // Extract verse number if present
                  final verseMatch = RegExp(r'^(\d+)').firstMatch(line.trim());
                  final verseNumber = verseMatch?.group(1) ?? '';
                  
                  results.add(SearchResult(
                    bookName: bookName,
                    bookIndex: bookIndex,
                    chapterNumber: chapter,
                    verseNumber: verseNumber,
                    text: line.trim(),
                    query: query,
                  ));
                  
                  // Limit results per chapter to avoid too many results
                  if (results.length >= 100) break;
                }
              }
            }
            
            if (results.length >= 100) break;
          }
        } catch (e) {
          // Skip books that can't be loaded
          print('Error searching in book $bookName: $e');
          continue;
        }
        
        if (results.length >= 100) break;
      }
    } catch (e) {
      print('Search error: $e');
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  int _getGlobalChapter(int bookIndex, int chapterNumber) {
    int globalChapter = 1;
    for (int i = 0; i < bookIndex; i++) {
      globalChapter += BibleData.books[i]['chapters'] as int;
    }
    return globalChapter + chapterNumber - 1;
  }

  void _navigateToChapter(SearchResult result) {
    try {
      final globalChapter = _getGlobalChapter(result.bookIndex, result.chapterNumber);
      
      // Validate the global chapter number
      final totalChapters = BibleData.getTotalChapters();
      if (globalChapter < 1 || globalChapter > totalChapters) {
        print('Invalid global chapter: $globalChapter');
        _showErrorDialog('Invalid chapter selection');
        return;
      }
      
      // Call the navigation function
      widget.onChapterSelected(globalChapter);
      
      // Pop the search screen safely
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Navigation error: $e');
      _showErrorDialog('Error navigating to chapter');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          // Search input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search for words or verses...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _performSearch(),
                        enabled: !_isSearching,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _performSearch,
                      child: _isSearching 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Searching...'),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Enter search terms above'
                                  : 'No results found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Try searching without diacritics (تشكيل)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Results count
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  'Found ${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (_searchResults.length >= 100)
                                  Text(
                                    ' (showing first 100)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Results list
                          Expanded(
                            child: ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final result = _searchResults[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      '${result.bookName} ${result.chapterNumber}${result.verseNumber.isNotEmpty ? ':${result.verseNumber}' : ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Container(
                                      alignment: result.text.contains(RegExp(r'[\u0600-\u06FF]'))
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Text(
                                        _highlightSearchTerm(result.text, result.query),
                                        textDirection: result.text.contains(RegExp(r'[\u0600-\u06FF]'))
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                        textAlign: result.text.contains(RegExp(r'[\u0600-\u06FF]'))
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onTap: () => _navigateToChapter(result),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  String _highlightSearchTerm(String text, String query) {
    // For now, just return the text as-is
    // In a more advanced version, you could wrap the search term with special characters
    return text;
  }
}

class SearchResult {
  final String bookName;
  final int bookIndex;
  final int chapterNumber;
  final String verseNumber;
  final String text;
  final String query;

  SearchResult({
    required this.bookName,
    required this.bookIndex,
    required this.chapterNumber,
    required this.verseNumber,
    required this.text,
    required this.query,
  });
}
