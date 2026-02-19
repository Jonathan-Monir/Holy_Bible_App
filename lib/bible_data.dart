// lib/bible_data.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class BibleData {
  static List<Map<String, dynamic>> books = [
    {'name': 'Genesis', 'shortName': 'Gen', 'chapters': 50, 'fileName': 'Genesis.txt', 'arabicName': 'التكوين'},
    {'name': 'Exodus', 'shortName': 'Exod', 'chapters': 40, 'fileName': 'Exodus.txt', 'arabicName': 'الخروج'},
    {'name': 'Leviticus', 'shortName': 'Lev', 'chapters': 27, 'fileName': 'Leviticus.txt', 'arabicName': 'اللاويين'},
    {'name': 'Numbers', 'shortName': 'Num', 'chapters': 36, 'fileName': 'Numbers.txt', 'arabicName': 'العدد (في البرية)'},
    {'name': 'Deuteronomy', 'shortName': 'Deut', 'chapters': 34, 'fileName': 'Deuteronomy.txt', 'arabicName': 'التثنية (او كلمات דְּבָרִים)'},
    {'name': 'Joshua', 'shortName': 'Josh', 'chapters': 24, 'fileName': 'Joshua.txt', 'arabicName': 'يهوشع'},
    {'name': 'Judges', 'shortName': 'Judg', 'chapters': 21, 'fileName': 'Judges.txt', 'arabicName': 'المدبرون'},
    {'name': 'Ruth', 'shortName': 'Ruth', 'chapters': 4, 'fileName': 'Ruth.txt', 'arabicName': 'روث (راعوث)'},
    {'name': '1 Samuel', 'shortName': '1 Sam', 'chapters': 31, 'fileName': '1Samuel.txt', 'arabicName': 'صموئيل الاول'},
    {'name': '2 Samuel', 'shortName': '2 Sam', 'chapters': 24, 'fileName': '2Samuel.txt', 'arabicName': 'صموئيل الثاني'},
    {'name': '1 Kings', 'shortName': '1 Kgs', 'chapters': 22, 'fileName': '1Kings.txt', 'arabicName': 'ملوك الاول'},
    {'name': '2 Kings', 'shortName': '2 Kgs', 'chapters': 25, 'fileName': '2Kings.txt', 'arabicName': 'ملوك الثاني'},
    {'name': '1 Chronicles', 'shortName': '1 Chr', 'chapters': 29, 'fileName': '1Chronicles.txt', 'arabicName': 'كلام الايام الاول'},
    {'name': '2 Chronicles', 'shortName': '2 Chr', 'chapters': 36, 'fileName': '2Chronicles.txt', 'arabicName': 'كلام الايام الثاني'},
    {'name': 'Ezra', 'shortName': 'Ezra', 'chapters': 10, 'fileName': 'Ezra.txt', 'arabicName': 'عزرا'},
    {'name': 'Nehemiah', 'shortName': 'Neh', 'chapters': 13, 'fileName': 'Nehemiah.txt', 'arabicName': 'نحمياه'},
    {'name': 'Esther', 'shortName': 'Esth', 'chapters': 10, 'fileName': 'Esther.txt', 'arabicName': 'استير'},
    {'name': 'Job', 'shortName': 'Job', 'chapters': 42, 'fileName': 'Job.txt', 'arabicName': 'ايوب'},
    {'name': 'Psalms', 'shortName': 'Ps', 'chapters': 150, 'fileName': 'Psalms.txt', 'arabicName': 'المزامير'},
    {'name': 'Proverbs', 'shortName': 'Prov', 'chapters': 31, 'fileName': 'Proverbs.txt', 'arabicName': 'الامثال'},
    {'name': 'Ecclesiastes', 'shortName': 'Eccl', 'chapters': 12, 'fileName': 'Ecclesiastes.txt', 'arabicName': 'كوهلت (جامع الحكمة)'},
    {'name': 'Song of Solomon', 'shortName': 'Song', 'chapters': 8, 'fileName': 'SongOfSolomon.txt', 'arabicName': 'اغنية الاغاني'},
    {'name': 'Isaiah', 'shortName': 'Isa', 'chapters': 66, 'fileName': 'Isaiah.txt', 'arabicName': 'يشعياهو'},
    {'name': 'Jeremiah', 'shortName': 'Jer', 'chapters': 52, 'fileName': 'Jeremiah.txt', 'arabicName': 'يرمياهو'},
    {'name': 'Lamentations', 'shortName': 'Lam', 'chapters': 5, 'fileName': 'Lamentations.txt', 'arabicName': 'مراثي يرمياهو'},
    {'name': 'Ezekiel', 'shortName': 'Ezek', 'chapters': 48, 'fileName': 'Ezekiel.txt', 'arabicName': 'يحزقئيل'},
    {'name': 'Daniel', 'shortName': 'Dan', 'chapters': 12, 'fileName': 'Daniel.txt', 'arabicName': 'دانيال'},
    {'name': 'Hosea', 'shortName': 'Hos', 'chapters': 14, 'fileName': 'Hosea.txt', 'arabicName': 'هوشع'},
    {'name': 'Joel', 'shortName': 'Joel', 'chapters': 3, 'fileName': 'Joel.txt', 'arabicName': 'يوئيل'},
    {'name': 'Amos', 'shortName': 'Amos', 'chapters': 9, 'fileName': 'Amos.txt', 'arabicName': 'عاموس'},
    {'name': 'Obadiah', 'shortName': 'Obad', 'chapters': 1, 'fileName': 'Obadiah.txt', 'arabicName': 'عوبدياه'},
    {'name': 'Jonah', 'shortName': 'Jonah', 'chapters': 4, 'fileName': 'Jonah.txt', 'arabicName': 'يونان'},
    {'name': 'Micah', 'shortName': 'Mic', 'chapters': 7, 'fileName': 'Micah.txt', 'arabicName': 'ميخا'},
    {'name': 'Nahum', 'shortName': 'Nah', 'chapters': 3, 'fileName': 'Nahum.txt', 'arabicName': 'ناحوم'},
    {'name': 'Habakkuk', 'shortName': 'Hab', 'chapters': 3, 'fileName': 'Habakkuk.txt', 'arabicName': 'حبقوق'},
    {'name': 'Zephaniah', 'shortName': 'Zeph', 'chapters': 3, 'fileName': 'Zephaniah.txt', 'arabicName': 'صفنياه'},
    {'name': 'Haggai', 'shortName': 'Hag', 'chapters': 2, 'fileName': 'Haggai.txt', 'arabicName': 'حجي'},
    {'name': 'Zechariah', 'shortName': 'Zech', 'chapters': 14, 'fileName': 'Zechariah.txt', 'arabicName': 'زكرياه'},
    {'name': 'Malachi', 'shortName': 'Mal', 'chapters': 4, 'fileName': 'Malachi.txt', 'arabicName': 'ملاخي (ملاكي او مبعوثي)'},
    {'name': 'Matthew', 'shortName': 'Matt', 'chapters': 28, 'fileName': 'Matthew.txt', 'arabicName': 'نص انجيل متى الرسول'},
    {'name': 'Mark', 'shortName': 'Mark', 'chapters': 16, 'fileName': 'Mark.txt', 'arabicName': 'نص انجيل مرقس الرسول'},
    {'name': 'Luke', 'shortName': 'Luke', 'chapters': 24, 'fileName': 'Luke.txt', 'arabicName': 'البشارة (الانجيل) بحسب الرسول لوقا'},
    {'name': 'John', 'shortName': 'John', 'chapters': 21, 'fileName': 'John.txt', 'arabicName': 'البشارة (الانجيل) بحسب الرسول يوحنا'},
    {'name': 'Acts', 'shortName': 'Acts', 'chapters': 28, 'fileName': 'Acts.txt', 'arabicName': 'سفر اعمال الروح القدس'},
    {'name': 'Romans', 'shortName': 'Rom', 'chapters': 16, 'fileName': 'Romans.txt', 'arabicName': 'رسالة بولس الرسول الى اهل روما'},
    {'name': '1 Corinthians', 'shortName': '1 Cor', 'chapters': 16, 'fileName': '1Corinthians.txt', 'arabicName': 'رسالة بولس الرسول الاولى الى اهل كورنثوس'},
    {'name': '2 Corinthians', 'shortName': '2 Cor', 'chapters': 13, 'fileName': '2Corinthians.txt', 'arabicName': 'رسالة بولس الرسول الثانية الى اهل كورنثوس'},
    {'name': 'Galatians', 'shortName': 'Gal', 'chapters': 6, 'fileName': 'Galatians.txt', 'arabicName': 'رسالة بولس الرسول الى اهل غلاطية'},
    {'name': 'Ephesians', 'shortName': 'Eph', 'chapters': 6, 'fileName': 'Ephesians.txt', 'arabicName': 'رسالة بولس الرسول الى اهل افسس'},
    {'name': 'Philippians', 'shortName': 'Phil', 'chapters': 4, 'fileName': 'Philippians.txt', 'arabicName': 'رسالة بولس الرسول الى اهل فيلبي'},
    {'name': 'Colossians', 'shortName': 'Col', 'chapters': 4, 'fileName': 'Colossians.txt', 'arabicName': 'رسالة بولس الرسول الى اهل كولوسي'},
    {'name': '1 Thessalonians', 'shortName': '1 Thess', 'chapters': 5, 'fileName': '1Thessalonians.txt', 'arabicName': 'رسالة بولس الرسول الاولى الى اهل تسالونيكي'},
    {'name': '2 Thessalonians', 'shortName': '2 Thess', 'chapters': 3, 'fileName': '2Thessalonians.txt', 'arabicName': 'رسالة بولس الرسول الثانية الى اهل تسالونيكي'},
    {'name': '1 Timothy', 'shortName': '1 Tim', 'chapters': 6, 'fileName': '1Timothy.txt', 'arabicName': 'رسالة بولس الرسول الاولى الى تيموثاوس'},
    {'name': '2 Timothy', 'shortName': '2 Tim', 'chapters': 4, 'fileName': '2Timothy.txt', 'arabicName': 'رسالة بولس الرسول الثانية الى تيموثاوس'},
    {'name': 'Titus', 'shortName': 'Titus', 'chapters': 3, 'fileName': 'Titus.txt', 'arabicName': 'رسالة بولس الرسول الى تيطس'},
    {'name': 'Philemon', 'shortName': 'Phlm', 'chapters': 1, 'fileName': 'Philemon.txt', 'arabicName': 'رسالة بولس الرسول الى فيليمون'},
    {'name': 'Hebrews', 'shortName': 'Heb', 'chapters': 13, 'fileName': 'Hebrews.txt', 'arabicName': 'الرسالة الى العبرانيين'},
    {'name': 'James', 'shortName': 'Jas', 'chapters': 5, 'fileName': 'James.txt', 'arabicName': 'رسالة يعقوب'},
    {'name': '1 Peter', 'shortName': '1 Pet', 'chapters': 5, 'fileName': '1Peter.txt', 'arabicName': 'رسالة بطرس الرسول الاولى'},
    {'name': '2 Peter', 'shortName': '2 Pet', 'chapters': 3, 'fileName': '2Peter.txt', 'arabicName': 'رسالة بطرس الرسول الثانية'},
    {'name': '1 John', 'shortName': '1 John', 'chapters': 5, 'fileName': '1John.txt', 'arabicName': 'رسالة يوحنا الرسول الاولى'},
    {'name': '2 John', 'shortName': '2 John', 'chapters': 1, 'fileName': '2John.txt', 'arabicName': 'رسالة يوحنا الرسول الثانية'},
    {'name': '3 John', 'shortName': '3 John', 'chapters': 1, 'fileName': '3John.txt', 'arabicName': 'رسالة يوحنا الرسول الثالثة'},
    {'name': 'Jude', 'shortName': 'Jude', 'chapters': 1, 'fileName': 'Jude.txt', 'arabicName': 'رسالة يهوذا'},
    {'name': 'Revelation', 'shortName': 'Rev', 'chapters': 22, 'fileName': 'Revelation.txt', 'arabicName': 'رؤيا يوحنا اللاهوتي'},
  ];

  static Map<String, Map<int, String>> _bookCache = {};
  static Map<String, Map<int, String>> _footnotesCache = {};
  static final Map<String, Future<Map<int, String>>> _loadingBooks = {};

  static final Map<String, Future<Map<int, String>>> _loadingFootnotes = {};


  static int getTotalChapters() {
    int total = 0;
    for (var book in books) {
      total += book['chapters'] as int;
    }
    return total;
  }

  static Map<String, dynamic> getChapterInfo(int globalChapter) {
    int currentChapter = 1;
    for (int bookIndex = 0; bookIndex < books.length; bookIndex++) {
      var book = books[bookIndex];
      int bookChapters = book['chapters'];
      
      if (globalChapter <= currentChapter + bookChapters - 1) {
        int chapterInBook = globalChapter - currentChapter + 1;
        return {
          'bookIndex': bookIndex,
          'bookName': book['name'],
          'shortName': book['shortName'],
          'arabicName': book['arabicName'],
          'chapterInBook': chapterInBook,
          'totalChapters': bookChapters,
          'fileName': book['fileName'],
        };
      }
      currentChapter += bookChapters;
    }
    return {};
  }

  static Future<bool> _checkStoragePermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }
    
    try {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      
      if (Platform.isAndroid) {
        var manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isDenied) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
      }
      
      return status.isGranted;
    } catch (e) {
      print('Permission check error: $e');
      return false;
    }
  }

  static Future<bool> fileExistsInStorage(String fileName) async {
    if (kIsWeb) {
      return false;
    }
    
    try {
      final bibleDocsPath = await getBibleDocsPath();
      final file = File('$bibleDocsPath/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<void> createMissingBookFile(String fileName, String bookName, String arabicName) async {
    if (kIsWeb) {
      return;
    }
    
    try {
      bool hasPermission = await _checkStoragePermissions();
      if (!hasPermission) {
        print('Storage permission denied');
        return;
      }
      
      final bibleDocsPath = await getBibleDocsPath();
      final file = File('$bibleDocsPath/$fileName');
      
      if (!await file.exists()) {
        final placeholder = 'This book isn\'t available yet';
        
        await file.writeAsString(placeholder);
        print('Created placeholder file: ${file.path}');
      }
    } catch (e) {
      print('Error creating file $fileName: $e');
    }
  }

  static Future<String> getChapterContent(int bookIndex, int chapterNumber) async {
    final book = books[bookIndex];
    final fileName = book['fileName'];
    
    // Return from cache if available
    if (_bookCache.containsKey(fileName) && _bookCache[fileName]!.containsKey(chapterNumber)) {
      return _bookCache[fileName]![chapterNumber]!;
    }

    // If already loading this book, wait for it
    if (_loadingBooks.containsKey(fileName)) {
      final chapters = await _loadingBooks[fileName]!;
      return chapters[chapterNumber] ?? 'This book isn\'t available yet';
    }

    // Start loading the book
    final loadFuture = _loadAndCacheBook(fileName, book['name'], book['arabicName']);
    _loadingBooks[fileName] = loadFuture;

    try {
      final chapters = await loadFuture;
      return chapters[chapterNumber] ?? 'This book isn\'t available yet';
    } finally {
      _loadingBooks.remove(fileName);
    }
  }

// Add this NEW method right after getChapterContent (around line 180)
static Future<Map<int, String>> _loadAndCacheBook(String fileName, String bookName, String arabicName) async {
  print('📚 Loading book: $fileName');
  
  String? content;
  bool foundContent = false;
  
  try {
    if (!kIsWeb) {
      final bibleDocsPath = await getBibleDocsPath();
      final externalFile = File('$bibleDocsPath/$fileName');
      
      print('📂 Checking external file: ${externalFile.path}');
      
      if (await externalFile.exists()) {
        try {
          content = await externalFile.readAsString();
          foundContent = true;
          print('✅ Loaded from external: ${content.length} characters');
        } catch (e) {
          print('❌ Error reading file $fileName: $e');
        }
      } else {
        print('⚠ External file not found');
      }
    }
    
    if (!foundContent) {
      try {
        print('📦 Trying to load from assets: assets/bible_docs/$fileName');
        content = await rootBundle.loadString('assets/bible_docs/$fileName');
        foundContent = true;
        print('✅ Loaded from assets: ${content.length} characters');
      } catch (e) {
        print('❌ File not found in assets: assets/bible_docs/$fileName');
      }
    }
    
    if (!foundContent) {
      print('❌ No content found for $fileName');
      if (!kIsWeb) {
        await createMissingBookFile(fileName, bookName, arabicName);
      }
      return {1: 'This book isn\'t available yet'};
    }
    
    print('🔄 Parsing document content...');
    final chapters = _parseDocumentContent(content!);
    print('✅ Parsed ${chapters.length} chapters');
    
    _bookCache[fileName] = chapters;
    
    return chapters;
    
  } catch (e, stackTrace) {
    print('❌ Error loading book: $e');
    print('❌ Stack trace: $stackTrace');
    return {1: 'This book isn\'t available yet'};
  }
}

  static Future<String> getBibleDocsPath() async {
    if (kIsWeb) {
      return 'web_storage';
    }
    
    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        List<String> possiblePaths = [
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/Documents/Holy_bible',
          '/sdcard/Documents',
          '/sdcard/Documents/Holy_bible',
        ];
        
        for (String path in possiblePaths) {
          directory = Directory(path);
          if (await directory.exists()) {
            print('✅ Found documents directory: $path');
            break;
          }
        }
        
        if (directory == null || !await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
          print('📁 Using app documents directory: ${directory.path}');
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      directory = await getApplicationDocumentsDirectory();
      print('📁 Fallback to app documents directory: ${directory.path}');
    }
    
    final bibleDocsPath = directory!.path.endsWith('Holy_bible') 
        ? directory.path 
        : '${directory.path}/Holy_bible';
    
    final bibleDocsDir = Directory(bibleDocsPath);
    if (!await bibleDocsDir.exists()) {
      await bibleDocsDir.create(recursive: true);
      print('📂 Created directory: $bibleDocsPath');
    }
    
    print('🎯 Final Bible docs path: $bibleDocsPath');
    return bibleDocsPath;
  }

  static String _getFileNotFoundMessage(Map<String, dynamic> book, String fileName) {
    return 'This book isn\'t available yet';
  }

  static Map<int, String> _parseDocumentContent(String content, {bool formatVerses = true}) {
    Map<int, String> chapters = {};
    
    // Check which pattern this document uses
    bool isPsalms = content.contains(RegExp(r'اَلْمَزْمُورُ'));
    
    if (isPsalms) {
      // For Psalms, use a different approach: find all occurrences and extract between them
      RegExp psalmPattern = RegExp(r'اَلْمَزْمُورُ\s+([^\n]+)', multiLine: true);
      List<RegExpMatch> matches = psalmPattern.allMatches(content).toList();
      
      
      // For footnotes, ignore any content before the first psalm marker
      // For regular content, keep it
      int firstMatchStart = matches[0].start;
      if (!formatVerses && firstMatchStart > 0) {
        String beforeFirstMatch = content.substring(0, firstMatchStart).trim();
      }
      
      for (int i = 0; i < matches.length; i++) {
        RegExpMatch match = matches[i];
        String chapterName = match.group(1)!.trim();
        
        
        int chapterNum = _parseArabicChapterNumber(chapterName);
        
        
        // Extract content from current match to next match (or end of file)
        int startPos = match.end;
        int endPos = (i < matches.length - 1) ? matches[i + 1].start : content.length;
        String chapterContent = content.substring(startPos, endPos).trim();
        
        
        // For footnotes, if content is empty, skip it
        if (!formatVerses && chapterContent.isEmpty) {
          continue;
        }
        
        // Add back the heading
        String fullContent = 'اَلْمَزْمُورُ $chapterName\n$chapterContent';
        
        if (formatVerses) {
          fullContent = _formatVerses(fullContent);
        }
        
        chapters[chapterNum] = fullContent;
      }
      
    } else {
      // Original logic for non-Psalms books
      List<String> parts = content.split(RegExp(r'ال[إأ]صحَاحُ\s+', multiLine: true));
      
      if (parts.length > 1) {
        for (int i = 1; i < parts.length; i++) {
          String chapterContent = parts[i];
          
          // Extract the chapter number from the first line
          String firstLine = chapterContent.split('\n').first.trim();
          int chapterNum = _parseArabicChapterNumber(firstLine);
          
          // Reconstruct with heading
          String reconstructed = 'الإصحَاحُ $chapterContent';
          
          if (formatVerses) {
            reconstructed = _formatVerses(reconstructed);
          }
          chapters[chapterNum] = reconstructed.trim();
        }
      } else {
        String formatted = formatVerses ? _formatVerses(content.trim()) : content.trim();
        chapters[1] = formatted;
      }
    }
    
    return chapters;
  }

  static int _parseArabicChapterNumber(String chapterHeading) {
    // Remove diacritics for easier matching
    String clean = removeTashkeel(chapterHeading);
    
    
    // Check for hundreds FIRST (since "المئة" appears at the beginning in Psalms like "المئة والرابع والاربعون")
// Check for hundreds FIRST (since "المئة" appears at the beginning in Psalms like "المئة والرابع والاربعون")
    if (clean.contains('المئة') || clean.contains('المية')) {
      int result = 100;
      
      // Extract the tens and units that come AFTER "المئة"
      int unit = 0;
      int ten = 0;
      
      // Check for teens pattern first (e.g., "المئة والحادي عشر" = 111)
      if (clean.contains('عشر') && !clean.contains('عشرون')) {
        if (clean.contains('الحادي')) unit = 11;
        else if (clean.contains('الثاني')) unit = 12;
        else if (clean.contains('الثالث')) unit = 13;
        else if (clean.contains('الرابع')) unit = 14;
        else if (clean.contains('الخامس')) unit = 15;
        else if (clean.contains('السادس')) unit = 16;
        else if (clean.contains('السابع')) unit = 17;
        else if (clean.contains('الثامن')) unit = 18;
        else if (clean.contains('التاسع')) unit = 19;
        
        return result + unit;
      }
      
      // Determine the unit part (1-10)
      if (clean.contains('الواحد')) unit = 1;
      else if (clean.contains('الحادي')) unit = 1;  // ADD THIS LINE - "الحادي" means "the first/eleventh"
      else if (clean.contains('الثاني')) unit = 2;
      else if (clean.contains('الثالث')) unit = 3;
      else if (clean.contains('الرابع')) unit = 4;
      else if (clean.contains('الخامس')) unit = 5;
      else if (clean.contains('السادس')) unit = 6;
      else if (clean.contains('السابع')) unit = 7;
      else if (clean.contains('الثامن')) unit = 8;
      else if (clean.contains('التاسع')) unit = 9;
      else if (clean.contains('العاشر')) unit = 10;
      
      // Determine the tens part
      if (clean.contains('العشرون')) ten = 20;
      else if (clean.contains('الثلاثون')) ten = 30;
      else if (clean.contains('الأربعون') || clean.contains('الاربعون')) ten = 40;
      else if (clean.contains('الخمسون')) ten = 50;
      else if (clean.contains('الستون')) ten = 60;
      else if (clean.contains('السبعون')) ten = 70;
      else if (clean.contains('الثمانون')) ten = 80;
      else if (clean.contains('التسعون')) ten = 90;
      
      return result + ten + unit;
    }
    
    // Teens 11-19 (pattern: "الثاني عشر" = 12) - check BEFORE simple numbers
    if (clean.contains('عشر') && !clean.contains('العشرون')) {
      if (clean.contains('الحادي')) return 11;
      if (clean.contains('الثاني')) return 12;
      if (clean.contains('الثالث')) return 13;
      if (clean.contains('الرابع')) return 14;
      if (clean.contains('الخامس')) return 15;
      if (clean.contains('السادس')) return 16;
      if (clean.contains('السابع')) return 17;
      if (clean.contains('الثامن')) return 18;
      if (clean.contains('التاسع')) return 19;
    }
    
    // Compound numbers (21-29, 31-39, etc.) with "و" - check BEFORE simple numbers and tens
    if (clean.contains('و') && !clean.contains('المئة') && !clean.contains('المية')) {
      int unit = 0;
      int ten = 0;
      
      // Determine the unit part
      if (clean.contains('الحادي')) unit = 1;
      else if (clean.contains('الثاني')) unit = 2;
      else if (clean.contains('الثالث')) unit = 3;
      else if (clean.contains('الرابع')) unit = 4;
      else if (clean.contains('الخامس')) unit = 5;
      else if (clean.contains('السادس')) unit = 6;
      else if (clean.contains('السابع')) unit = 7;
      else if (clean.contains('الثامن')) unit = 8;
      else if (clean.contains('التاسع')) unit = 9;
      
      // Determine the tens part
      if (clean.contains('العشرون')) ten = 20;
      else if (clean.contains('الثلاثون')) ten = 30;
      else if (clean.contains('الأربعون') || clean.contains('الاربعون')) ten = 40;
      else if (clean.contains('الخمسون')) ten = 50;
      else if (clean.contains('الستون')) ten = 60;
      else if (clean.contains('السبعون')) ten = 70;
      else if (clean.contains('الثمانون')) ten = 80;
      else if (clean.contains('التسعون')) ten = 90;
      
      if (unit > 0 && ten > 0) {
        return ten + unit;
      }
    }
    
    // Tens (20, 30, 40, 50, 60, 70, 80, 90) - check BEFORE simple numbers
    final Map<String, int> tens = {
      'العشرون': 20,
      'الثلاثون': 30,
      'الأربعون': 40, 'الاربعون': 40,
      'الخمسون': 50,
      'الستون': 60,
      'السبعون': 70,
      'الثمانون': 80,
      'التسعون': 90,
    };
    
    for (var entry in tens.entries) {
      if (clean.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Simple numbers 1-10 - check LAST to avoid false matches
    final Map<String, int> simple = {
      'الأول': 1, 'الاول': 1,
      'الثاني': 2,
      'الثالث': 3,
      'الرابع': 4,
      'الخامس': 5,
      'السادس': 6,
      'السابع': 7,
      'الثامن': 8,
      'التاسع': 9,
      'العاشر': 10,
    };
    
    for (var entry in simple.entries) {
      if (clean.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Fallback: return 1 if nothing matches
    print('WARNING: Could not parse chapter number from: "$chapterHeading"');
    return 1;
  }

static Future<String> getChapterFootnotes(int bookIndex, int chapterNumber) async {
  final book = books[bookIndex];
  final fileName = book['fileName'].replaceAll('.txt', '_footnotes.txt');
  
  // Return from cache if available
  if (_footnotesCache.containsKey(fileName) && _footnotesCache[fileName]!.containsKey(chapterNumber)) {
    return _footnotesCache[fileName]![chapterNumber]!;
  }

  // If already loading, wait for it
  if (_loadingFootnotes.containsKey(fileName)) {
    final chapters = await _loadingFootnotes[fileName]!;
    return chapters[chapterNumber] ?? '';
  }

  // Start loading
  final loadFuture = _loadAndCacheFootnotes(fileName);
  _loadingFootnotes[fileName] = loadFuture;

  try {
    final chapters = await loadFuture;
    return chapters[chapterNumber] ?? '';
  } finally {
    _loadingFootnotes.remove(fileName);
  }
}

// Add this NEW method right after getChapterFootnotes
static Future<Map<int, String>> _loadAndCacheFootnotes(String fileName) async {
  String? content;
  bool foundContent = false;

  if (!kIsWeb) {
    final bibleDocsPath = await getBibleDocsPath();
    final externalFile = File('$bibleDocsPath/$fileName');
    if (await externalFile.exists()) {
      content = await externalFile.readAsString();
      foundContent = true;
    }
  }

  if (!foundContent) {
    try {
      content = await rootBundle.loadString('assets/bible_docs/$fileName');
      foundContent = true;
    } catch (e) {
      return {};
    }
  }

  final chapters = _parseDocumentContent(content!, formatVerses: false);
  _footnotesCache[fileName] = chapters;
  return chapters;
}

  static String _formatVerses(String content) {
    String formatted = content;
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\s)(\d+)([^\d\s])', multiLine: true),
      (match) {
        String space = match.group(1)!;
        String verseNumber = match.group(2)!;
        String restOfVerse = match.group(3)!;
        return '$space\n$verseNumber$restOfVerse';
      },
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'^(\d+)([^\d\s])', multiLine: true),
      (match) {
        String verseNumber = match.group(1)!;
        String restOfVerse = match.group(2)!;
        return '$verseNumber$restOfVerse';
      },
    );
    
    formatted = formatted.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    formatted = formatted.replaceAll(RegExp(r'^\n+'), '');
    
    return formatted;
  }

  // NEW: Method to remove tashkeel (diacritics) from Arabic text
  static String removeTashkeel(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
  }

  static bool searchMatch(String content, String query) {
    String cleanContent = removeTashkeel(content.toLowerCase());
    String cleanQuery = removeTashkeel(query.toLowerCase());
    
    return cleanContent.contains(cleanQuery);
  }
  // Get books in Old Testament (indices 0-38)
  static List<int> getOldTestamentIndices() {
    return List.generate(39, (index) => index);
  }

  // Get books in New Testament (indices 39-65)
  static List<int> getNewTestamentIndices() {
    return List.generate(27, (index) => index + 39);
  }

  // Parse reference like "تكوين 3:2" or "Genesis 3:2" into bookIndex, chapter, verse
  static Map<String, int>? parseReference(String reference) {
    reference = reference.trim();
    
    // Remove diacritics for matching
    String cleanRef = removeTashkeel(reference.toLowerCase());
    
    // Try to match book name
    int? bookIndex;
    String remainder = '';
    
    for (int i = 0; i < books.length; i++) {
      String bookName = books[i]['name'].toLowerCase();
      String arabicName = removeTashkeel(books[i]['arabicName'].toLowerCase());
      String shortName = books[i]['shortName'].toLowerCase();
      
      if (cleanRef.startsWith(arabicName)) {
        bookIndex = i;
        remainder = reference.substring(books[i]['arabicName'].length).trim();
        break;
      } else if (cleanRef.startsWith(bookName)) {
        bookIndex = i;
        remainder = reference.substring(bookName.length).trim();
        break;
      } else if (cleanRef.startsWith(shortName)) {
        bookIndex = i;
        remainder = reference.substring(books[i]['shortName'].length).trim();
        break;
      }
    }
    
    if (bookIndex == null) return null;
    
    // Parse chapter and verse
    // Format: "3:2" or "3" or ":2"
    int? chapter;
    int? verse;
    
    if (remainder.isEmpty) {
      // Just book name, return chapter 1
      return {'bookIndex': bookIndex, 'chapter': 1};
    }
    
    // Match patterns like "3:2", "3", or ":2"
    RegExp refPattern = RegExp(r'^(\d+)?:?(\d+)?$');
    Match? match = refPattern.firstMatch(remainder);
    
    if (match != null) {
      String? chapterStr = match.group(1);
      String? verseStr = match.group(2);
      
      if (chapterStr != null) {
        chapter = int.tryParse(chapterStr);
      }
      if (verseStr != null) {
        verse = int.tryParse(verseStr);
      }
      
      // Validate chapter exists in book
      if (chapter != null && chapter > 0 && chapter <= books[bookIndex]['chapters']) {
        Map<String, int> result = {
          'bookIndex': bookIndex,
          'chapter': chapter,
        };
        if (verse != null && verse > 0) {
          result['verse'] = verse;
        }
        return result;
      }
    }
    
    return null;
  }
}
