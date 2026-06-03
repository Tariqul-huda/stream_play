import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

/// Service handling real Google Sign-In with YouTube Data API v3 integration.
/// Uses the `google_sign_in` package for native OAuth and fetches
/// liked videos via direct HTTP calls to the YouTube API.
class GoogleAuthService extends ChangeNotifier {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Triggers the native Google Sign-In flow.
  /// Returns true on success, false on failure/cancel.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in
        return false;
      }

      _currentUser = account;
      notifyListeners();

      // Sync to SettingsService
      final settings = SettingsService().settings;
      settings.isGoogleConnected = true;
      settings.googleEmail = account.email;
      settings.googleName = account.displayName ?? account.email;
      settings.googlePhotoUrl = account.photoUrl;
      await SettingsService().saveSettings(settings);

      return true;
    } catch (e) {
      debugPrint('[GoogleAuthService] signIn error: $e');
      return false;
    }
  }

  /// Signs out and disconnects the Google account.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] signOut error: $e');
    }

    _currentUser = null;
    notifyListeners();

    // Clear Google state in SettingsService
    final settings = SettingsService().settings;
    settings.isGoogleConnected = false;
    settings.googleEmail = null;
    settings.googleName = null;
    settings.googlePhotoUrl = null;
    await SettingsService().saveSettings(settings);
  }

  /// Attempts to silently sign in (restore previous session).
  /// Call this at app startup.
  Future<void> trySilentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
        notifyListeners();

        // Sync to SettingsService
        final settings = SettingsService().settings;
        settings.isGoogleConnected = true;
        settings.googleEmail = account.email;
        settings.googleName = account.displayName ?? account.email;
        settings.googlePhotoUrl = account.photoUrl;
        await SettingsService().saveSettings(settings);
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] trySilentSignIn error: $e');
    }
  }

  /// Gets a fresh OAuth access token for API calls.
  Future<String?> _getAccessToken() async {
    if (_currentUser == null) return null;
    try {
      final auth = await _currentUser!.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('[GoogleAuthService] _getAccessToken error: $e');
      return null;
    }
  }

  /// Fetches the user's liked videos from YouTube Data API v3.
  /// Returns a list of video maps with keys: videoId, title, artist, thumbnail, duration.
  Future<List<Map<String, dynamic>>> fetchLikedVideos({int maxResults = 30}) async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint('[GoogleAuthService] No access token available');
      return [];
    }

    try {
      final uri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos'
        '?myRating=like'
        '&part=snippet,contentDetails'
        '&maxResults=$maxResults',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map<Map<String, dynamic>>((item) {
          final snippet = item['snippet'] ?? {};
          final contentDetails = item['contentDetails'] ?? {};
          final thumbnails = snippet['thumbnails'] ?? {};
          final thumbUrl = (thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {})['url'] ?? '';

          return {
            'videoId': item['id'] ?? '',
            'title': snippet['title'] ?? 'Unknown',
            'artist': snippet['channelTitle'] ?? 'YouTube',
            'thumbnail': thumbUrl,
            'duration': _parseDuration(contentDetails['duration'] ?? 'PT0S'),
          };
        }).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[GoogleAuthService] YouTube API auth error: ${response.statusCode} ${response.body}');
        // Token might be expired, try re-auth
        return [];
      } else {
        debugPrint('[GoogleAuthService] YouTube API error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] fetchLikedVideos error: $e');
      return [];
    }
  }

  /// Fetches videos from a user's specific playlist (e.g. watch history, watch later).
  /// playlistId can be 'HL' for watch history (limited access), 'WL' for watch later, etc.
  Future<List<Map<String, dynamic>>> fetchPlaylistVideos(String playlistId, {int maxResults = 30}) async {
    final token = await _getAccessToken();
    if (token == null) return [];

    try {
      final uri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/playlistItems'
        '?playlistId=$playlistId'
        '&part=snippet,contentDetails'
        '&maxResults=$maxResults',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map<Map<String, dynamic>>((item) {
          final snippet = item['snippet'] ?? {};
          final thumbnails = snippet['thumbnails'] ?? {};
          final thumbUrl = (thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {})['url'] ?? '';

          return {
            'videoId': snippet['resourceId']?['videoId'] ?? '',
            'title': snippet['title'] ?? 'Unknown',
            'artist': snippet['videoOwnerChannelTitle'] ?? 'YouTube',
            'thumbnail': thumbUrl,
            'duration': 0, // Playlist items don't include duration directly
          };
        }).toList();
      } else {
        debugPrint('[GoogleAuthService] Playlist API error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] fetchPlaylistVideos error: $e');
      return [];
    }
  }

  /// Searches YouTube using the user's OAuth credentials.
  /// Returns a list of video maps with keys: videoId, title, artist, thumbnail, duration.
  Future<List<Map<String, dynamic>>> searchYouTube(String query, {int maxResults = 25}) async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint('[GoogleAuthService] No access token available for search');
      return [];
    }

    try {
      // 1. Search for videos
      final searchUri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet'
        '&q=${Uri.encodeComponent(query)}'
        '&type=video'
        '&maxResults=$maxResults',
      );

      final searchResponse = await http.get(
        searchUri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        debugPrint('[GoogleAuthService] Search API error: ${searchResponse.statusCode} ${searchResponse.body}');
        return [];
      }

      final searchData = jsonDecode(searchResponse.body);
      final List<dynamic> searchItems = searchData['items'] ?? [];
      if (searchItems.isEmpty) return [];

      final List<String> videoIds = [];
      for (final item in searchItems) {
        final videoId = item['id']?['videoId'];
        if (videoId != null) {
          videoIds.add(videoId);
        }
      }

      if (videoIds.isEmpty) return [];

      // 2. Fetch contentDetails (for duration) and snippet for the videos in batch
      final detailsUri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos'
        '?part=snippet,contentDetails'
        '&id=${videoIds.join(',')}',
      );

      final detailsResponse = await http.get(
        detailsUri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (detailsResponse.statusCode != 200) {
        debugPrint('[GoogleAuthService] Videos API error: ${detailsResponse.statusCode} ${detailsResponse.body}');
        // Return search results without duration
        return searchItems.map<Map<String, dynamic>>((item) {
          final snippet = item['snippet'] ?? {};
          final thumbnails = snippet['thumbnails'] ?? {};
          final thumbUrl = (thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {})['url'] ?? '';
          return {
            'videoId': item['id']?['videoId'] ?? '',
            'title': snippet['title'] ?? 'Unknown',
            'artist': snippet['channelTitle'] ?? 'YouTube',
            'thumbnail': thumbUrl,
            'duration': 0,
          };
        }).toList();
      }

      final detailsData = jsonDecode(detailsResponse.body);
      final List<dynamic> detailsItems = detailsData['items'] ?? [];

      return detailsItems.map<Map<String, dynamic>>((item) {
        final snippet = item['snippet'] ?? {};
        final contentDetails = item['contentDetails'] ?? {};
        final thumbnails = snippet['thumbnails'] ?? {};
        final thumbUrl = (thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {})['url'] ?? '';

        return {
          'videoId': item['id'] ?? '',
          'title': snippet['title'] ?? 'Unknown',
          'artist': snippet['channelTitle'] ?? 'YouTube',
          'thumbnail': thumbUrl,
          'duration': _parseDuration(contentDetails['duration'] ?? 'PT0S'),
        };
      }).toList();

    } catch (e) {
      debugPrint('[GoogleAuthService] searchYouTube error: $e');
      return [];
    }
  }

  /// Parses ISO 8601 duration (e.g. "PT4M33S") to seconds.
  int _parseDuration(String iso8601) {
    try {
      final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regex.firstMatch(iso8601);
      if (match == null) return 0;

      final hours = int.tryParse(match.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '') ?? 0;

      return hours * 3600 + minutes * 60 + seconds;
    } catch (_) {
      return 0;
    }
  }
}
