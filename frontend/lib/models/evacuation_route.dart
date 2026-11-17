class EvacuationRoute {
  final String status; // SAFE_ROUTE_FOUND, TRAPPED_NO_SAFE_ROUTE
  final String origin;
  final String destination;
  final List<String> path;
  final double pathDistance;
  final List<String> hazardNodesBlocked;
  final String? warningMessage;

  EvacuationRoute({
    required this.status,
    required this.origin,
    required this.destination,
    required this.path,
    required this.pathDistance,
    required this.hazardNodesBlocked,
    this.warningMessage,
  });

  factory EvacuationRoute.fromJson(Map<String, dynamic> json) {
    return EvacuationRoute(
      status: json['status'] ?? 'UNKNOWN',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      path: (json['path'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      pathDistance: (json['path_distance'] as num?)?.toDouble() ?? 0.0,
      hazardNodesBlocked: (json['hazard_nodes_blocked'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      warningMessage: json['warning_message'],
    );
  }

  bool get isTrapped => status == 'TRAPPED_NO_SAFE_ROUTE';
  bool get isSafeRoute => status == 'SAFE_ROUTE_FOUND';
}
