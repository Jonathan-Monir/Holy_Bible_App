// lib/chapter_content_page.dart

import 'package:flutter/scheduler.dart';  // ← ADD THIS LINE
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
// import 'package:flutter/material/selectable_text_arabic.dart';
import 'arabic_selectable_text.dart';  // ← add this line

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

  void _debugTextComparison(String editableText) {
    print('═══════════════════════════════════════');
    print('🔍 TEXT COMPARISON DEBUG');
    print('═══════════════════════════════════════');
    
    // Build the text the same way we build spans
    String reconstructedText = '';
    for (int i = 0; i < verses.length; i++) {
      VerseData verse = verses[i];
      
      if (verse.number == 0) {
        String displayText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
        reconstructedText += displayText;
        reconstructedText += '\n\n';
      } else {
        // Add WidgetSpan marker
        reconstructedText += '\uFFFC'; // This is the verse number widget
        
        String processedText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
        reconstructedText += processedText;
        
        if (i < verses.length - 1) {
          reconstructedText += ' ';
        }
      }
    }
    
    print('📊 Editable text length: ${editableText.length}');
    print('📊 Reconstructed text length: ${reconstructedText.length}');
    print('📊 Difference: ${editableText.length - reconstructedText.length}');
    
    // Find first difference
    int firstDiff = -1;
    for (int i = 0; i < editableText.length && i < reconstructedText.length; i++) {
      if (editableText[i] != reconstructedText[i]) {
        firstDiff = i;
        break;
      }
    }
    
    if (firstDiff >= 0) {
      print('⚠️ First difference at position $firstDiff');
      int start = (firstDiff - 20).clamp(0, editableText.length);
      int end = (firstDiff + 20).clamp(0, editableText.length);
      
      print('   Editable text around diff:');
      for (int i = start; i < end; i++) {
        String char = editableText[i];
        int code = char.codeUnitAt(0);
        String marker = (i == firstDiff) ? ' <<<' : '';
        print('     [$i] "${char}" (U+${code.toRadixString(16).padLeft(4, '0').toUpperCase()})$marker');
      }
      
      print('   Reconstructed text around diff:');
      for (int i = start; i < end && i < reconstructedText.length; i++) {
        String char = reconstructedText[i];
        int code = char.codeUnitAt(0);
        String marker = (i == firstDiff) ? ' <<<' : '';
        print('     [$i] "${char}" (U+${code.toRadixString(16).padLeft(4, '0').toUpperCase()})$marker');
      }
    } else {
      print('✅ Texts match up to min length');
    }
    
    // Sample at position 3900
    print('\n📍 Sample at position 3900:');
    if (3900 < editableText.length) {
      for (int i = 3890; i < 3910 && i < editableText.length; i++) {
        String char = editableText[i];
        int code = char.codeUnitAt(0);
        print('   E[$i] "${char}" (U+${code.toRadixString(16).padLeft(4, '0').toUpperCase()})');
      }
    }
    
    if (3900 < reconstructedText.length) {
      print('   Reconstructed at 3900:');
      for (int i = 3890; i < 3910 && i < reconstructedText.length; i++) {
        String char = reconstructedText[i];
        int code = char.codeUnitAt(0);
        print('   R[$i] "${char}" (U+${code.toRadixString(16).padLeft(4, '0').toUpperCase()})');
      }
    }
    
    print('═══════════════════════════════════════\n');
  }

  static const double _lineHeight = 1.8;  // Adjust this value as needed
  String chapterContent = '';
  bool isLoading = true;
  List<VerseData> verses = [];
  Map<int, int> verseOffsets = {};
  Map<String, Map<int, List<TextRange>>> highlightedRanges = <String, Map<int, List<TextRange>>>{};
  Map<String, Map<int, List<TextRange>>> underlinedRanges = <String, Map<int, List<TextRange>>>{};

  String footnotes = '';
  final GlobalKey _footnotesKey = GlobalKey();
  final Map<int, GlobalKey> _footnoteKeys = {};

  // NEW - Add this instead:
  final Map<int, GlobalKey> _verseKeys = {};  // Keep for verse scrolling (int key for verse number)
  final Map<String, GlobalKey> _uniqueVerseKeys = {};  // NEW: For unique widget instances (string key for uniqueness)
  Map<int, TextRange> verseTextRanges = {};
  late ScrollController _scrollController;

  // ADD THESE NEW LINES:
  final Map<int, GlobalKey> _verseNumberKeys = {};
  final Map<String, GlobalKey> _footnoteNumberKeys = {};  // Changed from int to String
  bool _isSwappingPositions = false;
  Size? _lastKnownSize;

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
      
      // Listen for orientation/size changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scheduleOrientationListener();
        }
      });
  }

  void _scheduleOrientationListener() {
    // This will detect when the widget rebuilds due to orientation change
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final newSize = MediaQuery.of(context).size;
        if (_lastKnownSize != null && _lastKnownSize != newSize) {
          _resetAllVerseOffsets();
          _schedulePositionSwapping();
        }
        _lastKnownSize = newSize;
        _scheduleOrientationListener(); // Keep listening
      }
    });
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
    
    // Reset and recalculate positions if fontSize or fontFamily changed
    if (oldWidget.fontSize != widget.fontSize || 
        oldWidget.fontFamily != widget.fontFamily) {
      _resetAllVerseOffsets();
      _schedulePositionSwapping();
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
    print('🔵 START: Loading chapter ${widget.bookIndex} - ${widget.chapterNumber}');
    
    try {
      final content = await BibleData.getChapterContent(widget.bookIndex, widget.chapterNumber);
      print('📄 Content loaded, length: ${content.length}');
      print('📄 First 200 chars: ${content.substring(0, min(200, content.length))}');
      
      final fn = await BibleData.getChapterFootnotes(widget.bookIndex, widget.chapterNumber);
      print('📝 Footnotes loaded, length: ${fn.length}');
      
      if (mounted) {
        print('🔄 Parsing verses...');
        final parsedVerses = _parseVersesToList(content);
        print('✅ Parsed ${parsedVerses.length} verses');
        
        for (int i = 0; i < min(5, parsedVerses.length); i++) {
          print('   Verse ${parsedVerses[i].number}: ${parsedVerses[i].text.substring(0, min(50, parsedVerses[i].text.length))}...');
        }
        
        print('🔄 Computing verse offsets...');
        final offsets = _computeVerseOffsets(parsedVerses);
        print('✅ Computed ${offsets.length} offsets');
        
        print('🔄 Computing verse text ranges...');
        final ranges = _computeVerseTextRanges(parsedVerses, widget.removeDiacritics);
        print('✅ Computed ${ranges.length} ranges');
        
        setState(() {
          chapterContent = content;
          verses = parsedVerses;
          verseOffsets = offsets;
          verseTextRanges = ranges;
          footnotes = fn;
          isLoading = false;
        });

        print('✅ DONE: Chapter loaded successfully');

        // ADD THIS LINE:
        _debugVersePositions();

        _schedulePositionSwapping();
      }
    } catch (e, stackTrace) {
      print('❌ ERROR loading chapter: $e');
      print('❌ Stack trace: $stackTrace');
      
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
    print('🔍 PARSE: Starting to parse content, length: ${content.length}');
    
    List<VerseData> verseList = [];
    List<String> lines = content.split('\n');
    
    print('🔍 PARSE: Split into ${lines.length} lines');
    
    for (int i = 0; i < min(3, lines.length); i++) {
      print('   Line $i: ${lines[i].substring(0, min(100, lines[i].length))}');
    }
    
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
          
          if (verseList.length <= 3) {
            print('   ✓ Added verse $verseNumber: ${verseText.substring(0, min(50, verseText.length))}...');
          }
        }
      } else {
        // Line doesn't match verse pattern - might be chapter heading
        if (line.trim().isNotEmpty) {
          print('   ⚠ Non-verse line: ${line.substring(0, min(100, line.length))}');
          verseList.add(VerseData(number: 0, text: line.trim()));
        }
      }
    }
    
    print('🔍 PARSE: Complete, found ${verseList.length} verses');
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
    print('🔧 COMPUTE VERSE TEXT RANGES: Starting...');
    
    Map<int, TextRange> ranges = {};
    int offset = 0;
    
    for (int i = 0; i < verses.length; i++) {
      VerseData verse = verses[i];
      
      if (verse.number == 0) {
        // Chapter heading
        String displayText = removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
        print('   Chapter heading: offset=$offset, length=${displayText.length}');
        offset += displayText.length;
        offset += 2; // \n\n
        continue;
      }
      
      // Account for WidgetSpan verse number (1 character: U+FFFC)
      int start = offset;  // Start at the WidgetSpan
      offset += 1;  // The WidgetSpan itself
      
      // Process the verse text to count footnotes
      String verseText = verse.text;
      String processedText = removeDiacritics ? BibleData.removeTashkeel(verseText) : verseText;
      
      // Count footnote markers in the original text
      RegExp footnotePattern = RegExp(r'\[(\d+)\]');
      List<Match> footnoteMatches = footnotePattern.allMatches(processedText).toList();
      
      // Calculate actual displayed length:
      // - Each [N] in text becomes a WidgetSpan (1 char: U+FFFC)
      // - So we subtract the bracket length [1] = 3 chars, and add 1 for the widget
      int displayedLength = processedText.length;
      
      for (Match match in footnoteMatches) {
        int bracketLength = match.group(0)!.length; // "[1]" = 3, "[12]" = 4, etc.
        displayedLength = displayedLength - bracketLength + 1; // Replace with 1 widget char
      }
      
      // Range now includes: [verse number widget] + [verse text with footnote widgets]
      ranges[verse.number] = TextRange(start: start, end: offset + displayedLength);
      
      print('   Verse ${verse.number}: range $start to ${offset + displayedLength}');
      print('     Text length: ${processedText.length}, Footnotes: ${footnoteMatches.length}, Displayed: $displayedLength');
      
      offset += displayedLength;
      
      if (i < verses.length - 1) {
        offset += 1; // ' ' between verses
      }
    }
    
    print('🔧 COMPUTE VERSE TEXT RANGES: Complete, ${ranges.length} ranges');
    return ranges;
  }

  List<int> _getSpannedVerses(TextSelection selection) {
    print('🔍 GET SPANNED VERSES:');
    print('   Selection: ${selection.start} to ${selection.end}');
    
    List<int> spannedVerses = [];
    
    for (final entry in verseTextRanges.entries) {
      final verseNum = entry.key;
      final range = entry.value;
      
      print('   Checking verse $verseNum: range ${range.start} to ${range.end}');
      
      // Check if selection overlaps with this verse's range
      if (selection.start < range.end && selection.end > range.start) {
        print('   ✓ Verse $verseNum IS in selection');
        spannedVerses.add(verseNum);
      } else {
        print('   ✗ Verse $verseNum NOT in selection');
      }
    }
    
    spannedVerses.sort();
    print('   Final spanned verses: $spannedVerses');
    return spannedVerses;
  }

  TextSelection _adjustSelectionForRTL(TextSelection selection, String fullText) {
    print('🚨 ADJUSTMENT FUNCTION CALLED!!! 🚨');
    print('🔧 SELECTION ADJUSTMENT START');
    print('   Original: ${selection.start} to ${selection.end}');
    
    if (selection.start >= fullText.length || selection.end > fullText.length) {
      print('🔧 SELECTION ADJUSTMENT: Invalid bounds');
      return selection;
    }
    
    // Get the selected text
    String selectedText = fullText.substring(selection.start, selection.end);
    print('   Selected text (first 100): "${selectedText.substring(0, min(100, selectedText.length))}"');
    
    // CRITICAL DEBUG: Check what's BEFORE start and AFTER end
    if (selection.start > 0) {
      String charBefore = fullText[selection.start - 1];
      int codeBefore = charBefore.codeUnitAt(0);
      print('   Char BEFORE start: "$charBefore" (code: $codeBefore, hex: ${codeBefore.toRadixString(16)})');
    }
    
    if (selection.end < fullText.length) {
      String charAfter = fullText[selection.end];
      int codeAfter = charAfter.codeUnitAt(0);
      print('   Char AFTER end: "$charAfter" (code: $codeAfter, hex: ${codeAfter.toRadixString(16)})');
    }
    
    // Clean the selected text (remove verse number markers)
    String cleanedSelection = selectedText.replaceAll('\uFFFC', '').trim();
    print('   Cleaned selection length: ${cleanedSelection.length}');
    
    if (cleanedSelection.length < 10) {
      print('🔧 SELECTION ADJUSTMENT: Selection too short');
      return selection;
    }
    
    // CRITICAL FIX: If selection starts with a space, DON'T expand backward
    // Instead, move forward TO the first non-space character
    int adjustedStart = selection.start;
    
    // First, skip any leading spaces/whitespace IN the selection
    while (adjustedStart < selection.end && fullText[adjustedStart] == ' ') {
      adjustedStart++;
    }
    print('   After skipping leading spaces: adjustedStart=$adjustedStart');
    
    // Now expand backward from this position to get the full word
    int backwardSteps = 0;
    while (adjustedStart > 0) {
      String charBefore = fullText[adjustedStart - 1];
      int codePoint = charBefore.codeUnitAt(0);
      
      print('   Backward step $backwardSteps: pos=${adjustedStart - 1}, char="$charBefore", code=$codePoint');
      
      // Stop at word boundaries
      if (charBefore == ' ' || charBefore == '\n' || charBefore == '\uFFFC') {
        print('   → Stop: word boundary (space/newline/widget)');
        break;
      }
      
      // Stop at punctuation
      if (RegExp(r'[،؛:.!؟»«]').hasMatch(charBefore)) {
        print('   → Stop: punctuation');
        break;
      }
      
      // Check if it's a diacritic (Arabic diacritical marks: U+064B to U+065F)
      if (codePoint >= 0x064B && codePoint <= 0x065F) {
        print('   → Continue: diacritic mark');
        adjustedStart--;
        backwardSteps++;
        continue;
      }
      
      // Check if it's an Arabic letter (U+0600 to U+06FF)
      if (codePoint >= 0x0600 && codePoint <= 0x06FF) {
        print('   → Continue: Arabic letter');
        adjustedStart--;
        backwardSteps++;
        continue;
      }
      
      // Check if it's a Latin letter or digit
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(charBefore)) {
        print('   → Continue: Latin letter/digit');
        adjustedStart--;
        backwardSteps++;
        continue;
      }
      
      // Unknown character - stop
      print('   → Stop: unknown character type');
      break;
    }
    
    // EXPAND FORWARD from end position
    // First, skip any trailing spaces IN the selection
    int adjustedEnd = selection.end;
    
    // Move backward TO the last non-space character
    while (adjustedEnd > selection.start && fullText[adjustedEnd - 1] == ' ') {
      adjustedEnd--;
    }
    print('   After removing trailing spaces: adjustedEnd=$adjustedEnd');
    
    // Now expand forward from this position to get the full word
    int forwardSteps = 0;
    while (adjustedEnd < fullText.length) {
      String charAt = fullText[adjustedEnd];
      int codePoint = charAt.codeUnitAt(0);
      
      print('   Forward step $forwardSteps: pos=$adjustedEnd, char="$charAt", code=$codePoint');
      
      // Stop at word boundaries
      if (charAt == ' ' || charAt == '\n' || charAt == '\uFFFC') {
        print('   → Stop: word boundary (space/newline/widget)');
        break;
      }
      
      // Stop at punctuation
      if (RegExp(r'[،؛:.!؟»«]').hasMatch(charAt)) {
        print('   → Stop: punctuation');
        break;
      }
      
      // Check if it's a diacritic (Arabic diacritical marks)
      if (codePoint >= 0x064B && codePoint <= 0x065F) {
        print('   → Continue: diacritic mark');
        adjustedEnd++;
        forwardSteps++;
        continue;
      }
      
      // Check if it's an Arabic letter
      if (codePoint >= 0x0600 && codePoint <= 0x06FF) {
        print('   → Continue: Arabic letter');
        adjustedEnd++;
        forwardSteps++;
        continue;
      }
      
      // Check if it's a Latin letter or digit
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(charAt)) {
        print('   → Continue: Latin letter/digit');
        adjustedEnd++;
        forwardSteps++;
        continue;
      }
      
      // Unknown character - stop
      print('   → Stop: unknown character type');
      break;
    }
    
    print('🔧 SELECTION ADJUSTMENT: Expanded to word boundaries');
    print('   Adjusted: $adjustedStart to $adjustedEnd');
    print('   Start moved by: ${selection.start - adjustedStart} chars backward ($backwardSteps steps)');
    print('   End moved by: ${adjustedEnd - selection.end} chars forward ($forwardSteps steps)');
    
    // Verify the adjustment
    if (adjustedStart < adjustedEnd && adjustedEnd <= fullText.length) {
      String adjustedText = fullText.substring(adjustedStart, adjustedEnd);
      String cleanedAdjusted = adjustedText.replaceAll('\uFFFC', '').trim();
      
      print('   Adjusted text (first 100): "${cleanedAdjusted.substring(0, min(100, cleanedAdjusted.length))}"');
      if (cleanedAdjusted.length > 50) {
        print('   Adjusted text (last 50): "${cleanedAdjusted.substring(cleanedAdjusted.length - 50)}"');
      }
      
      return TextSelection(baseOffset: adjustedStart, extentOffset: adjustedEnd);
    }
    
    print('🔧 SELECTION ADJUSTMENT: Failed, using original');
    return selection;
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
            height: 1.8,
          ),
        ));
        allSpans.add(const TextSpan(text: '\n\n'));
      } else {
        final uniqueKeyIdentifier = '${verse.number}_$i';
        if (!_uniqueVerseKeys.containsKey(uniqueKeyIdentifier)) {
          _uniqueVerseKeys[uniqueKeyIdentifier] = GlobalKey();
        }
        if (!_verseKeys.containsKey(verse.number)) {
          _verseKeys[verse.number] = GlobalKey();
        }
        final verseKey = _verseKeys[verse.number]!;
        final uniqueWidgetKey = _uniqueVerseKeys[uniqueKeyIdentifier]!;
        
        List<TextRange> hlRanges = highlightedRanges[_chapterKey]?[verse.number] ?? [];
        List<TextRange> ulRanges = underlinedRanges[_chapterKey]?[verse.number] ?? [];

        String verseNumText = '${verse.number} ';
        bool verseNumHighlighted = hlRanges.any((r) => r.start == 0 || r.start < verseNumText.length);
        bool verseNumUnderlined = ulRanges.any((r) => r.start == 0 || r.start < verseNumText.length);

        final verseNumberKey = _verseNumberKeys.putIfAbsent(
          verse.number, 
          () => GlobalKey()
        );

        allSpans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _VerseNumberWidget(
              key: uniqueWidgetKey,
              verseKey: verseKey,
              verseNumText: verseNumText,
              fontSize: widget.fontSize,
              fontFamily: isArabic ? widget.fontFamily : 'serif',
              color: themeProvider.verseNumberColor,
              isHighlighted: verseNumHighlighted,
              isUnderlined: verseNumUnderlined,
              primaryColor: Theme.of(context).primaryColor,
            ),
          ),
        ));
                
        // CRITICAL CHANGE: Don't add RTL markers in the spans
        allSpans.addAll(_buildVerseSpansForWidget(verse.text, hlRanges, ulRanges, isArabic, verse.number));
        
        if (i < verses.length - 1) {
          allSpans.add(const TextSpan(text: ' '));
        }
      }
    }
    
    return FixedSelectableText.rich(
      TextSpan(children: allSpans),
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      textAlign: TextAlign.start,
      strutStyle: StrutStyle(
        fontSize: widget.fontSize,
        height: _lineHeight,
        forceStrutHeight: true,
        fontFamily: isArabic ? widget.fontFamily : 'serif',
      ),
      contextMenuBuilder: (context, editableTextState) {
        return _buildVerseContextMenuWithDetection(context, editableTextState, isArabic);
      },
    );
  }
  
  Widget _buildVerseContextMenuWithDetection(BuildContext context, EditableTextState editableTextState, bool isArabic) {
    final TextEditingValue value = editableTextState.textEditingValue;
    final TextSelection editableSelection = value.selection;
    
    // DEBUG: Compare texts
    // _debugTextComparison(value.text);
    
    print('🎯 CONTEXT MENU: Chapter ${widget.bookIndex}-${widget.chapterNumber}');
    print('🎯 SELECTION from EditableText: ${editableSelection.start} to ${editableSelection.end}');
    print('   verseTextRanges has ${verseTextRanges.length} entries');
    print('   First 3 verse numbers: ${verseTextRanges.keys.take(3).toList()}');
    
    if (!editableSelection.isValid || editableSelection.isCollapsed) {
      return const SizedBox.shrink();
    }
    
    final String selectedText = value.text.substring(editableSelection.start, editableSelection.end);
    print("edddd ${editableSelection.start}, ${editableSelection.end}");
    print('FULL TEXT LENGTH: ${value.text.length}');
    print('   Selected text: "$selectedText"');
    print('   Selected text (first 50 chars): "${selectedText.substring(0, selectedText.length.clamp(0, 50))}"');
    
    // Convert EditableText selection to actual text selection (removing special chars)
    final TextSelection selection = _convertEditableSelectionToActualSelection(editableSelection, value.text);
    
    if (!selection.isValid || selection.isCollapsed) {
      return const SizedBox.shrink();
    }
    
    print(' hey valuetext ${value.text}');
    print(' hey selectedtext ${selectedText}');

  
    // Detect verse using precomputed ranges
    int? detectedVerseNumber;
    for (final entry in verseTextRanges.entries) {
      final range = entry.value;
      if (selection.start >= range.start && selection.start < range.end) {
        detectedVerseNumber = entry.key;
        break;
      }
    }
    
    List<ContextMenuButtonItem> buttonItems = [];
    
    buttonItems.add(
      ContextMenuButtonItem(
        label: isArabic ? 'نسخ' : 'Copy',
        onPressed: () {
          String cleanedText = _cleanTextForCopy(selectedText);
          print("hey cleaned text ${cleanedText}");
          Clipboard.setData(ClipboardData(text: cleanedText));
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
      buttonItems.add(
        ContextMenuButtonItem(
          label: isArabic ? 'تمييز' : 'Highlight',
          onPressed: () {
            // Use the converted selection, not the editable selection
            _handleVerseHighlight(value.text, editableSelection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
          },
        ),
      );
      
      buttonItems.add(
        ContextMenuButtonItem(
          label: isArabic ? 'تسطير' : 'Underline',
          onPressed: () {
            // Use the converted selection, not the editable selection
            _handleVerseUnderline(value.text, selection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
          },
        ),
      );
    }
    
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

void _handleVerseHighlight(String fullText, TextSelection selection, int firstDetectedVerse, bool isArabic) {
  print('🎯 HIGHLIGHT: sel=${selection.start}-${selection.end}');
  
  if (selection.isCollapsed) return;
  
  // Get all verses that the selection spans
  List<int> spannedVerses = _getSpannedVerses(selection);
  if (spannedVerses.isEmpty) return;
  
  setState(() {
    if (!highlightedRanges.containsKey(_chapterKey)) {
      highlightedRanges[_chapterKey] = {};
    }
    
    for (int verseNum in spannedVerses) {
      if (!verseTextRanges.containsKey(verseNum)) continue;
      
      TextRange verseRange = verseTextRanges[verseNum]!;
      
      // CRITICAL FIX: verseRange includes the WidgetSpan for verse number
      // We need to subtract 1 from the start to account for it when calculating highlight position
      // The WidgetSpan is 1 character (U+FFFC) at verseRange.start
      
      // Calculate global selection boundaries within this verse
      int globalHighlightStart = max(selection.start, verseRange.start);
      int globalHighlightEnd = min(selection.end, verseRange.end);
      
      // Convert to LOCAL position within verse text (excluding the WidgetSpan)
      // verseRange.start points to the WidgetSpan, so text starts at verseRange.start + 1
      int localHighlightStart = globalHighlightStart - (verseRange.start + 1);
      int localHighlightEnd = globalHighlightEnd - (verseRange.start + 1);
      
      // Get the verse text
      final verse = verses.firstWhere((v) => v.number == verseNum);
      String verseText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
      
      // Clamp to verse text length
      localHighlightStart = localHighlightStart.clamp(0, verseText.length);
      localHighlightEnd = localHighlightEnd.clamp(localHighlightStart, verseText.length);
      
      print('   V$verseNum: local=$localHighlightStart-$localHighlightEnd, text="${verseText.substring(localHighlightStart, min(localHighlightEnd, localHighlightStart + 30))}..."');
      
      if (localHighlightStart < localHighlightEnd) {
        TextRange highlightRange = TextRange(start: localHighlightStart, end: localHighlightEnd);
        
        if (!highlightedRanges[_chapterKey]!.containsKey(verseNum)) {
          highlightedRanges[_chapterKey]![verseNum] = [];
        }
        
        highlightedRanges[_chapterKey]![verseNum] = _toggleRange(
          highlightedRanges[_chapterKey]![verseNum]!,
          highlightRange
        );
      }
    }
  });
  
  _saveHighlightedRanges();
}

  void _handleVerseUnderline(String fullText, TextSelection selection, int firstDetectedVerse, bool isArabic) {
    
    if (selection.isCollapsed) {
      return;
    }
    
    // Get all verses that the selection spans
    List<int> spannedVerses = _getSpannedVerses(selection);
    
    if (spannedVerses.isEmpty) {
      return;
    }
    
    
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
    
    _saveUnderlinedRanges();
  }


  void _debugVersePositions() {
    print('🔍 DEBUG VERSE POSITIONS:');
    print('📊 Total verses: ${verses.length}');
    
    int currentPos = 0;
    for (int i = 0; i < verses.length; i++) {
      VerseData verse = verses[i];
      
      if (verse.number == 0) {
        String displayText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
        print('📍 Chapter heading at $currentPos: length=${displayText.length}');
        currentPos += displayText.length + 2; // +2 for \n\n
        continue;
      }
      
      // Account for verse number WidgetSpan (1 char: U+FFFC)
      int verseStartPos = currentPos;
      currentPos += 1; // WidgetSpan
      
      String processedText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;
      int verseTextLength = processedText.length;
      
      int verseEndPos = currentPos + verseTextLength;
      
      // Compare with stored range
      TextRange? storedRange = verseTextRanges[verse.number];
      
      print('📍 Verse ${verse.number}:');
      print('   Calculated: $verseStartPos to $verseEndPos (len=$verseTextLength)');
      if (storedRange != null) {
        print('   Stored:     ${storedRange.start} to ${storedRange.end} (len=${storedRange.end - storedRange.start})');
        if (verseStartPos != storedRange.start || verseEndPos != storedRange.end) {
          print('   ⚠️ MISMATCH!');
        }
      }
      print('   First 50 chars: "${processedText.substring(0, min(50, processedText.length))}"');
      
      currentPos = verseEndPos;
      
      if (i < verses.length - 1) {
        currentPos += 1; // space between verses
      }
    }
  }

  String _cleanTextForCopy(String selectedText) {
    String cleaned = selectedText;
    
    // Remove directional markers first
    cleaned = cleaned.replaceAll('\u200F', ''); // RTL mark
    cleaned = cleaned.replaceAll('\u2066', ''); // LRI mark
    cleaned = cleaned.replaceAll('\u2069', ''); // PDI mark
    cleaned = cleaned.replaceAll('\uFFFC', ''); // Object replacement character
    
    // Remove footnote references [1], [2], etc.
    cleaned = cleaned.replaceAll(RegExp(r'\[\d+\]'), '');
    
    // Remove ALL standalone numbers (verse numbers)
    // This matches any sequence of digits that are standalone
    cleaned = cleaned.replaceAll(RegExp(r'\d+'), '');
    
    // Clean up multiple spaces that might result from removing numbers
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Clean up dots/periods that might be left alone after removing numbers
    cleaned = cleaned.replaceAll(RegExp(r'\s*\.\s*'), '. ').trim();
    
    return cleaned;
  }

/// Converts EditableText selection positions to actual text positions
/// by removing special characters that EditableText includes but our ranges don't
  TextSelection _convertEditableSelectionToActualSelection(TextSelection editableSelection, String fullEditableText) {
    print('🔄 CONVERTING SELECTION:');
    print('   Editable: ${editableSelection.start} to ${editableSelection.end}');
    
    if (editableSelection.start >= fullEditableText.length || editableSelection.end > fullEditableText.length) {
      print('   ⚠️ Invalid bounds, returning original');
      return editableSelection;
    }
    
    // Count special characters before start position
    int specialCharsBeforeStart = 0;
    for (int i = 0; i < editableSelection.start && i < fullEditableText.length; i++) {
      String char = fullEditableText[i];
      int code = char.codeUnitAt(0);
      
      // Count: RTL marks, LRI/PDI marks, Object replacement (WidgetSpan)
      if (code == 0x200F ||  // RTL mark
          code == 0x2066 ||  // LRI mark  
          code == 0x2069 ||  // PDI mark
          code == 0xFFFC) {  // Object replacement character (WidgetSpan)
        specialCharsBeforeStart++;
      }
    }
    
    // Count special characters before end position
    int specialCharsBeforeEnd = 0;
    for (int i = 0; i < editableSelection.end && i < fullEditableText.length; i++) {
      String char = fullEditableText[i];
      int code = char.codeUnitAt(0);
      
      if (code == 0x200F ||  // RTL mark
          code == 0x2066 ||  // LRI mark
          code == 0x2069 ||  // PDI mark
          code == 0xFFFC) {  // Object replacement character
        specialCharsBeforeEnd++;
      }
    }
    
    // Adjust positions by subtracting special characters
    int actualStart = editableSelection.start + specialCharsBeforeStart;
    int actualEnd = editableSelection.end + specialCharsBeforeEnd;
    
    print('   Special chars before start: $specialCharsBeforeStart');
    print('   Special chars before end: $specialCharsBeforeEnd');
    print('   Actual: $actualStart to $actualEnd');
    
    return TextSelection(
      baseOffset: actualStart.clamp(0, actualStart),
      extentOffset: actualEnd.clamp(actualStart, actualEnd),
    );
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
    
    // print('🔧 BUILD VERSE SPANS: Verse $verseNumber, text length=${processedText.length}');
    
    List<InlineSpan> spans = [];
    
    RegExp footnotePattern = RegExp(r'\[(\d+)\]');
    int lastEnd = 0;
    
    List<Match> matches = footnotePattern.allMatches(processedText).toList();
    
    for (int matchIndex = 0; matchIndex < matches.length; matchIndex++) {
      Match match = matches[matchIndex];
      int start = match.start;
      int end = match.end;
      int footnoteNum = int.parse(match.group(1)!);
          
      // Add text BEFORE footnote with styling
      if (start > lastEnd) {
        String textBefore = processedText.substring(lastEnd, start);
        // DON'T add RTL marker here
        spans.addAll(_buildStyledSpans(textBefore, hlRanges, ulRanges, isArabic, lastEnd));
      }
      
      bool footnoteHighlighted = hlRanges.any((r) => r.start <= start && r.end >= end);
      bool footnoteUnderlined = ulRanges.any((r) => r.start <= start && r.end >= end);
      
      final footnoteKeyId = 'fn_${footnoteNum}_${verseNumber}_$matchIndex';
      if (!_footnoteNumberKeys.containsKey(footnoteKeyId)) {
        _footnoteNumberKeys[footnoteKeyId] = GlobalKey();
      }
      final footnoteNumberKey = _footnoteNumberKeys[footnoteKeyId]!;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _FootnoteNumberWidget(
          key: footnoteNumberKey,
          footnoteNum: footnoteNum,
          fontSize: widget.fontSize,
          color: themeProvider.footnoteNumberColor,
          isHighlighted: footnoteHighlighted,
          isUnderlined: footnoteUnderlined,
          primaryColor: Theme.of(context).primaryColor,
          onTap: () => _scrollToFootnote(footnoteNum),
        ),
      ));
            
      lastEnd = end;
    }
    
    // Add remaining text after last footnote
    if (lastEnd < processedText.length) {
      String remainingText = processedText.substring(lastEnd);
      // DON'T add RTL marker here
      spans.addAll(_buildStyledSpans(remainingText, hlRanges, ulRanges, isArabic, lastEnd));
    }
    
    return spans;
  }

  List<InlineSpan> _buildStyledSpans(String text, List<TextRange> hlRanges, List<TextRange> ulRanges, bool isArabic, int offset) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    if (text.isEmpty) return [];
    
    // CRITICAL: Don't add RTL markers here - they mess up position calculations
    String cleanText = text;
    
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

      String spanText = cleanText.substring(start, end);
      
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
    print('🎨 BUILD: isLoading=$isLoading, verses.length=${verses.length}, chapterContent.length=${chapterContent.length}');
    
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
                                          child: FixedSelectableText(
                                            footnoteContent,
                                            style: _getFontStyle(isArabic).copyWith(
                                              fontSize: widget.fontSize * 0.85,
                                              color: themeProvider.secondaryTextColor,
                                            ),
                                            strutStyle: StrutStyle(
                                              fontSize: widget.fontSize * 0.85,
                                              height: 1.0,
                                              forceStrutHeight: true,
                                              fontFamily: isArabic ? widget.fontFamily : 'serif',
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

  void _schedulePositionSwapping() {
    
    if (!mounted || _isSwappingPositions) return;
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _swapVerseNumberPositions();
    });
  }

  void _swapVerseNumberPositions() {
    if (!mounted || _isSwappingPositions) {
      return;
    }
    

    // Reset all offsets first
    _resetAllVerseOffsets();

    setState(() {
      _isSwappingPositions = true;
    });

    try {
      // Group verse numbers by their Y position (same line)
      Map<double, List<_VersePosition>> lineGroups = {};
      
      for (var entry in _verseNumberKeys.entries) {
        final verseNum = entry.key;
        final key = entry.value;
        final context = key.currentContext;
        
        
        if (context == null) continue;
        
        final renderBox = context.findRenderObject() as RenderBox?;
        
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          final yPos = (position.dy / 10).round() * 10.0;
          
          
          if (!lineGroups.containsKey(yPos)) {
            lineGroups[yPos] = [];
          }
          
          lineGroups[yPos]!.add(_VersePosition(
            verseNumber: verseNum,
            xPosition: position.dx,
            key: key,
          ));
        }
      }


      for (var entry in _footnoteNumberKeys.entries) {
        final footnoteKeyId = entry.key;  // This is a String
        final key = entry.value;
        final context = key.currentContext;
        
        
        if (context == null) continue;
        
        final renderBox = context.findRenderObject() as RenderBox?;
        
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          final yPos = (position.dy / 10).round() * 10.0;
          
          
          if (!lineGroups.containsKey(yPos)) {
            lineGroups[yPos] = [];
          }
          
          // Use hash code as unique identifier (won't conflict with positive verse numbers)
          lineGroups[yPos]!.add(_VersePosition(
            verseNumber: -footnoteKeyId.hashCode,  // Use hash of string ID
            xPosition: position.dx,
            key: key,
          ));
        }
      }

      
      
      // For each line with multiple verse numbers, swap them
      int lineIndex = 0;
      for (var entry in lineGroups.entries) {
        final yPos = entry.key;
        final positions = entry.value;
        lineIndex++;
        
        
        if (positions.length > 1) {
          // Sort by X position
          positions.sort((a, b) => a.xPosition.compareTo(b.xPosition));
          
          
          // Apply swapping by reversing the list
          for (int i = 0; i < positions.length; i++) {
            final currentPos = positions[i];
            final targetIndex = positions.length - 1 - i;
            final targetPos = positions[targetIndex];
            
            
            final context = currentPos.key.currentContext;
            if (context != null) {
              // Try to get the state directly from the StatefulElement
              final element = context as StatefulElement?;
              final offsetX = targetPos.xPosition - currentPos.xPosition;

              // Handle both verse numbers (positive) and footnote numbers (negative)
              if (currentPos.verseNumber > 0) {
                // Verse number
                final state = element?.state as _VerseNumberWidgetState?;
                if (state != null) {
                  state.updateOffset(offsetX);
                } else {
                }
              } else {
                // Footnote number (negative verseNumber)
                final state = element?.state as _FootnoteNumberWidgetState?;
                if (state != null) {
                  state.updateOffset(offsetX);
                } else {
                }
              }
            } else {
            }
          }
          
        } else {
        }
      }
      
    } catch (e, stackTrace) {
    } finally {
      if (mounted) {
        // Force a rebuild to apply all the transforms
        setState(() {
          _isSwappingPositions = false;
        });
        
        // Schedule another frame to ensure transforms are applied
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // Empty setState to force rebuild with new offsets
            });
          }
        });
      }
    }
  }

  void _resetAllVerseOffsets() {
    
    for (var entry in _verseNumberKeys.entries) {
      final context = entry.value.currentContext;
      if (context != null) {
        final element = context as StatefulElement?;
        final state = element?.state as _VerseNumberWidgetState?;
        
        if (state != null) {
          state.updateOffset(0.0);
        }
      }
    }

    for (var entry in _footnoteNumberKeys.entries) {
      final context = entry.value.currentContext;
      if (context != null) {
        final element = context as StatefulElement?;
        final state = element?.state as _FootnoteNumberWidgetState?;
        
        if (state != null) {
          state.updateOffset(0.0);
        }
      }
    }
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


class _VersePosition {
  final int verseNumber;
  final double xPosition;
  final GlobalKey key;
  
  _VersePosition({
    required this.verseNumber,
    required this.xPosition,
    required this.key,
  });
}

class _VerseNumberWidget extends StatefulWidget {
  final GlobalKey verseKey;
  final String verseNumText;
  final double fontSize;
  final String fontFamily;
  final Color color;
  final bool isHighlighted;
  final bool isUnderlined;
  final Color primaryColor;
  
  const _VerseNumberWidget({
    required Key key,
    required this.verseKey,
    required this.verseNumText,
    required this.fontSize,
    required this.fontFamily,
    required this.color,
    required this.isHighlighted,
    required this.isUnderlined,
    required this.primaryColor,
  }) : super(key: key);
  
  @override
  State<_VerseNumberWidget> createState() => _VerseNumberWidgetState();
}

class _FootnoteNumberWidget extends StatefulWidget {
  final int footnoteNum;
  final double fontSize;
  final Color color;
  final bool isHighlighted;
  final bool isUnderlined;
  final Color primaryColor;
  final VoidCallback onTap;
  
  const _FootnoteNumberWidget({
    required Key key,
    required this.footnoteNum,
    required this.fontSize,
    required this.color,
    required this.isHighlighted,
    required this.isUnderlined,
    required this.primaryColor,
    required this.onTap,
  }) : super(key: key);
  
  @override
  State<_FootnoteNumberWidget> createState() => _FootnoteNumberWidgetState();
}

class _FootnoteNumberWidgetState extends State<_FootnoteNumberWidget> {
  double _offsetX = 0.0;
  
  void updateOffset(double newOffset) {
    if (_offsetX != newOffset) {
      setState(() {
        _offsetX = newOffset;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: Transform.translate(
        offset: Offset(_offsetX, 0),
        transformHitTests: false,
        child: widget.isHighlighted
            ? Container(
                padding: const EdgeInsets.only(
                  left: 0.0,
                  right: 0.0,
                  top: 5,
                  bottom: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '\u2066${widget.footnoteNum}\u2069',
                  style: TextStyle(
                    fontSize: widget.fontSize * 0.65,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                    fontFeatures: const [FontFeature.superscripts()],
                    height: 1.8,
                    decoration: widget.isUnderlined ? TextDecoration.underline : null,
                    decorationColor: widget.primaryColor,
                    decorationThickness: 2,
                  ),
                ),
              )
            : Text(
                '\u2066${widget.footnoteNum}\u2069',
                style: TextStyle(
                  fontSize: widget.fontSize * 0.65,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                  fontFeatures: const [FontFeature.superscripts()],
                  height: 1.8,
                  decoration: widget.isUnderlined ? TextDecoration.underline : null,
                  decorationColor: widget.primaryColor,
                  decorationThickness: 2,
                ),
              ),
      ),
    );
  }
}

class _VerseNumberWidgetState extends State<_VerseNumberWidget> {
  double _offsetX = 0.0;  // Move offset to STATE
  
  void updateOffset(double newOffset) {
    if (_offsetX != newOffset) {
      setState(() {
        _offsetX = newOffset;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(_offsetX, 0),
      transformHitTests: true,
      child: widget.isHighlighted
          ? Container(
              padding: const EdgeInsets.only(
                left: 0,
                right: 0,
                top: 3.8,
                bottom: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(0),
              ),
              child: Text(
                widget.verseNumText,
                key: widget.verseKey,
                style: TextStyle(
                  fontSize: widget.fontSize * 0.8,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                  fontFamily: widget.fontFamily,
                  letterSpacing: 0.5,
                  height: 1.8,
                  decoration: widget.isUnderlined ? TextDecoration.underline : null,
                  decorationColor: widget.primaryColor,
                  decorationThickness: 2,
                ),
              ),
            )
          : Text(
              widget.verseNumText,
              key: widget.verseKey,
              style: TextStyle(
                fontSize: widget.fontSize * 0.8,
                fontWeight: FontWeight.bold,
                color: widget.color,
                fontFamily: widget.fontFamily,
                letterSpacing: 0.5,
                height: 1.8,
                decoration: widget.isUnderlined ? TextDecoration.underline : null,
                decorationColor: widget.primaryColor,
                decorationThickness: 2,
              ),
            ),
    );
  }
}



// starting the swapping thing
