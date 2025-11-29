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
  Map<int, TextRange> verseTextRanges = {};
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
      _loadSavedAnnotations();
      _loadChapterContent();
  }

  @override
  void didUpdateWidget(ChapterContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookIndex != widget.bookIndex || 
        oldWidget.chapterNumber != widget.chapterNumber ||
        oldWidget.removeDiacritics != widget.removeDiacritics) {
      _loadSavedAnnotations();
      _loadChapterContent();
    }
  }

  String get _chapterKey => '${widget.bookIndex}_${widget.chapterNumber}';

  Future<void> _loadSavedAnnotations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final highlightedData = prefs.getString('highlighted_ranges') ?? '{}';
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
      
      final underlinedData = prefs.getString('underlined_ranges') ?? '{}';
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
      print('Error loading annotations: $e');
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
          verseTextRanges = _computeVerseTextRanges(verses, widget.removeDiacritics);
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
          List<int> footnoteRefs = [];
          RegExp footnotePattern = RegExp(r'\[(\d+)\]');
          List<Match> matches = footnotePattern.allMatches(verseText).toList();
          
          matches.sort((a, b) => a.start.compareTo(b.start));
          
          for (Match m in matches) {
            int refNum = int.parse(m.group(1)!);
            if (!footnoteRefs.contains(refNum)) {
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

  Map<int, TextRange> _computeVerseTextRanges(List<VerseData> verses, bool removeDiacritics) {
    Map<int, TextRange> ranges = {};
    int offset = 0;
    
    for (int i = 0; i < verses.length; i++) {
      VerseData verse = verses[i];
      
      if (verse.number == 0) {
        // Chapter heading
        String displayText = removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
        offset += displayText.length;
        offset += 2; // \n\n
        continue;
      }
      
      // Account for invisible SizedBox marker (1 character: U+FFFC)
      offset += 1;
      
      // NOW INCLUDE THE VERSE NUMBER IN THE RANGE
      int start = offset;  // Start BEFORE verse number
      
      // Account for verse number text (e.g., "1 " = 2 characters)
      String verseNumText = '${verse.number} ';
      offset += verseNumText.length;
      
      // Add the actual verse content length
      String processedText = removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
      int verseLength = processedText.length;
      
      // Range now includes: [verse number] + [verse text]
      ranges[verse.number] = TextRange(start: start, end: offset + verseLength);
      
      offset += verseLength;
      
      if (i < verses.length - 1) {
        offset += 1; // ' ' between verses
      }
    }
    
    return ranges;
  }

  List<int> _getSpannedVerses(TextSelection selection) {
    List<int> spannedVerses = [];
    
    for (final entry in verseTextRanges.entries) {
      final verseNum = entry.key;
      final range = entry.value;
      
      // Check if selection overlaps with this verse's range
      if (selection.start < range.end && selection.end > range.start) {
        spannedVerses.add(verseNum);
      }
    }
    
    spannedVerses.sort();
    return spannedVerses;
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

  Widget _buildAllVersesWidget(List<VerseData> verses, bool isArabic) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    List<InlineSpan> allSpans = [];
    
    for (int i = 0; i < verses.length; i++) {
      VerseData verse = verses[i];
      
      if (verse.number == 0) {
        String displayText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
        
        allSpans.add(TextSpan(
          text: displayText,
          style: _getFontStyle(isArabic).copyWith(
            fontWeight: FontWeight.bold,
            color: themeProvider.primaryTextColor,
            fontSize: widget.fontSize * 1.1,
          ),
        ));
        allSpans.add(const TextSpan(text: '\n\n'));
      } else {
        final verseKey = _verseKeys[verse.number] ??= GlobalKey();
        
        // Store key reference for scrolling (attach to invisible marker)
        allSpans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: SizedBox(
            key: verseKey,
            width: 0,
            height: 0,
          ),
        ));

        // Check if verse number should be highlighted/underlined
        List<TextRange> hlRanges = highlightedRanges[_chapterKey]?[verse.number] ?? [];
        List<TextRange> ulRanges = underlinedRanges[_chapterKey]?[verse.number] ?? [];

        String verseNumText = '${verse.number} ';
        bool verseNumHighlighted = hlRanges.any((r) => r.start == 0 || r.start < verseNumText.length);
        bool verseNumUnderlined = ulRanges.any((r) => r.start == 0 || r.start < verseNumText.length);

        // Add verse number as TextSpan with potential highlighting/underlining
        allSpans.add(TextSpan(
          text: verseNumText,
          style: TextStyle(
            fontSize: widget.fontSize * 0.8,
            fontWeight: FontWeight.bold,
            color: themeProvider.verseNumberColor,
            fontFamily: isArabic ? widget.fontFamily : 'serif',
            letterSpacing: 0.5,
            // Apply highlighting/underlining to verse numbers
            backgroundColor: verseNumHighlighted ? Colors.yellow : null,
            decoration: verseNumUnderlined ? TextDecoration.underline : null,
            decorationColor: Theme.of(context).primaryColor,
            decorationThickness: 2,
          ),
        ));
                
        allSpans.addAll(_buildVerseSpansForWidget(verse.text, hlRanges, ulRanges, isArabic, verse.number));
        
        if (i < verses.length - 1) {
          allSpans.add(const TextSpan(text: ' '));
        }
      }
    }
    
    return SelectableText.rich(
      TextSpan(children: allSpans),
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      textAlign: TextAlign.start,
      contextMenuBuilder: (context, editableTextState) {
        return _buildVerseContextMenuWithDetection(context, editableTextState, isArabic);
      },
    );
  }
  
  Widget _buildVerseContextMenuWithDetection(BuildContext context, EditableTextState editableTextState, bool isArabic) {
    final TextEditingValue value = editableTextState.textEditingValue;
    final TextSelection selection = value.selection;
    print('🔍 CONTEXT MENU DEBUG:');
    print(' Selection valid: ${selection.isValid}');
    print(' Selection collapsed: ${selection.isCollapsed}');
    print(' Selection start: ${selection.start}, end: ${selection.end}');
    if (!selection.isValid || selection.isCollapsed) {
      print(' ❌ Selection invalid or collapsed');
      return const SizedBox.shrink();
    }
    final String selectedText = value.text.substring(selection.start, selection.end);
    print(' Selected text: "${selectedText.substring(0, min(50, selectedText.length))}"...');
    // Detect verse using precomputed ranges
    int? detectedVerseNumber;
    for (final entry in verseTextRanges.entries) {
      final range = entry.value;
      if (selection.start >= range.start && selection.start < range.end) {
        detectedVerseNumber = entry.key;
        break;
      }
    }
    print(' Detected verse: $detectedVerseNumber');
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
    buttonItems.add(
      ContextMenuButtonItem(
        label: isArabic ? 'مشاركة' : 'Share',
        onPressed: () {
          Share.share(selectedText);
          editableTextState.hideToolbar();
        },
      ),
    );
    if (detectedVerseNumber != null) {
      print(' ✅ Adding Highlight and Underline buttons for verse $detectedVerseNumber');
      buttonItems.add(
        ContextMenuButtonItem(
          label: isArabic ? 'تمييز' : 'Highlight',
          onPressed: () {
            print('🎨 Highlight button pressed for verse $detectedVerseNumber');
            _handleVerseHighlight(value.text, selection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
          },
        ),
      );
      buttonItems.add(
        ContextMenuButtonItem(
          label: isArabic ? 'تسطير' : 'Underline',
          onPressed: () {
            print('📏 Underline button pressed for verse $detectedVerseNumber');
            _handleVerseUnderline(value.text, selection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
          },
        ),
      );
    } else {
      print(' ⚠️ No verse detected - Highlight/Underline buttons NOT added');
    }
    print(' Total button items: ${buttonItems.length}');
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  void _handleVerseHighlight(String fullText, TextSelection selection, int firstDetectedVerse, bool isArabic) {
    print('🎨 MULTI-VERSE HIGHLIGHT DEBUG:');
    print('  Selection: ${selection.start} to ${selection.end}');
    
    if (selection.isCollapsed) {
      print('  ❌ Selection is collapsed');
      return;
    }
    
    // Get all verses that the selection spans
    List<int> spannedVerses = _getSpannedVerses(selection);
    
    if (spannedVerses.isEmpty) {
      print('  ❌ No verses detected in selection');
      return;
    }
    
    print('  ✅ Selection spans ${spannedVerses.length} verse(s): $spannedVerses');
    
    setState(() {
      if (!highlightedRanges.containsKey(_chapterKey)) {
        highlightedRanges[_chapterKey] = {};
      }
      
      for (int verseNum in spannedVerses) {
        if (!verseTextRanges.containsKey(verseNum)) continue;
        
        TextRange verseRange = verseTextRanges[verseNum]!;
        
        // Calculate the portion of selection that falls within this verse
        int highlightStart = selection.start < verseRange.start 
            ? 0  // Selection started before this verse
            : selection.start - verseRange.start;  // Selection started within this verse
        
        int highlightEnd = selection.end > verseRange.end
            ? verseRange.end - verseRange.start  // Selection extends beyond this verse
            : selection.end - verseRange.start;  // Selection ends within this verse
        
        print('  📍 Verse $verseNum: highlighting from $highlightStart to $highlightEnd (verse length: ${verseRange.end - verseRange.start})');
        
        TextRange highlightRange = TextRange(start: highlightStart, end: highlightEnd);
        
        if (!highlightedRanges[_chapterKey]!.containsKey(verseNum)) {
          highlightedRanges[_chapterKey]![verseNum] = [];
        }
        
        highlightedRanges[_chapterKey]![verseNum] = _toggleRange(
          highlightedRanges[_chapterKey]![verseNum]!,
          highlightRange
        );
      }
    });
    
    print('  ✅ Highlight applied to ${spannedVerses.length} verse(s)');
    _saveHighlightedRanges();
  }

  void _handleVerseUnderline(String fullText, TextSelection selection, int firstDetectedVerse, bool isArabic) {
    print('📏 MULTI-VERSE UNDERLINE DEBUG:');
    print('  Selection: ${selection.start} to ${selection.end}');
    
    if (selection.isCollapsed) {
      print('  ❌ Selection is collapsed');
      return;
    }
    
    // Get all verses that the selection spans
    List<int> spannedVerses = _getSpannedVerses(selection);
    
    if (spannedVerses.isEmpty) {
      print('  ❌ No verses detected in selection');
      return;
    }
    
    print('  ✅ Selection spans ${spannedVerses.length} verse(s): $spannedVerses');
    
    setState(() {
      if (!underlinedRanges.containsKey(_chapterKey)) {
        underlinedRanges[_chapterKey] = {};
      }
      
      for (int verseNum in spannedVerses) {
        if (!verseTextRanges.containsKey(verseNum)) continue;
        
        TextRange verseRange = verseTextRanges[verseNum]!;
        
        // Calculate the portion of selection that falls within this verse
        int underlineStart = selection.start < verseRange.start 
            ? 0  // Selection started before this verse
            : selection.start - verseRange.start;  // Selection started within this verse
        
        int underlineEnd = selection.end > verseRange.end
            ? verseRange.end - verseRange.start  // Selection extends beyond this verse
            : selection.end - verseRange.start;  // Selection ends within this verse
        
        print('  📍 Verse $verseNum: underlining from $underlineStart to $underlineEnd (verse length: ${verseRange.end - verseRange.start})');
        
        TextRange underlineRange = TextRange(start: underlineStart, end: underlineEnd);
        
        if (!underlinedRanges[_chapterKey]!.containsKey(verseNum)) {
          underlinedRanges[_chapterKey]![verseNum] = [];
        }
        
        underlinedRanges[_chapterKey]![verseNum] = _toggleRange(
          underlinedRanges[_chapterKey]![verseNum]!,
          underlineRange
        );
      }
    });
    
    print('  ✅ Underline applied to ${spannedVerses.length} verse(s)');
    _saveUnderlinedRanges();
  }

  int _findBestMatch(String original, String target) {
    if (target.isEmpty) return -1;
    
    // Try removing common whitespace differences
    String normalizedTarget = target.replaceAll(RegExp(r'\s+'), ' ').trim();
    String normalizedOriginal = original.replaceAll(RegExp(r'\s+'), ' ');
    
    int pos = normalizedOriginal.indexOf(normalizedTarget);
    if (pos != -1) {
      // Map back to original position
      int actualPos = 0;
      int normalizedPos = 0;
      while (normalizedPos < pos && actualPos < original.length) {
        if (!original[actualPos].trim().isEmpty || normalizedOriginal[normalizedPos] == ' ') {
          normalizedPos++;
        }
        actualPos++;
      }
      return actualPos;
    }
    
    // Last resort: substring search with partial matching
    int bestMatch = -1;
    int bestScore = 0;
    
    for (int i = 0; i <= original.length - target.length; i++) {
      int score = 0;
      for (int j = 0; j < target.length; j++) {
        if (original[i + j] == target[j]) {
          score++;
        }
      }
      if (score > bestScore && score > target.length * 0.8) {
        bestScore = score;
        bestMatch = i;
      }
    }
    
    return bestMatch;
  }

  List<InlineSpan> _buildVerseSpansForWidget(String verseText, List<TextRange> hlRanges, List<TextRange> ulRanges, bool isArabic, int verseNumber) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (verseText.isEmpty) return [TextSpan(text: verseText)];

    String processedText = widget.removeDiacritics ? BibleData.removeTashkeel(verseText) : verseText;
    
    List<InlineSpan> spans = [];
    
    RegExp footnotePattern = RegExp(r'\[(\d+)\]');
    int lastEnd = 0;
    
    List<Match> matches = footnotePattern.allMatches(processedText).toList();
    
    for (Match match in matches) {
      int start = match.start;
      int end = match.end;
      int footnoteNum = int.parse(match.group(1)!);
      
      // Add text BEFORE footnote with styling
      if (start > lastEnd) {
        String textBefore = processedText.substring(lastEnd, start);
        String displayText = isArabic ? '\u200F$textBefore' : textBefore;
        spans.addAll(_buildStyledSpans(displayText, hlRanges, ulRanges, isArabic, lastEnd));
      }
      
      // Determine if footnote number should be highlighted/underlined
      bool footnoteHighlighted = hlRanges.any((r) => r.start <= start && r.end >= end);
      bool footnoteUnderlined = ulRanges.any((r) => r.start <= start && r.end >= end);
      
      // Add footnote number with potential highlighting/underlining
      spans.add(
        TextSpan(
          text: '\u2066$footnoteNum\u2069',
          style: TextStyle(
            fontSize: widget.fontSize * 0.65,
            color: themeProvider.footnoteNumberColor,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.superscripts()],
            // Apply highlighting/underlining to footnote numbers
            backgroundColor: footnoteHighlighted ? Colors.yellow : null,
            decoration: footnoteUnderlined ? TextDecoration.underline : null,
            decorationColor: Theme.of(context).primaryColor,
            decorationThickness: 2,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _scrollToFootnote(footnoteNum),
        ),
      );
            
      lastEnd = end;
    }
    
    // Add remaining text after last footnote
    if (lastEnd < processedText.length) {
      String remainingText = processedText.substring(lastEnd);
      String displayText = isArabic ? '\u200F$remainingText' : remainingText;
      spans.addAll(_buildStyledSpans(displayText, hlRanges, ulRanges, isArabic, lastEnd));
    }
    
    return spans;
  }

  List<InlineSpan> _buildStyledSpans(String text, List<TextRange> hlRanges, List<TextRange> ulRanges, bool isArabic, int offset) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (text.isEmpty) return [];
    
    // Remove RTL marker for calculation
    String cleanText = text.replaceAll('\u200F', '');
    int rtlOffset = text.startsWith('\u200F') ? 1 : 0;
    
    Set<int> points = {0, cleanText.length};
    for (var r in [...hlRanges, ...ulRanges]) {
      int adjustedStart = r.start - offset;
      int adjustedEnd = r.end - offset;
      if (adjustedStart >= 0 && adjustedStart <= cleanText.length) points.add(adjustedStart);
      if (adjustedEnd >= 0 && adjustedEnd <= cleanText.length) points.add(adjustedEnd);
    }
    List<int> sortedPoints = points.toList()..sort();

    List<InlineSpan> spans = [];
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      int start = sortedPoints[i];
      int end = sortedPoints[i + 1];
      
      int globalStart = start + offset;
      int globalEnd = end + offset;

      bool isHighlighted = hlRanges.any((r) => r.start <= globalStart && r.end >= globalEnd);
      bool isUnderlined = ulRanges.any((r) => r.start <= globalStart && r.end >= globalEnd);

      // Get text with RTL marker if applicable
      String spanText = text.substring(start + rtlOffset, end + rtlOffset);
      
      spans.add(TextSpan(
        text: spanText,
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isArabic = chapterContent.contains(RegExp(r'[\u0600-\u06FF]'));
    
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                        _buildAllVersesWidget(verses, isArabic),
                        
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
                                  RegExp footnoteNumPattern = RegExp(r'^\[(\d+)\]\s*(.*)$', dotAll: true);
                                  Match? match = footnoteNumPattern.firstMatch(noteText);
                                  
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
  final List<int> footnoteRefs;

  VerseData({
    required this.number,
    required this.text,
    this.footnoteRefs = const [],
  });
}
