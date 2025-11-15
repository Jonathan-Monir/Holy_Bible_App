// lib/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bible_data.dart';
import 'theme_provider.dart';
import 'search_filter.dart';

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
  SearchFilter _filter = SearchFilter();
  
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

    // Check if it's a reference search (e.g., "تكوين 3:2")
    Map<String, int>? reference = BibleData.parseReference(query);
    if (reference != null) {
      await _searchByReference(reference);
      return;
    }

    // Regular text search
    await _searchByText(query);
  }

  Future<void> _searchByReference(Map<String, int> reference) async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    int bookIndex = reference['bookIndex']!;
    int chapter = reference['chapter']!;
    int? verse = reference['verse'];

    try {
      final book = BibleData.books[bookIndex];
      final content = await BibleData.getChapterContent(bookIndex, chapter);
      
      if (verse != null) {
        // Search for specific verse
        final lines = content.split('\n');
        for (String line in lines) {
          if (line.trim().startsWith('$verse')) {
            _searchResults.add(SearchResult(
              bookIndex: bookIndex,
              bookName: book['name'],
              arabicName: book['arabicName'],
              chapterNumber: chapter,
              verseNumber: verse,
              verseText: line.trim(),
            ));
            break;
          }
        }
      } else {
        // Show all verses in chapter
        final lines = content.split('\n');
        for (String line in lines) {
          if (line.trim().isNotEmpty) {
            RegExp versePattern = RegExp(r'^(\d+)(.*)');
            Match? match = versePattern.firstMatch(line.trim());
            if (match != null) {
              int verseNum = int.parse(match.group(1)!);
              _searchResults.add(SearchResult(
                bookIndex: bookIndex,
                bookName: book['name'],
                arabicName: book['arabicName'],
                chapterNumber: chapter,
                verseNumber: verseNum,
                verseText: line.trim(),
              ));
            }
          }
        }
      }
    } catch (e) {
      print('Error searching reference: $e');
    }

    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _searchByText(String query) async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    List<SearchResult> results = [];
    
    for (int bookIndex = 0; bookIndex < BibleData.books.length; bookIndex++) {
      // Apply filter
      if (!_filter.shouldSearchBook(bookIndex)) {
        continue;
      }

      final book = BibleData.books[bookIndex];
      final totalChapters = book['chapters'] as int;
      
      for (int chapter = 1; chapter <= totalChapters; chapter++) {
        try {
          final content = await BibleData.getChapterContent(bookIndex, chapter);
          
          if (BibleData.searchMatch(content, query)) {
            final lines = content.split('\n');
            for (String line in lines) {
              if (BibleData.searchMatch(line, query)) {
                RegExp versePattern = RegExp(r'^(\d+)(.*)');
                Match? match = versePattern.firstMatch(line.trim());
                int? verseNum;
                if (match != null) {
                  verseNum = int.tryParse(match.group(1)!);
                }
                
                results.add(SearchResult(
                  bookIndex: bookIndex,
                  bookName: book['name'],
                  arabicName: book['arabicName'],
                  chapterNumber: chapter,
                  verseNumber: verseNum,
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        currentFilter: _filter,
        onFilterChanged: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
          // Re-search if there's a query
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
      ),
    );
  }

  String _getFilterSummary() {
    if (_filter.hasCustomSelection) {
      return '${_filter.selectedBooks.length} books selected';
    }
    if (_filter.searchOldTestament && _filter.searchNewTestament) {
      return 'All books';
    }
    if (_filter.searchOldTestament) {
      return 'Old Testament';
    }
    if (_filter.searchNewTestament) {
      return 'New Testament';
    }
    return 'No books selected';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Bible',
          style: TextStyle(color: themeProvider.primaryTextColor),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: themeProvider.primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: themeProvider.secondaryTextColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: themeProvider.secondaryTextColor),
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: themeProvider.secondaryTextColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: _performSearch,
            ),
          ),
          
          // Filter chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getFilterSummary(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results
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
                    Icon(Icons.search_off, size: 64, color: themeProvider.secondaryTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(
                        fontSize: 18,
                        color: themeProvider.secondaryTextColor,
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
                        '${result.bookName} ${result.chapterNumber}${result.verseNumber != null ? ':${result.verseNumber}' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: themeProvider.primaryTextColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.arabicName,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.secondaryTextColor,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.verseText,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: themeProvider.primaryTextColor,
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
                    Icon(Icons.search, size: 64, color: themeProvider.secondaryTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Enter search term or reference',
                      style: TextStyle(
                        fontSize: 18,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor,
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

class _FilterDialog extends StatefulWidget {
  final SearchFilter currentFilter;
  final Function(SearchFilter) onFilterChanged;

  const _FilterDialog({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late bool _searchOT;
  late bool _searchNT;
  late Set<int> _selectedBooks;
  bool _showCustomSelection = false;

  @override
  void initState() {
    super.initState();
    _searchOT = widget.currentFilter.searchOldTestament;
    _searchNT = widget.currentFilter.searchNewTestament;
    _selectedBooks = Set.from(widget.currentFilter.selectedBooks);
    _showCustomSelection = widget.currentFilter.hasCustomSelection;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(
        'Search Filters',
        style: TextStyle(color: themeProvider.primaryTextColor),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Testament filters
            if (!_showCustomSelection) ...[
              CheckboxListTile(
                title: Text(
                  'Old Testament (39 books)',
                  style: TextStyle(color: themeProvider.primaryTextColor),
                ),
                value: _searchOT,
                onChanged: (value) {
                  setState(() {
                    _searchOT = value ?? true;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              CheckboxListTile(
                title: Text(
                  'New Testament (27 books)',
                  style: TextStyle(color: themeProvider.primaryTextColor),
                ),
                value: _searchNT,
                onChanged: (value) {
                  setState(() {
                    _searchNT = value ?? true;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              const Divider(),
            ],
            
            // Custom book selection toggle
            ListTile(
              title: Text(
                'Select specific books',
                style: TextStyle(color: themeProvider.primaryTextColor),
              ),
              trailing: Switch(
                value: _showCustomSelection,
                onChanged: (value) {
                  setState(() {
                    _showCustomSelection = value;
                    if (!value) {
                      _selectedBooks.clear();
                    }
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
            
            // Book list
            if (_showCustomSelection) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedBooks.addAll(List.generate(66, (i) => i));
                      });
                    },
                    child: const Text('Select All'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedBooks.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: BibleData.books.length,
                  itemBuilder: (context, index) {
                    final book = BibleData.books[index];
                    final isSelected = _selectedBooks.contains(index);
                    
                    return CheckboxListTile(
                      dense: true,
                      title: Text(
                        '${book['name']} - ${book['arabicName']}',
                        style: TextStyle(
                          color: themeProvider.primaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedBooks.add(index);
                          } else {
                            _selectedBooks.remove(index);
                          }
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
        ),
        TextButton(
          onPressed: () {
            widget.onFilterChanged(SearchFilter(
              selectedBooks: _showCustomSelection ? _selectedBooks : {},
              searchOldTestament: _searchOT,
              searchNewTestament: _searchNT,
            ));
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class SearchResult {
  final int bookIndex;
  final String bookName;
  final String arabicName;
  final int chapterNumber;
  final int? verseNumber;
  final String verseText;

  SearchResult({
    required this.bookIndex,
    required this.bookName,
    required this.arabicName,
    required this.chapterNumber,
    this.verseNumber,
    required this.verseText,
  });
}
