import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../map/building_map_screen.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchAlertHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeAlerts = state.activeAlerts;
    final history = state.alertHistory;
    final route = state.currentRoute;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Emergency Dispatch Center"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              state.fetchData();
              state.fetchAlertHistory();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Emergency Broadcast Banner
            if (activeAlerts.isNotEmpty) ...[
              for (final alert in activeAlerts) ...[
                _buildActiveAlertHeroCard(context, alert, route),
                const SizedBox(height: 16),
              ],
            ] else ...[
              _buildAllClearCard(),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 10),
            // Section Header: Alert Audit History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Incident & Drill History",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  "${history.length} logged events",
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Center(
                  child: Text(
                    "No historical alerts recorded yet.",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final date = DateTime.fromMillisecondsSinceEpoch((item.timestamp * 1000).toInt());
                  final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
                  return _buildHistoryItem(item, formattedDate);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlertHeroCard(BuildContext context, dynamic alert, dynamic route) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dangerRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dangerRed.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.dangerRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EMERGENCY ALERT",
                    style: TextStyle(
                      color: AppTheme.dangerRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    "Life Safety Hazard Detected",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detail rows
          _buildInfoRow("Hazard Classification", alert.hazardType, AppTheme.warningAmber),
          _buildInfoRow("Affected Sector", alert.roomId, AppTheme.textPrimary),
          if (alert.sensorSnapshot != null)
            _buildInfoRow(
              "Sensor Telemetry",
              "Temp: ${alert.sensorSnapshot['temperature']}°C | Smoke: ${alert.sensorSnapshot['smoke_ppm']} PPM | Flame: ${alert.sensorSnapshot['flame_detected']}",
              AppTheme.textSecondary,
            ),
          const SizedBox(height: 10),

          // Evacuation Guidance Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.safeGreen.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_run_rounded, color: AppTheme.safeGreen, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "SUGGESTED ALTERNATIVE EXIT",
                      style: TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  route != null && route.isSafeRoute
                      ? "Proceed immediately to ${route.destination} via: ${route.path.join(' ➔ ')}"
                      : "CRITICAL: Follow nearest verified safe exit. Check floor map.",
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Map Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BuildingMapScreen()),
                );
              },
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text("OPEN 2D EVACUATION ROUTE MAP", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.safeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllClearCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.safeGreen, width: 1.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_user_rounded, color: AppTheme.safeGreen, size: 48),
          SizedBox(height: 12),
          Text(
            "ALL CLEAR: NO ACTIVE HAZARDS",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.safeGreen,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "All sensor readings are within normal atmospheric thresholds.",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(dynamic alert, String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardBorder,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: AppTheme.cyanAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert.hazardType,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
