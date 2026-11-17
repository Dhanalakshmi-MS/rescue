class AlertModel {
  final String alertId;
  final String roomId;
  final String hazardLevel; // WARNING, CRITICAL
  final String hazardType;
  final String message;
  final double timestamp;
  final bool resolved;
  final String recommendedAction;
  final Map<String, dynamic>? sensorSnapshot;

  AlertModel({
    required this.alertId,
    required this.roomId,
    required this.hazardLevel,
    required this.hazardType,
    required this.message,
    required this.timestamp,
    required this.resolved,
    required this.recommendedAction,
    this.sensorSnapshot,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alert_id'] ?? '',
      roomId: json['room_id'] ?? '',
      hazardLevel: json['hazard_level'] ?? 'WARNING',
      hazardType: json['hazard_type'] ?? 'UNKNOWN',
      message: json['message'] ?? 'Alert triggered',
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      resolved: json['resolved'] ?? false,
      recommendedAction: json['recommended_action'] ?? 'Evacuate area.',
      sensorSnapshot: json['sensor_snapshot'],
    );
  }
}
