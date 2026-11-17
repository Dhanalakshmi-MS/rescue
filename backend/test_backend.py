from fastapi.testclient import TestClient
from main import app
from services.simulation import simulation_engine
from models.schemas import ScenarioTriggerRequest

client = TestClient(app)

def test_root_and_health():
    res = client.get("/")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ONLINE"
    assert "endpoints" in data

    res_h = client.get("/health")
    assert res_h.status_code == 200
    assert res_h.json()["status"] == "HEALTHY"

def test_baseline_building_status():
    # Reset to normal
    client.post("/api/v1/simulation/reset")
    
    res = client.get("/api/v1/building/status")
    assert res.status_code == 200
    data = res.json()
    assert data["overall_status"] == "NORMAL"
    assert data["critical_rooms"] == 0
    assert data["active_alerts_count"] == 0

def test_normal_dijkstra_evacuation_route():
    # In normal conditions, Room 2 to Main Exit should follow Corridor Central -> Corridor East -> Main Exit
    res = client.get("/api/v1/evacuation/route?origin=ROOM_2&target_exit=MAIN_EXIT")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "SAFE_ROUTE_FOUND"
    assert data["destination"] == "MAIN_EXIT"
    assert data["path"] == ["ROOM_2", "CORRIDOR_CENTRAL", "CORRIDOR_EAST", "MAIN_EXIT"]
    assert data["path_distance"] == 20.0

def test_telemetry_hazard_detection():
    # Ingest abnormal telemetry in Room 1
    telemetry = {
        "device_id": "TEST_ESP32",
        "room_id": "ROOM_1",
        "temperature": 55.0,
        "humidity": 30.0,
        "smoke_ppm": 600.0,
        "flame_detected": True
    }
    res = client.post("/api/v1/sensors/telemetry", json=telemetry)
    assert res.status_code == 200
    data = res.json()
    assert data["hazard_level"] == "CRITICAL"
    assert data["is_passable"] is False
    assert data["alert_triggered"] is True

    # Check that alert appears in active alerts
    res_alerts = client.get("/api/v1/alerts/active")
    assert res_alerts.status_code == 200
    alerts = res_alerts.json()
    assert len(alerts) >= 1
    assert any(a["room_id"] == "ROOM_1" for a in alerts)

def test_dynamic_evacuation_rerouting_scenario_1():
    # Trigger Scenario 1 (Fire in Room 1, West corridor hazy)
    res_sc = client.post("/api/v1/simulation/scenario", json={"scenario_id": 1})
    assert res_sc.status_code == 200

    # Evacuating from Room 2: Since Room 1 is on fire, route towards Main Exit should be chosen
    res_route = client.get("/api/v1/evacuation/route?origin=ROOM_2")
    assert res_route.status_code == 200
    data = res_route.json()
    assert data["status"] == "SAFE_ROUTE_FOUND"
    assert "ROOM_1" not in data["path"]
    assert "ROOM_1" in data["hazard_nodes_blocked"]

def test_dynamic_evacuation_rerouting_scenario_2_main_exit_blocked():
    # Trigger Scenario 2 (Corridor East fire -> Main Exit impassable)
    client.post("/api/v1/simulation/scenario", json={"scenario_id": 2})

    # Evacuating from Room 2: Must reroute through Corridor Central -> Corridor West -> Emergency Exit!
    res_route = client.get("/api/v1/evacuation/route?origin=ROOM_2")
    assert res_route.status_code == 200
    data = res_route.json()
    assert data["status"] == "SAFE_ROUTE_FOUND"
    assert data["destination"] == "EMERGENCY_EXIT"
    assert data["path"] == ["ROOM_2", "CORRIDOR_CENTRAL", "CORRIDOR_WEST", "EMERGENCY_EXIT"]

def test_trapped_no_safe_route_scenario_4():
    # Trigger Scenario 4 (Catastrophe: Both East and West corridors blocked)
    client.post("/api/v1/simulation/scenario", json={"scenario_id": 4})

    # Evacuating from Room 2: Should detect that no safe exit is reachable
    res_route = client.get("/api/v1/evacuation/route?origin=ROOM_2")
    assert res_route.status_code == 200
    data = res_route.json()
    assert data["status"] == "TRAPPED_NO_SAFE_ROUTE"
    assert data["path"] == []
    assert "CRITICAL DANGER" in data["warning_message"]

def test_admin_reset():
    # Reset building
    res_reset = client.post("/api/v1/alerts/reset")
    assert res_reset.status_code == 200
    assert res_reset.json()["status"] == "RESET_SUCCESSFUL"

    # Verify building is normal again
    res_status = client.get("/api/v1/building/status")
    assert res_status.json()["overall_status"] == "NORMAL"
    assert res_status.json()["critical_rooms"] == 0

if __name__ == "__main__":
    test_root_and_health()
    test_baseline_building_status()
    test_normal_dijkstra_evacuation_route()
    test_telemetry_hazard_detection()
    test_dynamic_evacuation_rerouting_scenario_1()
    test_dynamic_evacuation_rerouting_scenario_2_main_exit_blocked()
    test_trapped_no_safe_route_scenario_4()
    test_admin_reset()
    print("\n[SUCCESS] All 7 automated backend and algorithm tests passed flawlessly!")
