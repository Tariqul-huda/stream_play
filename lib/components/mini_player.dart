import 'package:flutter/material.dart';
import '../color/color_scheme.dart';
import '../services/audio_player_service.dart';
import '../pages/player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService();

    return ListenableBuilder(
      listenable: audioService,
      builder: (context, child) {
        if (audioService.currentTrackTitle == null) {
          return const SizedBox.shrink(); // Don't show if nothing is playing
        }

        final position = audioService.currentPosition;
        final duration = audioService.totalDuration;
        
        double progress = 0.0;
        if (duration.inMilliseconds > 0) {
          progress = position.inMilliseconds / duration.inMilliseconds;
          if (progress > 1.0) progress = 1.0;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Mock cover art
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              audioService.currentTrackTitle ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Local Audio",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Playback controls
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () => audioService.togglePlayPause(),
                      ),
                    ],
                  ),
                ),
                // Progress bar
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(ColorTheme.neonLabelColor),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}

