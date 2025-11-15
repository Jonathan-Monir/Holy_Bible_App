// lib/search_filter.dart
class SearchFilter {
  final Set<int> selectedBooks;
  final bool searchOldTestament;
  final bool searchNewTestament;
  
  SearchFilter({
    Set<int>? selectedBooks,
    this.searchOldTestament = true,
    this.searchNewTestament = true,
  }) : selectedBooks = selectedBooks ?? {};
  
  bool get hasCustomSelection => selectedBooks.isNotEmpty;
  
  bool shouldSearchBook(int bookIndex) {
    if (hasCustomSelection) {
      return selectedBooks.contains(bookIndex);
    }
    
    // Old Testament: books 0-38, New Testament: books 39-65
    if (bookIndex <= 38) {
      return searchOldTestament;
    } else {
      return searchNewTestament;
    }
  }
  
  SearchFilter copyWith({
    Set<int>? selectedBooks,
    bool? searchOldTestament,
    bool? searchNewTestament,
  }) {
    return SearchFilter(
      selectedBooks: selectedBooks ?? this.selectedBooks,
      searchOldTestament: searchOldTestament ?? this.searchOldTestament,
      searchNewTestament: searchNewTestament ?? this.searchNewTestament,
    );
  }
}
