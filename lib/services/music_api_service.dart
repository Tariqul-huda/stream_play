import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import 'auth_storage.dart';

class MusicApiService {
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

  /// Looks up a music track by its file path.
  Future<Map<String, dynamic>?> findByPath(String path) async {
    final uri = _uri('/api/music/by-path').replace(queryParameters: {'path': path});
    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Adds a label to a music track and auto-creates a playlist for that label.
  /// Returns the updated track data on success, or null on failure.
  Future<Map<String, dynamic>?> addLabel(String musicId, String label) async {
    final res = await http.put(
      _uri('/api/music/$musicId/label'),
      headers: await _authHeaders(),
      body: jsonEncode({'label': label}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Bulk-creates music tracks and auto-adds them to a "Local" playlist.
  /// Each item needs at least title, artist, and filePath.
  Future<List<Map<String, dynamic>>> bulkCreate(List<Map<String, dynamic>> tracks) async {
    try {
      final res = await http.post(
        _uri('/api/music/bulk'),
        headers: await _authHeaders(),
        body: jsonEncode(tracks),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('[MusicApiService] bulkCreate failed: ${res.statusCode} ${res.body}');
    } catch (e, st) {
      debugPrint('[MusicApiService] bulkCreate error: $e\n$st');
    }
    return [];
  }
}

