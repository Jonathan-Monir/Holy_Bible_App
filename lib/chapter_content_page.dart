// lib/chapter_content_page.dart
import 'color_picker_dialog.dart';
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

  static const double _lineHeight = 1.8;  // Adjust this value as needed
  String chapterContent = '';
  bool isLoading = true;
  List<VerseData> verses = [];
  Map<String, Map<int, List<TextRange>>> highlightedRanges = <String, Map<int, List<TextRange>>>{};
  Map<String, Map<int, List<TextRange>>> underlinedRanges = <String, Map<int, List<TextRange>>>{};


  Color _highlightColor = Colors.yellow;
  Color _underlineColor = Colors.blue;

  String footnotes = '';
  final GlobalKey _footnotesKey = GlobalKey();

  // NEW - Add this instead:
  final Map<int, GlobalKey> _verseKeys = {};  // Keep for verse scrolling (int key for verse number)
  final Map<String, GlobalKey> _uniqueVerseKeys = {};
  Map<int, TextRange> verseTextRanges = {};
  late ScrollController _scrollController;

  final Map<String, GlobalKey> _footnoteNumberKeys = {};  // For inline footnote numbers in verses
  final Map<int, GlobalKey> _footnoteKeys = {};  // For footnote section at bottom

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
      print('🟣 CHAPTER_PAGE: initState called');
      print('🟣 CHAPTER_PAGE: bookIndex=${widget.bookIndex}, chapterNumber=${widget.chapterNumber}');
      
      super.initState();
      _scrollController = ScrollController();
      
      print('🟣 CHAPTER_PAGE: Scheduling post-frame callback...');
      // Defer heavy operations until after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🟣 CHAPTER_PAGE: Post-frame callback executing, mounted=$mounted');
        if (mounted) {
          print('🟣 CHAPTER_PAGE: Loading saved annotations...');
          _loadSavedAnnotations();
          
          print('🟣 CHAPTER_PAGE: Loading chapter content...');
          _loadChapterContent();
          
        } else {
          print('🟣 CHAPTER_PAGE: NOT MOUNTED in post-frame callback');
        }
      });

      print('🟣 CHAPTER_PAGE: initState completed');
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
    
    // No action needed for fontSize/fontFamily changes — text layout handles it
  }

  String get _chapterKey => '${widget.bookIndex}_${widget.chapterNumber}';

  Future<void> _loadSavedAnnotations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load highlight color
      final highlightColorValue = prefs.getInt('highlight_color');
      if (highlightColorValue != null) {
        _highlightColor = Color(highlightColorValue);
      }
      
      // Load underline color
      final underlineColorValue = prefs.getInt('underline_color');
      if (underlineColorValue != null) {
        _underlineColor = Color(underlineColorValue);
      }
      
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

  Future<void> _saveHighlightColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highlight_color', color.value);
      setState(() {
        _highlightColor = color;
      });
    } catch (e) {
      print('Error saving highlight color: $e');
    }
  }

  Future<void> _saveUnderlineColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('underline_color', color.value);
      setState(() {
        _underlineColor = color;
      });
    } catch (e) {
      print('Error saving underline color: $e');
    }
  }

  Future<void> _showHighlightColorPicker() async {
    final Color? newColor = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ColorPickerBottomSheet(
          title: 'Choose Highlight Color',
          currentColor: _highlightColor,
        );
      },
    );
    
    if (newColor != null) {
      await _saveHighlightColor(newColor);
    }
  }

  Future<void> _showUnderlineColorPicker() async {
    final Color? newColor = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ColorPickerBottomSheet(
          title: 'Choose Underline Color',
          currentColor: _underlineColor,
        );
      },
    );
    
    if (newColor != null) {
      await _saveUnderlineColor(newColor);
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
    // print('🔵 START: Loading chapter ${widget.bookIndex} - ${widget.chapterNumber}');
    
    try {
      final content = await BibleData.getChapterContent(widget.bookIndex, widget.chapterNumber);
      // print('📄 Content loaded, length: ${content.length}');
      // print('📄 First 200 chars: ${content.substring(0, min(200, content.length))}');
      
      final fn = await BibleData.getChapterFootnotes(widget.bookIndex, widget.chapterNumber);
      // print('📝 Footnotes loaded, length: ${fn.length}');
      
      if (mounted) {
        print('🔄 Parsing verses for chapter ${widget.chapterNumber}...');
        print('📄 Raw content length: ${content.length}');
        print('📄 First 500 chars: ${content.substring(0, min(500, content.length))}');
        
        final parsedVerses = _parseVersesToList(content);
        print('✅ Parsed ${parsedVerses.length} verses');
        
        if (parsedVerses.isEmpty) {
          print('❌ WARNING: No verses parsed!');
        }
        
        for (int i = 0; i < min(5, parsedVerses.length); i++) {
          print('   Verse ${parsedVerses[i].number}: ${parsedVerses[i].text.substring(0, min(50, parsedVerses[i].text.length))}...');
        }
        
        // print('🔄 Computing verse text ranges...');
        final ranges = _computeVerseTextRanges(parsedVerses, widget.removeDiacritics);
        // print('✅ Computed ${ranges.length} ranges');

        setState(() {
          chapterContent = content;
          verses = parsedVerses;
          verseTextRanges = ranges;
          footnotes = fn;
          isLoading = false;
        });

        _debugVersePositions();
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
    List<VerseData> verseList = [];
    List<String> lines = content.split('\n');
    
    // Check if this chapter has verse numbers
    bool hasVerseNumbers = lines.any((line) {
      if (line.trim().isEmpty) return false;
      RegExp versePattern = RegExp(r'^(\d+)(.*)');
      return versePattern.hasMatch(line.trim());
    });
    
    if (!hasVerseNumbers) {
      // Handle chapters without verse numbers (auto-number them)
      int autoVerseNumber = 1;
      String? chapterHeading;
      
      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        
        // First non-empty line might be chapter heading if it contains specific patterns
        if (chapterHeading == null) {
          String cleanLine = BibleData.removeTashkeel(line.trim());
          if (RegExp(r'^(اَلْمَزْمُورُ|الإصحاح|Chapter)').hasMatch(cleanLine)) {
            chapterHeading = line.trim();
            verseList.add(VerseData(number: 0, text: chapterHeading));
            continue;
          }
        }
        
        // Auto-number verses
        String verseText = line.trim();
        
        // Extract footnote references
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
          number: autoVerseNumber,
          text: verseText,
          footnoteRefs: footnoteRefs,
        ));
        autoVerseNumber++;
      }
    } else {
      // Original logic for chapters WITH verse numbers
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
          // Line doesn't match verse pattern - might be chapter heading
          if (line.trim().isNotEmpty) {
            verseList.add(VerseData(number: 0, text: line.trim()));
          }
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

  Map<int, TextRange> _computeVerseTextRanges(List<VerseData> verses, bool removeDiacritics) {
    print('🔧 COMPUTE VERSE TEXT RANGES: Starting...');

    Map<int, TextRange> ranges = {};
    int offset = 0;

    for (int i = 0; i < verses.length; i++) {
      VerseData verse = verses[i];

      if (verse.number == 0) {
        // FIX: Skip verse 0 (chapter headings) — they are NOT rendered in
        // _buildAllVersesWidget, so they must NOT contribute to the offset.
        // Previously this added displayText.length + 2 to offset, which shifted
        // all subsequent verse ranges forward and caused highlights to land on
        // earlier text than what the user actually selected.
        print('🔧 VERSE RANGES: Skipping verse 0 (heading): "${verse.text.substring(0, verse.text.length.clamp(0, 50))}"');
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
      // Start with the processed text length
      int displayedLength = processedText.length;
      
      // Each [N] in text becomes a WidgetSpan (1 char: U+FFFC)
      // So we subtract the bracket length [1] = 3 chars, and add 1 for the widget
      for (Match match in footnoteMatches) {
        int bracketLength = match.group(0)!.length; // "[1]" = 3, "[12]" = 4, etc.
        displayedLength = displayedLength - bracketLength + 1; // Replace with 1 widget char
      }
      
      // CRITICAL: The range should match what EditableText sees (WITH widgets)
      // So we keep the offset in the "editable" coordinate system
      ranges[verse.number] = TextRange(start: start, end: offset + displayedLength);

      print('🔧 VERSE RANGES: V${verse.number}: range $start-${offset + displayedLength}, textLen=${processedText.length}, displayLen=$displayedLength, footnotes=${footnoteMatches.length}');

      offset += displayedLength;

      if (i < verses.length - 1) {
        offset += 1; // ' ' between verses
      }
    }

    print('🔧 COMPUTE VERSE TEXT RANGES: Complete, ${ranges.length} ranges, final offset=$offset');
    return ranges;
  }

  List<int> _getSpannedVerses(TextSelection selection) {
    // print('🔍 GET SPANNED VERSES:');
    // print('   Selection: ${selection.start} to ${selection.end}');
    
    List<int> spannedVerses = [];
    
    for (final entry in verseTextRanges.entries) {
      final verseNum = entry.key;
      final range = entry.value;
      
      // print('   Checking verse $verseNum: range ${range.start} to ${range.end}');
      
      // Check if selection overlaps with this verse's range
      if (selection.start < range.end && selection.end > range.start) {
        // print('   ✓ Verse $verseNum IS in selection');
        spannedVerses.add(verseNum);
      } else {
        // print('   ✗ Verse $verseNum NOT in selection');
      }
    }
    
    spannedVerses.sort();
    // print('   Final spanned verses: $spannedVerses');
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
        // Skip chapter headings - they're already shown in the page title
        // This handles both manually numbered chapters and auto-numbered ones
        continue;
      } else {
        // Create unique identifiers using both verse number AND index
        final uniqueKeyIdentifier = '${verse.number}_$i';
        if (!_uniqueVerseKeys.containsKey(uniqueKeyIdentifier)) {
          _uniqueVerseKeys[uniqueKeyIdentifier] = GlobalKey();
        }
        
        // CRITICAL FIX: Use index-based key for _verseKeys too to avoid duplicates
        final verseKeyIdentifier = '${verse.number}_$i';
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

        // CRITICAL FIX: Create a unique GlobalKey for each verse number widget instance
        final verseNumberKey = GlobalKey();  // ← Always create a new unique key

        // FIX: Removed Directionality(textDirection: TextDirection.ltr) wrapper.
        // Digits already render left-to-right in RTL context (Unicode BiDi rule).
        // The LTR wrapper was causing verse numbers on the same line to swap
        // positions due to BiDi reordering. Footnote numbers (which never had
        // this wrapper) didn't have the problem.
        allSpans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _VerseNumberWidget(
            key: verseNumberKey,
            verseKey: verseKey,
            verseNumText: verseNumText,
            fontSize: widget.fontSize,
            fontFamily: isArabic ? widget.fontFamily : 'serif',
            color: themeProvider.verseNumberColor,
            isHighlighted: verseNumHighlighted,
            isUnderlined: verseNumUnderlined,
            primaryColor: Theme.of(context).primaryColor,
            highlightColor: _highlightColor,
            underlineColor: _underlineColor,
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
    
    print('🎯 CONTEXT MENU: Chapter ${widget.bookIndex}-${widget.chapterNumber}');
    print('🎯 SELECTION from EditableText: ${editableSelection.start} to ${editableSelection.end}');
    print('   verseTextRanges has ${verseTextRanges.length} entries');

    if (!editableSelection.isValid || editableSelection.isCollapsed) {
      return const SizedBox.shrink();
    }

    final String selectedText = value.text.substring(editableSelection.start, editableSelection.end);
    print('🎯 CONTEXT MENU: selectedText="${selectedText.substring(0, selectedText.length.clamp(0, 80))}"');
    print('🎯 CONTEXT MENU: fullText length=${value.text.length}');

    // Detect verse using precomputed ranges
    int? detectedVerseNumber;
    for (final entry in verseTextRanges.entries) {
      final range = entry.value;
      if (editableSelection.start >= range.start && editableSelection.start < range.end) {
        detectedVerseNumber = entry.key;
        print('🎯 CONTEXT MENU: detected verse $detectedVerseNumber (range ${range.start}-${range.end})');
        break;
      }
    }
    
    List<ContextMenuButtonItem> buttonItems = [];
    
    buttonItems.add(
      ContextMenuButtonItem(
        label: isArabic ? 'نسخ' : 'Copy',
        onPressed: () {
          String cleanedText = _cleanTextForCopy(selectedText);
          // print("hey cleaned text ${cleanedText}");
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
      // Highlight button
      buttonItems.add(
        ContextMenuButtonItem(
          label: isArabic ? 'تمييز' : 'Highlight',
          onPressed: () {
            _handleVerseHighlight(value.text, editableSelection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
          },
        ),
      );
      
      // Highlight color button (compact icon)
      buttonItems.add(
        ContextMenuButtonItem(
          label: '🎨',  // Color palette emoji
          onPressed: () {
            // First apply highlight if not already highlighted
            _handleVerseHighlight(value.text, editableSelection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
            // Then show color picker
            Future.delayed(const Duration(milliseconds: 100), () {
              _showHighlightColorPicker();
            });
          },
        ),
      );
      
      // Underline button
      buttonItems.add(
        ContextMenuButtonItem(
          label: isArabic ? 'تسطير' : 'Underline',
          onPressed: () {
            _handleVerseUnderline(value.text, editableSelection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
          },
        ),
      );

      // Underline color button (compact icon)
      buttonItems.add(
        ContextMenuButtonItem(
          label: '🎨',  // Color palette emoji
          onPressed: () {
            // First apply underline if not already underlined
            _handleVerseUnderline(value.text, editableSelection, detectedVerseNumber!, isArabic);
            editableTextState.hideToolbar();
            // Then show color picker
            Future.delayed(const Duration(milliseconds: 100), () {
              _showUnderlineColorPicker();
            });
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
    print('🎯 HIGHLIGHT: sel=${selection.start}-${selection.end}, firstVerse=$firstDetectedVerse');

    if (selection.isCollapsed) return;

    // Get all verses that the selection spans (using editable coordinates)
    List<int> spannedVerses = _getSpannedVerses(selection);
    print('🎯 HIGHLIGHT: spannedVerses=$spannedVerses');
    if (spannedVerses.isEmpty) return;

    // Extract the actual selected text from the EditableText for verification
    final int selStart = selection.start.clamp(0, fullText.length);
    final int selEnd = selection.end.clamp(selStart, fullText.length);
    final String actualSelectedText = fullText.substring(selStart, selEnd);
    print('🎯 HIGHLIGHT: actualSelectedText="${actualSelectedText.substring(0, actualSelectedText.length.clamp(0, 80))}"');

    setState(() {
      if (!highlightedRanges.containsKey(_chapterKey)) {
        highlightedRanges[_chapterKey] = {};
      }

      for (int verseNum in spannedVerses) {
        if (!verseTextRanges.containsKey(verseNum)) continue;

        TextRange verseRange = verseTextRanges[verseNum]!;

        // Calculate global selection boundaries within this verse (in editable coordinates)
        int globalHighlightStart = max(selection.start, verseRange.start);
        int globalHighlightEnd = min(selection.end, verseRange.end);

        // Get the verse text (with original [N] brackets)
        final verse = verses.firstWhere((v) => v.number == verseNum);
        String verseText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;

        // Convert to local position within verse text
        // verseRange.start points to the verse number widget
        // verseRange.start + 1 is where the actual text begins
        int localHighlightStart = globalHighlightStart - (verseRange.start + 1);
        int localHighlightEnd = globalHighlightEnd - (verseRange.start + 1);

        // Calculate displayed length (footnotes as widgets)
        RegExp footnotePattern = RegExp(r'\[(\d+)\]');
        int displayedLength = verseText.length;
        for (Match match in footnotePattern.allMatches(verseText)) {
          displayedLength -= (match.group(0)!.length - 1); // [N] becomes single widget
        }

        // Clamp to displayed length
        localHighlightStart = localHighlightStart.clamp(0, displayedLength);
        localHighlightEnd = localHighlightEnd.clamp(localHighlightStart, displayedLength);

        // Convert from displayed coordinates to original text coordinates (with brackets)
        int originalStart = _displayPosToOriginalPos(localHighlightStart, verseText);
        int originalEnd = _displayPosToOriginalPos(localHighlightEnd, verseText);

        // Debug: show exactly what text will be highlighted
        final int safeOrigStart = originalStart.clamp(0, verseText.length);
        final int safeOrigEnd = originalEnd.clamp(safeOrigStart, verseText.length);
        final String highlightedText = verseText.substring(safeOrigStart, safeOrigEnd);
        print('🎯 HIGHLIGHT V$verseNum: verseRange=${verseRange.start}-${verseRange.end}, '
            'global=$globalHighlightStart-$globalHighlightEnd, '
            'local=$localHighlightStart-$localHighlightEnd, '
            'original=$originalStart-$originalEnd, '
            'text="$highlightedText"');

        if (originalStart < originalEnd) {
          TextRange highlightRange = TextRange(start: originalStart, end: originalEnd);

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
    print('📏 UNDERLINE: sel=${selection.start}-${selection.end}, firstVerse=$firstDetectedVerse');

    if (selection.isCollapsed) return;

    List<int> spannedVerses = _getSpannedVerses(selection);
    print('📏 UNDERLINE: spannedVerses=$spannedVerses');
    if (spannedVerses.isEmpty) return;

    final int selStart = selection.start.clamp(0, fullText.length);
    final int selEnd = selection.end.clamp(selStart, fullText.length);
    final String actualSelectedText = fullText.substring(selStart, selEnd);
    print('📏 UNDERLINE: actualSelectedText="${actualSelectedText.substring(0, actualSelectedText.length.clamp(0, 80))}"');

    setState(() {
      if (!underlinedRanges.containsKey(_chapterKey)) {
        underlinedRanges[_chapterKey] = {};
      }

      for (int verseNum in spannedVerses) {
        if (!verseTextRanges.containsKey(verseNum)) continue;

        TextRange verseRange = verseTextRanges[verseNum]!;

        int globalUnderlineStart = max(selection.start, verseRange.start);
        int globalUnderlineEnd = min(selection.end, verseRange.end);

        final verse = verses.firstWhere((v) => v.number == verseNum);
        String verseText = widget.removeDiacritics ? BibleData.removeTashkeel(verse.text) : verse.text;

        int localUnderlineStart = globalUnderlineStart - (verseRange.start + 1);
        int localUnderlineEnd = globalUnderlineEnd - (verseRange.start + 1);

        RegExp footnotePattern = RegExp(r'\[(\d+)\]');
        int displayedLength = verseText.length;
        for (Match match in footnotePattern.allMatches(verseText)) {
          displayedLength -= (match.group(0)!.length - 1);
        }

        localUnderlineStart = localUnderlineStart.clamp(0, displayedLength);
        localUnderlineEnd = localUnderlineEnd.clamp(localUnderlineStart, displayedLength);

        int originalStart = _displayPosToOriginalPos(localUnderlineStart, verseText);
        int originalEnd = _displayPosToOriginalPos(localUnderlineEnd, verseText);

        final int safeOrigStart = originalStart.clamp(0, verseText.length);
        final int safeOrigEnd = originalEnd.clamp(safeOrigStart, verseText.length);
        final String underlinedText = verseText.substring(safeOrigStart, safeOrigEnd);
        print('📏 UNDERLINE V$verseNum: verseRange=${verseRange.start}-${verseRange.end}, '
            'global=$globalUnderlineStart-$globalUnderlineEnd, '
            'local=$localUnderlineStart-$localUnderlineEnd, '
            'original=$originalStart-$originalEnd, '
            'text="$underlinedText"');

        if (originalStart < originalEnd) {
          TextRange underlineRange = TextRange(start: originalStart, end: originalEnd);

          if (!underlinedRanges[_chapterKey]!.containsKey(verseNum)) {
            underlinedRanges[_chapterKey]![verseNum] = [];
          }

          underlinedRanges[_chapterKey]![verseNum] = _toggleRange(
            underlinedRanges[_chapterKey]![verseNum]!,
            underlineRange
          );
        }
      }
    });

    _saveUnderlinedRanges();
  }

/// Converts a position in displayed text (where [N] is a widget) to position in original text (with [N] brackets)
  int _displayPosToOriginalPos(int displayPos, String originalText) {
    RegExp footnotePattern = RegExp(r'\[(\d+)\]');
    List<Match> matches = footnotePattern.allMatches(originalText).toList();

    int originalPos = displayPos;
    int currentDisplayPos = 0;
    int currentOriginalPos = 0;

    for (Match match in matches) {
      int bracketStart = match.start;
      int bracketLength = match.group(0)!.length;

      // Add the text before this bracket
      int textBeforeBracket = bracketStart - currentOriginalPos;

      if (currentDisplayPos + textBeforeBracket >= displayPos) {
        // The target position is before this bracket
        print('🔧 DISPLAY→ORIG: displayPos=$displayPos → originalPos=$originalPos (before bracket at $bracketStart)');
        return originalPos;
      }

      currentDisplayPos += textBeforeBracket;
      currentOriginalPos = bracketStart + bracketLength;

      // The bracket becomes 1 widget character in display
      // FIX: Each [N] bracket (length bracketLength) maps to 1 display char.
      // The shift in original coords is (bracketLength - 1), NOT bracketLength.
      // Previously this added the full bracketLength, which over-shifted positions
      // for any verse containing footnotes.
      if (currentDisplayPos < displayPos) {
        currentDisplayPos += 1;
        originalPos += (bracketLength - 1);
      }
    }

    print('🔧 DISPLAY→ORIG: displayPos=$displayPos → originalPos=$originalPos (final, ${matches.length} footnotes)');
    return originalPos;
  }

  void _debugVersePositions() {
    // print('🔍 DEBUG VERSE POSITIONS:');
    // print('📊 Total verses: ${verses.length}');
    
    int currentPos = 0;
    for (int i = 0; i < verses.length; i++) {
      VerseData verse = verses[i];
      
      if (verse.number == 0) {
        // FIX: Skip verse 0 — matches _buildAllVersesWidget and _computeVerseTextRanges
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
      
      // print('📍 Verse ${verse.number}:');
      // print('   Calculated: $verseStartPos to $verseEndPos (len=$verseTextLength)');
      if (storedRange != null) {
        // print('   Stored:     ${storedRange.start} to ${storedRange.end} (len=${storedRange.end - storedRange.start})');
        if (verseStartPos != storedRange.start || verseEndPos != storedRange.end) {
          // print('   ⚠️ MISMATCH!');
        }
      }
      // print('   First 50 chars: "${processedText.substring(0, min(50, processedText.length))}"');
      
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
/// Converts EditableText selection positions to actual text positions
/// by removing special characters that EditableText includes but our ranges don't
  TextSelection _convertEditableSelectionToActualSelection(TextSelection editableSelection, String fullEditableText) {
    // print('🔄 CONVERTING SELECTION:');
    // print('   Editable: ${editableSelection.start} to ${editableSelection.end}');
    
    if (editableSelection.start >= fullEditableText.length || editableSelection.end > fullEditableText.length) {
      // print('   ⚠️ Invalid bounds, returning original');
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
    
    // CRITICAL FIX: Subtract special characters, don't add them!
    // The editable text has MORE characters than our ranges (due to widgets)
    // So we need to subtract to get back to the original positions
    int actualStart = editableSelection.start - specialCharsBeforeStart;
    int actualEnd = editableSelection.end - specialCharsBeforeEnd;
    
    // print('   Special chars before start: $specialCharsBeforeStart');
    // print('   Special chars before end: $specialCharsBeforeEnd');
    // print('   Actual: $actualStart to $actualEnd');
    
    return TextSelection(
      baseOffset: actualStart.clamp(0, actualStart),
      extentOffset: actualEnd.clamp(actualStart, actualEnd),
    );
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
          highlightColor: _highlightColor,  // ADD THIS
          underlineColor: _underlineColor,  // ADD THIS
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
          color: isHighlighted 
              ? _getContrastingTextColor(_highlightColor)  // Auto black/white based on highlight
              : themeProvider.primaryTextColor,
          backgroundColor: isHighlighted ? _highlightColor : null,
          decoration: isUnderlined ? TextDecoration.underline : null,
          decorationColor: isUnderlined ? _underlineColor : Theme.of(context).primaryColor,
          decorationThickness: 2,
        ),
      ));
    }
    return spans;
  }
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance using the standard formula
    // https://www.w3.org/TR/WCAG20/#relativeluminancedef
    double luminance = (0.299 * backgroundColor.red + 
                        0.587 * backgroundColor.green + 
                        0.114 * backgroundColor.blue) / 255;
    
    // If luminance is greater than 0.5, the color is light, so use black text
    // Otherwise, use white text
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    // print('🎨 BUILD: isLoading=$isLoading, verses.length=${verses.length}, chapterContent.length=${chapterContent.length}');
    
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
                  '${widget.arabicName} ${widget.chapterNumber}',  // ← Use arabicName instead of bookName
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
                                              height: 1.0,  // ← Add this for better line spacing within footnote
                                            ),
                                            strutStyle: StrutStyle(
                                              fontSize: widget.fontSize * 0.85,
                                              height: 1.8,  // ← Increase from 1.0 to 1.5 for more space between lines
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
              '${widget.arabicName} - ترجمة باسم يهوه - لإڤرايم بشرى برسوم',
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



class _VerseNumberWidget extends StatefulWidget {
  final GlobalKey verseKey;
  final String verseNumText;
  final double fontSize;
  final String fontFamily;
  final Color color;
  final bool isHighlighted;
  final bool isUnderlined;
  final Color primaryColor;
  final Color highlightColor;
  final Color underlineColor;
  
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
    required this.highlightColor,  // ADD THIS
    required this.underlineColor,  // ADD THIS
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
  final Color highlightColor;
  final Color underlineColor;
  
  const _FootnoteNumberWidget({
    required Key key,
    required this.footnoteNum,
    required this.fontSize,
    required this.color,
    required this.isHighlighted,
    required this.isUnderlined,
    required this.primaryColor,
    required this.onTap,
    required this.highlightColor,  // ADD THIS
    required this.underlineColor,  // ADD THIS
  }) : super(key: key);
  
  @override
  State<_FootnoteNumberWidget> createState() => _FootnoteNumberWidgetState();
}

class _FootnoteNumberWidgetState extends State<_FootnoteNumberWidget> {
  @override
  Widget build(BuildContext context) {
    // FIX: Use a single Text widget with backgroundColor in TextStyle instead
    // of wrapping in a Container with padding. Same fix as verse numbers —
    // keeps widget size stable across highlighted/non-highlighted states.
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: Text(
        '\u2066${widget.footnoteNum}\u2069',
        style: TextStyle(
          fontSize: widget.fontSize * 0.65,
          fontWeight: FontWeight.bold,
          color: widget.color,
          fontFeatures: const [FontFeature.superscripts()],
          height: 1.8,
          backgroundColor: widget.isHighlighted ? widget.highlightColor : null,
          decoration: widget.isUnderlined ? TextDecoration.underline : null,
          decorationColor: widget.isUnderlined ? widget.underlineColor : widget.primaryColor,
          decorationThickness: 2,
        ),
      ),
    );
  }
}

class _VerseNumberWidgetState extends State<_VerseNumberWidget> {
  @override
  Widget build(BuildContext context) {
    // FIX: Use a single Text widget for both highlighted and non-highlighted
    // states, applying backgroundColor via TextStyle instead of wrapping in a
    // Container with padding. The Container approach changed the widget's size,
    // causing highlight height to shrink and underlines to shift up.
    return Text(
      widget.verseNumText,
      key: widget.verseKey,
      style: TextStyle(
        fontSize: widget.fontSize * 0.8,
        fontWeight: FontWeight.bold,
        color: widget.color,
        fontFamily: widget.fontFamily,
        letterSpacing: 0.5,
        height: 1.8,
        backgroundColor: widget.isHighlighted ? widget.highlightColor : null,
        decoration: widget.isUnderlined ? TextDecoration.underline : null,
        decorationColor: widget.isUnderlined ? widget.underlineColor : widget.primaryColor,
        decorationThickness: 2,
      ),
    );
  }
}


//helb
