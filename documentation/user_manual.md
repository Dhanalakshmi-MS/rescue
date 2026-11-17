# RescueLens XR – User Manual & Viva Demonstration Guide

---

## 1. College Viva Demonstration Script (Step-by-Step)

This 5-minute presentation script is designed for your 3-member team to demonstrate the project before the examination panel.

### Step 1: Introduction (Member 3 - Team Lead / Backend) - 1 Minute
- *"Good morning, respected professors. Our project is **RescueLens XR – IoT-Based Smart Emergency Detection and Evacuation Guidance System**."*
- *"During structural fires and emergencies, traditional static exit signs often lead occupants directly into smoke-filled corridors. RescueLens XR solves this by combining IoT edge sensors, real-time FastAPI analytics, dynamic Dijkstra shortest-path recalculation, and a cross-platform Flutter application with AR/VR visualization."*

### Step 2: System Architecture & Normal Monitoring (Member 2 - Mobile App) - 1.5 Minutes
- Open the Flutter application on your phone or emulator.
- Click **"Student/User"** demo button and log into the system.
- Show **Screen 2 (Home Dashboard)**: *"Here you can see the building status is ALL ZONES SECURE. The ESP32 node is actively streaming temperature, humidity, smoke, and flame metrics every 2 seconds."*
- Navigate to **Screen 3 (Sensor Monitoring)**: Show the real-time line charts smoothly plotting live trends.
- Navigate to **Screen 5 (Building Map)**: Show the 2D interactive canvas. Show that the user in Room 2 is directed to the Main Exit along the green path.

### Step 3: Triggering Emergency & Dynamic Rerouting (Member 1 - IoT Engineer) - 1.5 Minutes
- Switch to the Admin account or simulate a fire:
  - **Option A (Physical Hardware)**: Hold the TV remote to the Flame sensor or hold an alcohol cotton swab near the MQ-2 sensor.
  - **Option B (Admin Tab)**: Tap **"RUN"** on **Scenario 1 (Fire in Room 1)**.
- Point out the instant reactions:
  1. **ESP32 Edge**: Red LED flashes rapidly, buzzer sounds continuous alarm.
  2. **Mobile App**: Home Dashboard turns crimson red with an **EMERGENCY ALERT** banner.
  3. **2D Map**: Room 1 turns bright **RED (BLOCKED)**. The evacuation route dynamically reroutes occupants away from the fire zone!
- Tap **"Scenario 2: Main Exit Blocked"**:
  - Show the 2D Map instantly recalculating: Main Exit turns red, and the green evacuation path dynamically flips to the **EMERGENCY EXIT**!
- Tap **"Scenario 4: Catastrophic Blockade (Trapped Demo)"**:
  - Show that instead of giving false or dangerous guidance, the app displays: *"CRITICAL: NO SAFE ROUTE AVAILABLE (TRAPPED). SEEK SHELTER AND SEAL DOOR GAPS."*
- Tap **"1-Click Emergency Drill Reset"**: All 8 zones immediately return to safe green!

### Step 4: Extended Reality (XR) Overview (Member 3) - 1 Minute
- Present the Unity AR & VR modules:
  - *"In AR mode, the occupant views animated green chevrons on their camera feed leading to the safe exit."*
  - Explain the indoor positioning limitation: *"GPS fails indoors due to concrete attenuation and multipath interference, so we use visual fiducial door markers for sub-centimeter localization."*
  - Conclude: *"Thank you, professors. We are now open for questions."*

---

## 2. Top 15 Viva Questions & Technical Answers

### Q1: What is the core problem RescueLens XR addresses?
**Answer**: Traditional building emergency signage is static and unaware of real-time hazard conditions. During a fire, a standard green exit sign may guide fleeing occupants directly into a smoke-engulfed corridor. RescueLens XR introduces real-time situational awareness by dynamically blocking hazardous zones and computing verified safe alternate routes.

### Q2: Why did you choose Dijkstra's Algorithm instead of A* or Breadth-First Search (BFS)?
**Answer**:
- Dijkstra's algorithm guarantees the mathematically optimal shortest path in weighted graphs where edge weights represent physical metric distances (corridor lengths).
- While BFS works for unweighted graphs, corridors have varying physical distances (e.g. 4m vs 10m).
- A* uses a spatial heuristic (Euclidean distance). In an indoor floor plan with walls, Euclidean heuristics can lead to dead ends near walls. Because our building graph has a small-to-medium vertex set ($|V| \le 100$), Dijkstra runs in under $0.5\text{ ms}$, making it optimal, complete, and lightning-fast.

### Q3: Why can't conventional GPS be used for indoor building evacuation?
**Answer**:
1. Satellite RF signals (L1 band 1575 MHz) suffer severe signal attenuation (-30 to -50 dB loss) through concrete roofs and walls.
2. Multipath interference causes signals to bounce off interior walls, resulting in positional errors of 15 to 40 meters (placing occupants in the wrong room or on the wrong floor).
3. GPS lacks vertical accuracy ($Z$-axis) and cannot determine which floor level an occupant is on. We resolve this by using visual QR door markers with AR Foundation image tracking.

