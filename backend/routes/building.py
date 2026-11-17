from fastapi import APIRouter, HTTPException
from typing import Dict, Any, List
from models.schemas import BuildingStatusResponse, RoomStatus
from services.safety_analyzer import safety_analyzer

router = APIRouter()

@router.get("/status", response_model=BuildingStatusResponse)
async def get_building_overall_status():
    """
    Returns consolidated building status, room count, emergency counters,
    and ESP32 connectivity state for the Home Dashboard.
    """
    return safety_analyzer.get_building_status()

@router.get("/rooms", response_model=List[RoomStatus])
async def get_all_rooms():
    """
    Returns detailed status for each individual zone/room.
    """
    return list(safety_analyzer.rooms.values())

@router.get("/rooms/{room_id}", response_model=RoomStatus)
async def get_single_room(room_id: str):
    """
    Returns detailed status for a single room.
    """
    if room_id not in safety_analyzer.rooms:
        raise HTTPException(status_code=404, detail=f"Room '{room_id}' not found")
    return safety_analyzer.rooms[room_id]
