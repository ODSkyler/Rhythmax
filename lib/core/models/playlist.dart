import 'track.dart';

enum PlaylistType {
  source,
  user,
}

class Playlist {
  final String id;
  final String source;
  final PlaylistType type;
  final String title;
  final String? description;
  final String? artworkUrl;
  final List<Track> tracks;
  final bool isEditable;

  const Playlist({
    required this.id,
    required this.source,
    required this.type,
    required this.title,
    this.description,
    this.artworkUrl,
    this.tracks = const [],
    this.isEditable = false,
  });

  // ⭐ for Hive
  String get libraryKey => "${source}_$id";

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "source": source,
      "type": type.name,
      "title": title,
      "description": description,
      "artworkUrl": artworkUrl,
      "tracks": tracks.map((t) => t.toMap()).toList(),
      "isEditable": isEditable,
    };
  }

  factory Playlist.fromMap(Map map) {
    return Playlist(
      id: map["id"]?.toString() ?? "",
      source: map["source"]?.toString() ?? "",

      type: PlaylistType.values.firstWhere(
            (e) => e.name == map["type"],
        orElse: () => PlaylistType.source,
      ),

      title: map["title"]?.toString() ?? "",
      description: map["description"]?.toString(),
      artworkUrl: map["artworkUrl"]?.toString(),

      tracks: (map["tracks"] as List? ?? [])
          .map((e) => Track.fromMap(Map<String, dynamic>.from(e)))
          .toList(),

      isEditable: map["isEditable"] ?? false,
    );
  }

  Playlist copyWith({
    String? id,
    String? source,
    PlaylistType? type,
    String? title,
    String? description,
    String? artworkUrl,
    List<Track>? tracks,
    bool? isEditable,
  }) {
    return Playlist(
      id: id ?? this.id,
      source: source ?? this.source,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      tracks: tracks ?? this.tracks,
      isEditable: isEditable ?? this.isEditable,
    );
  }
}