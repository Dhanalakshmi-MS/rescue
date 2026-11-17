from fastapi import APIRouter
from typing import Dict, Any, List
from models.schemas import ScenarioTriggerRequest
from services.simulation import simulation_engine

router = APIRouter()

@router.post("/scenario", response_model=Dict[str, Any])
async def trigger_simulation_scenario(req: ScenarioTriggerRequest):
    """
    Triggers simulated emergency scenarios for college demonstration:
    - 0: Normal / Safe Building
    - 1: Fire & Heavy Smoke in Room 1 (Routes to Emergency Exit)
    - 2: Corridor East Fire / Main Exit Blocked (Reroutes to Emergency Exit)
    - 3: High Temperature Anomaly in Room 3
    - 4: Trapped Scenario (Both corridors blocked)
    - 5: Custom Injection
    """
    return simulation_engine.trigger_scenario(req)

@router.post("/reset", response_model=Dict[str, Any])
async def reset_simulation():
    """
    Convenience endpoint to restore all building sensors to normal.
    """
    return simulation_engine.trigger_scenario(ScenarioTriggerRequest(scenario_id=0))

@router.get("/scenarios", response_model=List[Dict[str, Any]])
async def list_available_scenarios():
    """
    Returns catalogue of demo scenarios for UI buttons.
    """
    return [
        {
            "id": 0,
            "name": "Normal Safe Baseline",
            "description": "All zones normal (Temp ~23.5°C, Smoke ~60 PPM, Flame=False)."
        },
        {
            "id": 1,
            "name": "Fire in Room 1",
            "description": "Flame + 620 PPM smoke in Room 1; smoke leaks to Corridor West. Room 1 blocked."
        },
        {
            "id": 2,
            "name": "Corridor East Fire (Main Exit Blocked)",
            "description": "Main exit path engulfed. Forces all occupants to evacuate via Emergency Exit."
        },
        {
            "id": 3,
            "name": "Room 3 Overheating",
            "description": "Temperature spikes to 48.2°C in Admin Office without open flame."
        },
        {
            "id": 4,
            "name": "Catastrophic Blockade (Trapped Demo)",
            "description": "Both Corridor West and Corridor East blocked. Evaluates TRAPPED fail-safe."
        }
    ]
