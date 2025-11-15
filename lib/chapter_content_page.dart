// lib/chapter_content_page.dart
import 'package:flutter/gestures.dart';
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
  final GlobalKey _footnotesKey = GlobalKey();
  final Map<int, GlobalKey> _footnoteKeys = {};
  final Map<int, GlobalKey> _verseKeys = {};
  late ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
      super.initState();
      _scrollController = ScrollController();
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
    // Load chapter content FIRST (it might already be cached)
    final contentFuture = _loadChapterContent();
    
    // Load highlights in parallel (non-blocking)
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final highlightedData = prefs.getString('highlighted_ranges') ?? '{}';
      final underlinedData = prefs.getString('underlined_ranges') ?? '{}';
      
      // Only parse if not empty
      if (highlightedData != '{}') {
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
      }
      
      if (underlinedData != '{}') {
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
      }
    } catch (e) {
      print('Error loading highlights: $e');
    }
    
    // Wait for content to finish loading
    await contentFuture;
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
      // These calls should now be instant if preloaded
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
          // Extract footnote references from the verse text
          // Store matches with their positions to maintain left-to-right order
          List<int> footnoteRefs = [];
          RegExp footnotePattern = RegExp(r'\[(\d+)\]');
          List<Match> matches = footnotePattern.allMatches(verseText).toList();
          
          // Sort matches by their position (left to right in the original text)
          // This ensures we get the correct order regardless of RTL display
          matches.sort((a, b) => a.start.compareTo(b.start));
          
          for (Match m in matches) {
            int refNum = int.parse(m.group(1)!);
            if (!footnoteRefs.contains(refNum)) {  // Avoid duplicates
              footnoteRefs.add(refNum);
            }
          }
          
          verseList.add(VerseData(
            number: verseNumber,
            text: verseText,
            footnoteRefs: footnoteRefs,
          ));
        }
      } else {
        if (line.trim().isNotEmpty) {
          verseList.add(VerseData(number: 0, text: line.trim()));
        }
      }
    }
    
    return verseList;
  }

  void _scrollToFootnote(int footnoteNumber) {
    final key = _footnoteKeys[footnoteNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  void _scrollToVerse(int verseNumber) {
    final key = _verseKeys[verseNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
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
            child: Container(
              key: verse.number > 0 ? (_verseKeys[verse.number] ??= GlobalKey()) : null,
              child: SelectableText.rich(
                TextSpan(
                  children: _buildVerseSpansForWidget(verse.text, hlRanges, ulRanges, isArabic, verse.number),
                ),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                textAlign: TextAlign.start,
                contextMenuBuilder: (context, editableTextState) {
                  return _buildVerseContextMenu(context, editableTextState, verse.number, isArabic);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildVerseSpansForWidget(String verseText, List<TextRange> hlRanges, List<TextRange> ulRanges, bool isArabic, int verseNumber) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (verseText.isEmpty) return [TextSpan(text: verseText)];

    String processedText = widget.removeDiacritics ? BibleData.removeTashkeel(verseText) : verseText;
    
    List<InlineSpan> spans = [];
    
    // Split text by footnote markers [1], [2], etc.
    RegExp footnotePattern = RegExp(r'\[(\d+)\]');
    int lastEnd = 0;
    
    List<Match> matches = footnotePattern.allMatches(processedText).toList();
    
    for (Match match in matches) {
      int start = match.start;
      int end = match.end;
      int footnoteNum = int.parse(match.group(1)!);
      
      // Add text before the footnote marker
      if (start > lastEnd) {
        String textBefore = processedText.substring(lastEnd, start);
        String displayText = isArabic ? '\u200F$textBefore' : textBefore;
        spans.addAll(_buildStyledSpans(displayText, hlRanges, ulRanges, isArabic, lastEnd));
      }
      
      // Use TextSpan with regular numbers (not Unicode superscripts) for both Arabic and non-Arabic
      // Wrap with LRI/PDI to keep the number in LTR direction
      spans.add(
        TextSpan(
          text: '\u2066$footnoteNum\u2069',
          style: TextStyle(
            fontSize: widget.fontSize * 0.65,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.superscripts()],
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _scrollToFootnote(footnoteNum),
        ),
      );
      
      lastEnd = end;
    }
    
    // Add remaining text after the last footnote marker
    if (lastEnd < processedText.length) {
      String remainingText = processedText.substring(lastEnd);
      String displayText = isArabic ? '\u200F$remainingText' : remainingText;
      spans.addAll(_buildStyledSpans(displayText, hlRanges, ulRanges, isArabic, lastEnd));
    }
    
    return spans;
  }

  String _toSuperscript(String number) {
    const superscriptMap = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
    };
    
    return number.split('').map((char) => superscriptMap[char] ?? char).join();
  }

  List<InlineSpan> _buildStyledSpans(String text, List<TextRange> hlRanges, List<TextRange> ulRanges, bool isArabic, int offset) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (text.isEmpty) return [];
    
    Set<int> points = {0, text.length};
    for (var r in [...hlRanges, ...ulRanges]) {
      int adjustedStart = r.start + 1 - offset;
      int adjustedEnd = r.end + 1 - offset;
      if (adjustedStart >= 0 && adjustedStart <= text.length) points.add(adjustedStart);
      if (adjustedEnd >= 0 && adjustedEnd <= text.length) points.add(adjustedEnd);
    }
    List<int> sortedPoints = points.toList()..sort();

    List<InlineSpan> spans = [];
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      int start = sortedPoints[i];
      int end = sortedPoints[i + 1];
      
      int globalStart = start + offset;
      int globalEnd = end + offset;

      bool isHighlighted = hlRanges.any((r) => r.start + 1 <= globalStart && r.end + 1 >= globalEnd);
      bool isUnderlined = ulRanges.any((r) => r.start + 1 <= globalStart && r.end + 1 >= globalEnd);

      spans.add(TextSpan(
        text: text.substring(start, end),
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
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        ...verses.map((verse) => _buildVerseWidget(verse, isArabic)).toList(),
                        
                        if (noteList.isNotEmpty || chapterSubtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Column(
                              key: _footnotesKey,
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
                                ...noteList.map((noteText) {
                                  // Extract footnote number and text
                                  RegExp footnoteNumPattern = RegExp(r'^\[(\d+)\]\s*(.*)$', dotAll: true);
                                  Match? match = footnoteNumPattern.firstMatch(noteText);
                                  
                                  // If no number found in the text, skip this footnote
                                  if (match == null) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  int footnoteNumber = int.parse(match.group(1)!);
                                  String footnoteContent = match.group(2)!.trim();
                                  
                                  
                                  if (widget.removeDiacritics) {
                                    footnoteContent = BibleData.removeTashkeel(footnoteContent);
                                  }
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      key: _footnoteKeys[footnoteNumber] ??= GlobalKey(),
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            // Find verse that contains this footnote reference
                                            for (var verse in verses) {
                                              if (verse.footnoteRefs.contains(footnoteNumber)) {
                                                _scrollToVerse(verse.number);
                                                break;
                                              }
                                            }
                                          },
                                          child: Container(
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
                                              '[$footnoteNumber]',
                                              style: TextStyle(
                                                fontSize: widget.fontSize * 0.75,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: SelectableText(
                                            footnoteContent,
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
                                }).toList(),
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
  final List<int> footnoteRefs; // List of footnote numbers referenced in this verse

  VerseData({
    required this.number,
    required this.text,
    this.footnoteRefs = const [],
  });
}
