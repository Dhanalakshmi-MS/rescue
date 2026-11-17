from fastapi import APIRouter
from .sensors import router as sensors_router
from .building import router as building_router
from .evacuation import router as evacuation_router
from .alerts import router as alerts_router
from .simulation import router as simulation_router

api_router = APIRouter()

api_router.include_router(sensors_router, prefix="/sensors", tags=["Sensors & Telemetry"])
api_router.include_router(building_router, prefix="/building", tags=["Building Status"])
api_router.include_router(evacuation_router, prefix="/evacuation", tags=["Evacuation Routing"])
api_router.include_router(alerts_router, prefix="/alerts", tags=["Emergency Alerts"])
api_router.include_router(simulation_router, prefix="/simulation", tags=["Simulation Controls"])
