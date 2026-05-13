import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_service/audio_service.dart';

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

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_isLooping) {
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

    try {
      AudioSource source;

      if (kIsWeb) {
        // On web, path might be a data URI, blob URL, or just a filename.
        // If it's a data/blob URI, play it directly. Otherwise, we can't play.
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
        // Native platforms: use file URI
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

  /// Plays from a URL (e.g. YouTube extracted stream in the future).
  Future<void> playUrl(String url, String title, {String? playlistName}) async {
    _currentTrackTitle = title;
    _currentPath = url;
    _currentPlaylistName = playlistName;
    notifyListeners();

    try {
      final source = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          title: title,
          artist: playlistName ?? 'Stream',
        ),
      );
      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[AudioPlayerService] playUrl error: $e');
    }
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
    _audioPlayer.dispose();
    super.dispose();
  }
}
