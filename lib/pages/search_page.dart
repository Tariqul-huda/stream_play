import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../color/color_scheme.dart';
import '../services/audio_player_service.dart';
import '../services/google_auth_service.dart';
import '../services/settings_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final AudioPlayerService _audioService = AudioPlayerService();
  final SettingsService _settingsService = SettingsService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _likedVideos = [];
  bool _isSearching = false;
  bool _isLoadingLiked = false;
  String? _errorMessage;

  // List of public Piped API instances for robust fallback
  final List<String> _pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.tokhmi.xyz',
    'https://api.piped.yt',
    'https://piped-api.garudalinux.org'
  ];

  @override
  void initState() {
    super.initState();
    _settingsService.loadSettings();
    _googleAuthService.addListener(_onGoogleAuthStateChanged);
    _loadLikedVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _googleAuthService.removeListener(_onGoogleAuthStateChanged);
    super.dispose();
  }

  void _onGoogleAuthStateChanged() {
    if (mounted) {
      _loadLikedVideos();
    }
  }

  /// Fetches liked videos from YouTube Data API if signed in.
  Future<void> _loadLikedVideos() async {
    if (!_googleAuthService.isSignedIn) {
      if (mounted) {
        setState(() {
          _likedVideos = [];
          _isLoadingLiked = false;
        });
      }
      return;
    }

    setState(() => _isLoadingLiked = true);
    try {
      final videos = await _googleAuthService.fetchLikedVideos(maxResults: 30);
      if (mounted) {
        setState(() {
          _likedVideos = videos;
          _isLoadingLiked = false;
        });
      }
    } catch (e) {
      debugPrint('[SearchPage] Error loading liked videos: $e');
      if (mounted) setState(() => _isLoadingLiked = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
    });

    bool success = false;

    // 1. Try YouTube Data API Search if signed in
    if (_googleAuthService.isSignedIn) {
      try {
        final results = await _googleAuthService.searchYouTube(query, maxResults: 25);
        if (results.isNotEmpty) {
          if (mounted) {
            setState(() {
              _searchResults = results;
              _isSearching = false;
            });
          }
          success = true;
        }
      } catch (e) {
        debugPrint('[SearchPage] YouTube Data API Search error: $e');
      }
    }

    // 2. Fall back to public Piped instances if YouTube search failed or not signed in
    if (!success) {
      for (final instance in _pipedInstances) {
        try {
          final uri = Uri.parse('$instance/search').replace(queryParameters: {
            'q': query,
            'filter': 'music_videos',
          });
          
          final res = await http.get(uri).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['items'] != null) {
              final List<dynamic> items = data['items'];
              if (mounted) {
                setState(() {
                  _searchResults = items.where((item) => item['type'] == 'stream').map((item) {
                    return {
                      'videoId': (item['url'] as String).replaceFirst('/watch?v=', ''),
                      'title': item['title'] ?? 'Unknown Track',
                      'artist': item['uploaderName'] ?? 'YouTube Artist',
                      'thumbnail': item['thumbnail'] ?? '',
                      'duration': item['duration'] ?? 0,
                    };
                  }).toList();
                  _isSearching = false;
                });
              }
              success = true;
              break;
            }
          }
        } catch (e) {
          debugPrint('[SearchPage] Error searching instance $instance: $e');
        }
      }
    }

    if (!success) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Could not fetch search results. Please try again.';
        });
      }
    }
  }

  Future<void> _playYoutubeVideo(Map<String, dynamic> track) async {
    final String videoId = track['videoId'];
    final String title = track['title'];
    final String artist = track['artist'];
    final String thumbnail = track['thumbnail'];
    final int duration = track['duration'];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Loading audio stream for "$title"...', overflow: TextOverflow.ellipsis)),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );

    bool streamFound = false;

    // 1. Try extracting the stream on-device using youtube_explode_dart
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 7));
      final mp4Streams = manifest.audioOnly.where((s) => s.container.name == 'mp4');
      final audioStream = mp4Streams.isNotEmpty
          ? mp4Streams.withHighestBitrate()
          : manifest.audioOnly.withHighestBitrate();
      final audioUrl = audioStream.url.toString();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      final success = await _audioService.playUrl(
        audioUrl,
        title,
        playlistName: 'YouTube Music',
        coverUrl: thumbnail,
      );

      if (success) {
        await _settingsService.addToYoutubeHistory(videoId, title, artist, thumbnail, duration);
        streamFound = true;
      }
    } catch (e) {
      debugPrint('[SearchPage] youtube_explode extraction failed: $e');
    } finally {
      yt.close();
    }

    // 2. Fall back to Piped instances only if youtube_explode failed
    if (!streamFound) {
      for (final instance in _pipedInstances) {
        try {
          final uri = Uri.parse('$instance/streams/$videoId');
          final res = await http.get(uri).timeout(const Duration(seconds: 5));
          
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['audioStreams'] != null) {
              final List<dynamic> streams = data['audioStreams'];
              if (streams.isNotEmpty) {
                final audioUrl = streams.first['url'] as String;
                
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                }
                
                final success = await _audioService.playUrl(
                  audioUrl, 
                  title, 
                  playlistName: 'YouTube Music', 
                  coverUrl: thumbnail
                );

                if (success) {
                  await _settingsService.addToYoutubeHistory(videoId, title, artist, thumbnail, duration);
                  streamFound = true;
                  break;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[SearchPage] Error fetching stream from $instance: $e');
        }
      }
    }

    if (!streamFound) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error playing this track. Try another one.')),
        );
      }
    }
  }

  String _formatDurationSeconds(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, child) {
        final isGoogleConnected = _settingsService.settings.isGoogleConnected;
        final historyRaw = _settingsService.settings.youtubeHistory;

        // Parse history strings back to objects
        final List<Map<String, dynamic>> historyTracks = [];
        for (final record in historyRaw) {
          final parts = record.split('|');
          if (parts.length >= 5) {
            historyTracks.add({
              'videoId': parts[0],
              'title': parts[1],
              'artist': parts[2],
              'thumbnail': parts[3],
              'duration': int.tryParse(parts[4]) ?? 0,
            });
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Premium Search Bar Header
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _searchFocusNode.hasFocus
                                ? ColorTheme.neonLabelColor.withValues(alpha: 0.5)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search YouTube Music...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onSubmitted: _performSearch,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Results / History / Status
              Expanded(
                child: _isSearching
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: ColorTheme.neonLabelColor),
                            const SizedBox(height: 16),
                            Text(
                              'Scanning YouTube...',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _searchResults.isEmpty
                            ? _buildDefaultView(isGoogleConnected, historyTracks)
                            : _buildSearchResultsList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50, height: 50,
                child: track['thumbnail'].isNotEmpty
                    ? Image.network(
                        track['thumbnail'],
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.grey.shade900,
                          child: const Icon(Icons.music_note, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      ),
              ),
            ),
            title: Text(
              track['title'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${track['artist']} • ${_formatDurationSeconds(track['duration'])}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: ColorTheme.neonLabelColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.play_arrow, color: ColorTheme.neonLabelColor),
                onPressed: () => _playYoutubeVideo(track),
              ),
            ),
            onTap: () => _playYoutubeVideo(track),
          ),
        );
      },
    );
  }

  Widget _buildDefaultView(bool isGoogleConnected, List<Map<String, dynamic>> history) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner for Google Connection Promo
          if (!isGoogleConnected)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade900.withValues(alpha: 0.4),
                    const Color(0xFF1E1E2C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade900.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Unlock YouTube History',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connect your Google Account in Settings to sync your YouTube liked videos and playback history!',
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

          // YouTube Liked Videos (from Google API)
          if (isGoogleConnected) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_outlined, color: ColorTheme.neonLabelColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Liked Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoadingLiked)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                      onPressed: _loadLikedVideos,
                      tooltip: 'Refresh liked videos',
                    ),
                ],
              ),
            ),
            if (_isLoadingLiked)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ColorTheme.neonLabelColor),
                  ),
                ),
              )
            else if (_likedVideos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Center(
                  child: Text(
                    'No liked videos found.\nLike some videos on YouTube to see them here!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SizedBox(
                height: 190,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _likedVideos.length,
                  itemBuilder: (context, index) {
                    final track = _likedVideos[index];
                    return _buildVideoCard(track);
                  },
                ),
              ),
          ],

          // Local Playback History
          if (isGoogleConnected) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.history, color: ColorTheme.neonLabelColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Recently Played',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () => _settingsService.clearYoutubeHistory(),
                      child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
            ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Center(
                  child: Text(
                    'No playback history yet.\nSearch and play music to build your history!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SizedBox(
                height: 190,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final track = history[index];
                    return _buildVideoCard(track);
                  },
                ),
              ),
          ],

          // Quick Recommendations Section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 24.0, bottom: 12.0),
            child: Row(
              children: [
                Icon(Icons.star_outline, color: ColorTheme.neonLabelColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Trending Music Searches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildTrendingCard('Lo-fi Chill Beats', Icons.spa_outlined),
          _buildTrendingCard('Acoustic Hits 2026', Icons.music_note_outlined),
          _buildTrendingCard('Synthwave Night Drive', Icons.nightlife_outlined),
          _buildTrendingCard('Epic Gaming Orchestral', Icons.videogame_asset_outlined),
          const SizedBox(height: 120), // MiniPlayer spacing
        ],
      ),
    );
  }

  /// Reusable video card widget for both liked videos and history.
  Widget _buildVideoCard(Map<String, dynamic> track) {
    return GestureDetector(
      onTap: () => _playYoutubeVideo(track),
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 120, height: 120,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: (track['thumbnail'] ?? '').toString().isNotEmpty
                        ? Image.network(
                            track['thumbnail'],
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.music_note, color: Colors.grey, size: 40),
                          )
                        : const Icon(Icons.music_note, color: Colors.grey, size: 40),
                  ),
                ),
                Positioned(
                  bottom: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDurationSeconds(track['duration'] ?? 0),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: ColorTheme.neonLabelColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.black, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              track['title'] ?? 'Unknown',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              track['artist'] ?? 'YouTube',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCard(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        leading: Icon(icon, color: ColorTheme.neonLabelColor),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 14),
        onTap: () {
          _searchController.text = title;
          _performSearch(title);
        },
      ),
    );
  }
}
