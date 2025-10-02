// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final double currentFontSize;
  final Function(double) onFontSizeChanged;
  final String currentFontFamily;
  final Function(String) onFontFamilyChanged;
  final bool removeDiacritics;
  final Function(bool) onRemoveDiacriticsChanged;

  const SettingsScreen({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
    required this.currentFontFamily,
    required this.onFontFamilyChanged,
    required this.removeDiacritics,
    required this.onRemoveDiacriticsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _currentFontSize;
  late String _selectedFont;
  late bool _removeDiacritics;
  
  final Map<String, String> _arabicFonts = {
    'Amiri': 'أميري (Amiri)',
    'Cairo': 'القاهرة (Cairo)',
    'Lateef': 'لطيف (Lateef)',
    'Scheherazade New': 'شهرزاد (Scheherazade)',
    'Markazi Text': 'مركزي (Markazi)',
    'Noto Naskh Arabic': 'نسخ عربي (Noto Naskh)',
  };
  
  final Map<AppThemeMode, Map<String, dynamic>> _themes = {
    AppThemeMode.light: {
      'name': 'Light',
      'arabicName': 'فاتح',
      'icon': Icons.light_mode,
      'color': Colors.blue,
    },
    AppThemeMode.dark: {
      'name': 'Dark',
      'arabicName': 'داكن',
      'icon': Icons.dark_mode,
      'color': Colors.grey.shade800,
    },
    AppThemeMode.sepia: {
      'name': 'Sepia',
      'arabicName': 'بني فاتح',
      'icon': Icons.auto_stories,
      'color': const Color(0xFF8B7355),
    },
    AppThemeMode.blue: {
      'name': 'Blue Night',
      'arabicName': 'ليل أزرق',
      'icon': Icons.nightlight_round,
      'color': const Color(0xFF1B263B),
    },
  };
  
  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.currentFontSize;
    _selectedFont = widget.currentFontFamily;
    _removeDiacritics = widget.removeDiacritics;
  }

  void _saveFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('font_size', size);
    } catch (e) {
      print('Error saving font size: $e');
    }
  }

  void _saveFontFamily(String fontFamily) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('font_family', fontFamily);
    } catch (e) {
      print('Error saving font family: $e');
    }
  }

  void _saveRemoveDiacritics(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remove_diacritics', value);
    } catch (e) {
      print('Error saving remove diacritics setting: $e');
    }
  }

  TextStyle _getFontStyle(String fontFamily) {
    switch (fontFamily) {
      case 'Amiri':
        return const TextStyle(fontFamily: 'Amiri');
      case 'Cairo':
        return GoogleFonts.cairo();
      case 'Lateef':
        return GoogleFonts.lateef();
      case 'Scheherazade New':
        return GoogleFonts.scheherazadeNew();
      case 'Markazi Text':
        return GoogleFonts.markaziText();
      case 'Noto Naskh Arabic':
        return GoogleFonts.notoNaskhArabic();
      default:
        return const TextStyle(fontFamily: 'Amiri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: themeProvider.primaryTextColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font Size Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_fields, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Font Size',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Preview Text - النص التجريبي',
                        style: _getFontStyle(_selectedFont).copyWith(
                          fontSize: _currentFontSize,
                          height: 1.8,
                          color: themeProvider.primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Column(
                      children: [
                        Slider(
                          value: _currentFontSize,
                          min: 12.0,
                          max: 50.0,
                          divisions: 19,
                          label: _currentFontSize.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _currentFontSize = value;
                            });
                          },
                          onChangeEnd: (double value) {
                            widget.onFontSizeChanged(value);
                            _saveFontSize(value);
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Small',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                            Text(
                              '${_currentFontSize.round()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              'Large',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Font Family Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.font_download, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Arabic Font',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ..._arabicFonts.entries.map((entry) {
                      final fontKey = entry.key;
                      final fontLabel = entry.value;
                      final isSelected = _selectedFont == fontKey;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            fontLabel,
                            style: _getFontStyle(fontKey).copyWith(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: themeProvider.primaryTextColor,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Text(
                            '‏في البداءة خلق إلوهيم السماوات والأرض.',
                            style: _getFontStyle(fontKey).copyWith(
                              fontSize: 14,
                              color: themeProvider.secondaryTextColor,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          value: fontKey,
                          groupValue: _selectedFont,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedFont = value;
                              });
                              widget.onFontFamilyChanged(value);
                              _saveFontFamily(value);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Diacritics Toggle Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_rotation_none, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Text Display',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Remove Diacritics (التشكيل)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: themeProvider.primaryTextColor,
                              ),
                            ),
                            subtitle: Text(
                              'Hide vowel marks and diacritical marks',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                            value: _removeDiacritics,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (bool value) {
                              setState(() {
                                _removeDiacritics = value;
                              });
                              widget.onRemoveDiacriticsChanged(value);
                              _saveRemoveDiacritics(value);
                            },
                          ),
                          const SizedBox(height: 8),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'With diacritics:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: themeProvider.secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '‏فِي الْبَدَاءَةِ خَلَقَ إلُوهِيم السَّمَاوَاتِ وَالأَرْضَ.',
                                  style: _getFontStyle(_selectedFont).copyWith(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: themeProvider.primaryTextColor,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Without diacritics:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: themeProvider.secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '‏في البداءة خلق إلوهيم السماوات والأرض.',
                                  style: _getFontStyle(_selectedFont).copyWith(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: themeProvider.primaryTextColor,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            
            const SizedBox(height: 16),
            
            // Theme Selection Card (MOVED TO END)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _themes.length,
                      itemBuilder: (context, index) {
                        final mode = _themes.keys.elementAt(index);
                        final theme = _themes[mode]!;
                        final isSelected = themeProvider.themeMode == mode;
                        
                        return GestureDetector(
                          onTap: () => themeProvider.setTheme(mode),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme['color'],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: theme['color'].withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  theme['icon'],
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  theme['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  theme['arabicName'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
