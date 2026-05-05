import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../models/playlist_song.dart';

class PlaylistService {
  static const String _storageKey = 'user_playlists';

  Future<List<PlaylistModel>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsJson = prefs.getString(_storageKey);
    
    if (playlistsJson == null) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(playlistsJson);
      return decodedList.map((item) => PlaylistModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePlaylists(List<PlaylistModel> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(playlists.map((p) => p.toMap()).toList());
    await prefs.setString(_storageKey, encodedList);
  }

  Future<void> createPlaylist(String name) async {
    final playlists = await getPlaylists();
    if (!playlists.any((p) => p.name == name)) {
      playlists.add(PlaylistModel(name: name, songs: []));
      await _savePlaylists(playlists);
    }
  }

  Future<void> addSongToPlaylist(String playlistName, PlaylistSong song) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.name == playlistName);
    
    if (index != -1) {
      // Prevent duplicates based on path
      if (!playlists[index].songs.any((s) => s.path == song.path)) {
        playlists[index].songs.add(song);
        await _savePlaylists(playlists);
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistName, String songPath) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.name == playlistName);
    
    if (index != -1) {
      playlists[index].songs.removeWhere((s) => s.path == songPath);
      await _savePlaylists(playlists);
    }
  }
}
