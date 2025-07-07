
class Folder {
  Folder({required this.id, required this.name});
  final String id;
  final String name;
}

class FileMeta {
  FileMeta({
    required this.name,
    required this.size,
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  final String name;
  final int size;
  final String url;
  final String type;
  final DateTime uploadedAt;
}
