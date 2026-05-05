import 'playlist_song.dart';

class PlaylistModel {
  final String name;
  final List<PlaylistSong> songs;

  PlaylistModel({
    required this.name,
    required this.songs,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'songs': songs.map((x) => x.toMap()).toList(),
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      name: map['name'] ?? '',
      songs: List<PlaylistSong>.from(
        (map['songs'] as List<dynamic>? ?? []).map(
          (x) => PlaylistSong.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
