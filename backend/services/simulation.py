import random
import time
from typing import Dict, Any
from models.schemas import SensorTelemetry, ScenarioTriggerRequest
from services.safety_analyzer import safety_analyzer

class SimulationEngine:
    """
    Generates realistic sensor telemetry and preset fire/emergency demonstration
    scenarios, allowing thorough frontend and algorithm validation without hardware.
    """
    def __init__(self):
        self.current_scenario_id = 0
        self.last_simulated_readings: Dict[str, SensorTelemetry] = {}

    def get_normal_reading(self, room_id: str) -> SensorTelemetry:
        """Returns baseline normal reading with minor realistic fluctuations."""
        base_temp = 23.5 + random.uniform(-0.5, 0.8)
        base_humidity = 49.0 + random.uniform(-1.0, 1.5)
        base_smoke = 55.0 + random.uniform(-3.0, 5.0)

        return SensorTelemetry(
            device_id="SIMULATOR_ESP32",
            room_id=room_id,
            temperature=round(base_temp, 1),
            humidity=round(base_humidity, 1),
            smoke_ppm=round(base_smoke, 1),
            flame_detected=False,
            timestamp=time.time()
        )

    def trigger_scenario(self, req: ScenarioTriggerRequest) -> Dict[str, Any]:
        """
        Executes a pre-configured emergency demonstration scenario:
        0: Normal Baseline (all rooms safe)
        1: Fire in Room 1 (Smoke + Flame in Room 1; West Corridor hazy)
        2: Main Exit Blocked (Fire in Corridor East, re-routing to Emergency Exit)
        3: Overheating Warning in Room 3 (Abnormal heat, smoke warning)
        4: Catastrophic Blockade (Both exits blocked - Trapped state demo)
        5: Custom Injection
        """
        self.current_scenario_id = req.scenario_id

        if req.scenario_id == 0:
            # Reset all rooms to normal
            safety_analyzer.reset_all_hazards()
            for r_id in safety_analyzer.rooms.keys():
                telemetry = self.get_normal_reading(r_id)
                safety_analyzer.process_telemetry(telemetry)
                self.last_simulated_readings[r_id] = telemetry
            return {"status": "SUCCESS", "scenario": "0_NORMAL", "description": "All zones restored to normal safe status."}

        elif req.scenario_id == 1:
            # Scenario 1: Fire in Room 1
            safety_analyzer.reset_all_hazards()
            # Normal rooms
            for r_id in ["ROOM_2", "ROOM_3", "CORRIDOR_CENTRAL", "CORRIDOR_EAST", "MAIN_EXIT", "EMERGENCY_EXIT"]:
                t = self.get_normal_reading(r_id)
                safety_analyzer.process_telemetry(t)
                self.last_simulated_readings[r_id] = t
            
            # Fire in Room 1
            t_room1 = SensorTelemetry(
                device_id="SIMULATOR_ESP32",
                room_id="ROOM_1",
                temperature=58.5,
                humidity=28.0,
                smoke_ppm=620.0,
                flame_detected=True,
                timestamp=time.time()
            )
            # Smoke in adjacent West Corridor
            t_west = SensorTelemetry(
                device_id="SIMULATOR_ESP32",
                room_id="CORRIDOR_WEST",
                temperature=36.0,
                humidity=35.0,
                smoke_ppm=280.0,
                flame_detected=False,
                timestamp=time.time()
            )
            safety_analyzer.process_telemetry(t_room1)
            safety_analyzer.process_telemetry(t_west)
            self.last_simulated_readings["ROOM_1"] = t_room1
            self.last_simulated_readings["CORRIDOR_WEST"] = t_west

            return {
                "status": "SUCCESS",
                "scenario": "1_FIRE_ROOM_1",
                "description": "Fire triggered in Room 1 (Flame=True, Temp=58.5°C, Smoke=620PPM). Smoke spilling into Corridor West."
            }

        elif req.scenario_id == 2:
            # Scenario 2: Main Exit Blocked by Corridor East Fire
            safety_analyzer.reset_all_hazards()
            for r_id in ["ROOM_1", "ROOM_2", "ROOM_3", "CORRIDOR_WEST", "CORRIDOR_CENTRAL", "EMERGENCY_EXIT"]:
                t = self.get_normal_reading(r_id)
                safety_analyzer.process_telemetry(t)
                self.last_simulated_readings[r_id] = t

            t_east = SensorTelemetry(
                device_id="SIMULATOR_ESP32",
                room_id="CORRIDOR_EAST",
                temperature=64.0,
                humidity=22.0,
                smoke_ppm=750.0,
                flame_detected=True,
                timestamp=time.time()
            )
            safety_analyzer.process_telemetry(t_east)
            self.last_simulated_readings["CORRIDOR_EAST"] = t_east

            return {
                "status": "SUCCESS",
                "scenario": "2_MAIN_EXIT_BLOCKED",
                "description": "Corridor East engulfed in fire/smoke. Main Exit blocked. Dijkstra pathfinding must redirect everyone to Emergency Exit."
            }

        elif req.scenario_id == 3:
            # Scenario 3: High Temperature Anomaly in Room 3
            safety_analyzer.reset_all_hazards()
            for r_id in ["ROOM_1", "ROOM_2", "CORRIDOR_WEST", "CORRIDOR_CENTRAL", "CORRIDOR_EAST", "MAIN_EXIT", "EMERGENCY_EXIT"]:
                t = self.get_normal_reading(r_id)
                safety_analyzer.process_telemetry(t)
                self.last_simulated_readings[r_id] = t

            t_room3 = SensorTelemetry(
                device_id="SIMULATOR_ESP32",
                room_id="ROOM_3",
                temperature=48.2,
                humidity=31.0,
                smoke_ppm=210.0,
                flame_detected=False,
                timestamp=time.time()
            )
            safety_analyzer.process_telemetry(t_room3)
            self.last_simulated_readings["ROOM_3"] = t_room3

            return {
                "status": "SUCCESS",
                "scenario": "3_HIGH_TEMP_ROOM_3",
                "description": "Thermal anomaly in Room 3 (Temp=48.2°C). High temperature warning active."
            }

        elif req.scenario_id == 4:
            # Scenario 4: Both exits blocked (Trapped demonstration)
            safety_analyzer.reset_all_hazards()
            for r_id in ["ROOM_2", "CORRIDOR_CENTRAL"]:
                t = self.get_normal_reading(r_id)
                safety_analyzer.process_telemetry(t)
                self.last_simulated_readings[r_id] = t

            t_west = SensorTelemetry(device_id="SIM", room_id="CORRIDOR_WEST", temperature=60.0, humidity=20.0, smoke_ppm=600.0, flame_detected=True)
            t_east = SensorTelemetry(device_id="SIM", room_id="CORRIDOR_EAST", temperature=62.0, humidity=20.0, smoke_ppm=700.0, flame_detected=True)
            safety_analyzer.process_telemetry(t_west)
            safety_analyzer.process_telemetry(t_east)
            self.last_simulated_readings["CORRIDOR_WEST"] = t_west
            self.last_simulated_readings["CORRIDOR_EAST"] = t_east

            return {
                "status": "SUCCESS",
                "scenario": "4_ALL_EXITS_BLOCKED",
                "description": "Both Corridor West and Corridor East blocked by fire. Tests the 'TRAPPED_NO_SAFE_ROUTE' fail-safe."
            }

        elif req.scenario_id == 5:
            # Custom injection
            target = req.custom_room or "ROOM_1"
            temp = req.temperature if req.temperature is not None else 50.0
            smoke = req.smoke_ppm if req.smoke_ppm is not None else 500.0
            flame = req.flame_detected if req.flame_detected is not None else True

            custom_t = SensorTelemetry(
                device_id="CUSTOM_INJECTOR",
                room_id=target,
                temperature=temp,
                humidity=30.0,
                smoke_ppm=smoke,
                flame_detected=flame,
                timestamp=time.time()
            )
            safety_analyzer.process_telemetry(custom_t)
            self.last_simulated_readings[target] = custom_t
            return {
                "status": "SUCCESS",
                "scenario": "5_CUSTOM",
                "description": f"Custom telemetry applied to {target} (Temp: {temp}°C, Smoke: {smoke}PPM, Flame: {flame})."
            }

        return {"status": "ERROR", "message": "Unknown scenario id"}

simulation_engine = SimulationEngine()
