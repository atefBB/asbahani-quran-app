import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dartarabic/dartarabic.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // For loading the JSON file
import 'dart:async';
import 'package:al_quran/al_quran.dart';

import 'package:asbahani/data/page_data.dart';

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
              Tab(text: 'الأجزاء'),
              Tab(text: 'الأحزاب'),
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

  int totalPagesNumber = 604;
  List<dynamic> quran = [];
  List chapters = [];
  List searchResults = [];
  List<int> bookmarks = [];
  List ways = [
    "مصحف مجمع الملك فهد (ورش من طريق الأزرق)",
    "مصحف الأصبهاني إعداد علي صالح"
  ];
  int activeWayIndex = 1; // asbahani

  @override
  void initState() {
    super.initState();
    initialization();
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

  Future<void> _loadBookmarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bookmarks =
        prefs.getStringList('bookmarks')?.map((e) => int.parse(e)).toList() ??
            [];
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
    _loadBookmarks();

    // Load the last opened page after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int lastOpenedPage = await _getLastOpenedPage();
      activeWayIndex = await _getActiveWayIndex();

      _pageController
          .jumpToPage(lastOpenedPage - 1); // Page starts from 0, so subtract 1

      FlutterNativeSplash.remove();
    });
  }

  Widget _pageImageWidget(context, index) {
    var asbahaniPagePath = 'assets/quran_pages/$index.png';
    var azrakPagePath = 'assets/azrak/$index.png';

    var isAsbahaniWayChoosen = activeWayIndex == 1;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape
        ? SingleChildScrollView(
            child: _imageWidget(
              isAsbahaniWayChoosen ? asbahaniPagePath : azrakPagePath,
              context,
            ),
          )
        : Center(
            child: _imageWidget(
              isAsbahaniWayChoosen ? asbahaniPagePath : azrakPagePath,
              context,
            ),
          );
  }

  Widget _imageWidget(String assetPath, BuildContext ctx) {
    return RepaintBoundary(
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
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
        },
      ),
    );
  }

  bool isBookmarked(int page) {
    return bookmarks.contains(page);
  }

  Widget _headerRow(index) {
    var surahName = DartArabic.stripTashkeel(
        AlQuran.surahDetails.byPageNumber(index + 1).last.name);
    var hizb = _getHizbText(index + 1);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 4.0),
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
            icon: Icon(isBookmarked(index + 1)
                ? Icons.bookmark
                : Icons.bookmark_outline),
            onPressed: () => _toggleBookmark(index + 1),
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
        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
      },
      reverse: true, // For RTL navigation
      itemCount: totalPagesNumber,
      itemBuilder: (context, index) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              _headerRow(index),
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
                        Tab(text: 'السور'),
                        Tab(text: 'البحث'),
                        Tab(text: "العلامات"),
                        Tab(text: "المصاحف"),
                        Tab(text: "الأجزاء"),
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

  Widget _bookmarksTab(BuildContext context) {
    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final page = bookmarks[index];
        return ListTile(
          title: Text('الصفحة $page'),
          onTap: () {
            Navigator.pop(context);
            _pageController.jumpToPage(page - 1);
          },
        );
      },
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              onTap: () {
                Navigator.of(context).pop();
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(ayah["page"] - 1);
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
