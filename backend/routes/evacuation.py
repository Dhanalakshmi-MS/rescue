from fastapi import APIRouter, Query, HTTPException
from typing import Optional, Dict, Any, List
from models.schemas import RouteResponse, RouteRequest
from services.dijkstra import evacuation_manager

router = APIRouter()

@router.get("/route", response_model=RouteResponse)
async def compute_evacuation_route(
    origin: str = Query(default="ROOM_1", description="Current location node (e.g. ROOM_1, ROOM_2, ROOM_3)"),
    target_exit: Optional[str] = Query(default=None, description="Optional target exit override (MAIN_EXIT or EMERGENCY_EXIT)")
):
    """
    Computes mathematically optimal safe evacuation route using Dijkstra's algorithm.
    Dynamically routes around hazardous/impassable nodes. If all exits are blocked,
    returns a clear TRAPPED warning.
    """
    return evacuation_manager.calculate_best_evacuation_route(origin=origin, target_exit=target_exit)

@router.post("/route", response_model=RouteResponse)
async def compute_evacuation_route_post(req: RouteRequest):
    """
    POST variant for computing dynamic evacuation route.
    """
    return evacuation_manager.calculate_best_evacuation_route(origin=req.origin, target_exit=req.target_exit)

@router.get("/layout", response_model=Dict[str, Any])
async def get_building_layout():
    """
    Returns 2D map metadata, coordinates, nodes, and connections for the Flutter interactive map.
    """
    return evacuation_manager.get_layout_schema()

@router.get("/blocked", response_model=List[str])
async def get_blocked_nodes():
    """
    Returns the list of currently impassable nodes due to smoke or fire.
    """
    return list(sorted(evacuation_manager.blocked_nodes))
