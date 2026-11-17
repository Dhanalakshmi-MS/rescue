class SensorData {
  final String deviceId;
  final String roomId;
  final double temperature;
  final double humidity;
  final double smokePpm;
  final bool flameDetected;
  final double timestamp;

  SensorData({
    required this.deviceId,
    required this.roomId,
    required this.temperature,
    required this.humidity,
    required this.smokePpm,
    required this.flameDetected,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['device_id'] ?? 'ESP32_NODE_01',
      roomId: json['room_id'] ?? 'ROOM_1',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 24.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 50.0,
      smokePpm: (json['smoke_ppm'] as num?)?.toDouble() ?? 60.0,
      flameDetected: json['flame_detected'] ?? false,
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? DateTime.now().millisecondsSinceEpoch / 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'room_id': roomId,
      'temperature': temperature,
      'humidity': humidity,
      'smoke_ppm': smokePpm,
      'flame_detected': flameDetected,
      'timestamp': timestamp,
    };
  }
}
