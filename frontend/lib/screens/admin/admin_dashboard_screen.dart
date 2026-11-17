import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _ipController = TextEditingController(text: ApiService.baseUrl);

  void _applyNewBackendUrl() {
    ApiService.setBaseUrl(_ipController.text.trim());
    context.read<AppState>().fetchData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Backend URL updated to: ${ApiService.baseUrl}"),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final status = state.buildingStatus;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Safety Commander Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRed),
            tooltip: "Logout",
            onPressed: () async {
              await state.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Officer Profile Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.25),
                    child: const Icon(Icons.admin_panel_settings, color: AppTheme.cyanAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? "Safety Chief",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        Text(
                          "Role: ${user?.role.toUpperCase() ?? 'ADMIN'} | Access Level: Full Control",
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("AUTHORIZED", style: TextStyle(color: AppTheme.safeGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Drill Controller Section
            const Text(
              "College Viva Drill Demonstration Scenarios",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              "Trigger live fire, smoke, and evacuation recalculation without physical hardware:",
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),

            _buildScenarioButton(
              context: context,
              state: state,
              scenarioId: 0,
              title: "Scenario 0: Normal / Safe Building",
              desc: "Restores all 8 zones to baseline normal status (23°C, 60 PPM, No Flame).",
              color: AppTheme.safeGreen,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 10),

            _buildScenarioButton(
              context: context,
              state: state,
              scenarioId: 1,
              title: "Scenario 1: Fire & Heavy Smoke in Room 1",
              desc: "Room 1 hits 58°C, 620 PPM + Flame. Room 1 blocked. Tests dynamic rerouting.",
              color: AppTheme.dangerRed,
              icon: Icons.local_fire_department_rounded,
            ),
            const SizedBox(height: 10),

            _buildScenarioButton(
              context: context,
              state: state,
              scenarioId: 2,
              title: "Scenario 2: Corridor East Fire (Main Exit Blocked)",
              desc: "Engulfs Main Exit corridor. Dijkstra redirects all building occupants to Emergency Exit.",
              color: AppTheme.warningAmber,
              icon: Icons.block_flipped,
            ),
            const SizedBox(height: 10),

            _buildScenarioButton(
              context: context,
              state: state,
              scenarioId: 3,
              title: "Scenario 3: Thermal Anomaly in Room 3",
              desc: "Admin Office heats up to 48.2°C without open flame. Tests caution alert state.",
              color: Colors.deepOrangeAccent,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 10),

            _buildScenarioButton(
              context: context,
              state: state,
              scenarioId: 4,
              title: "Scenario 4: Catastrophic Blockade (Trapped Demo)",
              desc: "Both East & West corridors blocked. Verifies TRAPPED_NO_SAFE_ROUTE fail-safe.",
              color: Colors.purpleAccent,
              icon: Icons.dangerous_rounded,
            ),
            const SizedBox(height: 20),

            // Emergency Alert System Reset Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final ok = await state.resetAlerts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? "All alerts reset successfully." : "Reset failed. Is backend running?"),
                              backgroundColor: ok ? AppTheme.safeGreen : AppTheme.dangerRed,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                label: const Text("1-CLICK EMERGENCY DRILL RESET", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Network Configuration Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Backend API Endpoint", style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text("10.0.2.2 for Android Emulator, or host PC IP for physical devices.", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.surfaceLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _applyNewBackendUrl,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cyanAccent,
                          foregroundColor: AppTheme.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioButton({
    required BuildContext context,
    required AppState state,
    required int scenarioId,
    required String title,
    required String desc,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        subtitle: Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        trailing: ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () async {
                  final ok = await state.triggerScenario(scenarioId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? "Scenario $scenarioId activated!" : "Trigger failed. Check backend connection."),
                        backgroundColor: ok ? color : AppTheme.dangerRed,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("RUN", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      ),
    );
  }
}
