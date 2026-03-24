import 'track.dart';

class Album {
  final String id;
  final String source;
  final String title;
  final List<String> artists;
  final String? artworkUrl;
  final DateTime? releaseDate;
  final List<Track> tracks;
  final bool isExplicit;

  Album({
    required this.id,
    required this.source,
    required this.title,
    required this.artists,
    this.artworkUrl,
    this.releaseDate,
    required this.tracks,
    this.isExplicit = false,
  });

  String get libraryKey => "${source}_$id";

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "source": source,
      "title": title,
      "artists": artists,
      "artworkUrl": artworkUrl,
      "releaseDate": releaseDate?.millisecondsSinceEpoch,
      "isExplicit": isExplicit,
    };
  }

  factory Album.fromMap(Map map) {
    return Album(
      id: map["id"]?.toString() ?? "",
      source: map["source"]?.toString() ?? "",
      title: map["title"]?.toString() ?? "",

      artists: List<String>.from(
        (map["artists"] ?? []).map((e) => e.toString()),
      ),

      artworkUrl: map["artworkUrl"]?.toString(),

      releaseDate: map["releaseDate"] != null
          ? DateTime.fromMillisecondsSinceEpoch(map["releaseDate"])
          : null,

      tracks: const [], // ⭐ always empty (will fetch later)

      isExplicit: map["isExplicit"] ?? false,
    );
  }

}
