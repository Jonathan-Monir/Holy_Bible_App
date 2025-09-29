// lib/bible_data.dart
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
    {'name': 'Numbers', 'shortName': 'Num', 'chapters': 36, 'fileName': 'Numbers.txt', 'arabicName': 'العدد'},
    {'name': 'Deuteronomy', 'shortName': 'Deut', 'chapters': 34, 'fileName': 'Deuteronomy.txt', 'arabicName': 'التثنية'},
    {'name': 'Joshua', 'shortName': 'Josh', 'chapters': 24, 'fileName': 'Joshua.txt', 'arabicName': 'يشوع'},
    {'name': 'Judges', 'shortName': 'Judg', 'chapters': 21, 'fileName': 'Judges.txt', 'arabicName': 'القضاة'},
    {'name': 'Ruth', 'shortName': 'Ruth', 'chapters': 4, 'fileName': 'Ruth.txt', 'arabicName': 'راعوث'},
    {'name': '1 Samuel', 'shortName': '1 Sam', 'chapters': 31, 'fileName': '1Samuel.txt', 'arabicName': 'صموئيل الأول'},
    {'name': '2 Samuel', 'shortName': '2 Sam', 'chapters': 24, 'fileName': '2Samuel.txt', 'arabicName': 'صموئيل الثاني'},
    {'name': '1 Kings', 'shortName': '1 Kgs', 'chapters': 22, 'fileName': '1Kings.txt', 'arabicName': 'الملوك الأول'},
    {'name': '2 Kings', 'shortName': '2 Kgs', 'chapters': 25, 'fileName': '2Kings.txt', 'arabicName': 'الملوك الثاني'},
    {'name': '1 Chronicles', 'shortName': '1 Chr', 'chapters': 29, 'fileName': '1Chronicles.txt', 'arabicName': 'أخبار الأيام الأول'},
    {'name': '2 Chronicles', 'shortName': '2 Chr', 'chapters': 36, 'fileName': '2Chronicles.txt', 'arabicName': 'أخبار الأيام الثاني'},
    {'name': 'Ezra', 'shortName': 'Ezra', 'chapters': 10, 'fileName': 'Ezra.txt', 'arabicName': 'عزرا'},
    {'name': 'Nehemiah', 'shortName': 'Neh', 'chapters': 13, 'fileName': 'Nehemiah.txt', 'arabicName': 'نحميا'},
    {'name': 'Esther', 'shortName': 'Esth', 'chapters': 10, 'fileName': 'Esther.txt', 'arabicName': 'أستير'},
    {'name': 'Job', 'shortName': 'Job', 'chapters': 42, 'fileName': 'Job.txt', 'arabicName': 'أيوب'},
    {'name': 'Psalms', 'shortName': 'Ps', 'chapters': 150, 'fileName': 'Psalms.txt', 'arabicName': 'المزامير'},
    {'name': 'Proverbs', 'shortName': 'Prov', 'chapters': 31, 'fileName': 'Proverbs.txt', 'arabicName': 'الأمثال'},
    {'name': 'Ecclesiastes', 'shortName': 'Eccl', 'chapters': 12, 'fileName': 'Ecclesiastes.txt', 'arabicName': 'الجامعة'},
    {'name': 'Song of Solomon', 'shortName': 'Song', 'chapters': 8, 'fileName': 'SongOfSolomon.txt', 'arabicName': 'نشيد الأنشاد'},
    {'name': 'Isaiah', 'shortName': 'Isa', 'chapters': 66, 'fileName': 'Isaiah.txt', 'arabicName': 'إشعياء'},
    {'name': 'Jeremiah', 'shortName': 'Jer', 'chapters': 52, 'fileName': 'Jeremiah.txt', 'arabicName': 'إرميا'},
    {'name': 'Lamentations', 'shortName': 'Lam', 'chapters': 5, 'fileName': 'Lamentations.txt', 'arabicName': 'مراثي إرميا'},
    {'name': 'Ezekiel', 'shortName': 'Ezek', 'chapters': 48, 'fileName': 'Ezekiel.txt', 'arabicName': 'حزقيال'},
    {'name': 'Daniel', 'shortName': 'Dan', 'chapters': 12, 'fileName': 'Daniel.txt', 'arabicName': 'دانيال'},
    {'name': 'Hosea', 'shortName': 'Hos', 'chapters': 14, 'fileName': 'Hosea.txt', 'arabicName': 'هوشع'},
    {'name': 'Joel', 'shortName': 'Joel', 'chapters': 3, 'fileName': 'Joel.txt', 'arabicName': 'يوئيل'},
    {'name': 'Amos', 'shortName': 'Amos', 'chapters': 9, 'fileName': 'Amos.txt', 'arabicName': 'عاموس'},
    {'name': 'Obadiah', 'shortName': 'Obad', 'chapters': 1, 'fileName': 'Obadiah.txt', 'arabicName': 'عوبديا'},
    {'name': 'Jonah', 'shortName': 'Jonah', 'chapters': 4, 'fileName': 'Jonah.txt', 'arabicName': 'يونان'},
    {'name': 'Micah', 'shortName': 'Mic', 'chapters': 7, 'fileName': 'Micah.txt', 'arabicName': 'ميخا'},
    {'name': 'Nahum', 'shortName': 'Nah', 'chapters': 3, 'fileName': 'Nahum.txt', 'arabicName': 'ناحوم'},
    {'name': 'Habakkuk', 'shortName': 'Hab', 'chapters': 3, 'fileName': 'Habakkuk.txt', 'arabicName': 'حبقوق'},
    {'name': 'Zephaniah', 'shortName': 'Zeph', 'chapters': 3, 'fileName': 'Zephaniah.txt', 'arabicName': 'صفنيا'},
    {'name': 'Haggai', 'shortName': 'Hag', 'chapters': 2, 'fileName': 'Haggai.txt', 'arabicName': 'حجي'},
    {'name': 'Zechariah', 'shortName': 'Zech', 'chapters': 14, 'fileName': 'Zechariah.txt', 'arabicName': 'زكريا'},
    {'name': 'Malachi', 'shortName': 'Mal', 'chapters': 4, 'fileName': 'Malachi.txt', 'arabicName': 'ملاخي'},
    {'name': 'Matthew', 'shortName': 'Matt', 'chapters': 28, 'fileName': 'Matthew.txt', 'arabicName': 'إنجيل متى'},
    {'name': 'Mark', 'shortName': 'Mark', 'chapters': 16, 'fileName': 'Mark.txt', 'arabicName': 'إنجيل مرقس'},
    {'name': 'Luke', 'shortName': 'Luke', 'chapters': 24, 'fileName': 'Luke.txt', 'arabicName': 'إنجيل لوقا'},
    {'name': 'John', 'shortName': 'John', 'chapters': 21, 'fileName': 'John.txt', 'arabicName': 'إنجيل يوحنا'},
    {'name': 'Acts', 'shortName': 'Acts', 'chapters': 28, 'fileName': 'Acts.txt', 'arabicName': 'أعمال الرسل'},
    {'name': 'Romans', 'shortName': 'Rom', 'chapters': 16, 'fileName': 'Romans.txt', 'arabicName': 'رسالة رومية'},
    {'name': '1 Corinthians', 'shortName': '1 Cor', 'chapters': 16, 'fileName': '1Corinthians.txt', 'arabicName': 'كورنثوس الأولى'},
    {'name': '2 Corinthians', 'shortName': '2 Cor', 'chapters': 13, 'fileName': '2Corinthians.txt', 'arabicName': 'كورنثوس الثانية'},
    {'name': 'Galatians', 'shortName': 'Gal', 'chapters': 6, 'fileName': 'Galatians.txt', 'arabicName': 'غلاطية'},
    {'name': 'Ephesians', 'shortName': 'Eph', 'chapters': 6, 'fileName': 'Ephesians.txt', 'arabicName': 'أفسس'},
    {'name': 'Philippians', 'shortName': 'Phil', 'chapters': 4, 'fileName': 'Philippians.txt', 'arabicName': 'فيلبي'},
    {'name': 'Colossians', 'shortName': 'Col', 'chapters': 4, 'fileName': 'Colossians.txt', 'arabicName': 'كولوسي'},
    {'name': '1 Thessalonians', 'shortName': '1 Thess', 'chapters': 5, 'fileName': '1Thessalonians.txt', 'arabicName': 'تسالونيكي الأولى'},
    {'name': '2 Thessalonians', 'shortName': '2 Thess', 'chapters': 3, 'fileName': '2Thessalonians.txt', 'arabicName': 'تسالونيكي الثانية'},
    {'name': '1 Timothy', 'shortName': '1 Tim', 'chapters': 6, 'fileName': '1Timothy.txt', 'arabicName': 'تيموثاوس الأولى'},
    {'name': '2 Timothy', 'shortName': '2 Tim', 'chapters': 4, 'fileName': '2Timothy.txt', 'arabicName': 'تيموثاوس الثانية'},
    {'name': 'Titus', 'shortName': 'Titus', 'chapters': 3, 'fileName': 'Titus.txt', 'arabicName': 'تيطس'},
    {'name': 'Philemon', 'shortName': 'Phlm', 'chapters': 1, 'fileName': 'Philemon.txt', 'arabicName': 'فليمون'},
    {'name': 'Hebrews', 'shortName': 'Heb', 'chapters': 13, 'fileName': 'Hebrews.txt', 'arabicName': 'العبرانيين'},
    {'name': 'James', 'shortName': 'Jas', 'chapters': 5, 'fileName': 'James.txt', 'arabicName': 'يعقوب'},
    {'name': '1 Peter', 'shortName': '1 Pet', 'chapters': 5, 'fileName': '1Peter.txt', 'arabicName': 'بطرس الأولى'},
    {'name': '2 Peter', 'shortName': '2 Pet', 'chapters': 3, 'fileName': '2Peter.txt', 'arabicName': 'بطرس الثانية'},
    {'name': '1 John', 'shortName': '1 John', 'chapters': 5, 'fileName': '1John.txt', 'arabicName': 'يوحنا الأولى'},
    {'name': '2 John', 'shortName': '2 John', 'chapters': 1, 'fileName': '2John.txt', 'arabicName': 'يوحنا الثانية'},
    {'name': '3 John', 'shortName': '3 John', 'chapters': 1, 'fileName': '3John.txt', 'arabicName': 'يوحنا الثالثة'},
    {'name': 'Jude', 'shortName': 'Jude', 'chapters': 1, 'fileName': 'Jude.txt', 'arabicName': 'يهوذا'},
    {'name': 'Revelation', 'shortName': 'Rev', 'chapters': 22, 'fileName': 'Revelation.txt', 'arabicName': 'الرؤيا'},
  ];

  // Cache for loaded content
  static Map<String, Map<int, String>> _bookCache = {};

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

  // Get the Bible documents directory path

  // Check storage permissions
  static Future<bool> _checkStoragePermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }
    
    try {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      
      // For Android 11+, also check manage external storage if needed
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

  // Check if file exists in external storage
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

  // Create missing book file with placeholder content
  static Future<void> createMissingBookFile(String fileName, String bookName, String arabicName) async {
    if (kIsWeb) {
      return;
    }
    
    try {
      // Check permissions first
      bool hasPermission = await _checkStoragePermissions();
      if (!hasPermission) {
        print('Storage permission denied');
        return;
      }
      
      final bibleDocsPath = await getBibleDocsPath();
      final file = File('$bibleDocsPath/$fileName');
      
      if (!await file.exists()) {
        final placeholder = 'This book isn\'t available yet'; // Simplified message
        
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
    final bookName = book['name'];
    final arabicName = book['arabicName'];

    // Check cache first
    if (_bookCache.containsKey(fileName) && _bookCache[fileName]!.containsKey(chapterNumber)) {
      return _bookCache[fileName]![chapterNumber]!;
    }

    String? content;
    bool foundContent = false;
    
    try {
      // Try to read from external storage first (only on mobile)
      if (!kIsWeb) {
        final bibleDocsPath = await getBibleDocsPath();
        final externalFile = File('$bibleDocsPath/$fileName');
        
        print('Looking for file at: ${externalFile.path}');
        print('File exists: ${await externalFile.exists()}');
        
        if (await externalFile.exists()) {
          try {
            content = await externalFile.readAsString();
            foundContent = true;
            print('✅ Successfully loaded from external storage: $fileName');
          } catch (e) {
            print('❌ Error reading file $fileName: $e');
          }
        } else {
          print('❌ File not found in external storage: $fileName');
        }
      }
      
      // If not found in external storage, try assets
      if (!foundContent) {
        try {
          content = await rootBundle.loadString('assets/bible_docs/$fileName');
          foundContent = true;
          print('✅ Loaded from assets: $fileName');
        } catch (e) {
          print('❌ File not found in assets: assets/bible_docs/$fileName');
        }
      }
      
      // If still not found, create placeholder file (mobile only) and return message
      if (!foundContent) {
        if (!kIsWeb) {
          await createMissingBookFile(fileName, bookName, arabicName);
        }
        return 'This book isn\'t available yet';
      }
      
      // Parse the content and split into chapters
      final chapters = _parseDocumentContent(content!);
      
      // Cache the parsed chapters
      _bookCache[fileName] = chapters;
      
      // Return the requested chapter
      if (chapters.containsKey(chapterNumber)) {
        return chapters[chapterNumber]!;
      } else {
        return 'This book isn\'t available yet';
      }
      
    } catch (e) {
      print('❌ Error loading chapter: $e');
      return 'This book isn\'t available yet';
    }
  }

  static Future<String> getBibleDocsPath() async {
    if (kIsWeb) {
      return 'web_storage';
    }
    
    Directory? directory;
    
    try {
      // Try to get external storage directory first
      if (Platform.isAndroid) {
        // Try multiple possible paths for Documents directory
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
        
        // If none of the above work, fallback to app documents directory
        if (directory == null || !await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
          print('📁 Using app documents directory: ${directory.path}');
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      // Fallback to app documents directory
      directory = await getApplicationDocumentsDirectory();
      print('📁 Fallback to app documents directory: ${directory.path}');
    }
    
    // If we found a Documents directory, use Holy_bible subdirectory
    final bibleDocsPath = directory!.path.endsWith('Holy_bible') 
        ? directory.path 
        : '${directory.path}/Holy_bible';
    
    // Create directory if it doesn't exist
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

  static Map<int, String> _parseDocumentContent(String content) {
    Map<int, String> chapters = {};
    
    // Split by Arabic chapter headings
    List<String> parts = content.split(RegExp(r'الأصحَاحُ', multiLine: true));
    
    if (parts.length > 1) {
      // First part (before first chapter) might contain book title
      for (int i = 1; i < parts.length; i++) {
        String chapterContent = 'الأصحَاحُ${parts[i]}';
        // Format verses - put each verse on new line
        chapterContent = _formatVerses(chapterContent);
        chapters[i] = chapterContent.trim();
      }
    } else {
      // If no chapter divisions found, try different approach
      // Look for patterns like "الأول" "الثاني" etc.
      if (content.contains('الأول')) {
        List<String> chapterParts = content.split(RegExp(r'الأول|الثاني|الثالث|الرابع|الخامس', multiLine: true));
        for (int i = 0; i < chapterParts.length; i++) {
          if (chapterParts[i].trim().isNotEmpty) {
            String formattedContent = _formatVerses(chapterParts[i].trim());
            chapters[i + 1] = formattedContent;
          }
        }
      } else {
        // Put all content in chapter 1 and format verses
        String formattedContent = _formatVerses(content.trim());
        chapters[1] = formattedContent;
      }
    }
    
    return chapters;
  }

  // Helper method to format verses - each verse on new line
  static String _formatVerses(String content) {
    // Replace verse numbers (Arabic digits) with newline + verse number
    String formatted = content;
    
    // Match Arabic verse numbers like 1, 2, 3, etc. at the start of verses
    // More precise pattern to avoid false matches
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\s)(\d+)([^\d\s])', multiLine: true),
      (match) {
        String space = match.group(1)!;
        String verseNumber = match.group(2)!;
        String restOfVerse = match.group(3)!;
        return '$space\n$verseNumber$restOfVerse';
      },
    );
    
    // Also handle verse numbers at the very beginning
    formatted = formatted.replaceAllMapped(
      RegExp(r'^(\d+)([^\d\s])', multiLine: true),
      (match) {
        String verseNumber = match.group(1)!;
        String restOfVerse = match.group(2)!;
        return '$verseNumber$restOfVerse';
      },
    );
    
    // Clean up extra newlines and spaces
    formatted = formatted.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    formatted = formatted.replaceAll(RegExp(r'^\n+'), '');
    
    return formatted;
  }

  // Helper method to remove tashkeel (diacritics) from Arabic text
  static String removeTashkeel(String text) {
    // Remove common Arabic diacritics
    return text.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
  }

  // Method to search with tashkeel-insensitive comparison
  static bool searchMatch(String content, String query) {
    // Remove tashkeel from both content and query for comparison
    String cleanContent = removeTashkeel(content.toLowerCase());
    String cleanQuery = removeTashkeel(query.toLowerCase());
    
    return cleanContent.contains(cleanQuery);
  }
}
