# Al-Asbahani (الأصبهاني)

A beautiful and feature-rich Quran reading application built with **Flutter**, designed for an optimal reading experience with support for multiple recitation styles and Warsh audio playback.

<p align="center">
  <img src="assets/asbahani-logo.png" alt="Al-Asbahani Logo" width="150" />
</p>

## ✨ Features

- **Complete Quran Display**: All 604 pages rendered in a smooth, swipeable page view
- **Multiple Recitation Styles (Riwayat)**:
  - 🕌 **Mushaf King Fahd Complex** — Warsh via Al-Azraq (North African recitation)
  - 📖 **Al-Asbahani** — Prepared by Ali Saleh (default)
- **Verse Audio Playback (Warsh)**: Listen to any verse in Warsh recitation by Yassin Al-Jazaery, streamed directly from EveryAyah.com CDN
- **Page Recitation**: Play the full-page MP3 audio for any page — uses Abdul Basit Warsh recitation as primary source, with automatic fallback to Ibrahim Aldosary Warsh recitation for any missing pages
- **RTL Navigation**: Right-to-left page swiping matching Arabic reading direction
- **Smart Bookmarks**: Save and quickly access your favorite pages
- **Last Page Memory**: Automatically resumes where you left off
- **Surah Index**: Quick navigation to any of the 114 chapters
- **Search Functionality**: Search ayah text with diacritic-insensitive matching
- **Hizb & Juz Indicators**: Visual hizb quarter markers in the page header
- **Screen Wake Lock**: Prevents screen from turning off during reading
- **Responsive Design**: Adapts beautifully to both portrait and landscape orientations
- **Web Support**: Run in any Chromium-based browser (Chrome, Brave, Edge, etc.)
- **Arabic Typography**: Custom Amiri and Avenir fonts for authentic Arabic rendering

## 📱 Screenshots

<!-- Add screenshots here -->
<!-- | Portrait | Landscape |
|----------|-----------|
| <img src="screenshots/portrait.png" width="250"> | <img src="screenshots/landscape.png" width="250"> | -->

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.5.3)
- Dart SDK (>=3.5.3)
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/asbahani-quran-app.git
   cd asbahani-quran-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Running on Web (Chromium)

```bash
flutter run -d chrome
```

Or run a local web server and open any browser manually:

```bash
flutter run -d web-server --web-port=8080
# Then open http://localhost:8080
```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 📂 Project Structure

```
lib/
├── main.dart              # Entry point; initializes wakelock & splash screen
├── quran_app.dart         # Alternative Quran app widget (using flutter_quran package)
├── data/
│   └── page_data.dart     # Page metadata model (surah numbers, hizb quarters for 604 pages)
├── models/
│   └── chapter.dart       # Chapter model (id, page, name, verse count, type)
└── screens/
    ├── quran_screen.dart  # MaterialApp with Arabic theming & font configuration
    └── quran_page.dart    # Main reading interface with bottom sheet menu & audio playback

assets/
├── quran_pages/          # Asbahani recitation page images (604 PNGs)
├── azrak/                # Azrak recitation page images (604 PNGs)
├── quran.json            # Complete Quran text with metadata
├── chapters.json         # 114 surahs with names, verse counts, page numbers
├── quran.db              # SQLite database (available for future use)
├── fonts/                # Amiri & Avenir font families
└── *.png                 # App logos and splash screen assets
```

## 🛠️ Tech Stack

### Core
- **Flutter** — Cross-platform UI framework
- **Dart** — Programming language

### Key Dependencies

| Package | Purpose |
|---------|---------|
| `al_quran` | Surah metadata lookup by page number |
| `shared_preferences` | Local storage for bookmarks & preferences |
| `arabic_font` | Arabic font theming integration |
| `dartarabic` | Arabic text processing (diacritic removal) |
| `wakelock_plus` | Keep screen on while reading |
| `flutter_native_splash` | Custom branded splash screen |
| `flutter_launcher_icons` | App icon generation |

### Assets
- **Page Images**: 1,208 high-quality PNG images (604 per recitation style)
- **Quran Text**: JSON with 6,236 ayahs in Uthmani and Emlaei scripts
- **Chapters**: Complete surah metadata in Arabic, English, and French

## 📖 Usage Guide

### Navigation
- **Swipe left/right** to move between pages
- **Tap anywhere** on the page to open the bottom menu

### Bottom Menu Tabs

