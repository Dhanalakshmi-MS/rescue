import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../alerts/emergency_alert_screen.dart';
import '../map/building_map_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.buildingStatus;
    final isCritical = status?.isCritical ?? false;
    final isWarning = status?.isWarning ?? false;

    // Pick active telemetry for display (from Room 1 or selected room)
    final activeRoom = state.rooms.firstWhere(
      (r) => r.roomId == state.selectedOriginRoom,
      orElse: () => state.rooms.isNotEmpty ? state.rooms.first : null as dynamic,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("RescueLens XR Dashboard"),
        actions: [
          // ESP32 Connectivity Pill
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: state.isBackendConnected
                  ? AppTheme.safeGreen.withOpacity(0.15)
                  : AppTheme.dangerRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.isBackendConnected ? AppTheme.safeGreen : AppTheme.dangerRed,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isBackendConnected ? AppTheme.safeGreen : AppTheme.dangerRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isBackendConnected ? "ESP32 LINKED" : "OFFLINE",
                  style: TextStyle(
                    color: state.isBackendConnected ? AppTheme.safeGreen : AppTheme.dangerRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.fetchData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Overall Building Status Banner
              _buildOverallStatusBanner(context, isCritical, isWarning, state),
              const SizedBox(height: 18),

              // 2. Active Alert Warning Card (if any hazard exists)
              if (state.activeAlerts.isNotEmpty) ...[
                _buildActiveEmergencyCard(context, state),
                const SizedBox(height: 18),
              ],

              // 3. Environmental Sensor Telemetry Grid
              const Text(
                "Real-Time Atmospheric Telemetry",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "SMOKE LEVEL",
                      value: "${activeRoom?.smokePpm.toStringAsFixed(1) ?? '60.0'} PPM",
                      icon: Icons.cloud_queue_rounded,
                      iconColor: (activeRoom?.smokePpm ?? 0) > 300
                          ? AppTheme.dangerRed
                          : AppTheme.cyanAccent,
                      statusText: (activeRoom?.smokePpm ?? 0) > 300 ? "HAZARDOUS" : "SAFE",
                      statusColor: (activeRoom?.smokePpm ?? 0) > 300
                          ? AppTheme.dangerRed
                          : AppTheme.safeGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: "TEMPERATURE",
                      value: "${activeRoom?.temperature.toStringAsFixed(1) ?? '24.0'} °C",
                      icon: Icons.thermostat_rounded,
                      iconColor: (activeRoom?.temperature ?? 0) > 45
                          ? AppTheme.dangerRed
                          : Colors.orangeAccent,
                      statusText: (activeRoom?.temperature ?? 0) > 45 ? "OVERHEAT" : "NORMAL",
                      statusColor: (activeRoom?.temperature ?? 0) > 45
                          ? AppTheme.dangerRed
                          : AppTheme.safeGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "HUMIDITY",
                      value: "${activeRoom?.humidity.toStringAsFixed(1) ?? '50.0'} %",
                      icon: Icons.water_drop_rounded,
                      iconColor: Colors.lightBlueAccent,
                      statusText: "OPTIMAL",
                      statusColor: AppTheme.safeGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: "OPTICAL FLAME",
                      value: (activeRoom?.flameDetected ?? false) ? "DETECTED!" : "CLEAR",
                      icon: Icons.local_fire_department_rounded,
                      iconColor: (activeRoom?.flameDetected ?? false)
                          ? AppTheme.dangerRed
                          : AppTheme.safeGreen,
                      statusText: (activeRoom?.flameDetected ?? false) ? "FIRE ALERT" : "NO FLAME",
                      statusColor: (activeRoom?.flameDetected ?? false)
                          ? AppTheme.dangerRed
                          : AppTheme.safeGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 4. Quick Evacuation Access Card
              _buildEvacuationActionCard(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStatusBanner(
      BuildContext context, bool isCritical, bool isWarning, AppState state) {
    Color bannerColor = AppTheme.safeGreen;
    String statusTitle = "BUILDING STATUS: ALL ZONES SECURE";
    String subtitle = "Continuous sensor monitoring active across 8 building sectors.";
    IconData icon = Icons.check_circle_outline_rounded;

    if (isCritical) {
      bannerColor = AppTheme.dangerRed;
      statusTitle = "EMERGENCY: EVACUATION ORDER IN EFFECT";
      subtitle = "${state.activeAlerts.length} Critical hazard(s) active! Follow dynamic green route.";
      icon = Icons.warning_amber_rounded;
    } else if (isWarning) {
      bannerColor = AppTheme.warningAmber;
      statusTitle = "CAUTION: ELEVATED READINGS DETECTED";
      subtitle = "Atmospheric anomalies detected. Prepare for potential evacuation.";
      icon = Icons.info_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bannerColor, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: bannerColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEmergencyCard(BuildContext context, AppState state) {
    final alert = state.activeAlerts.first;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmergencyAlertScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dangerRed, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dangerRed.withOpacity(0.2),
              blurRadius: 14,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency_rounded, color: AppTheme.dangerRed, size: 22),
                const SizedBox(width: 8),
                Text(
                  "ACTIVE HAZARD: ${alert.hazardType}",
                  style: const TextStyle(
                    color: AppTheme.dangerRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.dangerRed, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              "➔ ACTION: ${alert.recommendedAction}",
              style: const TextStyle(
                color: AppTheme.warningAmber,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvacuationActionCard(BuildContext context, AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cyanAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.map_rounded, color: AppTheme.cyanAccent, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Interactive Building Map",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "View live Dijkstra evacuation paths & hazard zones",
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuildingMapScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cyanAccent,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text("VIEW MAP", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
