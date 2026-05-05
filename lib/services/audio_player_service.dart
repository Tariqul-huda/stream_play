import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

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

  bool _isLooping = false;
  bool get isLooping => _isLooping;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  Future<void> init() async {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _totalDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentPosition = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (!_isLooping) {
        _isPlaying = false;
        _currentPosition = Duration.zero;
        notifyListeners();
      }
    });
  }

  /// Plays a local audio file picked by the user.
  Future<void> playLocalFile(String path, String fileName, {String? playlistName}) async {
    _currentTrackTitle = fileName;
    _currentPath = path;
    _currentPlaylistName = playlistName;
    notifyListeners();
    
    await _audioPlayer.play(DeviceFileSource(path));
  }

  /// Plays from a URL (e.g. YouTube extracted stream in the future).
  Future<void> playUrl(String url, String title, {String? playlistName}) async {
    _currentTrackTitle = title;
    _currentPath = url;
    _currentPlaylistName = playlistName;
    notifyListeners();

    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
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
    await _audioPlayer.setReleaseMode(_isLooping ? ReleaseMode.loop : ReleaseMode.release);
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
