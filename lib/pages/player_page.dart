import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../models/playlist_song.dart';
import '../color/color_scheme.dart';
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final PlaylistService _playlistService = PlaylistService();

  void _showAddToPlaylistBottomSheet(BuildContext context) {
    if (_audioService.currentPath == null || _audioService.currentTrackTitle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No song playing')));
      return;
    }
    
    final currentSong = PlaylistSong(
      title: _audioService.currentTrackTitle!,
      path: _audioService.currentPath!,
      isUrl: _audioService.currentPath!.startsWith('http'),
    );

    final TextEditingController newPlaylistController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
          child: FutureBuilder(
            future: _playlistService.getPlaylists(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              final playlists = snapshot.data!;
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (playlists.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.playlist_play, color: Colors.white),
                            title: Text(playlists[index].name, style: const TextStyle(color: Colors.white)),
                            onTap: () async {
                              await _playlistService.addSongToPlaylist(playlists[index].name, currentSong);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to ${playlists[index].name}')));
                              }
                            },
                          );
                        },
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No playlists yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  const Divider(color: Colors.white24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newPlaylistController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'New playlist name',
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ColorTheme.neonLabelColor)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: ColorTheme.neonLabelColor),
                        onPressed: () async {
                          if (newPlaylistController.text.trim().isNotEmpty) {
                            final name = newPlaylistController.text.trim();
                            await _playlistService.createPlaylist(name);
                            await _playlistService.addSongToPlaylist(name, currentSong);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created $name and added song')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Now Playing",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _audioService,
        builder: (context, child) {
          final position = _audioService.currentPosition;
          final duration = _audioService.totalDuration;
          
          double sliderValue = position.inSeconds.toDouble();
          double sliderMax = duration.inSeconds.toDouble();
          if (sliderMax == 0) sliderMax = 1; // Prevent division by zero
          if (sliderValue > sliderMax) sliderValue = sliderMax;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Album Art
                Container(
                  width: MediaQuery.of(context).size.width - 48,
                  height: MediaQuery.of(context).size.width - 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: ColorTheme.neonLabelColor.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(Icons.music_note, size: 100, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                
                // Track Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _audioService.currentTrackTitle ?? "Not Playing",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (_audioService.currentPlaylistName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ColorTheme.neonLabelColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _audioService.currentPlaylistName!,
                                style: const TextStyle(color: ColorTheme.neonLabelColor, fontSize: 12),
                              ),
                            )
                          else
                            const Text(
                              "Local Audio",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                      onPressed: () => _showAddToPlaylistBottomSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress Bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0,
                    max: sliderMax,
                    value: sliderValue,
                    onChanged: (value) {
                      _audioService.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                
                // Timestamps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 20),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                      onPressed: () {},
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: ColorTheme.neonLabelColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 40,
                        ),
                        onPressed: () => _audioService.togglePlayPause(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.repeat, color: _audioService.isLooping ? ColorTheme.neonLabelColor : Colors.white),
                      onPressed: () => _audioService.toggleLoop(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
