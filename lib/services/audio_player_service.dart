import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'settings_service.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _currentTrackTitle;
  String? get currentTrackTitle => _currentTrackTitle;

  String? _currentPath;
  String? get currentPath => _currentPath;

  String? _currentPlaylistName;
  String? get currentPlaylistName => _currentPlaylistName;

  String? _currentCoverUrl;
  String? get currentCoverUrl => _currentCoverUrl;

  bool _isLooping = false;
  bool get isLooping => _isLooping;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  // Queue Support
  List<Map<String, dynamic>> _playlistQueue = [];
  int _queueIndex = -1;
  List<Map<String, dynamic>> get playlistQueue => _playlistQueue;
  int get queueIndex => _queueIndex;

  // Sleep Timer Support
  Timer? _sleepTimer;
  int _sleepTimerSecondsRemaining = 0;
  int get sleepTimerSecondsRemaining => _sleepTimerSecondsRemaining;

  /// Call once at app startup (before runApp).
  static Future<void> initBackground() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.streamplay.audio',
      androidNotificationChannelName: 'StreamPlay Audio',
      androidNotificationOngoing: true,
    );
  }

  Future<void> init() async {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (_isLooping) {
          // just_audio handles looping internally, but safety logic is good
        } else {
          final autoplayEnabled = SettingsService().settings.autoplayNext;
          if (autoplayEnabled && _playlistQueue.isNotEmpty && _queueIndex != -1 && _queueIndex < _playlistQueue.length - 1) {
            await playNext();
          } else {
            _isPlaying = false;
            _currentPosition = Duration.zero;
            notifyListeners();
          }
        }
      }
    });
  }

  /// Sets the active playback queue
  void setQueue(List<Map<String, dynamic>> queue, int startIndex) {
    _playlistQueue = queue;
    _queueIndex = startIndex;
    notifyListeners();
  }

  /// Plays next track in the queue
  Future<void> playNext() async {
    if (_playlistQueue.isEmpty || _queueIndex == -1) return;
    int nextIndex = _queueIndex + 1;
    if (nextIndex < _playlistQueue.length) {
      _queueIndex = nextIndex;
      final track = _playlistQueue[_queueIndex];
      notifyListeners();
      await _playTrack(track);
    }
  }

  /// Plays previous track in the queue
  Future<void> playPrevious() async {
    if (_playlistQueue.isEmpty || _queueIndex == -1) return;
    int prevIndex = _queueIndex - 1;
    if (prevIndex >= 0) {
      _queueIndex = prevIndex;
      final track = _playlistQueue[_queueIndex];
      notifyListeners();
      await _playTrack(track);
    }
  }

  Future<void> _playTrack(Map<String, dynamic> track) async {
    final String title = track['title'] ?? 'Unknown Track';
    final String filePath = track['filePath'] ?? track['url'] ?? '';
    final String? coverUrl = track['coverImage'] ?? track['thumbnail'];
    
    if (filePath.startsWith('http')) {
      await playUrl(filePath, title, playlistName: _currentPlaylistName, coverUrl: coverUrl);
    } else {
      await playLocalFile(filePath, title, playlistName: _currentPlaylistName);
    }
  }

  /// Plays a local audio file picked by the user.
  Future<void> playLocalFile(String path, String fileName, {String? playlistName}) async {
    _currentTrackTitle = fileName;
    _currentPath = path;
    _currentPlaylistName = playlistName;
    _currentCoverUrl = null;
    notifyListeners();

    try {
      AudioSource source;

      if (kIsWeb) {
        if (path.startsWith('data:') || path.startsWith('blob:') || path.startsWith('http')) {
          source = AudioSource.uri(
            Uri.parse(path),
            tag: MediaItem(
              id: path,
              title: fileName,
              artist: playlistName ?? 'Local',
            ),
          );
        } else {
          debugPrint('[AudioPlayerService] Cannot play local file on web: $path');
          return;
        }
      } else {
        source = AudioSource.uri(
          Uri.file(path),
          tag: MediaItem(
            id: path,
            title: fileName,
            artist: playlistName ?? 'Local',
          ),
        );
      }

      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[AudioPlayerService] playLocalFile error: $e');
    }
  }

  /// Plays from a URL (e.g. YouTube stream or remote link).
  /// Returns true if successfully loaded and started playing, false otherwise.
  Future<bool> playUrl(String url, String title, {String? playlistName, String? coverUrl}) async {
    _currentTrackTitle = title;
    _currentPath = url;
    _currentPlaylistName = playlistName;
    _currentCoverUrl = coverUrl;
    notifyListeners();

    try {
      final source = AudioSource.uri(
        Uri.parse(url),
        headers: url.contains('googlevideo.com') ? {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        } : null,
        tag: MediaItem(
          id: url,
          title: title,
          artist: playlistName ?? 'Stream',
          artUri: coverUrl != null ? Uri.parse(coverUrl) : null,
        ),
      );
      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
      return true;
    } catch (e) {
      debugPrint('[AudioPlayerService] playUrl error: $e');
      return false;
    }
  }

  /// Start a functional Sleep Timer
  void startSleepTimer(int minutes) {
    cancelSleepTimer();
    if (minutes <= 0) return;
    
    _sleepTimerSecondsRemaining = minutes * 60;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerSecondsRemaining > 0) {
        _sleepTimerSecondsRemaining--;
        notifyListeners();
      } else {
        pause();
        cancelSleepTimer();
      }
    });
  }

  /// Cancel current Sleep Timer
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerSecondsRemaining = 0;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> toggleLoop() async {
    _isLooping = !_isLooping;
    await _audioPlayer.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
