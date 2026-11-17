from fastapi import APIRouter, HTTPException
from typing import Dict, Any, Optional
from models.schemas import SensorTelemetry, RoomStatus, AlertEvent
from services.safety_analyzer import safety_analyzer

router = APIRouter()

@router.post("/telemetry", response_model=Dict[str, Any])
async def receive_telemetry(telemetry: SensorTelemetry):
    """
    Primary ingestion endpoint for ESP32 hardware and simulation clients.
    Processes temperature, humidity, smoke PPM, and flame sensor signals.
    """
    try:
        updated_room, alert = safety_analyzer.process_telemetry(telemetry)
        return {
            "status": "PROCESSED",
            "room_id": updated_room.room_id,
            "hazard_level": updated_room.hazard_level.value,
            "is_passable": updated_room.is_passable,
            "alert_triggered": alert is not None,
            "alert_details": alert.model_dump() if alert else None,
            "timestamp": updated_room.last_updated
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process telemetry: {str(e)}")

@router.get("/latest", response_model=Dict[str, Any])
async def get_latest_readings(room_id: Optional[str] = None):
    """
    Retrieves the most recent environmental readings across the building or for a specific room.
    """
    if room_id:
        if room_id not in safety_analyzer.rooms:
            raise HTTPException(status_code=404, detail=f"Room '{room_id}' not found")
        room = safety_analyzer.rooms[room_id]
        return {
            "room_id": room.room_id,
            "room_name": room.room_name,
            "temperature": room.temperature,
            "humidity": room.humidity,
            "smoke_ppm": room.smoke_ppm,
            "flame_detected": room.flame_detected,
            "hazard_level": room.hazard_level.value,
            "last_updated": room.last_updated
        }
    
    return {
        r_id: {
            "room_id": r.room_id,
            "room_name": r.room_name,
            "temperature": r.temperature,
            "humidity": r.humidity,
            "smoke_ppm": r.smoke_ppm,
            "flame_detected": r.flame_detected,
            "hazard_level": r.hazard_level.value,
            "last_updated": r.last_updated
        }
        for r_id, r in safety_analyzer.rooms.items()
    }
