class Artist {
  final String id;
  final String source;
  final String name;
  final String? artworkUrl;

  const Artist({
    required this.id,
    required this.source,
    required this.name,
    this.artworkUrl,
  });

  // ⭐ for Hive
  String get libraryKey => "${source}_$id";

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "source": source,
      "name": name,
      "artworkUrl": artworkUrl,
    };
  }

  factory Artist.fromMap(Map map) {
    return Artist(
      id: map["id"]?.toString() ?? "",
      source: map["source"]?.toString() ?? "",
      name: map["name"]?.toString() ?? "",
      artworkUrl: map["artworkUrl"]?.toString(),
    );
  }

  Artist copyWith({
    String? id,
    String? source,
    String? name,
    String? artworkUrl,
  }) {
    return Artist(
      id: id ?? this.id,
      source: source ?? this.source,
      name: name ?? this.name,
      artworkUrl: artworkUrl ?? this.artworkUrl,
    );
  }
}