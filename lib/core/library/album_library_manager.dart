import 'package:hive/hive.dart';
import '../models/album.dart';

class AlbumLibraryManager {
  static final Box _box = Hive.box('library_albums');

  static Future<void> likeAlbum(Album album) async {
    await _box.put(album.libraryKey, album.toMap());
  }

  static Future<void> unlikeAlbum(Album album) async {
    await _box.delete(album.libraryKey);
  }

  static bool isLiked(Album album) {
    return _box.containsKey(album.libraryKey);
  }

  static List<Album> getLikedAlbums() {
    return _box.values.map((e) {
      try {
        final map = Map<String, dynamic>.from(e as Map);
        return Album.fromMap(map);
      } catch (_) {
        return null;
      }
    }).whereType<Album>().toList();
  }
}