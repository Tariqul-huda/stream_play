class PlaylistModel {
  final String id;
  final String name;
  final List<String> musicIds;
  final List<Map<String, dynamic>> tracks;
  final DateTime createdAtUtc;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.musicIds,
    this.tracks = const [],
    required this.createdAtUtc,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      musicIds: List<String>.from(json['musicIds'] ?? []),
      tracks: List<Map<String, dynamic>>.from(json['tracks'] ?? []),
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'musicIds': musicIds,
      'tracks': tracks,
      'createdAtUtc': createdAtUtc.toIso8601String(),
    };
  }
}
