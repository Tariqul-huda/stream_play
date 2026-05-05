class PlaylistSong {
  final String title;
  final String path;
  final bool isUrl;

  PlaylistSong({
    required this.title,
    required this.path,
    this.isUrl = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'path': path,
      'isUrl': isUrl,
    };
  }

  factory PlaylistSong.fromMap(Map<String, dynamic> map) {
    return PlaylistSong(
      title: map['title'] ?? '',
      path: map['path'] ?? '',
      isUrl: map['isUrl'] ?? false,
    );
  }
}
