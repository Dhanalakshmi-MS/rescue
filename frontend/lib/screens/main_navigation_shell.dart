import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import 'dashboard/home_dashboard_screen.dart';
import 'monitor/sensor_monitor_screen.dart';
import 'map/building_map_screen.dart';
import 'alerts/emergency_alert_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    SensorMonitorScreen(),
    BuildingMapScreen(),
    EmergencyAlertScreen(),
    AdminDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeAlertCount = state.activeAlerts.length;
    final isCritical = state.buildingStatus?.isCritical ?? false;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.surface,
        selectedItemColor: isCritical && _currentIndex == 3 ? AppTheme.dangerRed : AppTheme.cyanAccent,
        unselectedItemColor: AppTheme.neutralGrey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: "Sensors",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: isCritical ? AppTheme.dangerRed : null,
                ),
                if (activeAlertCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.dangerRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$activeAlertCount",
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            label: "Alerts",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: "Admin",
          ),
        ],
      ),
    );
  }
}
