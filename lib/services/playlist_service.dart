import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/playlist_model.dart';
import 'auth_storage.dart';

class PlaylistService {
  final AuthStorage _storage = AuthStorage();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) {
    final base = Env.apiBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<List<PlaylistModel>> getPlaylists() async {
    try {
      final res = await http.get(
        _uri('/api/playlists'),
        headers: await _authHeaders(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => PlaylistModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      debugPrint('[PlaylistService] getPlaylists failed: ${res.statusCode} ${res.body}');
    } catch (e, st) {
      debugPrint('[PlaylistService] getPlaylists error: $e\n$st');
    }
    return [];
  }

  Future<PlaylistModel?> createPlaylist(String name) async {
    try {
      final res = await http.post(
        _uri('/api/playlists'),
        headers: await _authHeaders(),
        body: jsonEncode({'name': name}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return PlaylistModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      debugPrint('[PlaylistService] createPlaylist failed: ${res.statusCode} ${res.body}');
    } catch (e, st) {
      debugPrint('[PlaylistService] createPlaylist error: $e\n$st');
    }
    return null;
  }

  Future<PlaylistModel?> addSongToPlaylist(String playlistId, String musicId) async {
    try {
      final res = await http.post(
        _uri('/api/playlists/$playlistId/add'),
        headers: await _authHeaders(),
        body: jsonEncode({'musicId': musicId}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return PlaylistModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      debugPrint('[PlaylistService] addSongToPlaylist failed: ${res.statusCode} ${res.body}');
    } catch (e, st) {
      debugPrint('[PlaylistService] addSongToPlaylist error: $e\n$st');
    }
    return null;
  }

  Future<PlaylistModel?> removeSongFromPlaylist(String playlistId, String musicId) async {
    try {
      final res = await http.post(
        _uri('/api/playlists/$playlistId/remove'),
        headers: await _authHeaders(),
        body: jsonEncode({'musicId': musicId}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return PlaylistModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      debugPrint('[PlaylistService] removeSongFromPlaylist failed: ${res.statusCode} ${res.body}');
    } catch (e, st) {
      debugPrint('[PlaylistService] removeSongFromPlaylist error: $e\n$st');
    }
    return null;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final res = await http.delete(
        _uri('/api/playlists/$playlistId'),
        headers: await _authHeaders(),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e, st) {
      debugPrint('[PlaylistService] deletePlaylist error: $e\n$st');
      return false;
    }
  }
}

