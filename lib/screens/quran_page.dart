import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dartarabic/dartarabic.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // For loading the JSON file
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:al_quran/al_quran.dart';

import '../providers/chapter_provider.dart';
import '../data/page_data.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  TextEditingController searchController = TextEditingController();
  static PageController pageController = PageController();

  List<dynamic> quran = [];
  List searchResults = [];

  @override
  void initState() {
    initialization();

    super.initState();
  }

  // Load Quran JSON data from assets
  Future<void> loadQuranData() async {
    final String response = await rootBundle.loadString('assets/quran.json');
    final List<dynamic> data = await jsonDecode(response);
    setState(() {
      quran = data;
    });
  }

  // load the last opened page from SharedPreferences
  Future<void> _loadLastOpenedPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastOpenedPage =
        prefs.getInt('lastOpenedPage') ?? 1; // Default to page 1

    // Wait until the first frame is rendered before jumping to the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(lastOpenedPage - 1);
      }
    });
  }

  // Function to save the last opened page in SharedPreferences
  Future<void> _saveLastOpenedPage(int pageNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastOpenedPage', pageNumber);
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

  void initialization() async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.

    _loadLastOpenedPage();
    loadQuranData();
    FlutterNativeSplash.remove();
  }

  Widget _pageImageExpandedRow(context, index) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/quran_pages/$index.png',
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }

  Widget _headerRow(index) {
    var surahName = DartArabic.stripTashkeel(
        AlQuran.surahDetails.byPageNumber(index + 1).last.name);
    var hizb = _getHizbText(index + 1);

    return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 11.0), // Add padding here
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          DefaultTextStyle(
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'amiri',
                fontWeight: FontWeight.bold),
            child: Text(hizb),
          ),
          DefaultTextStyle(
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'amiri',
                fontWeight: FontWeight.bold),
            child: Text(surahName),
          )
        ]));
  }

  Widget _footerRow(index) {
    return Row(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    const totalPagesNumber = 604;
    return FutureBuilder(
        future:
            Provider.of<ChapterProvider>(context, listen: false).loadChapters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Consumer<ChapterProvider>(
            builder: (context, chapterProvider, child) {
              return GestureDetector(
                onTap: () => _showMenu(context, chapterProvider.chapters),
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    _saveLastOpenedPage(index + 1);
                  },
                  reverse: true, // For RTL navigation
                  itemCount: totalPagesNumber,
                  itemBuilder: (context, index) {
                    return SafeArea(
                      top: true,
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).height,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        alignment: const AlignmentDirectional(0, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _headerRow(index),
                            _pageImageExpandedRow(context, index + 1),
                            _footerRow(index),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        });
  }

  void _showMenu(BuildContext context, chapters) {
    // @todo add bookmarked pages as tab

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTabController(
            length: 2, // 2 tabs: Chapters, Search
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.black,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'السور'),
                    Tab(text: 'البحث'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _chapterTab(context, chapters),
                      _searchTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chapterTab(context, chapters) {
    return ListView.builder(
      itemCount: chapters.length,
      itemBuilder: (BuildContext context, int index) {
        var chapterPageNumber = chapters[index].pageNumber;

        return ListTile(
          title: Text(
              DartArabic.stripTashkeel(chapters[index].name)), // Chapter name
          subtitle: Text('صفحة  $chapterPageNumber'), // Chapter page number
          onTap: () {
            Navigator.pop(context);
            pageController.jumpToPage(chapterPageNumber - 1);
          },
        );
      },
    );
  }

  // Perform search by filtering ayahs
  void _performSearch(String query) {
    setState(() {
      searchResults = quran.where((ayah) {
        return ayah['aya_text_emlaey']
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    });
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
            child: _newSearchResultsWidget(context, searchResults),
          ),
        ],
      ),
    );
  }

  Widget _newSearchResultsWidget(context, searchResults) {
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
              subtitle: Text(ayah["sura_name_ar"],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  )),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              onTap: () {
                Navigator.of(context).pop();
                pageController.jumpToPage(ayah["page"] - 1);
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
}
