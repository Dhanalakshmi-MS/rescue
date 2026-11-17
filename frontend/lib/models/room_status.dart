class RoomStatus {
  final String roomId;
  final String roomName;
  final String hazardLevel; // NORMAL, WARNING, CRITICAL
  final List<String> hazardTypes;
  final double temperature;
  final double humidity;
  final double smokePpm;
  final bool flameDetected;
  final bool isPassable;
  final double lastUpdated;

  RoomStatus({
    required this.roomId,
    required this.roomName,
    required this.hazardLevel,
    required this.hazardTypes,
    required this.temperature,
    required this.humidity,
    required this.smokePpm,
    required this.flameDetected,
    required this.isPassable,
    required this.lastUpdated,
  });

  factory RoomStatus.fromJson(Map<String, dynamic> json) {
    return RoomStatus(
      roomId: json['room_id'] ?? '',
      roomName: json['room_name'] ?? json['room_id'] ?? 'Zone',
      hazardLevel: json['hazard_level'] ?? 'NORMAL',
      hazardTypes: (json['hazard_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['NONE'],
      temperature: (json['temperature'] as num?)?.toDouble() ?? 24.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 50.0,
      smokePpm: (json['smoke_ppm'] as num?)?.toDouble() ?? 60.0,
      flameDetected: json['flame_detected'] ?? false,
      isPassable: json['is_passable'] ?? true,
      lastUpdated: (json['last_updated'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
