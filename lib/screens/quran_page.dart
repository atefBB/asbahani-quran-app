import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dartarabic/dartarabic.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // For loading the JSON file

import 'package:asbahani/data/page_data.dart';
import 'package:asbahani/data/ayah_geometry.dart';

class _JuzHizbTabPage extends StatefulWidget {
  final dynamic pageController;
  const _JuzHizbTabPage({required this.pageController});

  @override
  State<_JuzHizbTabPage> createState() => _JuzHizbTabPageState();
}

class _JuzHizbTabPageState extends State<_JuzHizbTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(icon: Icon(Icons.view_list)),
              Tab(icon: Icon(Icons.grid_view)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _JuzTabContent(pageController: widget.pageController),
                _HizbTabContent(pageController: widget.pageController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JuzTabContent extends StatelessWidget {
  final dynamic pageController;
  const _JuzTabContent({required this.pageController});

  @override
  Widget build(BuildContext context) {
    final juzMap = <int, int>{};
    for (int i = 0; i < quranPages.length; i++) {
      final juz = quranPages[i].juz;
      if (!juzMap.containsKey(juz)) {
        juzMap[juz] = i + 1;
      }
    }

    return ListView.builder(
      itemCount: juzMap.length,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final pageNumber = juzMap[juzNumber]!;
        return ListTile(
          leading: const Text('جزء', style: TextStyle(fontFamily: 'amiri')),
          title: Text('$juzNumber'),
          trailing: Text('ص $pageNumber'),
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (pageController.hasClients) {
                pageController.jumpToPage(pageNumber - 1);
              }
            });
          },
        );
      },
    );
  }
}

class _HizbTabContent extends StatelessWidget {
  final dynamic pageController;
  const _HizbTabContent({required this.pageController});

