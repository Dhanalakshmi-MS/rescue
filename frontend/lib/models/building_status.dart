import 'room_status.dart';

class BuildingStatus {
  final String overallStatus; // NORMAL, WARNING, CRITICAL
  final int totalRooms;
  final int safeRooms;
  final int warningRooms;
  final int criticalRooms;
  final int activeAlertsCount;
  final bool esp32Connected;
  final double lastHeartbeat;
  final Map<String, RoomStatus> rooms;

  BuildingStatus({
    required this.overallStatus,
    required this.totalRooms,
    required this.safeRooms,
    required this.warningRooms,
    required this.criticalRooms,
    required this.activeAlertsCount,
    required this.esp32Connected,
    required this.lastHeartbeat,
    required this.rooms,
  });

  factory BuildingStatus.fromJson(Map<String, dynamic> json) {
    Map<String, RoomStatus> parsedRooms = {};
    if (json['rooms'] != null && json['rooms'] is Map) {
      json['rooms'].forEach((key, val) {
        if (val is Map<String, dynamic>) {
          parsedRooms[key] = RoomStatus.fromJson(val);
        }
      });
    }

    return BuildingStatus(
      overallStatus: json['overall_status'] ?? 'NORMAL',
      totalRooms: json['total_rooms'] ?? 0,
      safeRooms: json['safe_rooms'] ?? 0,
      warningRooms: json['warning_rooms'] ?? 0,
      criticalRooms: json['critical_rooms'] ?? 0,
      activeAlertsCount: json['active_alerts_count'] ?? 0,
      esp32Connected: json['esp32_connected'] ?? false,
      lastHeartbeat: (json['last_heartbeat'] as num?)?.toDouble() ?? 0.0,
      rooms: parsedRooms,
    );
  }

  bool get isCritical => overallStatus == 'CRITICAL';
  bool get isWarning => overallStatus == 'WARNING';
  bool get isNormal => overallStatus == 'NORMAL';
}
