import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dartarabic/dartarabic.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart'; // For loading the JSON file
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:asbahani/data/app_preferences.dart';
import 'package:asbahani/data/ayah_search.dart';
import 'package:asbahani/data/bookmark_transfer.dart';
import 'package:asbahani/data/page_data.dart';
import 'package:asbahani/data/ayah_geometry.dart';
import 'package:asbahani/data/page_prefetch.dart';
import 'package:asbahani/data/quran_navigation.dart';
import 'package:asbahani/screens/quran_menu_tab.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  TextEditingController searchController = TextEditingController();
  dynamic _pageController;

  @override
  void initState() {
    super.initState();
    initialization();
  }

  int totalPagesNumber = 604;
  List<dynamic> quran = [];
  List chapters = [];
  List quranPagesIndex = [];
  List searchResults = [];
  List<int> bookmarks = [];
  List<String> ayahBookmarks = [];
  // The bottom sheet has its own element tree, so parent setState alone does
  // not rebuild the open bookmarks tab after an import.
  final ValueNotifier<int> _bookmarksVersion = ValueNotifier<int>(0);
  final Map<int, AyahPageGeometry> _ayahGeometryCache = {};
  final PagePrefetchController _pagePrefetch = PagePrefetchController();
  AyahSearchIndex? _ayahSearchIndex;
  bool _keepAwake = true;
  int? _highlightAyahPage;
  String? _highlightAyahKey;
  AyahPageGeometry? _highlightGeometry;
  List ways = [
    "مصحف مجمع الملك فهد (ورش من طريق الأزرق)",
    "مصحف الأصبهاني إعداد علي صالح"
  ];
  int activeWayIndex = 1; // asbahani

  // Focus mode hides the page chrome without leaving this PageView. Enter by
  // swiping up from the bottom edge; exit by swiping down from the top edge.
  bool _focusMode = false;
  bool _focusHintSeen = false;
  bool _showFocusHint = false;
  bool _focusControlsVisible = false;
  double _focusDragDistance = 0;
  Timer? _focusPillTimer;
  Timer? _focusHintTimer;

  @override
  void dispose() {
    _focusPillTimer?.cancel();
    _focusHintTimer?.cancel();
    searchController.dispose();
    _bookmarksVersion.dispose();
    _pagePrefetch.dispose();
    super.dispose();
  }

  // Load Quran JSON data from assets
  Future<void> _loadQuranData() async {
    final String response = await rootBundle.loadString('assets/quran.json');
    final List<dynamic> data = await jsonDecode(response);
    if (!mounted) return;
    setState(() {
      quran = data;
      _ayahSearchIndex = AyahSearchIndex(data);
    });
  }

  Future<void> _loadQuranChapters() async {
    final String response = await rootBundle.loadString('assets/chapters.json');
    final List<dynamic> rawData = await jsonDecode(response);
    if (!mounted) return;
    setState(() {
      chapters = rawData.toList();
    });
  }

  Future<void> _loadQuranPagesIndex() async {
    final String response =
        await rootBundle.loadString('assets/quran-pages-index.json');
    final Map<String, dynamic> data = await jsonDecode(response);
    if (!mounted) return;
    setState(() {
      quranPagesIndex = data['pages'] as List;
    });
  }

  Future<void> _loadBookmarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bookmarks =
        prefs.getStringList('bookmarks')?.map((e) => int.parse(e)).toList() ??
            [];
    ayahBookmarks = prefs.getStringList('ayahBookmarks') ?? [];
    if (mounted) setState(() {});
  }

  Future<int> _getLastOpenedPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastOpenedPage') ?? 1; // Default to page 1
  }

  Future<void> _saveLastOpenedPage(int pageNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastOpenedPage', pageNumber);
  }

  Future<void> _saveLastTabPanelIndex(int tabIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastTabPanelIndex', tabIndex);
  }

  Future<int> _getLastTabPanelIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastTabPanelIndex') ?? 0;
  }

  Future<void> _saveActiveWayIndex(int newActiveWayIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeWayIndex', newActiveWayIndex);

    if (!mounted) return;
    setState(() {
      activeWayIndex = newActiveWayIndex;
    });
    final current = _pageController.hasClients
        ? _pageController.page?.round() ?? 0
        : 0;
    _prefetchNeighbors(current + 1);
  }

  Future<int> _getActiveWayIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('activeWayIndex') ?? 1; // Default to asbahani
  }

  Future<bool> _getFocusHintSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('focusHintSeen') ?? false;
  }

  Future<void> _saveFocusHintSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('focusHintSeen', true);
  }

  Future<void> _setKeepAwake(bool enabled) async {
    setState(() => _keepAwake = enabled);
    await AppPreferences.setKeepAwake(enabled);
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Unsupported platforms keep their default behaviour.
    }
  }

  Future<void> _saveBookmarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'bookmarks', bookmarks.map((e) => e.toString()).toList());
  }

  Future<void> _saveAyahBookmarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ayahBookmarks', ayahBookmarks);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Exports page and ayah bookmarks together as one JSON file. XFile.fromData
  /// keeps this working on web and desktop too, without a temp directory.
  Future<void> _exportBookmarks() async {
    try {
      final json = BookmarkTransfer.encode(BookmarkData(
        pages: bookmarks,
        ayahs: ayahBookmarks,
      ));
      final stamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = XFile.fromData(
        utf8.encode(json),
        name: 'asbahani-bookmarks-$stamp.json',
        mimeType: 'application/json',
      );
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: 'محفوظات الأصبهاني',
        ),
      );
      if (result.status == ShareResultStatus.success) {
        _showMessage('تم تصدير المحفوظات');
      }
    } catch (_) {
      _showMessage('تعذّر تصدير المحفوظات');
    }
  }

  /// Picks a JSON file and merges its bookmarks into the current ones.
  Future<void> _importBookmarks() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null) return; // user cancelled
      final bytes = picked.files.single.bytes;
      if (bytes == null) {
        _showMessage('تعذّر قراءة الملف');
        return;
      }

      final parsed = BookmarkTransfer.decode(utf8.decode(bytes));
      final merged = BookmarkTransfer.merge(
        BookmarkData(pages: bookmarks, ayahs: ayahBookmarks),
        parsed.bookmarks,
      );
      if (merged.isEmpty) {
        _showMessage('المحفوظات في الملف موجودة بالفعل');
        return;
      }

      setState(() {
        bookmarks = merged.bookmarks.pages;
        ayahBookmarks = merged.bookmarks.ayahs;
      });
      _bookmarksVersion.value++;
      await Future.wait([_saveBookmarks(), _saveAyahBookmarks()]);

      final skipped = parsed.skipped > 0
          ? ' (تم تجاهل ${parsed.skipped} إدخال غير صالح)'
          : '';
      _showMessage(
          'تم استيراد ${merged.addedPages} صفحة و ${merged.addedAyahs} آية$skipped');
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذّر استيراد المحفوظات');
    }
  }

  bool _toggleAyahBookmark(int surah, int ayah) {
    final key = '$surah:$ayah';
    final added = !ayahBookmarks.contains(key);
    setState(() {
      if (added) {
        ayahBookmarks.add(key);
      } else {
        ayahBookmarks.remove(key);
      }
      _saveAyahBookmarks();
    });
    _bookmarksVersion.value++;
    final surahName = _chapterName(surah);
    final message = added
        ? 'تم حفظ الآية $ayah من $surahName'
        : 'تم إزالة الآية من المحفوظات';
    _showMessage(message);
    return added;
  }

  void _setAyahHighlight(int page, int surah, int ayah, AyahPageGeometry geometry) {
    setState(() {
      _highlightAyahPage = page;
      _highlightAyahKey = '$surah:$ayah';
      _highlightGeometry = geometry;
    });
  }

  void _clearAyahHighlight() {
    setState(() {
      _highlightAyahPage = null;
      _highlightAyahKey = null;
      _highlightGeometry = null;
    });
  }

  (int, int)? _highlightFor(int page) {
    if (_highlightAyahPage != page ||
        _highlightAyahKey == null ||
        _highlightGeometry == null ||
        activeWayIndex == 1) {
      return null;
    }
    final parts = _highlightAyahKey!.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  String _chapterName(int surah) {
    try {
      final chapter = chapters
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['id'] == surah);
      return DartArabic.stripTashkeel(chapter['name_ar'] as String);
    } catch (_) {
      return 'سورة $surah';
    }
  }

  int? _pageOfAyah(int surah, int ayah) {
    for (int i = 0; i < quranPagesIndex.length; i++) {
      final segments = quranPagesIndex[i] as List;
      for (final seg in segments) {
        final s = (seg as List)[0] as int;
        final start = seg[1] as int;
        final end = seg[2] as int;
        if (s == surah && ayah >= start && ayah <= end) {
          return i + 1;
        }
      }
    }
    for (final item in quran) {
      if (item['sura_no'] == surah && item['aya_no'] == ayah) {
        return item['page'];
      }
    }
    return null;
  }

  Future<AyahPageGeometry?> _ayahGeometryFor(int page) async {
    final cached = _ayahGeometryCache[page];
    if (cached != null) {
      return cached;
    }
    try {
      final geometry = await AyahPageGeometry.load(page);
      _ayahGeometryCache[page] = geometry;
      return geometry;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleAyahLongPress(
      int page, Offset position, Size size) async {
    if (activeWayIndex == 1) return; // asbahani pages have no ayah polygons
    if (size.width <= 0 || size.height <= 0) return;
    final geometry = await _ayahGeometryFor(page);
    if (geometry == null || !mounted) return;
    final x = geometry.viewBox.left + position.dx / (size.width / geometry.viewBox.width);
    final y = geometry.viewBox.top + position.dy / (size.height / geometry.viewBox.height);
    final hit = geometry.findAt(x, y);
    if (hit != null) {
      final added = _toggleAyahBookmark(hit.surah, hit.ayah);
      if (added) {
        _setAyahHighlight(page, hit.surah, hit.ayah, geometry);
      } else {
        _clearAyahHighlight();
      }
    }
  }

  String _getHizbText(int page) {
    final currentPage = quranPages[page - 1];
    final hizb = currentPage.hizb;

    switch (currentPage.hizbQuarter % 4) {
      case 0:
        return '¾ الحزب $hizb';
      case 2:
        return '¼ الحزب $hizb';
      case 3:
        return '½ الحزب $hizb';
      default:
        return 'الحزب $hizb';
    }
  }

  void initialization() {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.
    _pageController = PageController();

    _loadQuranData();
    _loadQuranChapters();
    _loadQuranPagesIndex();
    _loadBookmarks();

    // Load the last opened page after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int lastOpenedPage = await _getLastOpenedPage();
      activeWayIndex = await _getActiveWayIndex();
      _focusHintSeen = await _getFocusHintSeen();
      _keepAwake = await AppPreferences.keepAwake();
      if (!mounted) return;

      _pageController
          .jumpToPage(lastOpenedPage - 1); // Page starts from 0, so subtract 1

      _prefetchNeighbors(lastOpenedPage);

      FlutterNativeSplash.remove();
    });
  }

  // Warm the neighbouring page assets. Waking the hit layers is separate:
  // they are small JSON files used only for ayah bookmarks/highlights.
  void _prefetchNeighbors(int page) {
    final azrak = activeWayIndex != 1;
    _pagePrefetch.update(page, azrak: azrak, context: context);
    if (azrak) {
      for (final neighbor in _pagePrefetch.neighbors) {
        unawaited(_ayahGeometryFor(neighbor));
      }
    }
  }

  Widget _vectorPicture(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.fill,
  }) {
    return createCompatVectorGraphic(
      loader: AssetBytesLoader(assetPath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _pageLoadErrorPlaceholder(),
    );
  }

  Widget _pageLoadErrorPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'فشل تحميل الصفحة',
            style: TextStyle(color: Colors.grey, fontFamily: 'amiri'),
          ),
        ],
      ),
    );
  }

  Widget _pageImageWidget(BuildContext context, int page) {
    var asbahaniPagePath = 'assets/quran_pages/$page.png';
    var azrakPagePath = 'assets/azrak/$page.svg.vec';

    var isAsbahaniWayChoosen = activeWayIndex == 1;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape
        ? LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: _imageWidget(
                    isAsbahaniWayChoosen ? asbahaniPagePath : azrakPagePath,
                    context,
                    page,
                  ),
                ),
              );
            },
          )
        : _imageWidget(
            isAsbahaniWayChoosen ? asbahaniPagePath : azrakPagePath,
            context,
            page,
          );
  }

  Widget _imageWidget(String assetPath, BuildContext ctx, int page) {
    final svg = assetPath.endsWith('.svg.vec');

    return RepaintBoundary(
      child: svg
          ? LayoutBuilder(
              builder: (context, constraints) {
                Widget svgWidget;
                if (constraints.hasBoundedWidth &&
                    constraints.hasBoundedHeight) {
                  svgWidget = SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: _vectorPicture(assetPath),
                  );
                } else if (constraints.hasBoundedWidth) {
                  svgWidget = _vectorPicture(
                    assetPath,
                    width: constraints.maxWidth,
                  );
                } else {
                  svgWidget = _vectorPicture(assetPath);
                }
                final highlight = _highlightFor(page);
                final gestureWidget = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPressStart: (details) {
                    final effectiveSize = context.size ??
                        Size(constraints.maxWidth, constraints.maxHeight);
                    _handleAyahLongPress(
                        page, details.localPosition, effectiveSize);
                  },
                  child: svgWidget,
                );
                return Stack(
                  children: [
                    gestureWidget,
                    if (highlight != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: AyahHighlightPainter(
                              geometry: _highlightGeometry!,
                              surah: highlight.$1,
                              ayah: highlight.$2,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            )
          : Image.asset(
              assetPath,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  _pageLoadErrorPlaceholder(),
            ),
    );
  }

  String _quranHeaderSurahName(int page) {
    if (quranPagesIndex.length < page || chapters.isEmpty) {
      return '';
    }
    try {
      final lastSurahNumber =
          (quranPagesIndex[page - 1].last as List)[0] as int;
      final chapter = chapters
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['id'] == lastSurahNumber);
      return DartArabic.stripTashkeel(chapter['name_ar'] as String);
    } catch (_) {
      return '';
    }
  }

  Widget _headerRow(index) {
    var surahName = _quranHeaderSurahName(index + 1);
    var hizb = _getHizbText(index + 1);
    return Padding(
        padding: const EdgeInsets.all(1.0),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () => _showMenu(
              context,
              initialTabIndex: 0,
              initialMenuSection: QuranMenuSection.hizb,
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamily: 'amiri',
                  fontWeight: FontWeight.bold),
              child: Text(hizb),
            ),
          ),
          GestureDetector(
            onTap: () => _showMenu(
              context,
              initialTabIndex: 0,
              initialMenuSection: QuranMenuSection.surah,
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamily: 'amiri',
                  fontWeight: FontWeight.bold),
              child: Text(surahName),
            ),
          )
        ]));
  }

  Widget _footerRow(index) {
    return GestureDetector(
      onTap: () => _showQuickGoToPageDialog(context),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              child: Text('${index + 1}'),
            ),
          ],
        ),
      ),
    );
  }

  void _setFocusMode(bool enabled) {
    if (_focusMode == enabled) return;
    _focusPillTimer?.cancel();
    _focusHintTimer?.cancel();

    setState(() {
      _focusMode = enabled;
      _focusControlsVisible = enabled;
      _showFocusHint = enabled && !_focusHintSeen;
    });

    if (!enabled) return;

    if (_showFocusHint) {
      _focusHintSeen = true;
      _saveFocusHintSeen();
      _focusHintTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showFocusHint = false);
      });
    }
    _focusPillTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _focusControlsVisible = false);
    });
  }

  /// Fades the chrome and animates its height to zero; the focus gesture strips
  /// live outside this so they still work while the chrome is gone.
  Widget _animatedChrome({required Widget child}) {
    return AnimatedOpacity(
      opacity: _focusMode ? 0 : 1,
      duration: const Duration(milliseconds: 180),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: _focusMode ? const SizedBox.shrink() : child,
      ),
    );
  }

  /// [exits] is true for the top strip (swipe down to leave focus) and false
  /// for the bottom strip (swipe up to enter it).
  Widget _focusEdgeStrip({required bool exits}) {
    return Positioned(
      top: exits ? 0 : null,
      bottom: exits ? null : 0,
      left: 0,
      right: 0,
      height: 48,
      child: Semantics(
        label: exits
            ? 'اسحب للأسفل للخروج من وضع التركيز'
            : 'اسحب للأعلى لوضع التركيز',
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (_) => _focusDragDistance = 0,
          onVerticalDragUpdate: (details) {
            _focusDragDistance += details.delta.dy;
          },
          onVerticalDragEnd: (_) {
            if (exits && _focusDragDistance > 40) {
              _setFocusMode(false);
            } else if (!exits && _focusDragDistance < -40) {
              _setFocusMode(true);
            }
            _focusDragDistance = 0;
          },
        ),
      ),
    );
  }

  Widget _focusExitPill() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 12,
      child: GestureDetector(
        onTap: () => _setFocusMode(false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x99000000),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _showFocusHint ? 'اسحب من الأعلى للخروج' : 'خروج من التركيز',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'amiri',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
      onPageChanged: (index) {
        _saveLastOpenedPage(index + 1);
        _prefetchNeighbors(index + 1);
        if (_highlightAyahPage != null && _highlightAyahPage != index + 1) {
          _clearAyahHighlight();
        }
      },
      reverse: true, // For RTL navigation
      itemCount: totalPagesNumber,
      itemBuilder: (context, index) {
        // Azrak SVGs are transparent, so a soft blue page tint shows through
        // and is easier on the eyes; asbahani PNGs already carry their own
        // white background.
        final pageBackground =
            activeWayIndex == 0 ? const Color(0xFFDCEAF7) : Colors.white;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: pageBackground,
          ),
          child: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _animatedChrome(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headerRow(index),
                          // Keeps the page artwork's top decoration clear of the header.
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showMenu(context),
                        behavior: HitTestBehavior.opaque,
                        child: _pageImageWidget(context, index + 1),
                      ),
                    ),
                    _animatedChrome(child: _footerRow(index)),
                  ],
                ),
              ),
              if (!_focusMode) _focusEdgeStrip(exits: false),
              if (_focusMode) ...[
                _focusEdgeStrip(exits: true),
                if (_focusControlsVisible) _focusExitPill(),
              ],
            ],
          ),
        );
      },
        ),
        Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: PagePrefetchOverlay(controller: _pagePrefetch),
        ),
      ],
    );
  }

  void _showMenu(
    context, {
    int? initialTabIndex,
    QuranMenuSection initialMenuSection = QuranMenuSection.all,
  }) async {
    int tabIndex = initialTabIndex ?? await _getLastTabPanelIndex();
    // The old juzz/hizb tab (index 4) was merged into the surah tab.
    if (tabIndex >= 4) {
      tabIndex = 0;
    } else {
      tabIndex = tabIndex.clamp(0, 3).toInt();
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTabController(
            length: 4,
            initialIndex: tabIndex,
            child: Builder(
              builder: (context) {
                final tabController = DefaultTabController.of(context);

                tabController.addListener(() {
                  if (!tabController.indexIsChanging) {
                    _saveLastTabPanelIndex(tabController.index);
                  }
                });

                return Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.black,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(icon: Icon(Icons.menu_book)),
                        Tab(icon: Icon(Icons.search)),
                        Tab(icon: Icon(Icons.bookmark)),
                        Tab(icon: Icon(Icons.book)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          QuranMenuTab(
                            pageController: _pageController,
                            chapters: chapters,
                            initialSection: initialMenuSection,
                          ),
                          _searchTab(context),
                          _bookmarksTab(context),
                          _waysTab(context),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black12)),
                      ),
                      child: const Text(
                        'وقف لله تعالى',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontFamily: 'amiri',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _performSearch(String query) {
    setState(() {
      searchResults = _ayahSearchIndex?.search(query) ?? const <dynamic>[];
    });
  }

  Widget _waysTab(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: _keepAwake,
          secondary: const Icon(Icons.screen_lock_portrait),
          title: const Text('إبقاء الشاشة مضيئة'),
          onChanged: _setKeepAwake,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: ways.length,
            itemBuilder: (context, index) {
              final way = ways[index];

              return ListTile(
                title: Text('$way'),
                onTap: () {
                  Navigator.pop(context);
                  _saveActiveWayIndex(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _jumpToAyah(int page, int surah, int ayah) async {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page - 1);
    }
    final geometry = await _ayahGeometryFor(page);
    if (!mounted || geometry == null) return;
    final key = '$surah:$ayah';
    if (!ayahBookmarks.contains(key)) return;
    _setAyahHighlight(page, surah, ayah, geometry);
  }

  Future<void> _highlightSearchResult(int page, int surah, int ayah) async {
    final geometry = await _ayahGeometryFor(page);
    if (!mounted || geometry == null) return;
    _setAyahHighlight(page, surah, ayah, geometry);
  }

  Widget _bookmarksTab(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _bookmarksVersion,
      builder: (context, _, __) => _buildBookmarksTabContent(context),
    );
  }

  Widget _buildBookmarksTabContent(BuildContext context) {
    final sortedBookmarks = List<int>.from(bookmarks)..sort();
    final sortedAyahBookmarks = List<String>.from(ayahBookmarks)..sort((a, b) {
        final aParts = a.split(':').map(int.parse).toList();
        final bParts = b.split(':').map(int.parse).toList();
        return aParts[0] != bParts[0]
            ? aParts[0] - bParts[0]
            : aParts[1] - bParts[1];
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportBookmarks,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('تصدير'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importBookmarks,
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: const Text('استيراد'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: sortedBookmarks.isEmpty && sortedAyahBookmarks.isEmpty
              ? const Center(child: Text('لا توجد محفوظات بعد'))
              : ListView(
                  children: [
                    if (sortedBookmarks.isNotEmpty) ...[
                      _bookmarkSectionHeader('الصفحات المحفوظة'),
                      ...sortedBookmarks.map((page) {
                        return ListTile(
                          title: Text('الصفحة $page'),
                          onTap: () {
                            Navigator.pop(context);
                            _pageController.jumpToPage(page - 1);
                          },
                        );
                      }),
                    ],
                    if (sortedAyahBookmarks.isNotEmpty) ...[
                      _bookmarkSectionHeader('الآيات المحفوظة'),
                      ...sortedAyahBookmarks.map((key) {
                        final parts = key.split(':');
                        final surah = int.parse(parts[0]);
                        final ayah = int.parse(parts[1]);
                        final page = _pageOfAyah(surah, ayah);
                        return ListTile(
                          leading: const Icon(Icons.bookmark, size: 20),
                          title: Text('الآية $ayah - ${_chapterName(surah)}'),
                          subtitle: page != null ? Text('صفحة $page') : null,
                          onTap: () {
                            Navigator.pop(context);
                            if (page != null) {
                              _jumpToAyah(page, surah, ayah);
                            }
                          },
                        );
                      }),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _bookmarkSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          fontFamily: 'amiri',
        ),
      ),
    );
  }

  Widget _searchTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'ابحث ...',
              border: OutlineInputBorder(),
            ),
            onChanged: (String query) {
              _performSearch(query);
            },
          ),
          Expanded(
            child: _searchResultsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _searchResultsWidget() {
    if (searchResults.isEmpty) {
      return const Center(child: Text('لم يتم العثور على نتائج'));
    }
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final ayah = searchResults[index];
        return Column(
          children: [
            ListTile(
              title: Text(ayah["aya_text_emlaey"].replaceAll('\n', ' '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  )),
              subtitle: Text(
                  '${ayah["sura_name_ar"]} / ص  ${ayah["page"]} / آية ${ayah["aya_no"]}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                  )),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              onTap: () {
                final ayahPage = ayah["page"];
                final surahNo = ayah["sura_no"];
                final surahName = ayah["sura_name_ar"];
                final ayahNo = ayah["aya_no"];
                Navigator.of(context).pop();
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(ayahPage - 1);
                  _highlightSearchResult(ayahPage, surahNo, ayahNo);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$surahName - آية $ayahNo'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                }
              },
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
          ],
        );
      },
    );
  }

  void _showQuickGoToPageDialog(BuildContext context) {
    final quickController = TextEditingController();
    final currentPage = (_pageController.hasClients && _pageController.page != null)
        ? _pageController.page!.toInt() + 1
        : 1;
    quickController.text = currentPage.toString();
    quickController.selection = TextSelection(baseOffset: 0, extentOffset: quickController.text.length);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتقل إلى صفحة', textAlign: TextAlign.center),
        content: TextField(
          controller: quickController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final pageNumber = int.tryParse(value.trim());
            if (pageNumber != null && pageNumber >= 1 && pageNumber <= totalPagesNumber) {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(pageNumber - 1);
                }
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final pageNumber = int.tryParse(quickController.text.trim());
              if (pageNumber != null && pageNumber >= 1 && pageNumber <= totalPagesNumber) {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(pageNumber - 1);
                  }
                });
              }
            },
            child: const Text('انتقل'),
          ),
        ],
      ),
    );
  }
}
