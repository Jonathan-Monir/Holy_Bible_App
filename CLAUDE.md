# Arabic Holy Bible App — CLAUDE.md

## Project Overview
A Flutter mobile app (Android & iOS) that displays the Arabic Holy Bible (ترجمة عربية باسم يهوه).
It supports chapter-by-chapter reading, search, themes, font settings, verse highlighting, and footnotes.
The app is monetized via Google AdMob (banner ads + app open ads).

## Architecture

### Entry Point
- `main.dart` — Initializes AdMob, sets up `AppOpenAdManager`, wraps app in `ChangeNotifierProvider<ThemeProvider>`, launches `SplashScreen`.

### State Management
- **Provider** pattern via `ThemeProvider` (`theme_provider.dart`)
- `ThemeProvider` is the single global state provider (theme mode, verse/footnote colors)
- Settings (font size, font family, diacritics toggle) are managed locally in `MainReaderScreen` via `SharedPreferences`

### Navigation Flow
```
SplashScreen
    └── MainReaderScreen (PageView of all chapters)
            ├── ChapterContentPage (per chapter)
            ├── ChapterSelectorScreen (book/chapter picker)
            ├── SearchScreen
            └── SettingsScreen
```

### Data Layer
- `bible_data.dart` — Static class `BibleData`. All 66 books defined inline with English name, short name, Arabic name, chapter count, and asset filename.
- Bible text lives in `assets/bible_docs/BookName.txt`
- Footnotes live in `assets/bible_docs/BookName_footnotes.txt`
- Content is loaded via `rootBundle.loadString()` and cached in memory (`_bookCache`, `_footnotesCache`)
- Deduplication of in-flight loads via `_loadingBooks` / `_loadingFootnotes` Future maps
- Chapter splitting: standard books split on `الإصحَاحُ`; Psalms use `اَلْمَزْمُورُ` pattern
- Arabic chapter numbers (ordinal words) are parsed by `_parseArabicChapterNumber()`

### Theming
- 4 themes: `light`, `dark`, `sepia`, `blue`
- Defined as static `ThemeData` objects in `ThemeProvider`
- Persisted via `SharedPreferences` key `theme_mode`
- Custom colors: `verseNumberColor`, `footnoteNumberColor` — also persisted

### Reading Experience
- `MainReaderScreen` uses `PageView.builder` across all chapters globally (1–1189)
- Global chapter index maps to book + chapter-in-book via `BibleData.getChapterInfo()`
- Page cache: `Map<String, Widget>` keyed as `"$chapter-$fontSize-$fontFamily-$removeDiacritics"` — invalidated on settings change, capped at 10 entries ±5 chapters from current
- Preloading: adjacent ±2 chapters preloaded on page change (priority: current → +1 → -1 → +2 → -2)
- Last-read chapter persisted as `SharedPreferences` key `last_chapter`

### Arabic Text
- RTL text rendering via `arabic_selectable_text.dart` / `rtl_selectable_text.dart`
- Diacritics (tashkeel) can be stripped via `BibleData.removeTashkeel()`
- Default font: `Amiri`; additional fonts selectable in settings

### Ads
- `ad_helper.dart` — Provides AdMob unit IDs for banner and app open ads
- `banner_ad_widget.dart` — Banner shown at the bottom of `MainReaderScreen`
- `app_open_ad_manager.dart` — Manages app open ad lifecycle
- `AppLifecycleReactor` is a global instance in `main.dart` that listens to app state changes

## ⚠️ Critical: Do Not Modify Ad ID Comments in `ad_helper.dart`

**Never remove, reorder, or alter the commented-out lines in `ad_helper.dart`.**
The file intentionally keeps both TEST and PRODUCTION IDs as comments so the developer
can switch between them manually at release time by simply uncommenting one line.
The structure looks like this and must be preserved exactly:
```dart
// TEST ID — replace with real ID before release
return 'ca-app-pub-xxxx/test_id';
// PRODUCTION: return 'ca-app-pub-xxxx/real_id';
// TEST: return 'ca-app-pub-xxxx/test_id';
```

Do not "clean up" these comments. Do not consolidate them. Do not move IDs to a config file
unless explicitly asked. This pattern is intentional workflow tooling.

## Key SharedPreferences Keys
| Key | Type | Description |
|-----|------|-------------|
| `last_chapter` | int | Last global chapter read |
| `font_size` | double | Reader font size |
| `font_family` | String | Reader font family |
| `remove_diacritics` | bool | Strip tashkeel toggle |
| `theme_mode` | String | Theme name (light/dark/sepia/blue) |
| `verse_number_color` | int | ARGB int for verse number color |
| `footnote_number_color` | int | ARGB int for footnote number color |

## Asset Structure
```
assets/
  bible_docs/
    Genesis.txt
    Genesis_footnotes.txt
    ... (66 books × 2 files)
  fonts/
    Amiri/...
    (other Arabic fonts)
```

## Development Notes
- The app targets Android and iOS only — `AdHelper` throws `UnsupportedError` on other platforms
- `BibleData` methods are all static; do not instantiate the class
- Debug `print()` statements with emoji prefixes (🟢 🟡 🔴 📚 ✅ ❌) are used throughout for tracing navigation and data loading — leave them in place unless explicitly asked to clean up
- `color_picker_dialog.dart` provides the UI for customizing verse/footnote number colors
- `search_filter.dart` supports diacritics-agnostic search via `BibleData.searchMatch()`
