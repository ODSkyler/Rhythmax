import '../models/track.dart';

class QueueManager {
  final List<Track> queue = [];
  final List<Track> originalQueue = [];

  int currentIndex = -1;

  Track? get currentTrack =>
      (currentIndex >= 0 && currentIndex < queue.length)
          ? queue[currentIndex]
          : null;

  void clear() {
    queue.clear();
    originalQueue.clear();
    currentIndex = -1;
  }

  void addAll(List<Track> tracks) {
    queue.addAll(tracks);
    originalQueue.addAll(tracks);
  }

  void add(Track track) {
    queue.add(track);
    originalQueue.add(track);
  }

  void removeAt(int index) {
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    originalQueue.removeAt(index);
  }

  void move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= queue.length) return;
    if (newIndex < 0 || newIndex >= queue.length) return;

    if (newIndex > oldIndex) newIndex--;

    final track = queue.removeAt(oldIndex);
    queue.insert(newIndex, track);
  }

  bool containsTrack(String trackId) {
    return queue.any((t) => t.id == trackId);
  }

  int indexOfTrack(String trackId) {
    return queue.indexWhere((t) => t.id == trackId);
  }

  int? findNextPlayableIndex(
      bool Function(Track) explicitBlocked,
      bool repeatAll,
      ) {
    if (queue.isEmpty) return null;

    int i = currentIndex + 1;
    int guard = 0;

    while (guard < queue.length) {
      if (i >= queue.length) {
        if (repeatAll) {
          i = 0;
        } else {
          return null;
        }
      }

      if (!explicitBlocked(queue[i])) return i;

      i++;
      guard++;
    }

    return null;
  }
}