import 'package:hive/hive.dart';
import '../models/artist.dart';

class ArtistLibraryManager {
  static final Box _box = Hive.box('library_artists');

  static Future<void> likeArtist(Artist artist) async {
    await _box.put(artist.libraryKey, artist.toMap());
  }

  static Future<void> unlikeArtist(Artist artist) async {
    await _box.delete(artist.libraryKey);
  }

  static bool isLiked(Artist artist) {
    return _box.containsKey(artist.libraryKey);
  }

  static List<Artist> getLikedArtists() {
    return _box.values.map((e) {
      try {
        final map = Map<String, dynamic>.from(e as Map);
        return Artist.fromMap(map);
      } catch (_) {
        return null;
      }
    }).whereType<Artist>().toList();
  }
}