1. **السور (Chapters)**: Browse all 114 surahs; tap to jump to any chapter
2. **البحث (Search)**: Search Quran text (works without diacritics for easier matching)
3. **العلامات (Bookmarks)**: Access your saved pages
4. **المصاحف (Recitation Styles)**: Switch between Asbahani and Azrak recitations
5. **الجزء والحزب (Juz & Hizb)**: Navigate by juz or hizb

### Audio Playback (Warsh Recitation)

#### Verse Playback
- Open the **Search** tab and search for a verse
- Tap the **▶ play button** next to any search result to listen to that verse in Warsh recitation (Yassin Al-Jazaery)
- Tap the **⏹ stop button** to stop playback
- A loading spinner appears while audio is buffering
- Audio is streamed from [EveryAyah.com](https://everyayah.com) CDN — requires internet connection

#### Page Recitation

- Tap the **▶ play button** ▶ in the page header to recite the entire current page
- The page plays as a single audio file from start to finish
- Tap the **⏹ stop button** (turns green while playing) to stop
- Page recitation auto-stops when swiping to a different page
- **Primary reciter**: Abdul Basit (عبد الباسط) — Warsh recitation
- **Fallback reciter**: Ibrahim Al-Dosary (إبراهيم الدوسري) — automatically used for pages not available in the primary source

### Bookmarks
- Tap the **bookmark icon** in the page header to save/remove the current page
- Bookmarked pages show a filled bookmark icon

## ⚙️ Configuration

### App Metadata
- **App Name**: الأصبهاني (Al-Asbahani)
- **Package Name**: `com.quran.alasbahani`
- **Version**: 1.0.0+1

### Audio Sources

#### Single Verse Audio
- **Reciter**: Yassin Al-Jazaery (ياسين الجزائري)
- **Recitation Style**: Warsh 'an Nafi' (ورش عن نافع)
- **CDN**: EveryAyah.com
- **URL Pattern**: `https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps/{surah}{ayah}.mp3`

#### Full Page Audio
- **Primary Reciter**: Abdul Basit (عبد الباسط) — Warsh recitation
- **Fallback Reciter**: Ibrahim Al-Dosary (إبراهيم الدوسري) — automatically used for unavailable pages
- **CDN**: EveryAyah.com
- **URL Pattern**: `https://everyayah.com/data/warsh/warsh_Abdul_Basit_128kbps/PageMp3s/Page{page}.mp3`
- **Fallback Pattern**: `https://everyayah.com/data/warsh/warsh_ibrahim_aldosary_128kbps/PageMp3s/Page{page}.mp3`
- The app caches which URL works per page to avoid re-checking on subsequent plays

### Customizing the Splash Screen

Edit the `flutter_native_splash` section in `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/logo.png
  android_12:
    image: assets/asbahani-logo.png
    color: "#FFFFF9"
    icon_background_color: "#FFFFFF"
```

Then regenerate:
```bash
flutter pub run flutter_native_splash:create
```

## 🧪 Testing

Run the test suite:
```bash
flutter test
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🤲 وقف لله

هذا العمل **وقف لله تعالى**، لا يُباع ولا يُشترى. من استفاد منه فليدعُ لمَن ساهم في إعداده.

This application is a **waqf (endowment) for the sake of Allah** — it is not to be sold or bought. May Allah accept it from all who contributed.

## 🙏 Acknowledgments

- Quran text and page images sourced from verified Islamic resources
- Warsh audio provided by [EveryAyah.com](https://everyayah.com) — Yassin Al-Jazaery recitation
- Amiri font for beautiful Arabic typography
- The Flutter community for excellent packages and documentation

## 📞 Support

For questions, suggestions, or bug reports, please open an issue on [GitHub](https://github.com/your-username/asbahani-quran-app/issues).

---

## 📋 Recent Updates

### March 2025

- **Audio playback reliability**: Fixed race conditions when rapidly switching between verses — playback is now properly stopped before loading a new audio URL, and state updates are guarded against loading transitions to prevent inconsistencies.
- **Search audio state indicator**: Fixed the search results bottom sheet not showing the playing state (green stop icon / loading spinner) after clicking a verse's play button — the UI now properly reflects playback status by using reactive state notifiers.
- **Page recitation**: Added a play button in the page header to recite the entire page as a single audio file. Uses Abdul Basit Warsh recitation with automatic fallback to Ibrahim Al-Dosary for missing pages.
- **Page recitation source fix**: Switched from verse-by-verse playback to full-page MP3 files for better listening experience.
- **Offline detection**: Added network connectivity detection — when tapping play buttons without an internet connection, the app now shows a clear "لا يوجد اتصال بالإنترنت" (no internet connection) message instead of a raw error.

---

**May this app be a source of benefit and guidance. 📿**
