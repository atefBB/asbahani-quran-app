import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dartarabic/dartarabic.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // For loading the JSON file
import 'dart:async';
import 'package:al_quran/al_quran.dart';
import 'package:just_audio/just_audio.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAyahId; // 'suraNo:ayaNo' identifier
  bool _isAudioLoading = false;
  final ValueNotifier<String?> _currentAyahNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _audioLoadingNotifier = ValueNotifier(false);
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Page recitation state
  bool _isPlayingPage = false;
  int? _currentPageNumber;
  List<dynamic> _pagePlaylist = [];
  int _currentPagePlayIndex = 0;

  static const String _warshBaseUrl = 'https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps';

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (state) {
        if (state.processingState == ProcessingState.completed) {
          if (_isPlayingPage && mounted) {
            _playNextPageVerse();
          } else if (mounted && !_isAudioLoading) {
            setState(() {
              _currentlyPlayingAyahId = null;
              _isAudioLoading = false;
            });
            _currentAyahNotifier.value = null;
            _audioLoadingNotifier.value = false;
          }
        }
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _currentlyPlayingAyahId = null;
            _isAudioLoading = false;
          });
          _currentAyahNotifier.value = null;
          _audioLoadingNotifier.value = false;
        }
      },
    );
    initialization();
  }

  String _buildAyahAudioUrl(int surahNo, int ayahNo) {
    final surahStr = surahNo.toString().padLeft(3, '0');
    final ayahStr = ayahNo.toString().padLeft(3, '0');
    return '$_warshBaseUrl/$surahStr$ayahStr.mp3';
  }

  String _ayahId(int surahNo, int ayahNo) => '$surahNo:$ayahNo';

  Future<void> _playAyah(int surahNo, int ayahNo) async {
    // If page playback is active, stop it and play the single verse
    if (_isPlayingPage) {
      _stopPagePlayback();
    }

    final id = _ayahId(surahNo, ayahNo);

    if (_currentlyPlayingAyahId == id) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingAyahId = null;
        _isAudioLoading = false;
      });
      _currentAyahNotifier.value = null;
      _audioLoadingNotifier.value = false;
      return;
    }

    setState(() {
      _currentlyPlayingAyahId = id;
      _isAudioLoading = true;
    });
    _currentAyahNotifier.value = id;
    _audioLoadingNotifier.value = true;

    try {
      await _audioPlayer.stop();
      final url = _buildAyahAudioUrl(surahNo, ayahNo);
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
        _audioLoadingNotifier.value = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentlyPlayingAyahId = null;
          _isAudioLoading = false;
        });
        _currentAyahNotifier.value = null;
        _audioLoadingNotifier.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تشغيل الآية: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _stopPagePlayback() {
    _isPlayingPage = false;
    _currentPageNumber = null;
    _pagePlaylist = [];
    _currentPagePlayIndex = 0;
    _currentlyPlayingAyahId = null;
    _isAudioLoading = false;
    _currentAyahNotifier.value = null;
    _audioLoadingNotifier.value = false;
  }

  Future<void> _playPage(int pageNumber) async {
    // If already playing this page, stop
    if (_isPlayingPage && _currentPageNumber == pageNumber) {
      await _audioPlayer.stop();
      _stopPagePlayback();
      if (mounted) setState(() {});
      return;
    }

    // Stop any current audio
    await _audioPlayer.stop();

    // Find all verses on this page
    final pageVerses = quran.where((ayah) => ayah['page'] == pageNumber).toList();
    if (pageVerses.isEmpty) return;

    // Reset state and start page playback
    _isPlayingPage = true;
    _currentPageNumber = pageNumber;
    _pagePlaylist = pageVerses;
    _currentPagePlayIndex = 0;

    if (mounted) setState(() {});
    _playCurrentPageVerse();
  }

  void _playCurrentPageVerse() {
    if (_currentPagePlayIndex >= _pagePlaylist.length) {
      _stopPagePlayback();
      if (mounted) setState(() {});
      return;
    }

    if (!mounted) return;

    final ayah = _pagePlaylist[_currentPagePlayIndex];
    final surahNo = ayah['sura_no'];
    final ayahNo = ayah['aya_no'];
    final id = _ayahId(surahNo, ayahNo);

    setState(() {
      _currentlyPlayingAyahId = id;
      _isAudioLoading = true;
    });
    _currentAyahNotifier.value = id;
    _audioLoadingNotifier.value = true;

    _playAudioUrl(surahNo, ayahNo);
  }

  void _playNextPageVerse() {
    _currentPagePlayIndex++;
    _playCurrentPageVerse();
  }

  Future<void> _playAudioUrl(int surahNo, int ayahNo) async {
    try {
      final url = _buildAyahAudioUrl(surahNo, ayahNo);
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
        _audioLoadingNotifier.value = false;
      }
    } catch (e) {
      if (_isPlayingPage) {
        // On error during page playback, skip to next verse
        _playNextPageVerse();
      } else if (mounted) {
        setState(() {
          _currentlyPlayingAyahId = null;
          _isAudioLoading = false;
        });
        _currentAyahNotifier.value = null;
        _audioLoadingNotifier.value = false;
      }
    }
  }

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
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _currentAyahNotifier.dispose();
    _audioLoadingNotifier.dispose();
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
        ? LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: _imageWidget(
                    isAsbahaniWayChoosen ? asbahaniPagePath : azrakPagePath,
                    context,
                  ),
                ),
              );
            },
          )
        : _imageWidget(
            isAsbahaniWayChoosen ? asbahaniPagePath : azrakPagePath,
            context,
          );
  }

  Widget _imageWidget(String assetPath, BuildContext ctx) {
    return RepaintBoundary(
      child: Image.asset(
        assetPath,
        fit: BoxFit.fill,
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
    final pageNumber = index + 1;
    final isThisPagePlaying = _isPlayingPage && _currentPageNumber == pageNumber;

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isThisPagePlaying ? Icons.stop_circle : Icons.play_circle_fill,
                  color: isThisPagePlaying ? Colors.green : Colors.black54,
                  size: 24,
                ),
                onPressed: () => _playPage(pageNumber),
                tooltip: isThisPagePlaying ? 'إيقاف' : 'تشغيل الصفحة',
              ),
              IconButton(
                icon: Icon(isBookmarked(pageNumber)
                    ? Icons.bookmark
                    : Icons.bookmark_outline),
                onPressed: () => _toggleBookmark(pageNumber),
              ),
            ],
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
        if (_isPlayingPage) {
          _audioPlayer.stop();
          _stopPagePlayback();
        }
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
    return ListenableBuilder(
      listenable: Listenable.merge([_currentAyahNotifier, _audioLoadingNotifier]),
      builder: (context, _) {
        return ListView.builder(
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final ayah = searchResults[index];
            final ayahId = _ayahId(ayah["sura_no"], ayah["aya_no"]);
            final isPlaying = _currentAyahNotifier.value == ayahId;
            final isLoading = isPlaying && _audioLoadingNotifier.value;
            return Column(
              children: [
                ListTile(
                  leading: IconButton(
                    icon: isLoading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue),
                          )
                        : Icon(
                            isPlaying ? Icons.stop_circle : Icons.play_circle_outline,
                            color: isPlaying ? Colors.green : Colors.grey[600],
                            size: 28,
                          ),
                    onPressed: isLoading ? null : () {
                      _playAyah(ayah["sura_no"], ayah["aya_no"]);
                    },
                    tooltip: isPlaying ? 'إيقاف' : 'استماع',
                  ),
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