### Q4: How does the system handle an edge node (ESP32) power or network failure?
**Answer**: The backend implements an automated heartbeat monitor (`last_heartbeat`). If the ESP32 fails to transmit telemetry for 15 seconds, the system marks `esp32_connected = False` and displays an offline status pill on the mobile app. The building retains its last known state, and administrators receive a connectivity warning.

### Q5: What is the purpose of using both FastAPI and Firebase Realtime Database?
**Answer**:
- **FastAPI** handles complex computational intelligence: threshold evaluation, edge validation, and the Dijkstra graph pathfinding algorithm.
- **Firebase Realtime Database** provides managed, low-latency WebSocket push streaming to hundreds of mobile devices simultaneously without requiring complex socket infrastructure on our local server.

### Q6: How does the MQ-2 sensor detect smoke and gas?
**Answer**: The MQ-2 sensor uses an internal tin dioxide ($SnO_2$) semiconductor heating element. In clean air, the sensor has high electrical resistance. When combustible gases or smoke particles contact the heated sensor surface, donor electrons are transferred, lowering the surface resistance. This changes the output voltage, which is read by the ESP32's 12-bit ADC on GPIO 34.

### Q7: Why is the flame sensor input configured as Active LOW?
**Answer**: Most commercial IR flame sensor modules feature an LM393 comparator with a pull-up resistor. In the absence of infrared light, the output remains pulled HIGH (3.3V). When infrared light from a flame (760nm–1100nm) strikes the photodiode, it conducts, pulling the comparator output LOW (0V). Hence, `digitalRead(PIN_FLAME_DIGITAL) == LOW` indicates fire.

### Q8: What happens if both the Main Exit and the Emergency Exit are blocked by fire?
**Answer**: Our algorithm evaluates all known exits. If every path to an exit has an infinite weight due to blocked nodes, Dijkstra returns `status = TRAPPED_NO_SAFE_ROUTE`. The mobile app immediately displays a prominent red warning directing occupants to seek nearest shelter, seal door gaps with cloth to prevent smoke inhalation, and await emergency services, rather than providing false guidance into a fire zone.

### Q9: How do you prevent false alarms (e.g. from hot coffee steam or minor dust)?
**Answer**: We employ multi-sensor fusion:
- Flame detection requires optical infrared photodiode activation.
- Smoke requires MQ-2 PPM to exceed 450 PPM.
- Abnormal heat requires temperature to exceed 50°C.
If only one variable rises mildly (e.g., temperature reaches 41°C), the system transitions to a pre-alert **WARNING (Yellow)** state rather than triggering a full emergency evacuation.

### Q10: How does the Flutter application render the 2D floor plan?
**Answer**: The map uses Flutter's native `CustomPainter` API (`BuildingFloorPainter`). It renders vector geometry directly to the GPU canvas. The painter receives the room status list and the computed Dijkstra path array, dynamically styling nodes and connecting hallways with color shaders (Green for safe paths, Red for hazards, Yellow for warnings).

### Q11: How does the AR Navigation module display arrows?
**Answer**: The Unity AR Foundation module uses ARCore's plane detection and camera tracking. `ARRouteNavigator.cs` translates the backend's room node names into 3D world-space coordinates, instantiates animated 3D chevron arrow primitives along each hallway segment, and rotates them along the forward vector toward the designated exit.

### Q12: What role does the 3D VR Digital Twin play?
**Answer**: The VR Digital Twin provides incident commanders and firefighters outside the building with situational awareness. They can inspect the 3D floor plan in real-time, see exactly which rooms have active fire and smoke (tinted in glowing red), and identify clear pathways to coordinate search-and-rescue operations.

### Q13: Are the MQ-2 and DHT11 sensors certified for commercial fire safety?
**Answer**: No. This is an educational prototype. Certified commercial fire alarm systems must comply with rigorous international standards (such as EN 54 or NFPA 72) with hermetically sealed, factory-calibrated ionization or optical chambers. Low-cost hobbyist sensors are for academic demonstration and proof-of-concept only.

### Q14: How are Firebase credentials and API keys secured?
**Answer**: Private keys (`serviceAccountKey.json`, `.env`) are explicitly excluded from Git using `.gitignore`. In addition, Firebase Realtime Database security rules (`database.rules.json`) strictly validate write permissions, allowing only authenticated administrators or backend service accounts to alter building emergency states.

### Q15: What are potential future enhancements for this project?
**Answer**:
1. Integration with building HVAC systems to automatically shut down ventilation dampers and prevent smoke migration.
2. Bluetooth Low Energy (BLE) beacon triangulation for continuous indoor positioning without QR code scanning.
3. LoRaWAN long-range edge communication for large multi-story university campuses.
