import 'package:hive/hive.dart';
import '../models/track.dart';

class LibraryManager {
  static final Box _box = Hive.box('library');

  static Future<void> likeTrack(Track track) async {
    await _box.put(track.libraryKey, track.toMap());
  }

  static Future<void> unlikeTrack(Track track) async {
    await _box.delete(track.libraryKey);
  }

  static bool isLiked(Track track) {
    return _box.containsKey(track.libraryKey);
  }

  static List<Track> getLikedTracks() {
    return _box.values.map((e) {
      try {
        final map = Map<String, dynamic>.from(e as Map);
        return Track.fromMap(map);
      } catch (_) {
        return null;
      }
    }).whereType<Track>().toList();
  }
}