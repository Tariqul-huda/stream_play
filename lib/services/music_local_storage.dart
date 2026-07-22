import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class MusicTrackSnapshot {
  final String trackId;
  final String title;
  final String? artist;
  final String? coverUrl;
  final String? source;

  const MusicTrackSnapshot({
    required this.trackId,
    required this.title,
    this.artist,
    this.coverUrl,
    this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'trackId': trackId,
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'source': source,
    };
  }

  factory MusicTrackSnapshot.fromJson(Map<String, dynamic> json) {
    return MusicTrackSnapshot(
      trackId: json['trackId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Track',
      artist: json['artist']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      source: json['source']?.toString(),
    );
  }
}

class MusicLocalStorage {
  MusicLocalStorage._();

  static final MusicLocalStorage instance = MusicLocalStorage._();

  static const String _notesBoxName = 'music_notes_box';
  static const String _stateBoxName = 'music_state_box';
  static const String _notesPrefix = 'note:';
  static const String _positionPrefix = 'position:';
  static const String _favoriteIdsKey = 'favorite_ids';
  static const String _recentTracksKey = 'recent_tracks';

  Box<dynamic>? _notesBox;
  Box<dynamic>? _stateBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _notesBox = await Hive.openBox<dynamic>(_notesBoxName);
    _stateBox = await Hive.openBox<dynamic>(_stateBoxName);
    _initialized = true;
  }

  bool get isReady => _initialized && _notesBox != null && _stateBox != null;

  Box<dynamic> get _notes {
    final box = _notesBox;
    if (box == null) {
      throw StateError('MusicLocalStorage is not initialized');
    }
    return box;
  }

  Box<dynamic> get _state {
    final box = _stateBox;
    if (box == null) {
      throw StateError('MusicLocalStorage is not initialized');
    }
    return box;
  }

  String noteFor(String trackId) {
    final value = _notes.get('$_notesPrefix$trackId');
    return value is String ? value : '';
  }

  Future<void> saveNote(String trackId, String note) async {
    await _notes.put('$_notesPrefix$trackId', note);
  }

  Duration positionFor(String trackId) {
    final value = _state.get('$_positionPrefix$trackId');
    if (value is int && value > 0) {
      return Duration(milliseconds: value);
    }
    return Duration.zero;
  }

  Future<void> savePosition(String trackId, Duration position) async {
    await _state.put('$_positionPrefix$trackId', position.inMilliseconds);
  }

  Future<void> clearPosition(String trackId) async {
    await _state.delete('$_positionPrefix$trackId');
  }

  List<String> favoriteIds() {
    final value = _state.get(_favoriteIdsKey);
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return <String>[];
  }

  bool isFavorite(String trackId) => favoriteIds().contains(trackId);

  Future<void> toggleFavorite(MusicTrackSnapshot track) async {
    final ids = favoriteIds();
    if (ids.contains(track.trackId)) {
      ids.remove(track.trackId);
      await _state.delete('favorite:${track.trackId}');
    } else {
      ids.add(track.trackId);
      await _state.put('favorite:${track.trackId}', jsonEncode(track.toJson()));
    }
    await _state.put(_favoriteIdsKey, ids);
  }

  List<MusicTrackSnapshot> recentTracks() {
    final value = _state.get(_recentTracksKey);
    if (value is List) {
      return value
          .whereType<String>()
          .map(
            (item) => MusicTrackSnapshot.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            ),
          )
          .toList();
    }
    return <MusicTrackSnapshot>[];
  }

  Future<void> recordRecentTrack(MusicTrackSnapshot track) async {
    final list = recentTracks()
        .where((item) => item.trackId != track.trackId)
        .toList();
    list.insert(0, track);
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }
    await _state.put(
      _recentTracksKey,
      list.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> clearAll() async {
    await _notes.clear();
    await _state.clear();
  }
}