  @override
  Widget build(BuildContext context) {
    final hizbMap = <int, int>{};
    for (int i = 0; i < quranPages.length; i++) {
      final hizb = quranPages[i].hizb;
      if (!hizbMap.containsKey(hizb)) {
        hizbMap[hizb] = i + 1;
      }
    }

    return ListView.builder(
      itemCount: hizbMap.length,
      itemBuilder: (context, index) {
        final hizbNumber = index + 1;
        final pageNumber = hizbMap[hizbNumber]!;
        return ListTile(
          leading: const Text('حزب', style: TextStyle(fontFamily: 'amiri')),
          title: Text('$hizbNumber'),
          trailing: Text('ص $pageNumber'),
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (pageController.hasClients) {
                pageController.jumpToPage(pageNumber - 1);
              }
            });
          },
        );
      },
    );
  }
}

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
  final Map<int, AyahPageGeometry> _ayahGeometryCache = {};
  final List<String> _svgWarmPaths = [];
  int? _highlightAyahPage;
  String? _highlightAyahKey;
  AyahPageGeometry? _highlightGeometry;
  List ways = [
    "مصحف مجمع الملك فهد (ورش من طريق الأزرق)",
    "مصحف الأصبهاني إعداد علي صالح"
  ];
  int activeWayIndex = 1; // asbahani

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Load Quran JSON data from assets
  Future<void> _loadQuranData() async {
    final String response = await rootBundle.loadString('assets/quran.json');
    final List<dynamic> data = await jsonDecode(response);
    setState(() {
      quran = data;
    });
  }

  Future<void> _loadQuranChapters() async {
    final String response = await rootBundle.loadString('assets/chapters.json');
    final List<dynamic> rawData = await jsonDecode(response);
    setState(() {
      chapters = rawData.toList();
    });
  }

  Future<void> _loadQuranPagesIndex() async {
    final String response =
        await rootBundle.loadString('assets/quran-pages-index.json');
    final Map<String, dynamic> data = await jsonDecode(response);
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
    setState(() {});
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

    setState(() {
      activeWayIndex = newActiveWayIndex;
    });
  }

  Future<int> _getActiveWayIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('activeWayIndex') ?? 1; // Default to asbahani
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
    final surahName = _chapterName(surah);
    final message = added
        ? 'تم حفظ الآية $ayah من $surahName'
        : 'تم إزالة الآية من المحفوظات';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _toggleBookmark(int page) {
    setState(() {
      if (bookmarks.contains(page)) {
        bookmarks.remove(page);
      } else {
        bookmarks.add(page);
      }
      _saveBookmarks();
    });
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

      _pageController
          .jumpToPage(lastOpenedPage - 1); // Page starts from 0, so subtract 1

      _prefetchNeighbors(lastOpenedPage);

      FlutterNativeSplash.remove();
    });
  }

  // Pre-decode neighbor pages so swiping shows them without a delay.
  void _prefetchNeighbors(int page) {
    setState(() {
      _svgWarmPaths.clear();
      _prefetchPage(page - 1);
      _prefetchPage(page + 1);
    });
  }

  void _prefetchPage(int page) {
    if (page < 1 || page > totalPagesNumber) return;
    if (activeWayIndex == 1) {
      precacheImage(AssetImage('assets/quran_pages/$page.png'), context);
    } else {
      final path = 'assets/azrak/$page.svg';
      rootBundle.load(path); // warm the asset bytes
      _svgWarmPaths.add(path);
    }
  }

  Widget _pageImageWidget(BuildContext context, int page) {
    var asbahaniPagePath = 'assets/quran_pages/$page.png';
    var azrakPagePath = 'assets/azrak/$page.svg';

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
    final svg = assetPath.endsWith('.svg');
    Widget placeholder = const Center(
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
                    child: SvgPicture.asset(
                      assetPath,
                      fit: BoxFit.fill,
                    ),
                  );
                } else if (constraints.hasBoundedWidth) {
                  svgWidget = SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.fill,
                    width: constraints.maxWidth,
                  );
                } else {
                  svgWidget = SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.fill,
                  );
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
                if (highlight == null) {
                  return gestureWidget;
                }
                return Stack(
                  children: [
                    gestureWidget,
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
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }

  bool isBookmarked(int page) {
    return bookmarks.contains(page);
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
    final pageNumber = index + 1;

    return Padding(
        padding: const EdgeInsets.all(1.0),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () => _showMenu(context, initialTabIndex: 4),
            child: DefaultTextStyle(
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamily: 'amiri',
                  fontWeight: FontWeight.bold),
              child: Text(hizb),
            ),
          ),
          IconButton(
            icon: Icon(isBookmarked(pageNumber)
                ? Icons.bookmark
                : Icons.bookmark_outline),
            onPressed: () => _toggleBookmark(pageNumber),
          ),
          GestureDetector(
            onTap: () => _showMenu(context, initialTabIndex: 0),
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

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
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
              Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: _headerRow(index),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMenu(context),
                      behavior: HitTestBehavior.opaque,
                      child: _pageImageWidget(context, index + 1),
                    ),
                  ),
                  _footerRow(index),
                ],
              ),
              // Invisible decoy SVG loads for neighboring pages: this triggers
              // flutter_svg's cache so the real page appears instantly.
              ..._svgWarmPaths.map((path) => Positioned(
                    left: 0,
                    top: 0,
                    width: 1,
                    height: 1,
                    child: Opacity(opacity: 0, child: SvgPicture.asset(path)),
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showMenu(context, {int? initialTabIndex}) async {
    int tabIndex = initialTabIndex ?? await _getLastTabPanelIndex();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTabController(
            length: 5,
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
                        Tab(icon: Icon(Icons.view_list)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _chapterTab(context),
                          _searchTab(context),
                          _bookmarksTab(context),
                          _waysTab(context),
                          _juzHizbTab(context),
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

  Widget _chapterTab(context) {
    return ListView.builder(
      itemCount: chapters.length,
      itemBuilder: (BuildContext context, int index) {
        var chapterPageNumber = chapters[index]["page"];
        var chapterName = DartArabic.stripTashkeel(chapters[index]["name_ar"]);

        return ListTile(
          title: Text(chapterName),
          subtitle: Text('صفحة  $chapterPageNumber'),
          onTap: () {
            Navigator.pop(context);
            if (_pageController.hasClients) {
              _pageController.jumpToPage(chapterPageNumber - 1);
            }
          },
        );
      },
    );
  }

  void _performSearch(String query) {
    setState(() {
      searchResults = quran.where((ayah) {
        return ayah['aya_text_emlaey']
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _waysTab(BuildContext context) {
    return ListView.builder(
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

  Widget _bookmarksTab(BuildContext context) {
    final sortedBookmarks = List<int>.from(bookmarks)..sort();
    final sortedAyahBookmarks = List<String>.from(ayahBookmarks)..sort((a, b) {
        final aParts = a.split(':').map(int.parse).toList();
        final bParts = b.split(':').map(int.parse).toList();
        return aParts[0] != bParts[0]
            ? aParts[0] - bParts[0]
            : aParts[1] - bParts[1];
      });

    if (sortedBookmarks.isEmpty && sortedAyahBookmarks.isEmpty) {
      return const Center(child: Text('لا توجد محفوظات بعد'));
    }

    return ListView(
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
              subtitle: page != null
                  ? Text('صفحة $page')
                  : null,
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
                final surahName = ayah["sura_name_ar"];
                final ayahNo = ayah["aya_no"];
                Navigator.of(context).pop();
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(ayahPage - 1);
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

  Widget _juzHizbTab(BuildContext context) {
    return _JuzHizbTabPage(pageController: _pageController);
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
