import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';

class SensorMonitorScreen extends StatelessWidget {
  const SensorMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Current metrics
    final currentTemp = state.tempPoints.isNotEmpty ? state.tempPoints.last : 24.0;
    final currentSmoke = state.smokePoints.isNotEmpty ? state.smokePoints.last : 60.0;
    final currentHumidity = state.humidityPoints.isNotEmpty ? state.humidityPoints.last : 50.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Real-Time Sensor Telemetry"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone Selector
            _buildZoneSelector(context, state),
            const SizedBox(height: 18),

            // Chart 1: Temperature
            _buildChartCard(
              title: "Ambient Temperature Trend",
              currentValue: "${currentTemp.toStringAsFixed(1)} °C",
              icon: Icons.thermostat_rounded,
              color: currentTemp > 45 ? AppTheme.dangerRed : Colors.orangeAccent,
              spots: state.tempPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              minY: 15.0,
              maxY: 80.0,
              unit: "°C",
              thresholdWarning: 45.0,
            ),
            const SizedBox(height: 18),

            // Chart 2: MQ-2 Smoke & Gas
            _buildChartCard(
              title: "MQ-2 Smoke & Gas Concentration",
              currentValue: "${currentSmoke.toStringAsFixed(1)} PPM",
              icon: Icons.cloud_queue_rounded,
              color: currentSmoke > 300 ? AppTheme.dangerRed : AppTheme.cyanAccent,
              spots: state.smokePoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              minY: 0.0,
              maxY: 800.0,
              unit: "PPM",
              thresholdWarning: 300.0,
            ),
            const SizedBox(height: 18),

            // Chart 3: Relative Humidity
            _buildChartCard(
              title: "Relative Atmospheric Humidity",
              currentValue: "${currentHumidity.toStringAsFixed(1)} %",
              icon: Icons.water_drop_rounded,
              color: Colors.lightBlueAccent,
              spots: state.humidityPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              minY: 10.0,
              maxY: 100.0,
              unit: "%",
              thresholdWarning: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelector(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.room_rounded, color: AppTheme.cyanAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "Active Monitoring Zone:",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          DropdownButton<String>(
            value: state.selectedOriginRoom,
            dropdownColor: AppTheme.surfaceLight,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.cyanAccent),
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
            onChanged: (val) {
              if (val != null) state.selectOriginRoom(val);
            },
            items: const [
              DropdownMenuItem(value: "ROOM_1", child: Text("Room 1 (IoT Lab)")),
              DropdownMenuItem(value: "ROOM_2", child: Text("Room 2 (Auditorium)")),
              DropdownMenuItem(value: "ROOM_3", child: Text("Room 3 (Admin Office)")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String currentValue,
    required IconData icon,
    required Color color,
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
    required String unit,
    required double? thresholdWarning,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Text(
                currentValue,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppTheme.safeGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text("Live data polling active (2s interval)", style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              const Spacer(),
              if (thresholdWarning != null)
                Text("Threshold: ${thresholdWarning.toInt()} $unit", style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.cardBorder.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  show: false,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isNotEmpty ? spots : [const FlSpot(0, 0)],
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.12),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
