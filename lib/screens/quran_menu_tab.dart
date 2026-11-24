import 'package:flutter/material.dart';

import 'package:asbahani/data/quran_navigation.dart';

/// Combined surah/juz/hizb list with one search field.
///
/// This replaces the old separate juzz/hizb tab so all three ways of jumping
/// through the mushaf live in the surah menu.
class QuranMenuTab extends StatefulWidget {
  final dynamic pageController;
  final List<dynamic> chapters;
  final QuranMenuSection initialSection;

  const QuranMenuTab({
    super.key,
    required this.pageController,
    required this.chapters,
    this.initialSection = QuranMenuSection.all,
  });

  @override
  State<QuranMenuTab> createState() => _QuranMenuTabState();
}

class _QuranMenuTabState extends State<QuranMenuTab> {
  late final TextEditingController _searchController;
  late QuranMenuSection _selectedSection;
  late QuranMenuIndex _index;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedSection = widget.initialSection;
    _index = QuranMenuIndex(chapters: widget.chapters);
  }

  @override
  void didUpdateWidget(covariant QuranMenuTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.chapters, oldWidget.chapters)) {
      _index = QuranMenuIndex(chapters: widget.chapters);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _index.search(_selectedSection, _query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _searchController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة أو رقم الجزء/الحزب',
              border: const OutlineInputBorder(),
              suffixIcon: _query.isEmpty
                  ? const Icon(Icons.search)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (query) => setState(() => _query = query),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final section in QuranMenuSection.values)
                ChoiceChip(
                  label: Text(section.label),
                  selected: _selectedSection == section,
                  onSelected: (_) =>
                      setState(() => _selectedSection = section),
                ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('لم يتم العثور على نتائج'))
              : ListView(children: _buildRows(context, results)),
        ),
      ],
    );
  }

  List<Widget> _buildRows(BuildContext context, List<QuranMenuEntry> results) {
    final rows = <Widget>[];
    QuranMenuSection? currentSection;

    for (final entry in results) {
      if (entry.section != currentSection) {
        currentSection = entry.section;
        rows.add(_sectionHeader(currentSection.headerLabel));
      }
      rows.add(_entryTile(context, entry));
    }

    return rows;
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          fontFamily: 'amiri',
        ),
      ),
    );
  }

  Widget _entryTile(BuildContext context, QuranMenuEntry entry) {
    return ListTile(
      leading: SizedBox(
        width: 44,
        child: Text(
          entry.section.singular,
          style: const TextStyle(fontFamily: 'amiri', fontSize: 12),
        ),
      ),
      title: Text(
        entry.title,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'amiri'),
      ),
      trailing: Text('ص ${entry.page}'),
      onTap: () {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (widget.pageController.hasClients) {
            widget.pageController.jumpToPage(entry.page - 1);
          }
        });
      },
    );
  }
}
