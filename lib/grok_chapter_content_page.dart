// lib/chapter_content_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bible_data.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

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
  Map<int, int> verseOffsets = {};
  Map<String, Map<int, List<TextRange>>> highlightedRanges = <String, Map<int, List<TextRange>>>{};
  Map<String, Map<int, List<TextRange>>> underlinedRanges = <String, Map<int, List<TextRange>>>{};

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void didUpdateWidget(ChapterContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookIndex != widget.bookIndex || oldWidget.chapterNumber != widget.chapterNumber) {
      _loadSavedData();
    }
  }

  String get _chapterKey => '${widget.bookIndex}_${widget.chapterNumber}';

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load highlighted ranges
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
      
      // Load underlined ranges
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
      
      // Backward compatibility for old whole-verse highlights
      final oldHighlighted = prefs.getString('highlighted_verses') ?? '{}';
      if (oldHighlighted != '{}') {
        final oldMap = json.decode(oldHighlighted) as Map<String, dynamic>;
        for (String key in oldMap.keys) {
          if (oldMap[key] is List) {
            final oldVerses = Set<int>.from(oldMap[key].cast<int>());
            if (oldVerses.isNotEmpty) {
              await _loadChapterContent();
              _convertOldHighlights(key, oldVerses);
            }
          }
        }
        await prefs.remove('highlighted_verses');
      }
      
      await _loadChapterContent();
    } catch (e) {
      print('Error loading saved data: $e');
      await _loadChapterContent();
    }
  }

  void _convertOldHighlights(String key, Set<int> oldVerses) {
    if (key != _chapterKey) return;
    if (!highlightedRanges.containsKey(key)) highlightedRanges[key] = {};
    for (int verseNum in oldVerses) {
      final verse = verses.firstWhere((v) => v.number == verseNum, orElse: () => VerseData(number: 0, text: ''));
      if (verse.number != 0) {
        final fullRange = TextRange(start: 0, end: verse.text.length);
        if (!highlightedRanges[key]!.containsKey(verseNum)) highlightedRanges[key]![verseNum] = [];
        highlightedRanges[key]![verseNum]!.add(fullRange);
      }
    }
    _saveHighlightedRanges();
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

  Future<void> _loadChapterContent() async {
    try {
      final content = await BibleData.getChapterContent(widget.bookIndex, widget.chapterNumber);
      if (mounted) {
        setState(() {
          chapterContent = content;
          verses = _parseVersesToList(content);
          verseOffsets = _computeVerseOffsets(verses);
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
        currentOffset += verse.text.length + 2; // \n\n for title
        continue;
      }
      currentOffset += '${verse.number} '.length;
      offsets[verse.number] = currentOffset;
      currentOffset += verse.text.length + 1; // \n
    }
    return offsets;
  }

  List<TextSpan> _buildAllVerseSpans() {
    List<TextSpan> spans = [];
    for (var verse in verses) {
      if (verse.number == 0) {
        spans.add(TextSpan(
          text: '${verse.text}\n\n',
          style: TextStyle(
            fontSize: widget.fontSize * 1.1,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Amiri', // Use Arabic-specific font
          ),
        ));
        continue;
      }
      spans.add(TextSpan(
        text: '${verse.number} ',
        style: TextStyle(
          fontSize: widget.fontSize * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
          fontFamily: 'Amiri', // Use Arabic-specific font
        ),
      ));
      List<TextRange> hlRanges = highlightedRanges[_chapterKey]?[verse.number] ?? [];
      List<TextRange> ulRanges = underlinedRanges[_chapterKey]?[verse.number] ?? [];
      List<TextSpan> verseSpans = _buildVerseSpans(verse.text, hlRanges, ulRanges);
      for (var span in verseSpans) {
        spans.add(span.copyWith(
          style: span.style?.copyWith(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.normal,
            height: 1.8,
            color: Colors.black87,
            fontFamily: 'Amiri', // Use Arabic-specific font
          ) ?? TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.normal,
            height: 1.8,
            color: Colors.black87,
            fontFamily: 'Amiri', // Use Arabic-specific font
          ),
        ));
      }
      spans.add(const TextSpan(text: '\n'));
    }
    return spans;
  }

  List<TextSpan> _buildVerseSpans(String verseText, List<TextRange> hlRanges, List<TextRange> ulRanges) {
    if (verseText.isEmpty) return [TextSpan(text: verseText)];
    
    Set<int> points = {0, verseText.length};
    for (var r in [...hlRanges, ...ulRanges]) {
      points.add(r.start);
      points.add(r.end);
    }
    List<int> sortedPoints = points.toList()..sort();
    
    List<TextSpan> spans = [];
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      int start = sortedPoints[i];
      int end = sortedPoints[i + 1];
      bool isHighlighted = hlRanges.any((r) => r.start <= start && r.end >= end);
      bool isUnderlined = ulRanges.any((r) => r.start <= start && r.end >= end);
      
      spans.add(TextSpan(
        text: verseText.substring(start, end),
        style: TextStyle(
          backgroundColor: isHighlighted ? Colors.yellow : null,
          decoration: isUnderlined ? TextDecoration.underline : null,
          decorationColor: Colors.blue,
          decorationThickness: 2,
        ),
      ));
    }
    return spans;
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

  void _handleHighlight(TextSelection selection) {
    print('Highlight called with selection: start=${selection.start}, end=${selection.end}');
    if (selection.isCollapsed) return;
    int start = min(selection.baseOffset, selection.extentOffset);
    int end = max(selection.baseOffset, selection.extentOffset);
    
    setState(() {
      for (var verse in verses.where((v) => v.number > 0)) {
        int vNum = verse.number;
        if (!verseOffsets.containsKey(vNum)) continue;
        int vStart = verseOffsets[vNum]!;
        int vEnd = vStart + verse.text.length;
        if (end <= vStart || start >= vEnd) continue;
        int lStart = max(0, start - vStart);
        int lEnd = min(verse.text.length, end - vStart);
        TextRange tr = TextRange(start: lStart, end: lEnd);
        print('Toggling highlight for verse $vNum: $lStart-$lEnd');
        
        if (!highlightedRanges.containsKey(_chapterKey)) highlightedRanges[_chapterKey] = {};
        if (!highlightedRanges[_chapterKey]!.containsKey(vNum)) highlightedRanges[_chapterKey]![vNum] = [];
        highlightedRanges[_chapterKey]![vNum] = _toggleRange(highlightedRanges[_chapterKey]![vNum]!, tr);
      }
    });
    
    _saveHighlightedRanges();
  }

  void _handleUnderline(TextSelection selection) {
    print('Underline called with selection: start=${selection.start}, end=${selection.end}');
    if (selection.isCollapsed) return;
    int start = min(selection.baseOffset, selection.extentOffset);
    int end = max(selection.baseOffset, selection.extentOffset);
    
    setState(() {
      for (var verse in verses.where((v) => v.number > 0)) {
        int vNum = verse.number;
        if (!verseOffsets.containsKey(vNum)) continue;
        int vStart = verseOffsets[vNum]!;
        int vEnd = vStart + verse.text.length;
        if (end <= vStart || start >= vEnd) continue;
        int lStart = max(0, start - vStart);
        int lEnd = min(verse.text.length, end - vStart);
        TextRange tr = TextRange(start: lStart, end: lEnd);
        print('Toggling underline for verse $vNum: $lStart-$lEnd');
        
        if (!underlinedRanges.containsKey(_chapterKey)) underlinedRanges[_chapterKey] = {};
        if (!underlinedRanges[_chapterKey]!.containsKey(vNum)) underlinedRanges[_chapterKey]![vNum] = [];
        underlinedRanges[_chapterKey]![vNum] = _toggleRange(underlinedRanges[_chapterKey]![vNum]!, tr);
      }
    });
    
    _saveUnderlinedRanges();
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
    print('Context menu builder called');
    final TextEditingValue value = editableTextState.textEditingValue;
    final TextSelection selection = value.selection;

    if (!selection.isValid || selection.isCollapsed) {
      print('Selection invalid or collapsed, returning empty');
      return const SizedBox.shrink();
    }

    final String selectedText = value.text.substring(selection.start, selection.end);
    print('Selected text: $selectedText');

    List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;

    buttonItems.addAll([
      ContextMenuButtonItem(
        label: 'مشاركة', // Share in Arabic
        onPressed: () {
          Share.share(selectedText);
          editableTextState.hideToolbar();
        },
      ),
      ContextMenuButtonItem(
        label: 'تمييز', // Highlight in Arabic
        onPressed: () {
          _handleHighlight(selection);
          editableTextState.hideToolbar();
        },
      ),
      ContextMenuButtonItem(
        label: 'تسطير', // Underline in Arabic
        onPressed: () {
          _handleUnderline(selection);
          editableTextState.hideToolbar();
        },
      ),
    ]);

    print('Building toolbar with ${buttonItems.length} items');
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  // Alternative method using individual verse widgets for better RTL handling
  Widget _buildVerseWidget(VerseData verse, bool isArabic) {
    if (verse.number == 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: SelectableText(
          verse.text,
          style: TextStyle(
            fontSize: widget.fontSize * 1.1,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: isArabic ? 'Amiri' : 'serif',
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
        ),
      );
    }

    List<TextRange> hlRanges = highlightedRanges[_chapterKey]?[verse.number] ?? [];
    List<TextRange> ulRanges = underlinedRanges[_chapterKey]?[verse.number] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${verse.number} ',
                style: TextStyle(
                  fontSize: widget.fontSize * 0.8,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontFamily: isArabic ? 'Amiri' : 'serif',
                ),
              ),
              ..._buildVerseSpansForWidget(verse.text, hlRanges, ulRanges, isArabic),
            ],
          ),
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          contextMenuBuilder: (context, editableTextState) {
            return _buildVerseContextMenu(context, editableTextState, verse.number);
          },
        ),
      ),
    );
  }

  List<TextSpan> _buildVerseSpansForWidget(String verseText, List<TextRange> hlRanges, List<TextRange> ulRanges, bool isArabic) {
    if (verseText.isEmpty) return [TextSpan(text: verseText)];
    
    Set<int> points = {0, verseText.length};
    for (var r in [...hlRanges, ...ulRanges]) {
      points.add(r.start);
      points.add(r.end);
    }
    List<int> sortedPoints = points.toList()..sort();
    
    List<TextSpan> spans = [];
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      int start = sortedPoints[i];
      int end = sortedPoints[i + 1];
      bool isHighlighted = hlRanges.any((r) => r.start <= start && r.end >= end);
      bool isUnderlined = ulRanges.any((r) => r.start <= start && r.end >= end);
      
      spans.add(TextSpan(
        text: verseText.substring(start, end),
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.normal,
          height: 1.8,
          color: Colors.black87,
          fontFamily: isArabic ? 'Amiri' : 'serif',
          backgroundColor: isHighlighted ? Colors.yellow : null,
          decoration: isUnderlined ? TextDecoration.underline : null,
          decorationColor: Colors.blue,
          decorationThickness: 2,
        ),
      ));
    }
    return spans;
  }

  Widget _buildVerseContextMenu(BuildContext context, EditableTextState editableTextState, int verseNumber) {
    final TextEditingValue value = editableTextState.textEditingValue;
    final TextSelection selection = value.selection;

    if (!selection.isValid || selection.isCollapsed) {
      return const SizedBox.shrink();
    }

    final String selectedText = value.text.substring(selection.start, selection.end);

    List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;

    buttonItems.addAll([
      ContextMenuButtonItem(
        label: 'مشاركة', // Share in Arabic
        onPressed: () {
          Share.share(selectedText);
          editableTextState.hideToolbar();
        },
      ),
      ContextMenuButtonItem(
        label: 'تمييز', // Highlight in Arabic
        onPressed: () {
          _handleVerseHighlight(selection, verseNumber);
          editableTextState.hideToolbar();
        },
      ),
      ContextMenuButtonItem(
        label: 'تسطير', // Underline in Arabic
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
    
    // Adjust for verse number prefix
    int adjustedStart = selection.start - '${verseNumber} '.length;
    int adjustedEnd = selection.end - '${verseNumber} '.length;
    
    if (adjustedStart < 0) adjustedStart = 0;
    
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
    
    // Adjust for verse number prefix
    int adjustedStart = selection.start - '${verseNumber} '.length;
    int adjustedEnd = selection.end - '${verseNumber} '.length;
    
    if (adjustedStart < 0) adjustedStart = 0;
    
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
    bool isArabic = chapterContent.contains(RegExp(r'[\u0600-\u06FF]'));
    TextDirection dir = isArabic ? TextDirection.rtl : TextDirection.ltr;
    TextAlign align = isArabic ? TextAlign.right : TextAlign.left;

    return Directionality(
      textDirection: dir,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.bookName} ${widget.chapterNumber}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: align,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: verses.map((verse) => _buildVerseWidget(verse, isArabic)).toList(),
                      ),
                    ),
            ),
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
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
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

  VerseData({
    required this.number,
    required this.text,
  });
}

extension on TextSpan {
  TextSpan copyWith({TextStyle? style}) {
    return TextSpan(
      text: text,
      children: children,
      style: style,
    );
  }
}
