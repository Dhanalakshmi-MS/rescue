from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pathlib import Path
from config import settings
from routes import api_router
from models.schemas import ScenarioTriggerRequest
from services.simulation import simulation_engine

# Static directory path for built-in web frontend
STATIC_DIR = Path(__file__).resolve().parent / "static"

# Initialize FastAPI application
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Emergency detection, real-time sensor processing, and dynamic Dijkstra evacuation route planning engine for RescueLens XR.",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure Cross-Origin Resource Sharing (CORS)
# Enables Flutter web, Android emulator (10.0.2.2), and physical mobile devices on LAN to connect seamlessly
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API v1 router
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

@app.on_event("startup")
async def startup_event():
    """Seeds initial baseline safe building state on server startup."""
    print(f"[*] Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    print(f"[*] Simulation mode active: {settings.SIMULATION_MODE}")
    simulation_engine.trigger_scenario(ScenarioTriggerRequest(scenario_id=0))
    print("[*] Baseline building state initialized successfully.")

@app.get("/dashboard", tags=["Frontend"])
@app.get("/app", tags=["Frontend"])
async def serve_web_dashboard():
    """Serves the complete RescueLens XR interactive web application."""
    index_file = STATIC_DIR / "index.html"
    if index_file.exists():
        return FileResponse(index_file)
    return {"message": "Web dashboard file not found"}

@app.get("/", tags=["Root"])
async def root():
    return {
        "project": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "ONLINE",
        "documentation": "/docs",
        "endpoints": {
            "telemetry": f"{settings.API_V1_PREFIX}/sensors/telemetry",
            "building_status": f"{settings.API_V1_PREFIX}/building/status",
            "evacuation_route": f"{settings.API_V1_PREFIX}/evacuation/route?origin=ROOM_1",
            "building_layout": f"{settings.API_V1_PREFIX}/evacuation/layout",
            "active_alerts": f"{settings.API_V1_PREFIX}/alerts/active",
            "simulation_scenarios": f"{settings.API_V1_PREFIX}/simulation/scenarios"
        }
    }

@app.get("/health", tags=["Root"])
async def health_check():
    return {"status": "HEALTHY", "debug": settings.DEBUG}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG)
