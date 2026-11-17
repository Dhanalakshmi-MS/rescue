import 'dart:async';
import 'package:flutter/material.dart';
import '../models/building_status.dart';
import '../models/room_status.dart';
import '../models/alert_model.dart';
import '../models/evacuation_route.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  BuildingStatus? _buildingStatus;
  BuildingStatus? get buildingStatus => _buildingStatus;

  List<RoomStatus> _rooms = [];
  List<RoomStatus> get rooms => _rooms;

  EvacuationRoute? _currentRoute;
  EvacuationRoute? get currentRoute => _currentRoute;

  List<AlertModel> _activeAlerts = [];
  List<AlertModel> get activeAlerts => _activeAlerts;

  List<AlertModel> _alertHistory = [];
  List<AlertModel> get alertHistory => _alertHistory;

  String _selectedOriginRoom = 'ROOM_1';
  String get selectedOriginRoom => _selectedOriginRoom;

  bool _isBackendConnected = false;
  bool get isBackendConnected => _isBackendConnected;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Real-time chart telemetry buffers (15 latest data points)
  final List<double> _tempPoints = [23.5, 23.6, 23.8, 23.5, 24.0, 23.9, 24.1];
  final List<double> _smokePoints = [55.0, 58.0, 56.0, 60.0, 59.0, 62.0, 60.0];
  final List<double> _humidityPoints = [49.0, 50.0, 48.0, 49.5, 51.0, 50.0, 49.0];

  List<double> get tempPoints => List.unmodifiable(_tempPoints);
  List<double> get smokePoints => List.unmodifiable(_smokePoints);
  List<double> get humidityPoints => List.unmodifiable(_humidityPoints);

  Timer? _refreshTimer;

  AppState() {
    _initApp();
  }

  Future<void> _initApp() async {
    _currentUser = await AuthService.loadUserSession();
    startPolling();
  }

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void startPolling() {
    _refreshTimer?.cancel();
    fetchData(); // Immediate initial fetch
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchData();
    });
  }

  void stopPolling() {
    _refreshTimer?.cancel();
  }

  void selectOriginRoom(String roomId) {
    if (_selectedOriginRoom != roomId) {
      _selectedOriginRoom = roomId;
      fetchEvacuationRoute();
      notifyListeners();
    }
  }

  Future<void> fetchData() async {
    try {
      final status = await ApiService.getBuildingStatus();
      if (status != null) {
        _isBackendConnected = true;
        _buildingStatus = status;

        final roomList = await ApiService.getRooms();
        if (roomList.isNotEmpty) {
          _rooms = roomList;
        }

        // Buffer chart telemetry from the currently selected room or Room 1
        final targetRoom = _rooms.firstWhere(
          (r) => r.roomId == _selectedOriginRoom,
          orElse: () => _rooms.isNotEmpty
              ? _rooms.first
              : RoomStatus(
                  roomId: 'ROOM_1',
                  roomName: 'Room 1',
                  hazardLevel: 'NORMAL',
                  hazardTypes: ['NONE'],
                  temperature: 24.0,
                  humidity: 50.0,
                  smokePpm: 60.0,
                  flameDetected: false,
                  isPassable: true,
                  lastUpdated: 0.0,
                ),
        );

        _appendChartData(targetRoom.temperature, targetRoom.smokePpm, targetRoom.humidity);

        // Fetch active alerts
        _activeAlerts = await ApiService.getActiveAlerts();

        // Fetch active evacuation route
        await fetchEvacuationRoute();
      } else {
        _isBackendConnected = false;
      }
    } catch (_) {
      _isBackendConnected = false;
    }
    notifyListeners();
  }

  void _appendChartData(double temp, double smoke, double humidity) {
    _tempPoints.add(temp);
    if (_tempPoints.length > 20) _tempPoints.removeAt(0);

    _smokePoints.add(smoke);
    if (_smokePoints.length > 20) _smokePoints.removeAt(0);

    _humidityPoints.add(humidity);
    if (_humidityPoints.length > 20) _humidityPoints.removeAt(0);
  }

  Future<void> fetchEvacuationRoute() async {
    final route = await ApiService.getEvacuationRoute(origin: _selectedOriginRoom);
    if (route != null) {
      _currentRoute = route;
    }
  }

  Future<void> fetchAlertHistory() async {
    _alertHistory = await ApiService.getAlertHistory();
    notifyListeners();
  }

  Future<bool> triggerScenario(int scenarioId) async {
    _isLoading = true;
    notifyListeners();
    final success = await ApiService.triggerScenario(scenarioId);
    await fetchData();
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> resetAlerts() async {
    _isLoading = true;
    notifyListeners();
    final success = await ApiService.resetAlerts();
    await fetchData();
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
