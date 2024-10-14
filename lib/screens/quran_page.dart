import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dartarabic/dartarabic.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // For loading the JSON file
import 'dart:async';
import 'package:al_quran/al_quran.dart';

import '../data/page_data.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  TextEditingController searchController = TextEditingController();
  late PageController _pageController;
  int _initialPage = 0;

  List<dynamic> quran = [];
  List chapters = [];

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

  Future<void> _loadLastOpenedPage() async {
    int lastOpenedPage = await _getLastOpenedPage();

    setState(() {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(lastOpenedPage - 1);
      } else {
        _pageController = PageController(
            initialPage:
                lastOpenedPage - 1); // Page starts from 0, so subtract 1
      }
    });
  }

  Future<int> _getLastOpenedPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastOpenedPage') ?? 1; // Default to page 1
  }

  // save the last opened page in SharedPreferences
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

  void initialization() {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.
    _pageController = PageController(initialPage: _initialPage);

    _loadQuranData();
    _loadQuranChapters();

    // Load the last opened page after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastOpenedPage();
    });
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

    return GestureDetector(
      onTap: () => _showMenu(context),
      child: PageView.builder(
        controller: _pageController,
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
  }

  void _showMenu(context) {
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
                      _chapterTab(context),
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

  Widget _searchTab(BuildContext context) {
    List searchResults = [];

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
              setState(() {
                searchResults = quran.where((ayah) {
                  return ayah['aya_text_emlaey']
                      .toLowerCase()
                      .contains(query.toLowerCase());
                }).toList();
                debugPrint("search: $searchResults");
              });
            },
          ),
          Expanded(
            child: _searchResultsWidget(context, searchResults),
          ),
        ],
      ),
    );
  }

  Widget _searchResultsWidget(context, searchResults) {
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
              subtitle: Text('${ayah["sura_name_ar"]} / ص  ${ayah["page"]}',
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
}
