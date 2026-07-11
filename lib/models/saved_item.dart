/// A locally-persisted saved route or stop (Hive box entries stored as maps).
enum SavedKind { route, stop }

class SavedItem {
  final String id;
  final SavedKind kind;
  final String title;
  final String subtitle;
  final double? lat;
  final double? lon;
  final DateTime savedAt;

  const SavedItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.savedAt,
    this.lat,
    this.lon,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'lat': lat,
        'lon': lon,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedItem.fromMap(Map map) => SavedItem(
        id: map['id'].toString(),
        kind: SavedKind.values.firstWhere((k) => k.name == map['kind'],
            orElse: () => SavedKind.stop),
        title: map['title'].toString(),
        subtitle: map['subtitle'].toString(),
        lat: (map['lat'] as num?)?.toDouble(),
        lon: (map['lon'] as num?)?.toDouble(),
        savedAt: DateTime.tryParse(map['savedAt'].toString()) ?? DateTime.now(),
      );
}
