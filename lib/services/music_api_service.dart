import 'dart:convert';
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
}
