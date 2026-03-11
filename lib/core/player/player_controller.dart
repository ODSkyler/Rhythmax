import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import '../source/source_manager.dart';
import 'queue_manager.dart';

enum RepeatMode { off, all, one }

class PlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final QueueManager _queueManager = QueueManager();

  AudioPlayer get player => _player;

  Future<int?> get androidAudioSessionId async {
    return _player.androidAudioSessionId;
  }

  /* ---------------- QUEUE ---------------- */

  List<Track> get queue => List.unmodifiable(_queueManager.queue);
  int get currentIndex => _queueManager.currentIndex;
  Track? get currentTrack => _queueManager.currentTrack;

  /* ---------------- STATE ---------------- */

  String? _queueSourceId;
  String? _queueSourceType;

  String? _playingFromType;
  String? _playingFromTitle;

  String? get queueSourceId => _queueSourceId;
  String? get queueSourceType => _queueSourceType;
  String? get playingFromType => _playingFromType;
  String? get playingFromTitle => _playingFromTitle;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration bufferedPosition = Duration.zero;

  bool get isPlaying => _player.playing;

  bool get isBuffering =>
      _player.processingState == ProcessingState.buffering;

  bool get isLoading =>
      _player.processingState == ProcessingState.loading;

  bool get shouldShowLoader {
    final state = _player.processingState;
    return state == ProcessingState.loading ||
        state == ProcessingState.buffering;
  }

  bool shuffleEnabled = false;
  RepeatMode repeatMode = RepeatMode.off;

  final Color backgroundColor = const Color(0xFF1C1D22);

  /* ---------------- QUALITY LABEL ---------------- */

  String _currentQualityLabel = 'Normal (96 kbps)';
  String get currentQualityLabel => _currentQualityLabel;

  void setQualityLabel(String label) {
    _currentQualityLabel = label;
    _preloadedNextSource = null;
    _preloadedNextIndex = null;
    notifyListeners();
  }

  /* ---------------- PREF KEYS ---------------- */

  static const _prefShuffle = 'player_shuffle';
  static const _prefRepeat = 'player_repeat';
  static const _prefGapless = 'player_gapless';

  bool gaplessEnabled = true;

  /* ---------------- PRELOAD ---------------- */

  static const Duration _preloadThreshold = Duration(seconds: 15);

  AudioSource? _preloadedNextSource;
  int? _preloadedNextIndex;
  bool _isPreloadingNext = false;

  /* ---------------- INIT ---------------- */

  PlayerController() {
    _restorePrefs();

    _player.positionStream.listen((p) {
      position = p;
      _checkAndPreloadNext();
      notifyListeners();
    });

    _player.bufferedPositionStream.listen((buffered) {
      bufferedPosition = buffered;
      notifyListeners();
    });

    _player.durationStream.listen((d) {
      if (d != null) {
        duration = d;
        notifyListeners();
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      _queueManager.currentIndex = index;

      _preloadedNextSource = null;
      _preloadedNextIndex = null;

      notifyListeners();
    });

    _player.playerStateStream.listen((_) {
      notifyListeners();
    });
  }

  bool _isExplicitBlocked(Track track) {
    final source = SourceManager.instance.activeSource;
    return track.isExplicit && !source.explicitEnabled;
  }

  /* -------------------------------------------------------------------------- */
  /*                             PRELOAD NEXT TRACK                             */
  /* -------------------------------------------------------------------------- */

  Future<void> _checkAndPreloadNext() async {
    if (!gaplessEnabled) return;
    if (_queueManager.queue.isEmpty) return;
    if (_queueManager.currentIndex < 0) return;
    if (_isPreloadingNext) return;

    final remaining = duration - position;
    if (remaining > _preloadThreshold) return;

    final nextIndex = _queueManager.findNextPlayableIndex(
      _isExplicitBlocked,
      repeatMode == RepeatMode.all,
    );

    if (nextIndex == null) return;
    if (_preloadedNextIndex == nextIndex) return;

    _isPreloadingNext = true;

    try {
      final source = SourceManager.instance.activeSource;
      final track = _queueManager.queue[nextIndex];

      final uri = await source.getStreamUrl(track);

      _preloadedNextSource = AudioSource.uri(uri);
      _preloadedNextIndex = nextIndex;
    } catch (_) {}

    _isPreloadingNext = false;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 PLAY TRACK                                 */
  /* -------------------------------------------------------------------------- */

  Future<void> playTrack(
      Track track, {
        List<Track>? queue,
        String? sourceId,
        String? sourceType,
        String? playType,
        String? sourceTitle,
      }) async {
    _queueSourceId = sourceId;
    _queueSourceType = sourceType;
    _playingFromType = playType;
    _playingFromTitle = sourceTitle;

    _queueManager.clear();

    final inputQueue =
    (queue != null && queue.isNotEmpty) ? queue : [track];

    final playableQueue =
    inputQueue.where((t) => !_isExplicitBlocked(t)).toList();

    if (playableQueue.isEmpty) return;

    _queueManager.addAll(playableQueue);

    final startTrack =
    playableQueue.contains(track) ? track : playableQueue.first;

    _queueManager.currentIndex =
        _queueManager.queue.indexOf(startTrack);

    final source = SourceManager.instance.activeSource;

    final audioSources = <AudioSource>[];

    for (final t in _queueManager.queue) {
      final uri = await source.getStreamUrl(t);
      audioSources.add(AudioSource.uri(uri));
    }

    await _player.setAudioSources(
      audioSources,
      initialIndex: _queueManager.currentIndex,
      preload: false,
    );

    if (shuffleEnabled) {
      await _player.setShuffleModeEnabled(true);
      await _player.shuffle();
    }

    await _player.play();

    notifyListeners();
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queueManager.queue.length) return;

    _queueManager.currentIndex = index;
    await _player.seek(Duration.zero, index: index);

    notifyListeners();
  }

  /* -------------------------------------------------------------------------- */
  /*                                  CONTROLS                                  */
  /* -------------------------------------------------------------------------- */

  Future<void> play() async {
    if (!_player.playing) await _player.play();
  }

  Future<void> pause() async {
    if (_player.playing) await _player.pause();
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> next() async {
    if (shuffleEnabled) {
      final nextIndex = _player.nextIndex;

      if (nextIndex == null) return;

      await _player.seek(Duration.zero, index: nextIndex);
      return;
    }

    if (_queueManager.queue.isEmpty) return;

    final nextIndex = _queueManager.findNextPlayableIndex(
      _isExplicitBlocked,
      repeatMode == RepeatMode.all,
    );

    if (nextIndex == null) return;

    await _player.seek(Duration.zero, index: nextIndex);
  }

  Future<void> previous() async {
    if (shuffleEnabled) {
      final prevIndex = _player.previousIndex;

      if (prevIndex == null) return;

      await _player.seek(Duration.zero, index: prevIndex);
      return;
    }

    if (_queueManager.queue.isEmpty) return;

    int i = _queueManager.currentIndex - 1;

    while (i >= 0 && _isExplicitBlocked(_queueManager.queue[i])) {
      i--;
    }

    if (i < 0) return;

    await _player.seek(Duration.zero, index: i);
  }

  Future<void> seek(Duration value) async {
    await _player.seek(value);
  }

  /* -------------------------------------------------------------------------- */
  /*                             QUEUE OPERATIONS                               */
  /* -------------------------------------------------------------------------- */

  void clearQueue() {
    _queueManager.clear();

    _queueSourceId = null;
    _queueSourceType = null;

    _player.clearAudioSources();
    _player.stop();

    notifyListeners();
  }

  bool isTrackInQueue(String trackId) {
    return _queueManager.containsTrack(trackId);
  }

  Future<void> rebuildQueueWithNewQuality() async {
    if (_queueManager.queue.isEmpty) return;

    final currentTrack = this.currentTrack;
    final currentPos = position;

    if (currentTrack == null) return;

    final source = SourceManager.instance.activeSource;

    final newSources = <AudioSource>[];

    for (final track in _queueManager.queue) {
      final uri = await source.getStreamUrl(track);
      newSources.add(AudioSource.uri(uri));
    }

    await _player.setAudioSources(
      newSources,
      initialIndex: _queueManager.currentIndex,
      initialPosition: currentPos,
      preload: gaplessEnabled,
    );

    if (shuffleEnabled) {
      await _player.setShuffleModeEnabled(true);
      await _player.shuffle();
    }

    await _player.play();
  }

  /* -------------------------------------------------------------------------- */
/*                             QUEUE MODIFICATION                             */
/* -------------------------------------------------------------------------- */

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queueManager.queue.length) return;

    _queueManager.removeAt(index);

    _player.removeAudioSourceAt(index);

    notifyListeners();
  }

  void moveQueueItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queueManager.queue.length) return;
    if (newIndex < 0 || newIndex >= _queueManager.queue.length) return;

    _queueManager.move(oldIndex, newIndex);

    _player.moveAudioSource(oldIndex, newIndex);

    notifyListeners();
  }

  Future<void> addToQueue(Track track) async {
    final wasEmpty = _queueManager.queue.isEmpty;

    _queueManager.add(track);

    final source = SourceManager.instance.activeSource;
    final uri = await source.getStreamUrl(track);

    await _player.addAudioSource(AudioSource.uri(uri));

    if (wasEmpty) {
      _queueManager.currentIndex = 0;
      await _player.seek(Duration.zero, index: 0);
      await _player.play();
    }

    notifyListeners();
  }

  Future<void> removeTrackById(String trackId) async {
    final index = _queueManager.indexOfTrack(trackId);

    if (index == -1) return;

    _queueManager.removeAt(index);

    await _player.removeAudioSourceAt(index);

    if (_queueManager.currentIndex >= _queueManager.queue.length) {
      _queueManager.currentIndex = _queueManager.queue.length - 1;
    }

    notifyListeners();
  }

  void playFromCurrentQueue(Track track) {
    final index = _queueManager.indexOfTrack(track.id);

    if (index != -1) {
      playAt(index);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                 SHUFFLE                                    */
  /* -------------------------------------------------------------------------- */

  Future<void> toggleShuffle() async {
    shuffleEnabled = !shuffleEnabled;

    await _player.setShuffleModeEnabled(shuffleEnabled);

    if (shuffleEnabled) {
      await _player.shuffle();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShuffle, shuffleEnabled);

    notifyListeners();
  }

  /* -------------------------------------------------------------------------- */
  /*                                  REPEAT                                    */
  /* -------------------------------------------------------------------------- */

  Future<void> toggleRepeatMode() async {
    switch (repeatMode) {
      case RepeatMode.off:
        repeatMode = RepeatMode.all;
        await _player.setLoopMode(LoopMode.all);
        break;

      case RepeatMode.all:
        repeatMode = RepeatMode.one;
        await _player.setLoopMode(LoopMode.one);
        break;

      case RepeatMode.one:
        repeatMode = RepeatMode.off;
        await _player.setLoopMode(LoopMode.off);
        break;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefRepeat, repeatMode.index);

    notifyListeners();
  }

  /* -------------------------------------------------------------------------- */
  /*                               GAPLESS                                      */
  /* -------------------------------------------------------------------------- */

  Future<void> toggleGapless(bool value) async {
    gaplessEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefGapless, value);

    notifyListeners();
  }

  /* -------------------------------------------------------------------------- */
  /*                               RESTORE PREFS                                */
  /* -------------------------------------------------------------------------- */

  Future<void> _restorePrefs() async {
    final prefs = await SharedPreferences.getInstance();

    shuffleEnabled = prefs.getBool(_prefShuffle) ?? false;
    gaplessEnabled = prefs.getBool(_prefGapless) ?? true;

    final repeatIndex = prefs.getInt(_prefRepeat);

    if (repeatIndex != null &&
        repeatIndex >= 0 &&
        repeatIndex < RepeatMode.values.length) {
      repeatMode = RepeatMode.values[repeatIndex];
    }

    switch (repeatMode) {
      case RepeatMode.off:
        await _player.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
    }

    await _player.setShuffleModeEnabled(shuffleEnabled);

    if (shuffleEnabled) {
      await _player.shuffle();
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   CLEANUP                                  */
  /* -------------------------------------------------------------------------- */

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}