import 'package:hive/hive.dart';
import '../models/playlist.dart';

class PlaylistLibraryManager {
  static final Box _box = Hive.box('library_playlists');

  static Future<void> likePlaylist(Playlist playlist) async {
    await _box.put(playlist.libraryKey, playlist.toMap());
  }

  static Future<void> unlikePlaylist(Playlist playlist) async {
    await _box.delete(playlist.libraryKey);
  }

  static bool isLiked(Playlist playlist) {
    return _box.containsKey(playlist.libraryKey);
  }

  static List<Playlist> getLikedPlaylists() {
    return _box.values.map((e) {
      try {
        final map = Map<String, dynamic>.from(e as Map);
        return Playlist.fromMap(map);
      } catch (_) {
        return null;
      }
    }).whereType<Playlist>().toList();
  }
}