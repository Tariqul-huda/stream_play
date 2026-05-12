import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/folder_model.dart';
import 'auth_storage.dart';

class FolderService {
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

  Future<List<FolderModel>> getFolders() async {
    final res = await http.get(
      _uri('/api/folders'),
      headers: await _authHeaders(),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((item) => FolderModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<FolderModel?> createFolder(String name) async {
    final res = await http.post(
      _uri('/api/folders'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return FolderModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<FolderModel?> addPlaylistToFolder(String folderId, String playlistId) async {
    final res = await http.post(
      _uri('/api/folders/$folderId/add-playlist'),
      headers: await _authHeaders(),
      body: jsonEncode({'playlistId': playlistId}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return FolderModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> deleteFolder(String folderId) async {
    final res = await http.delete(
      _uri('/api/folders/$folderId'),
      headers: await _authHeaders(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
