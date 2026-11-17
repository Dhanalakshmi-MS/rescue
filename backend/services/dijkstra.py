import heapq
from typing import Dict, List, Optional, Tuple, Set, Any
from models.schemas import RouteResponse

class EvacuationGraphManager:
    """
    Manages the building floor graph, node statuses, and dynamic Dijkstra
    evacuation route computation with real-time hazard blocking.
    """
    def __init__(self):
        # 2D Coordinates for layout rendering (useful for frontend map)
        self.node_metadata: Dict[str, Dict[str, Any]] = {
            "ROOM_1": {
                "name": "Room 1 (IoT Lab - West)",
                "type": "room",
                "x": 100, "y": 100, "width": 140, "height": 120
            },
            "ROOM_2": {
                "name": "Room 2 (Auditorium - Central)",
                "type": "room",
                "x": 320, "y": 100, "width": 160, "height": 120
            },
            "ROOM_3": {
                "name": "Room 3 (Admin Office - East)",
                "type": "room",
                "x": 560, "y": 100, "width": 140, "height": 120
            },
            "CORRIDOR_WEST": {
                "name": "Corridor West",
                "type": "corridor",
                "x": 150, "y": 280, "width": 100, "height": 60
            },
            "CORRIDOR_CENTRAL": {
                "name": "Corridor Central",
                "type": "corridor",
                "x": 350, "y": 280, "width": 100, "height": 60
            },
            "CORRIDOR_EAST": {
                "name": "Corridor East",
                "type": "corridor",
                "x": 550, "y": 280, "width": 100, "height": 60
            },
            "MAIN_EXIT": {
                "name": "Main Building Exit",
                "type": "exit",
                "x": 720, "y": 280, "width": 90, "height": 80
            },
            "EMERGENCY_EXIT": {
                "name": "Fire Emergency Exit (Stairwell)",
                "type": "exit",
                "x": 20, "y": 280, "width": 90, "height": 80
            }
        }

        # Baseline graph adjacency with physical distances (in meters)
        self.base_adj_list: Dict[str, List[Tuple[str, float]]] = {
            "ROOM_1": [("CORRIDOR_WEST", 5.0)],
            "ROOM_2": [("CORRIDOR_CENTRAL", 4.0)],
            "ROOM_3": [("CORRIDOR_EAST", 5.0)],
            "CORRIDOR_WEST": [
                ("ROOM_1", 5.0),
                ("EMERGENCY_EXIT", 6.0),
                ("CORRIDOR_CENTRAL", 10.0)
            ],
            "CORRIDOR_CENTRAL": [
                ("ROOM_2", 4.0),
                ("CORRIDOR_WEST", 10.0),
                ("CORRIDOR_EAST", 10.0)
            ],
            "CORRIDOR_EAST": [
                ("ROOM_3", 5.0),
                ("CORRIDOR_CENTRAL", 10.0),
                ("MAIN_EXIT", 6.0)
            ],
            "MAIN_EXIT": [("CORRIDOR_EAST", 6.0)],
            "EMERGENCY_EXIT": [("CORRIDOR_WEST", 6.0)]
        }

        self.exits = ["MAIN_EXIT", "EMERGENCY_EXIT"]
        self.blocked_nodes: Set[str] = set()

    def set_blocked_nodes(self, blocked: Set[str]):
        """Sets the collection of currently impassable/hazardous nodes."""
        self.blocked_nodes = set(blocked)

    def is_node_blocked(self, node: str) -> bool:
        return node in self.blocked_nodes

    def dijkstra_shortest_path(self, start_node: str, target_node: str) -> Tuple[Optional[List[str]], float]:
        """
        Runs Dijkstra's algorithm from start_node to target_node,
        completely avoiding any blocked (hazardous) nodes.
        Returns: (path_list, total_distance) or (None, infinity)
        """
        if start_node not in self.base_adj_list or target_node not in self.base_adj_list:
            return None, float('inf')

        # If target itself is blocked, no safe route can end there
        if self.is_node_blocked(target_node):
            return None, float('inf')

        # Min-heap priority queue: entries are (accumulated_dist, current_node, path)
        pq: List[Tuple[float, str, List[str]]] = [(0.0, start_node, [start_node])]
        visited: Dict[str, float] = {}

        while pq:
            current_dist, current_node, current_path = heapq.heappop(pq)

            if current_node in visited and visited[current_node] <= current_dist:
                continue
            visited[current_node] = current_dist

            if current_node == target_node:
                return current_path, current_dist

            for neighbor, weight in self.base_adj_list.get(current_node, []):
                # Critical safety check: Skip impassable/hazard nodes
                # (Unless it's the start node itself where occupant is trapped and needs escape)
                if neighbor != start_node and self.is_node_blocked(neighbor):
                    continue

                new_dist = current_dist + weight
                if neighbor not in visited or new_dist < visited[neighbor]:
                    heapq.heappush(pq, (new_dist, neighbor, current_path + [neighbor]))

        return None, float('inf')

    def calculate_best_evacuation_route(self, origin: str, target_exit: Optional[str] = None) -> RouteResponse:
        """
        Evaluates safe routes from origin to all available exits and picks the optimal route.
        If all exits are blocked, returns a TRAPPED alert with zero false guidance.
        """
        if origin not in self.base_adj_list:
            return RouteResponse(
                status="INVALID_ORIGIN",
                origin=origin,
                destination="NONE",
                path=[],
                path_distance=float('inf'),
                hazard_nodes_blocked=list(self.blocked_nodes),
                warning_message=f"Origin node '{origin}' does not exist in building layout."
            )

        exits_to_check = [target_exit] if (target_exit and target_exit in self.exits) else self.exits
        
        evaluation_results: Dict[str, Any] = {}
        best_path: Optional[List[str]] = None
        best_exit: Optional[str] = None
        shortest_distance = float('inf')

        for exit_node in exits_to_check:
            path, dist = self.dijkstra_shortest_path(origin, exit_node)
            evaluation_results[exit_node] = {
                "reachable": path is not None,
                "distance": dist if dist != float('inf') else -1,
                "path": path or []
            }
            if path is not None and dist < shortest_distance:
                shortest_distance = dist
                best_path = path
                best_exit = exit_node

        # Condition 1: Safe route successfully found
        if best_path and best_exit:
            status = "SAFE_ROUTE_FOUND"
            warning = None
            if self.blocked_nodes:
                warning = f"Alternate route calculated avoiding hazardous zones: {', '.join(sorted(self.blocked_nodes))}."

            return RouteResponse(
                status=status,
                origin=origin,
                destination=best_exit,
                path=best_path,
                path_distance=round(shortest_distance, 2),
                hazard_nodes_blocked=list(sorted(self.blocked_nodes)),
                warning_message=warning,
                all_exits_evaluated=evaluation_results
            )

        # Condition 2: Trapped - No safe route exists
        return RouteResponse(
            status="TRAPPED_NO_SAFE_ROUTE",
            origin=origin,
            destination="NONE",
            path=[],
            path_distance=float('inf'),
            hazard_nodes_blocked=list(sorted(self.blocked_nodes)),
            warning_message="CRITICAL DANGER: All standard evacuation routes are blocked by smoke/fire. "
                            "Seek nearest safe refuge area, close doors to seal out smoke, and call 911/emergency response.",
            all_exits_evaluated=evaluation_results
        )

    def get_layout_schema(self) -> Dict[str, Any]:
        """Returns the floor layout coordinates and connection edges for frontend rendering."""
        edges = []
        for src, neighbors in self.base_adj_list.items():
            for dest, weight in neighbors:
                if src < dest:  # Undirected presentation
                    edges.append({"from": src, "to": dest, "weight": weight})
        return {
            "nodes": self.node_metadata,
            "edges": edges,
            "exits": self.exits,
            "blocked_nodes": list(sorted(self.blocked_nodes))
        }

# Singleton instance
evacuation_manager = EvacuationGraphManager()
