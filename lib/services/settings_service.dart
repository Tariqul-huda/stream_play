import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../color/color_scheme.dart';
import 'auth_storage.dart';

class UserSettingsModel {
  String? preferredMusicFolderPath;
  String? theme;
  String? googleEmail;
  String? googleName;
  String? googlePhotoUrl;
  bool isGoogleConnected;
  String audioQuality;
  bool autoplayNext;
  List<String> youtubeHistory;

  UserSettingsModel({
    this.preferredMusicFolderPath,
    this.theme,
    this.googleEmail,
    this.googleName,
    this.googlePhotoUrl,
    this.isGoogleConnected = false,
    this.audioQuality = 'High',
    this.autoplayNext = true,
    List<String>? youtubeHistory,
  }) : youtubeHistory = youtubeHistory ?? [];

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      preferredMusicFolderPath: json['preferredMusicFolderPath'],
      theme: json['theme'],
      googleEmail: json['googleEmail'],
      googleName: json['googleName'],
      googlePhotoUrl: json['googlePhotoUrl'],
      isGoogleConnected: json['isGoogleConnected'] ?? false,
      audioQuality: json['audioQuality'] ?? 'High',
      autoplayNext: json['autoplayNext'] ?? true,
      youtubeHistory: List<String>.from(json['youtubeHistory'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredMusicFolderPath': preferredMusicFolderPath,
      'theme': theme,
      'googleEmail': googleEmail,
      'googleName': googleName,
      'googlePhotoUrl': googlePhotoUrl,
      'isGoogleConnected': isGoogleConnected,
      'audioQuality': audioQuality,
      'autoplayNext': autoplayNext,
      'youtubeHistory': youtubeHistory,
    };
  }
}

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final AuthStorage _authStorage = AuthStorage();
  UserSettingsModel _settings = UserSettingsModel();
  bool _isLoading = false;

  UserSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authStorage.getAccessToken();
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

  /// Load settings from backend, falling back to local SharedPreferences
  Future<UserSettingsModel> loadSettings() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      final res = await http.get(
        _uri('/api/settings'),
        headers: await _authHeaders(),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _settings = UserSettingsModel.fromJson(data);
        
        // Update local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('settings_cache', jsonEncode(_settings.toJson()));

        // Apply active theme preset
        if (_settings.theme != null) {
          ColorTheme.setPreset(_settings.theme!);
        }
      } else {
        await _loadFromLocalCache();
      }
    } catch (e) {
      debugPrint('[SettingsService] loadSettings API error: $e');
      await _loadFromLocalCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _settings;
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('settings_cache');
      if (cacheStr != null) {
        final data = jsonDecode(cacheStr) as Map<String, dynamic>;
        _settings = UserSettingsModel.fromJson(data);

        // Apply active theme preset
        if (_settings.theme != null) {
          ColorTheme.setPreset(_settings.theme!);
        }
      }
    } catch (e) {
      debugPrint('[SettingsService] Local cache load error: $e');
    }
  }

  /// Save settings to backend and local cache
  Future<bool> saveSettings(UserSettingsModel newSettings) async {
    _isLoading = true;
    _settings = newSettings;
    Future.microtask(() => notifyListeners());

    // Apply active theme preset immediately for instant feedback
    if (_settings.theme != null) {
      ColorTheme.setPreset(_settings.theme!);
    }

    bool success = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings_cache', jsonEncode(_settings.toJson()));

      final res = await http.post(
        _uri('/api/settings'),
        headers: await _authHeaders(),
        body: jsonEncode(_settings.toJson()),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _settings = UserSettingsModel.fromJson(data);
        success = true;
      } else {
        debugPrint('[SettingsService] saveSettings API failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[SettingsService] saveSettings API error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  /// Appends a YouTube video to the user's history and saves it
  Future<void> addToYoutubeHistory(String videoId, String title, String artist, String thumbnail, int duration) async {
    // Format: "videoId|title|artist|thumbnail|duration"
    final record = '$videoId|$title|$artist|$thumbnail|$duration';
    
    // Remove if already exists (to move it to top)
    _settings.youtubeHistory.removeWhere((item) => item.startsWith('$videoId|'));
    _settings.youtubeHistory.insert(0, record);

    // Limit to last 50 items
    if (_settings.youtubeHistory.length > 50) {
      _settings.youtubeHistory = _settings.youtubeHistory.sublist(0, 50);
    }

    notifyListeners();
    await saveSettings(_settings);
  }

  /// Clears YouTube history
  Future<void> clearYoutubeHistory() async {
    _settings.youtubeHistory.clear();
    notifyListeners();
    await saveSettings(_settings);
  }
}
