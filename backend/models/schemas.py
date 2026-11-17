from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
import time

class HazardLevel(str, Enum):
    NORMAL = "NORMAL"
    WARNING = "WARNING"
    CRITICAL = "CRITICAL"

class HazardType(str, Enum):
    NONE = "NONE"
    SMOKE = "SMOKE"
    FIRE = "FIRE"
    HIGH_TEMPERATURE = "HIGH_TEMPERATURE"
    MULTIPLE = "MULTIPLE"

class SensorTelemetry(BaseModel):
    device_id: str = Field(default="ESP32_NODE_01", description="Identifier of the transmitting ESP32 node")
    room_id: str = Field(default="ROOM_1", description="Identifier of room or zone")
    temperature: float = Field(..., ge=-20.0, le=120.0, description="Ambient temperature in Celsius")
    humidity: float = Field(..., ge=0.0, le=100.0, description="Relative humidity percentage")
    smoke_ppm: float = Field(..., ge=0.0, description="MQ-2 smoke / combustible gas concentration in PPM")
    flame_detected: bool = Field(default=False, description="True if IR flame photodiode triggered")
    timestamp: float = Field(default_factory=time.time, description="Unix timestamp of sensor reading")

class RoomStatus(BaseModel):
    room_id: str
    room_name: str
    hazard_level: HazardLevel = HazardLevel.NORMAL
    hazard_types: List[HazardType] = [HazardType.NONE]
    temperature: float = 24.0
    humidity: float = 50.0
    smoke_ppm: float = 80.0
    flame_detected: bool = False
    is_passable: bool = True
    last_updated: float = Field(default_factory=time.time)

class AlertEvent(BaseModel):
    alert_id: str
    room_id: str
    hazard_level: HazardLevel
    hazard_type: str
    message: str
    timestamp: float = Field(default_factory=time.time)
    resolved: bool = False
    recommended_action: str
    sensor_snapshot: Optional[Dict[str, Any]] = None

class BuildingStatusResponse(BaseModel):
    overall_status: HazardLevel
    total_rooms: int
    safe_rooms: int
    warning_rooms: int
    critical_rooms: int
    active_alerts_count: int
    esp32_connected: bool
    last_heartbeat: float
    rooms: Dict[str, RoomStatus]

class RouteRequest(BaseModel):
    origin: str = Field(default="ROOM_1", description="Starting room node for evacuation")
    target_exit: Optional[str] = Field(default=None, description="Optional forced target exit (MAIN_EXIT or EMERGENCY_EXIT)")

class RouteResponse(BaseModel):
    status: str = Field(..., description="SAFE_ROUTE_FOUND, CAUTION_ROUTE_FOUND, or TRAPPED_NO_SAFE_ROUTE")
    origin: str
    destination: str
    path: List[str]
    path_distance: float
    hazard_nodes_blocked: List[str]
    warning_message: Optional[str] = None
    all_exits_evaluated: Dict[str, Any] = {}

class ScenarioTriggerRequest(BaseModel):
    scenario_id: int = Field(..., ge=0, le=5, description="Preset scenario (0=Normal, 1=Room 1 Fire, 2=Corridor Smoke, 3=Room 3 High Temp, 4=Both Exits Impassable)")
    custom_room: Optional[str] = None
    smoke_ppm: Optional[float] = None
    temperature: Optional[float] = None
    flame_detected: Optional[bool] = None
