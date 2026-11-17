import time
import uuid
from typing import Dict, List, Set, Optional, Tuple
from config import settings
from models.schemas import (
    SensorTelemetry,
    HazardLevel,
    HazardType,
    RoomStatus,
    AlertEvent,
    BuildingStatusResponse
)
from services.dijkstra import evacuation_manager
from services.firebase_sync import firebase_sync

class SafetyAnalyzer:
    """
    Evaluates raw sensor streams, calculates anomaly hazard levels,
    maintains room statuses, and coordinates real-time emergency alerts.
    """
    def __init__(self):
        self.rooms: Dict[str, RoomStatus] = {
            "ROOM_1": RoomStatus(room_id="ROOM_1", room_name="Room 1 (IoT Lab - West)", temperature=24.0, humidity=50.0, smoke_ppm=65.0),
            "ROOM_2": RoomStatus(room_id="ROOM_2", room_name="Room 2 (Auditorium - Central)", temperature=23.5, humidity=48.0, smoke_ppm=60.0),
            "ROOM_3": RoomStatus(room_id="ROOM_3", room_name="Room 3 (Admin Office - East)", temperature=24.5, humidity=52.0, smoke_ppm=70.0),
            "CORRIDOR_WEST": RoomStatus(room_id="CORRIDOR_WEST", room_name="Corridor West", temperature=23.0, humidity=49.0, smoke_ppm=50.0),
            "CORRIDOR_CENTRAL": RoomStatus(room_id="CORRIDOR_CENTRAL", room_name="Corridor Central", temperature=23.2, humidity=50.0, smoke_ppm=55.0),
            "CORRIDOR_EAST": RoomStatus(room_id="CORRIDOR_EAST", room_name="Corridor East", temperature=23.1, humidity=51.0, smoke_ppm=52.0),
            "MAIN_EXIT": RoomStatus(room_id="MAIN_EXIT", room_name="Main Exit Portal", temperature=22.5, humidity=50.0, smoke_ppm=45.0),
            "EMERGENCY_EXIT": RoomStatus(room_id="EMERGENCY_EXIT", room_name="Emergency Exit Stairwell", temperature=22.0, humidity=50.0, smoke_ppm=40.0),
        }
        
        self.active_alerts: Dict[str, AlertEvent] = {}
        self.alert_history: List[AlertEvent] = []
        self.last_esp32_heartbeat: float = 0.0
        self.esp32_timeout_seconds: float = 15.0

    def process_telemetry(self, telemetry: SensorTelemetry) -> Tuple[RoomStatus, Optional[AlertEvent]]:
        """
        Ingests real-time sensor telemetry, evaluates safety thresholds,
        updates room state and synchronizes with evacuation pathfinder.
        """
        room_id = telemetry.room_id
        if room_id not in self.rooms:
            # Dynamically register unknown room if needed
            self.rooms[room_id] = RoomStatus(
                room_id=room_id,
                room_name=f"Zone {room_id}"
            )

        self.last_esp32_heartbeat = time.time()
        room = self.rooms[room_id]

        # Update telemetry values
        room.temperature = round(telemetry.temperature, 1)
        room.humidity = round(telemetry.humidity, 1)
        room.smoke_ppm = round(telemetry.smoke_ppm, 1)
        room.flame_detected = telemetry.flame_detected
        room.last_updated = telemetry.timestamp or time.time()

        # Evaluate hazard types & severity
        hazard_types: List[HazardType] = []
        hazard_level = HazardLevel.NORMAL

        if telemetry.flame_detected:
            hazard_types.append(HazardType.FIRE)
            hazard_level = HazardLevel.CRITICAL

        if telemetry.smoke_ppm >= settings.SMOKE_THRESHOLD_CRITICAL_PPM:
            hazard_types.append(HazardType.SMOKE)
            hazard_level = HazardLevel.CRITICAL
        elif telemetry.smoke_ppm >= settings.SMOKE_THRESHOLD_WARNING_PPM:
            hazard_types.append(HazardType.SMOKE)
            if hazard_level != HazardLevel.CRITICAL:
                hazard_level = HazardLevel.WARNING

        if telemetry.temperature >= settings.TEMP_THRESHOLD_CRITICAL_C:
            hazard_types.append(HazardType.HIGH_TEMPERATURE)
            hazard_level = HazardLevel.CRITICAL
        elif telemetry.temperature >= settings.TEMP_THRESHOLD_WARNING_C:
            hazard_types.append(HazardType.HIGH_TEMPERATURE)
            if hazard_level != HazardLevel.CRITICAL:
                hazard_level = HazardLevel.WARNING

        if len(hazard_types) > 1:
            hazard_types = [HazardType.MULTIPLE] + hazard_types

        if not hazard_types:
            hazard_types = [HazardType.NONE]

        room.hazard_level = hazard_level
        room.hazard_types = hazard_types
        # Mark impassable if in critical emergency
        room.is_passable = (hazard_level != HazardLevel.CRITICAL)

        # Synchronize impassable rooms with Evacuation Graph Manager
        blocked_nodes: Set[str] = {r_id for r_id, r in self.rooms.items() if not r.is_passable}
        evacuation_manager.set_blocked_nodes(blocked_nodes)

        # Trigger or resolve alerts
        alert_event = None
        if hazard_level in (HazardLevel.WARNING, HazardLevel.CRITICAL):
            alert_id = f"ALERT_{room_id}_{int(room.last_updated)}"
            action_msg = (
                "IMMEDIATE EVACUATION REQUIRED! Avoid this zone and follow dynamic green exit signs."
                if hazard_level == HazardLevel.CRITICAL
                else "Caution: Abnormal atmospheric readings. Prepare for potential evacuation."
            )
            type_str = ", ".join([h.value for h in hazard_types if h != HazardType.NONE])
            
            alert_event = AlertEvent(
                alert_id=alert_id,
                room_id=room_id,
                hazard_level=hazard_level,
                hazard_type=type_str,
                message=f"{hazard_level.value} Hazard detected in {room.room_name}: {type_str} (Temp: {room.temperature}°C, Smoke: {room.smoke_ppm} PPM, Flame: {room.flame_detected})",
                timestamp=room.last_updated,
                resolved=False,
                recommended_action=action_msg,
                sensor_snapshot={
                    "temperature": room.temperature,
                    "humidity": room.humidity,
                    "smoke_ppm": room.smoke_ppm,
                    "flame_detected": room.flame_detected
                }
            )
            self.active_alerts[room_id] = alert_event
            self.alert_history.insert(0, alert_event)
            # Keep history to max 50 items
            if len(self.alert_history) > 50:
                self.alert_history.pop()

        elif hazard_level == HazardLevel.NORMAL and room_id in self.active_alerts:
            # Auto-resolve alert when condition normalizes
            resolved_alert = self.active_alerts.pop(room_id)
            resolved_alert.resolved = True

        # Synchronize with Firebase Realtime Database
        try:
            firebase_sync.sync_room_update(room_id, room.model_dump())
            if alert_event:
                firebase_sync.sync_alert(alert_event.alert_id, alert_event.model_dump())
        except Exception:
            pass

        return room, alert_event

    def get_building_status(self) -> BuildingStatusResponse:
        """Returns consolidated building health overview."""
        is_esp_online = (time.time() - self.last_esp32_heartbeat) < self.esp32_timeout_seconds if self.last_esp32_heartbeat > 0 else False
        
        safe_count = sum(1 for r in self.rooms.values() if r.hazard_level == HazardLevel.NORMAL)
        warning_count = sum(1 for r in self.rooms.values() if r.hazard_level == HazardLevel.WARNING)
        critical_count = sum(1 for r in self.rooms.values() if r.hazard_level == HazardLevel.CRITICAL)

        overall = HazardLevel.NORMAL
        if critical_count > 0:
            overall = HazardLevel.CRITICAL
        elif warning_count > 0:
            overall = HazardLevel.WARNING

        return BuildingStatusResponse(
            overall_status=overall,
            total_rooms=len(self.rooms),
            safe_rooms=safe_count,
            warning_rooms=warning_count,
            critical_rooms=critical_count,
            active_alerts_count=len(self.active_alerts),
            esp32_connected=is_esp_online,
            last_heartbeat=self.last_esp32_heartbeat,
            rooms=self.rooms
        )

    def reset_all_hazards(self):
        """Resets all simulation/demonstration hazards back to normal."""
        for room_id, room in self.rooms.items():
            room.hazard_level = HazardLevel.NORMAL
            room.hazard_types = [HazardType.NONE]
            room.temperature = 23.5
            room.humidity = 50.0
            room.smoke_ppm = 60.0
            room.flame_detected = False
            room.is_passable = True
            room.last_updated = time.time()
        
        self.active_alerts.clear()
        evacuation_manager.set_blocked_nodes(set())
        try:
            firebase_sync.clear_active_alerts()
            for r_id, r in self.rooms.items():
                firebase_sync.sync_room_update(r_id, r.model_dump())
        except Exception:
            pass

safety_analyzer = SafetyAnalyzer()
