import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';

class BuildingMapScreen extends StatelessWidget {
  const BuildingMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final route = state.currentRoute;
    final blockedNodes = route?.hazardNodesBlocked ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("2D Evacuation Guidance Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.fetchData(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Location Selector Bar
            _buildLocationBar(context, state),
            const SizedBox(height: 14),

            // Map Color Legend
            _buildLegendBar(),
            const SizedBox(height: 14),

            // 2D Interactive Building Canvas
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: BuildingFloorPainter(
                    rooms: state.rooms,
                    activePath: route?.path ?? [],
                    blockedNodes: blockedNodes,
                    origin: state.selectedOriginRoom,
                    destination: route?.destination ?? '',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Turn-by-Turn Dynamic Navigation Directive Card
            _buildRouteInstructionsCard(route),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBar(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.my_location_rounded, color: AppTheme.cyanAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "My Location:",
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

  Widget _buildLegendBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem("Hazard (Blocked)", AppTheme.dangerRed),
        _buildLegendItem("Warning Area", AppTheme.warningAmber),
        _buildLegendItem("Safe Route", AppTheme.safeGreen),
        _buildLegendItem("Normal Zone", AppTheme.neutralGrey),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRouteInstructionsCard(dynamic route) {
    if (route == null) {
      return const SizedBox();
    }

    if (route.isTrapped) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dangerRed, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.dangerous_rounded, color: AppTheme.dangerRed, size: 24),
                SizedBox(width: 8),
                Text(
                  "NO SAFE ROUTE AVAILABLE (TRAPPED)",
                  style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              route.warningMessage ?? "All exit corridors compromised by fire/smoke.",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation_rounded, color: AppTheme.safeGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                "Optimal Evacuation Exit: ${route.destination}",
                style: const TextStyle(
                  color: AppTheme.safeGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                "${route.pathDistance.toStringAsFixed(1)} m",
                style: const TextStyle(color: AppTheme.cyanAccent, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Turn-by-turn Directional Guidance:",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < route.path.length; i++) ...[
                Chip(
                  backgroundColor: i == 0
                      ? AppTheme.primaryBlue
                      : (i == route.path.length - 1 ? AppTheme.safeGreen : AppTheme.surfaceLight),
                  label: Text(
                    route.path[i],
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  avatar: Icon(
                    i == 0
                        ? Icons.person_pin_circle
                        : (i == route.path.length - 1 ? Icons.exit_to_app : Icons.arrow_forward),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
          if (route.warningMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              "⚠ ${route.warningMessage}",
              style: const TextStyle(color: AppTheme.warningAmber, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class BuildingFloorPainter extends CustomPainter {
  final List<dynamic> rooms;
  final List<String> activePath;
  final List<String> blockedNodes;
  final String origin;
  final String destination;

  BuildingFloorPainter({
    required this.rooms,
    required this.activePath,
    required this.blockedNodes,
    required this.origin,
    required this.destination,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale reference from logical coordinate plane (800 x 400) to actual canvas size
    final double scaleX = size.width / 820.0;
    final double scaleY = size.height / 380.0;

    // Node bounds definition
    final Map<String, Rect> nodes = {
      'ROOM_1': Rect.fromLTWH(80 * scaleX, 40 * scaleY, 160 * scaleX, 90 * scaleY),
      'ROOM_2': Rect.fromLTWH(330 * scaleX, 40 * scaleY, 160 * scaleX, 90 * scaleY),
      'ROOM_3': Rect.fromLTWH(580 * scaleX, 40 * scaleY, 160 * scaleX, 90 * scaleY),
      
      'CORRIDOR_WEST': Rect.fromLTWH(80 * scaleX, 190 * scaleY, 160 * scaleX, 60 * scaleY),
      'CORRIDOR_CENTRAL': Rect.fromLTWH(330 * scaleX, 190 * scaleY, 160 * scaleX, 60 * scaleY),
      'CORRIDOR_EAST': Rect.fromLTWH(580 * scaleX, 190 * scaleY, 160 * scaleX, 60 * scaleY),

      'EMERGENCY_EXIT': Rect.fromLTWH(10 * scaleX, 290 * scaleY, 180 * scaleX, 65 * scaleY),
      'MAIN_EXIT': Rect.fromLTWH(620 * scaleX, 290 * scaleY, 180 * scaleX, 65 * scaleY),
    };

    // Connections (edges)
    final edges = [
      ['ROOM_1', 'CORRIDOR_WEST'],
      ['ROOM_2', 'CORRIDOR_CENTRAL'],
      ['ROOM_3', 'CORRIDOR_EAST'],
      ['CORRIDOR_WEST', 'CORRIDOR_CENTRAL'],
      ['CORRIDOR_CENTRAL', 'CORRIDOR_EAST'],
      ['CORRIDOR_WEST', 'EMERGENCY_EXIT'],
      ['CORRIDOR_EAST', 'MAIN_EXIT'],
    ];

    // 1. Draw connecting hallway pathways
    final corridorPaint = Paint()
      ..color = const Color(0xFF203248)
      ..strokeWidth = 14 * scaleX
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final activePathPaint = Paint()
      ..color = AppTheme.safeGreen
      ..strokeWidth = 8 * scaleX
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final p1 = nodes[edge[0]]?.center ?? Offset.zero;
      final p2 = nodes[edge[1]]?.center ?? Offset.zero;
      canvas.drawLine(p1, p2, corridorPaint);

      // Highlight green if this edge is consecutive in the computed evacuation path!
      final idx1 = activePath.indexOf(edge[0]);
      final idx2 = activePath.indexOf(edge[1]);
      if (idx1 != -1 && idx2 != -1 && (idx1 - idx2).abs() == 1) {
        canvas.drawLine(p1, p2, activePathPaint);
      }
    }

    // 2. Draw each room & corridor node block
    nodes.forEach((id, rect) {
      Color fillColor = const Color(0xFF16253B);
      Color borderColor = AppTheme.cardBorder;
      String label = id.replaceAll('_', ' ');

      final bool isBlocked = blockedNodes.contains(id);
      final bool inPath = activePath.contains(id);
      final bool isOrigin = (id == origin);

      if (isBlocked) {
        fillColor = AppTheme.dangerRed.withOpacity(0.35);
        borderColor = AppTheme.dangerRed;
      } else if (inPath) {
        fillColor = AppTheme.safeGreen.withOpacity(0.35);
        borderColor = AppTheme.safeGreen;
      }

      if (id.contains('EXIT')) {
        if (!isBlocked) {
          fillColor = AppTheme.cyanAccent.withOpacity(0.25);
          borderColor = AppTheme.cyanAccent;
        }
      }

      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(10 * scaleX));
      
      // Fill
      final fillPaint = Paint()..color = fillColor;
      canvas.drawRRect(rrect, fillPaint);

      // Border
      final borderPaint = Paint()
        ..color = borderColor
        ..strokeWidth = isOrigin || inPath || isBlocked ? 3.0 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, borderPaint);

      // Draw label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: isOrigin ? "★ $label (YOU)" : label,
          style: TextStyle(
            color: isBlocked ? AppTheme.dangerRed : (inPath ? Colors.white : AppTheme.textSecondary),
            fontSize: 10 * scaleX,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: rect.width - 8);
      textPainter.paint(
        canvas,
        Offset(rect.left + 8, rect.top + 8),
      );

      // Sub-badge for status
      String badge = isBlocked ? "BLOCKED" : (inPath ? "SAFE ROUTE" : "NORMAL");
      if (id.contains('EXIT')) badge = isBlocked ? "CLOSED" : "EXIT PORTAL";

      final badgePainter = TextPainter(
        text: TextSpan(
          text: badge,
          style: TextStyle(
            color: isBlocked ? AppTheme.dangerRed : (inPath ? AppTheme.safeGreen : AppTheme.textMuted),
            fontSize: 8 * scaleX,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      badgePainter.layout(maxWidth: rect.width - 8);
      badgePainter.paint(
        canvas,
        Offset(rect.left + 8, rect.bottom - 18 * scaleY),
      );
    });
  }

  @override
  bool shouldRepaint(covariant BuildingFloorPainter oldDelegate) {
    return true;
  }
}
