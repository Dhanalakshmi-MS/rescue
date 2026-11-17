from fastapi import APIRouter
from typing import List, Dict, Any
from models.schemas import AlertEvent
from services.safety_analyzer import safety_analyzer

router = APIRouter()

@router.get("/active", response_model=List[AlertEvent])
async def get_active_alerts():
    """
    Returns all currently active hazard alerts.
    """
    return list(safety_analyzer.active_alerts.values())

@router.get("/history", response_model=List[AlertEvent])
async def get_alert_history():
    """
    Returns past alert logs for post-incident review and admin monitoring.
    """
    return safety_analyzer.alert_history

@router.post("/reset", response_model=Dict[str, Any])
async def reset_alerts():
    """
    Admin control action: Clears active alerts and restores baseline normal state.
    """
    safety_analyzer.reset_all_hazards()
    return {
        "status": "RESET_SUCCESSFUL",
        "message": "All emergency alerts and room hazard flags have been reset to normal baseline."
    }
