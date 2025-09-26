// lib/chapter_content_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bible_data.dart';

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
  List<VerseData> verses = [];
  Set<int> selectedVerses = <int>{};
  Map<String, Set<int>> highlightedVerses = <String, Set<int>>{};
  Map<String, Set<int>> underlinedVerses = <String, Set<int>>{};

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void didUpdateWidget(ChapterContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if chapter changed
    if (oldWidget.bookIndex != widget.bookIndex || oldWidget.chapterNumber != widget.chapterNumber) {
      _loadSavedData();
    }
  }

  String get _chapterKey => '${widget.bookIndex}_${widget.chapterNumber}';

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load highlighted verses
      final highlightedData = prefs.getString('highlighted_verses') ?? '{}';
      final highlightedMap = json.decode(highlightedData) as Map<String, dynamic>;
      highlightedVerses = {};
      for (String key in highlightedMap.keys) {
        if (highlightedMap[key] is List) {
          highlightedVerses[key] = Set<int>.from(highlightedMap[key].cast<int>());
        }
      }
      
      // Load underlined verses
      final underlinedData = prefs.getString('underlined_verses') ?? '{}';
      final underlinedMap = json.decode(underlinedData) as Map<String, dynamic>;
      underlinedVerses = {};
      for (String key in underlinedMap.keys) {
        if (underlinedMap[key] is List) {
          underlinedVerses[key] = Set<int>.from(underlinedMap[key].cast<int>());
        }
      }
      
      // Load chapter content after loading saved data
      await _loadChapterContent();
    } catch (e) {
      print('Error loading saved data: $e');
      // Still load chapter content even if saved data fails
      await _loadChapterContent();
    }
  }

  Future<void> _saveHighlightedVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, List<int>>{};
      for (String key in highlightedVerses.keys) {
        data[key] = highlightedVerses[key]!.toList();
      }
      await prefs.setString('highlighted_verses', json.encode(data));
    } catch (e) {
      print('Error saving highlighted verses: $e');
    }
  }

  Future<void> _saveUnderlinedVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, List<int>>{};
      for (String key in underlinedVerses.keys) {
        data[key] = underlinedVerses[key]!.toList();
      }
      await prefs.setString('underlined_verses', json.encode(data));
    } catch (e) {
      print('Error saving underlined verses: $e');
    }
  }

  Future<void> _loadChapterContent() async {
    try {
      final content = await BibleData.getChapterContent(widget.bookIndex, widget.chapterNumber);
      if (mounted) {
        setState(() {
          chapterContent = content;
          verses = _parseVersesToList(content);
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

  List<VerseData> _parseVersesToList(String content) {
    List<VerseData> verseList = [];
    
    // Split content by verses (assuming verses start with numbers)
    List<String> lines = content.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Check if line starts with a verse number
      RegExp versePattern = RegExp(r'^(\d+)(.*)');
      Match? match = versePattern.firstMatch(line.trim());
      
      if (match != null) {
        int verseNumber = int.parse(match.group(1)!);
        String verseText = match.group(2)!.trim();
        
        if (verseText.isNotEmpty) {
          verseList.add(VerseData(
            number: verseNumber,
            text: verseText,
            isHighlighted: highlightedVerses[_chapterKey]?.contains(verseNumber) ?? false,
            isUnderlined: underlinedVerses[_chapterKey]?.contains(verseNumber) ?? false,
          ));
        }
      } else {
        // If it's not a numbered verse, add it as verse 0 (chapter title or other content)
        if (line.trim().isNotEmpty) {
          verseList.add(VerseData(
            number: 0,
            text: line.trim(),
            isHighlighted: false,
            isUnderlined: false,
          ));
        }
      }
    }
    
    return verseList;
  }

  void _toggleVerseSelection(int verseNumber) {
    if (verseNumber == 0) return; // Don't select chapter titles
    
    setState(() {
      if (selectedVerses.contains(verseNumber)) {
        selectedVerses.remove(verseNumber);
      } else {
        selectedVerses.add(verseNumber);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedVerses.clear();
    });
  }

  String _getSelectedVersesText() {
    List<int> sortedVerses = selectedVerses.toList()..sort();
    List<String> verseTexts = [];
    
    for (int verseNumber in sortedVerses) {
      final verse = verses.firstWhere((v) => v.number == verseNumber, 
          orElse: () => VerseData(number: 0, text: ''));
      if (verse.number != 0) {
        verseTexts.add('${widget.shortName} ${widget.chapterNumber}:$verseNumber - ${verse.text}');
      }
    }
    
    return verseTexts.join('\n\n');
  }

  void _highlightSelectedVerses() async {
    if (selectedVerses.isEmpty) return;
    
    setState(() {
      if (!highlightedVerses.containsKey(_chapterKey)) {
        highlightedVerses[_chapterKey] = <int>{};
      }
      
      for (int verseNumber in selectedVerses) {
        if (highlightedVerses[_chapterKey]!.contains(verseNumber)) {
          highlightedVerses[_chapterKey]!.remove(verseNumber);
        } else {
          highlightedVerses[_chapterKey]!.add(verseNumber);
        }
      }
      
      // Update verses display state
      for (int i = 0; i < verses.length; i++) {
        if (selectedVerses.contains(verses[i].number)) {
          verses[i] = VerseData(
            number: verses[i].number,
            text: verses[i].text,
            isHighlighted: highlightedVerses[_chapterKey]?.contains(verses[i].number) ?? false,
            isUnderlined: verses[i].isUnderlined,
          );
        }
      }
    });
    
    await _saveHighlightedVerses();
    _clearSelection();
  }

  void _underlineSelectedVerses() async {
    if (selectedVerses.isEmpty) return;
    
    setState(() {
      if (!underlinedVerses.containsKey(_chapterKey)) {
        underlinedVerses[_chapterKey] = <int>{};
      }
      
      for (int verseNumber in selectedVerses) {
        if (underlinedVerses[_chapterKey]!.contains(verseNumber)) {
          underlinedVerses[_chapterKey]!.remove(verseNumber);
        } else {
          underlinedVerses[_chapterKey]!.add(verseNumber);
        }
      }
      
      // Update verses display state
      for (int i = 0; i < verses.length; i++) {
        if (selectedVerses.contains(verses[i].number)) {
          verses[i] = VerseData(
            number: verses[i].number,
            text: verses[i].text,
            isHighlighted: verses[i].isHighlighted,
            isUnderlined: underlinedVerses[_chapterKey]?.contains(verses[i].number) ?? false,
          );
        }
      }
    });
    
    await _saveUnderlinedVerses();
    _clearSelection();
  }

  void _shareSelectedVerses() {
    final text = _getSelectedVersesText();
    if (text.isNotEmpty) {
      Share.share(text);
    }
    _clearSelection();
  }

  void _copySelectedVerses() {
    final text = _getSelectedVersesText();
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedVerses.length} verse${selectedVerses.length > 1 ? 's' : ''} copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _clearSelection();
  }

  Widget _buildVerseWidget(VerseData verse) {
    bool isHighlighted = highlightedVerses[_chapterKey]?.contains(verse.number) ?? false;
    bool isUnderlined = underlinedVerses[_chapterKey]?.contains(verse.number) ?? false;
    bool isSelected = selectedVerses.contains(verse.number);
    bool isArabic = verse.text.contains(RegExp(r'[\u0600-\u06FF]'));

    return GestureDetector(
      onTap: () {
        if (verse.number > 0) {
          _toggleVerseSelection(verse.number);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.yellow.withOpacity(0.3) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: RichText(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          text: TextSpan(
            children: [
              if (verse.number > 0)
                TextSpan(
                  text: '${verse.number} ',
                  style: TextStyle(
                    fontSize: widget.fontSize * 0.8,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue.shade800 : Colors.blue.shade700,
                    fontFamily: 'serif',
                  ),
                ),
              TextSpan(
                text: verse.text,
                style: TextStyle(
                  fontSize: verse.number == 0 ? widget.fontSize * 1.1 : widget.fontSize,
                  fontWeight: verse.number == 0 ? FontWeight.bold : FontWeight.normal,
                  height: 1.8,
                  color: isSelected ? Colors.blue.shade800 : Colors.black87,
                  fontFamily: 'serif',
                  decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: Colors.blue,
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedVerses.isNotEmpty;
    
    return Scaffold(
      appBar: hasSelection
          ? AppBar(
              backgroundColor: Colors.blue.shade600,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearSelection,
              ),
              title: Text(
                '${selectedVerses.length} verse${selectedVerses.length > 1 ? 's' : ''} selected',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.highlight, color: Colors.white),
                  onPressed: _highlightSelectedVerses,
                  tooltip: 'Highlight verses',
                ),
                IconButton(
                  icon: const Icon(Icons.format_underlined, color: Colors.white),
                  onPressed: _underlineSelectedVerses,
                  tooltip: 'Underline verses',
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: _copySelectedVerses,
                  tooltip: 'Copy verses',
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareSelectedVerses,
                  tooltip: 'Share verses',
                ),
              ],
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasSelection) ...[
              // Chapter Header
              Text(
                '${widget.bookName} ${widget.chapterNumber}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Chapter Content
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        // Selection info banner
                        if (hasSelection)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Tap verses to select multiple. Selected: ${selectedVerses.map((v) => v.toString()).join(', ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        
                        // Main content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              alignment: chapterContent.contains(RegExp(r'[\u0600-\u06FF]'))
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: chapterContent.contains(RegExp(r'[\u0600-\u06FF]'))
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: verses.map((verse) => _buildVerseWidget(verse)).toList(),
                              ),
                            ),
                          ),
                        ),
                        
                        // Footer
                        if (!hasSelection) ...[
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
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerseData {
  final int number;
  final String text;
  final bool isHighlighted;
  final bool isUnderlined;

  VerseData({
    required this.number,
    required this.text,
    this.isHighlighted = false,
    this.isUnderlined = false,
  });
}
