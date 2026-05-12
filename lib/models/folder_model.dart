class FolderModel {
  final String id;
  final String name;
  final List<String> playlistIds;
  final DateTime createdAtUtc;

  FolderModel({
    required this.id,
    required this.name,
    required this.playlistIds,
    required this.createdAtUtc,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      playlistIds: List<String>.from(json['playlistIds'] ?? []),
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'playlistIds': playlistIds,
      'createdAtUtc': createdAtUtc.toIso8601String(),
    };
  }
}
