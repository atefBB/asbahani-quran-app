class Chapter {
  final int id;
  final int pageNumber;
  final String name;
  final int versesCount;

  Chapter(
      {required this.id,
      required this.pageNumber,
      required this.name,
      required this.versesCount});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
        id: json['id'],
        pageNumber: json['page'],
        name: json['name_ar'],
        versesCount: json["ayat_count"]);
  }
}
