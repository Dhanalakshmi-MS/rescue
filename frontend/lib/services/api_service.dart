import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/building_status.dart';
import '../models/room_status.dart';
import '../models/alert_model.dart';
import '../models/evacuation_route.dart';
import '../models/sensor_data.dart';

class ApiService {
  // 10.0.2.2 points to host machine on Android emulator.
  // For physical devices, change to host machine's Wi-Fi IP (e.g., http://192.168.1.100:8000/api/v1)
  static String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static void setBaseUrl(String newUrl) {
    baseUrl = newUrl.replaceAll(RegExp(r'/+$'), '');
  }

  // Fetch overall building status
  static Future<BuildingStatus?> getBuildingStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/building/status'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return BuildingStatus.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      // Backend offline or unreachable
    }
    return null;
  }

  // Fetch all room statuses
  static Future<List<RoomStatus>> getRooms() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/building/rooms'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => RoomStatus.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Calculate dynamic Dijkstra evacuation route
  static Future<EvacuationRoute?> getEvacuationRoute({
    String origin = 'ROOM_1',
    String? targetExit,
  }) async {
    try {
      String url = '$baseUrl/evacuation/route?origin=$origin';
      if (targetExit != null) {
        url += '&target_exit=$targetExit';
      }
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return EvacuationRoute.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  // Fetch active alerts
  static Future<List<AlertModel>> getActiveAlerts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/alerts/active'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => AlertModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Fetch alert history
  static Future<List<AlertModel>> getAlertHistory() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/alerts/history'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => AlertModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Trigger preset scenario (0-4)
  static Future<bool> triggerScenario(int scenarioId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/simulation/scenario'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'scenario_id': scenarioId}),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Reset all alerts
  static Future<bool> resetAlerts() async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/alerts/reset'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Send raw telemetry
  static Future<bool> sendTelemetry(SensorData telemetry) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sensors/telemetry'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(telemetry.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
