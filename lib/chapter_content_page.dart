// lib/chapter_content_page.dart

import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bible_data.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class ChapterContentPage extends StatefulWidget {
  final String bookName;
  final String shortName;
  final String arabicName;
  final int chapterNumber;
  final int bookIndex;
  final double fontSize;
  final String fontFamily;
  final bool removeDiacritics;

  const ChapterContentPage({
    super.key,
    required this.bookName,
    required this.shortName,
    required this.arabicName,
    required this.chapterNumber,
    required this.bookIndex,
    required this.fontSize,
    required this.fontFamily,
    required this.removeDiacritics,
  });

  @override
  State<ChapterContentPage> createState() => _ChapterContentPageState();
}

class _ChapterContentPageState extends State<ChapterContentPage> {
  String chapterContent = '';
  bool isLoading = true;
  List<VerseData> verses = [];
  Map<int, int> verseOffsets = {};
  Map<String, Map<int, List<TextRange>>> highlightedRanges = <String, Map<int, List<TextRange>>>{};
  Map<String, Map<int, List<TextRange>>> underlinedRanges = <String, Map<int, List<TextRange>>>{};
  String footnotes = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void didUpdateWidget(ChapterContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookIndex != widget.bookIndex || 
        oldWidget.chapterNumber != widget.chapterNumber ||
        oldWidget.removeDiacritics != widget.removeDiacritics) {
      _loadSavedData();
    }
  }

  String get _chapterKey => '${widget.bookIndex}_${widget.chapterNumber}';

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final highlightedData = prefs.getString('highlighted_ranges') ?? '{}';
      final highlightedMap = json.decode(highlightedData) as Map<String, dynamic>;
      highlightedRanges = {};
      for (String key in highlightedMap.keys) {
        final chapterMap = highlightedMap[key] as Map<String, dynamic>;
        highlightedRanges[key] = {};
        for (String verseStr in chapterMap.keys) {
          int verseNum = int.parse(verseStr);
          final rangesList = chapterMap[verseStr] as List<dynamic>;
          highlightedRanges[key]![verseNum] = rangesList.map((r) => TextRange(start: r['start'], end: r['end'])).toList();
        }
      }
      
      final underlinedData = prefs.getString('underlined_ranges') ?? '{}';
      final underlinedMap = json.decode(underlinedData) as Map<String, dynamic>;
      underlinedRanges = {};
      for (String key in underlinedMap.keys) {
        final chapterMap = underlinedMap[key] as Map<String, dynamic>;
        underlinedRanges[key] = {};
        for (String verseStr in chapterMap.keys) {
          int verseNum = int.parse(verseStr);
          final rangesList = chapterMap[verseStr] as List<dynamic>;
          underlinedRanges[key]![verseNum] = rangesList.map((r) => TextRange(start: r['start'], end: r['end'])).toList();
        }
      }
      
      await _loadChapterContent();
    } catch (e) {
      print('Error loading saved data: $e');
      await _loadChapterContent();
    }
  }

  Future<void> _saveHighlightedRanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, Map<String, List<Map<String, int>>>>{};
      for (String key in highlightedRanges.keys) {
        data[key] = {};
        for (int verse in highlightedRanges[key]!.keys) {
          data[key]![verse.toString()] = highlightedRanges[key]![verse]!.map((r) => {'start': r.start, 'end': r.end}).toList();
        }
      }
      await prefs.setString('highlighted_ranges', json.encode(data));
    } catch (e) {
      print('Error saving highlighted ranges: $e');
    }
  }

  Future<void> _saveUnderlinedRanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, Map<String, List<Map<String, int>>>>{};
      for (String key in underlinedRanges.keys) {
        data[key] = {};
        for (int verse in underlinedRanges[key]!.keys) {
          data[key]![verse.toString()] = underlinedRanges[key]![verse]!.map((r) => {'start': r.start, 'end': r.end}).toList();
        }
      }
      await prefs.setString('underlined_ranges', json.encode(data));
    } catch (e) {
      print('Error saving underlined ranges: $e');
    }
  }

  Future<void> _clearAllHighlights() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Clear All Highlights',
          style: TextStyle(color: themeProvider.primaryTextColor),
        ),
        content: Text(
          'Are you sure you want to remove all highlights and underlines from this chapter?',
          style: TextStyle(color: themeProvider.primaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        highlightedRanges.remove(_chapterKey);
        underlinedRanges.remove(_chapterKey);
      });
      await _saveHighlightedRanges();
      await _saveUnderlinedRanges();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All highlights cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadChapterContent() async {
    try {
      final content = await BibleData.getChapterContent(widget.bookIndex, widget.chapterNumber);
      final fn = await BibleData.getChapterFootnotes(widget.bookIndex, widget.chapterNumber);
      if (mounted) {
        setState(() {
          chapterContent = content;
          verses = _parseVersesToList(content);
          verseOffsets = _computeVerseOffsets(verses);
          footnotes = fn;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          chapterContent = 'Error loading chapter: $e';
          footnotes = '';
          isLoading = false;
        });
      }
    }
  }

  List<VerseData> _parseVersesToList(String content) {
    List<VerseData> verseList = [];
    List<String> lines = content.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      RegExp versePattern = RegExp(r'^(\d+)(.*)');
      Match? match = versePattern.firstMatch(line.trim());
      
      if (match != null) {
        int verseNumber = int.parse(match.group(1)!);
        String verseText = match.group(2)!.trim();
        
        if (verseText.isNotEmpty) {
          verseList.add(VerseData(number: verseNumber, text: verseText));
        }
      } else {
        if (line.trim().isNotEmpty) {
          verseList.add(VerseData(number: 0, text: line.trim()));
        }
      }
    }
    
    return verseList;
  }

  Map<int, int> _computeVerseOffsets(List<VerseData> verses) {
    Map<int, int> offsets = {};
    int currentOffset = 0;
    for (var verse in verses) {
      if (verse.number == 0) {
        currentOffset += verse.text.length + 2;
        continue;
      }
      offsets[verse.number] = currentOffset + verse.number.toString().length + 1;
      currentOffset += verse.number.toString().length + verse.text.length + 2;
    }
    return offsets;
  }

  List<TextRange> _toggleRange(List<TextRange> currentRanges, TextRange toggle) {
    List<TextRange> merged = _mergeRanges(currentRanges);
    
    List<TextRange> subtracted = [];
    for (var r in merged) {
      if (r.end <= toggle.start || r.start >= toggle.end) {
        subtracted.add(r);
      } else {
        if (r.start < toggle.start) {
          subtracted.add(TextRange(start: r.start, end: toggle.start));
        }
        if (r.end > toggle.end) {
          subtracted.add(TextRange(start: toggle.end, end: r.end));
        }
      }
    }
    
    List<TextRange> addParts = [];
    int currentStart = toggle.start;
    for (var r in merged..sort((a, b) => a.start.compareTo(b.start))) {
      if (currentStart < r.start) {
        addParts.add(TextRange(start: currentStart, end: min(toggle.end, r.start)));
      }
      currentStart = max(currentStart, r.end);
    }
    if (currentStart < toggle.end) {
      addParts.add(TextRange(start: currentStart, end: toggle.end));
    }
    
    return _mergeRanges([...subtracted, ...addParts]);
  }

  List<TextRange> _mergeRanges(List<TextRange> ranges) {
    if (ranges.isEmpty) return [];
    List<TextRange> sorted = ranges..sort((a, b) => a.start.compareTo(b.start));
    List<TextRange> merged = [sorted[0]];
    for (var r in sorted.skip(1)) {
      TextRange last = merged.last;
      if (r.start <= last.end) {
        merged[merged.length - 1] = TextRange(start: last.start, end: max(last.end, r.end));
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  TextStyle _getFontStyle(bool isArabic) {
    if (!isArabic) return TextStyle(fontSize: widget.fontSize, fontFamily: 'serif');
    
    switch (widget.fontFamily) {
      case 'Amiri':
        return TextStyle(fontFamily: 'Amiri', fontSize: widget.fontSize);
      case 'Cairo':
        return GoogleFonts.cairo(fontSize: widget.fontSize);
      case 'Lateef':
        return GoogleFonts.lateef(fontSize: widget.fontSize);
      case 'Scheherazade New':
        return GoogleFonts.scheherazadeNew(fontSize: widget.fontSize);
      case 'Markazi Text':
        return GoogleFonts.markaziText(fontSize: widget.fontSize);
      case 'Noto Naskh Arabic':
        return GoogleFonts.notoNaskhArabic(fontSize: widget.fontSize);
      default:
        return TextStyle(fontFamily: 'Amiri', fontSize: widget.fontSize);
    }
  }

  Widget _buildVerseWidget(VerseData verse, bool isArabic) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (verse.number == 0) {
      String displayText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Align(
          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            displayText,
            style: _getFontStyle(isArabic).copyWith(
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryTextColor,
              fontSize: widget.fontSize * 1.1,
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
          ),
        ),
      );
    }

    List<TextRange> hlRanges = highlightedRanges[_chapterKey]?[verse.number] ?? [];
    List<TextRange> ulRanges = underlinedRanges[_chapterKey]?[verse.number] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Text(
              '${verse.number}',
              style: TextStyle(
                fontSize: widget.fontSize * 0.8,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontFamily: isArabic ? widget.fontFamily : 'serif',
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: _buildVerseSpansForWidget(verse.text, hlRanges, ulRanges, isArabic),
              ),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: TextAlign.start,
              contextMenuBuilder: (context, editableTextState) {
                return _buildVerseContextMenu(context, editableTextState, verse.number, isArabic);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildVerseSpansForWidget(String verseText, List<TextRange> hlRanges, List<TextRange> ulRanges, bool isArabic) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (verseText.isEmpty) return [TextSpan(text: verseText)];

    String processedText = widget.removeDiacritics ? BibleData.removeTashkeel(verseText) : verseText;
    String displayText = '\u200F$processedText';

    Set<int> points = {0, displayText.length};
    for (var r in [...hlRanges, ...ulRanges]) {
      points.add(r.start + 1);
      points.add(r.end + 1);
    }
    List<int> sortedPoints = points.toList()..sort();

    List<TextSpan> spans = [];
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      int start = sortedPoints[i];
      int end = sortedPoints[i + 1];

      bool isHighlighted = hlRanges.any((r) => r.start + 1 <= start && r.end + 1 >= end);
      bool isUnderlined = ulRanges.any((r) => r.start + 1 <= start && r.end + 1 >= end);

      spans.add(TextSpan(
        text: displayText.substring(start, end),
        style: _getFontStyle(isArabic).copyWith(
          fontWeight: FontWeight.normal,
          height: 1.8,
          color: themeProvider.primaryTextColor,
          backgroundColor: isHighlighted ? Colors.yellow : null,
          decoration: isUnderlined ? TextDecoration.underline : null,
          decorationColor: Theme.of(context).primaryColor,
          decorationThickness: 2,
        ),
      ));
    }
    return spans;
  }

  Widget _buildVerseContextMenu(BuildContext context, EditableTextState editableTextState, int verseNumber, bool isArabic) {
    final TextEditingValue value = editableTextState.textEditingValue;
    final TextSelection selection = value.selection;

    if (!selection.isValid || selection.isCollapsed) {
      return const SizedBox.shrink();
    }

    final String selectedText = value.text.substring(selection.start, selection.end);

    List<ContextMenuButtonItem> buttonItems = [];
    
    buttonItems.add(
      ContextMenuButtonItem(
        label: isArabic ? 'نسخ' : 'Copy',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: selectedText));
          editableTextState.hideToolbar();
        },
      ),
    );

    buttonItems.addAll([
      ContextMenuButtonItem(
        label: isArabic ? 'مشاركة' : 'Share',
        onPressed: () {
          Share.share(selectedText);
          editableTextState.hideToolbar();
        },
      ),
      ContextMenuButtonItem(
        label: isArabic ? 'تمييز' : 'Highlight',
        onPressed: () {
          _handleVerseHighlight(selection, verseNumber);
          editableTextState.hideToolbar();
        },
      ),
      ContextMenuButtonItem(
        label: isArabic ? 'تسطير' : 'Underline',
        onPressed: () {
          _handleVerseUnderline(selection, verseNumber);
          editableTextState.hideToolbar();
        },
      ),
    ]);

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  void _handleVerseHighlight(TextSelection selection, int verseNumber) {
    if (selection.isCollapsed) return;

    int adjustedStart = max(0, selection.start - 1);
    int adjustedEnd = max(0, selection.end - 1);
    TextRange tr = TextRange(start: adjustedStart, end: adjustedEnd);

    setState(() {
      if (!highlightedRanges.containsKey(_chapterKey)) highlightedRanges[_chapterKey] = {};
      if (!highlightedRanges[_chapterKey]!.containsKey(verseNumber)) highlightedRanges[_chapterKey]![verseNumber] = [];
      highlightedRanges[_chapterKey]![verseNumber] = _toggleRange(highlightedRanges[_chapterKey]![verseNumber]!, tr);
    });

    _saveHighlightedRanges();
  }

  void _handleVerseUnderline(TextSelection selection, int verseNumber) {
    if (selection.isCollapsed) return;
    
    int adjustedStart = max(0, selection.start - 1);
    int adjustedEnd = max(0, selection.end - 1);
    TextRange tr = TextRange(start: adjustedStart, end: adjustedEnd);
    
    setState(() {
      if (!underlinedRanges.containsKey(_chapterKey)) underlinedRanges[_chapterKey] = {};
      if (!underlinedRanges[_chapterKey]!.containsKey(verseNumber)) underlinedRanges[_chapterKey]![verseNumber] = [];
      underlinedRanges[_chapterKey]![verseNumber] = _toggleRange(underlinedRanges[_chapterKey]![verseNumber]!, tr);
    });
    
    _saveUnderlinedRanges();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isArabic = chapterContent.contains(RegExp(r'[\u0600-\u06FF]'));
    
    // Split footnotes into individual lines
    List<String> rawNotes = footnotes.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    String? chapterSubtitle;
    List<String> noteList = rawNotes;
    if (rawNotes.isNotEmpty) {
      String firstLineClean = BibleData.removeTashkeel(rawNotes[0]);
      if (RegExp(r'^الإصحاح \S+$').hasMatch(firstLineClean)) {
        chapterSubtitle = rawNotes[0];
        noteList = rawNotes.skip(1).toList();
      }
    }

    bool hasHighlights = (highlightedRanges[_chapterKey]?.isNotEmpty ?? false) || 
                        (underlinedRanges[_chapterKey]?.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${widget.bookName} ${widget.chapterNumber}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryTextColor,
                  ),
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
              if (hasHighlights)
                IconButton(
                  onPressed: _clearAllHighlights,
                  icon: const Icon(Icons.highlight_off),
                  tooltip: 'Clear all highlights',
                  color: Colors.red.shade700,
                  iconSize: 28,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        ...verses.map((verse) => _buildVerseWidget(verse, isArabic)).toList(),
                        
                        // UPDATED FOOTNOTES SECTION WITH NUMBERING
                        if (noteList.isNotEmpty || chapterSubtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Column(
                              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 100,
                                    height: 1,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Footnotes',
                                  style: TextStyle(
                                    fontSize: widget.fontSize * 0.9,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (chapterSubtitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Align(
                                      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Text(
                                        chapterSubtitle!,
                                        style: _getFontStyle(isArabic).copyWith(
                                          fontSize: widget.fontSize * 1.1,
                                          fontWeight: FontWeight.bold,
                                          color: themeProvider.primaryTextColor,
                                        ),
                                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                      ),
                                    ),
                                  ),
                                ...List.generate(noteList.length, (index) {
                                  String noteText = widget.removeDiacritics 
                                      ? BibleData.removeTashkeel(noteList[index])
                                      : noteList[index];
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(left: 8, right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: widget.fontSize * 0.75,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: SelectableText(
                                            noteText,
                                            style: _getFontStyle(isArabic).copyWith(
                                              fontSize: widget.fontSize * 0.85,
                                              color: themeProvider.secondaryTextColor,
                                              height: 1.6,
                                            ),
                                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              '${widget.arabicName} - افرايم بشرى برسوم (ترجمة فانديك منحقة باسم يَهْوِه)',
              style: _getFontStyle(true).copyWith(
                fontSize: widget.fontSize * 0.8,
                color: themeProvider.secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

class VerseData {
  final int number;
  final String text;

  VerseData({
    required this.number,
    required this.text,
  });
}
