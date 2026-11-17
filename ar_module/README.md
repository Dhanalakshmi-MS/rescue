# RescueLens XR – Augmented Reality (AR) Evacuation Guidance

The **AR Navigation Module** brings dynamic, spatial visual guidance to building occupants during fire and smoke emergencies using **Unity 3D** and **Unity AR Foundation (ARCore)**.

---

## 1. System Features

1. **Smartphone Camera Passthrough**: Overlays high-visibility 3D directional arrows onto the real-world corridor floor.
2. **Dynamic Dijkstra Synchronization**: Pulls real-time rerouting data from the Python FastAPI backend every 3 seconds.
3. **Animated 3D Chevron Pathfinding**: Spawns animated green chevrons pointing toward the verified safe exit.
4. **Emergency Warning Billboard**: Floating 3D HUD banner facing the user, displaying exit name, distance in meters, and urgent hazard warnings.
5. **Fail-Safe Trapped Mode**: If all corridors are engulfed in smoke, the AR guidance switches immediately to a prominent red barrier with *"TRAPPED - SEEK IMMEDIATE SHELTER"* instructions.

---

## 2. Theoretical Analysis: Indoor Positioning Limitations & Why GPS Fails

> [!IMPORTANT]
> **Why GPS Cannot Be Used Inside Buildings**:
> 1. **Radio Frequency (RF) Attenuation**: Satellite signals (L1 band at 1575.42 MHz) are extremely faint (~-160 dBW). Reinforced concrete walls, metal rebar meshes, and double-glazed windows attenuate or completely absorb the signal.
> 2. **Multipath Reflection**: Signals that penetrate the exterior walls bounce off interior steel framing, floors, and drywall, introducing delay errors that produce horizontal inaccuracies of 15 to 40 meters. In a building, a 15-meter error means placing the user in the wrong room, on the wrong side of a fire door, or inside a blazing hazard zone!
> 3. **Vertical Blindness ($Z$-Axis Error)**: Standard consumer GPS has high vertical dilution of precision (VDOP) and cannot reliably determine which floor level an occupant is on.

### The Solution: Marker-Based Visual SLAM Anchoring
RescueLens XR combines **Visual-Inertial Odometry (VIO)** with **Visual Image Anchors (QR plaques)**:
- High-contrast printed QR plaques are posted at room doorways (e.g., `ROOM_1_DOOR_ANCHOR`, `ROOM_2_DOOR_ANCHOR`).
- When the smartphone camera glimpses the door plaque, `IndoorLocalizationManager.cs` instantly locks the virtual 3D floor plan coordinate origin $(0, 0, 0)$ to the physical door with millimeter precision.
- As the user walks down the corridor, the smartphone's gyroscope, accelerometer, and feature-point tracking (VIO) smoothly propel the animated green arrows forward.

---

## 3. Unity Project Setup Instructions

### Prerequisites
- **Unity Hub** (version 2022.3 LTS or 2023.2 LTS recommended).
- **Android Build Support** (with OpenJDK and Android NDK).
- ARCore-compatible Android smartphone.

### Step 1: Create Unity Project
1. Open Unity Hub and create a new **3D (URP)** project named `RescueLens_AR`.
2. Go to **Window ➔ Package Manager**.
3. Install:
   - `AR Foundation` (version 5.x or 6.x)
   - `Google ARCore XR Plugin`
   - `TextMesh Pro` (Essentials)

### Step 2: Scene Hierarchy Setup
1. In the default scene, delete the standard `Main Camera`.
2. Right-click in the Hierarchy:
   - Add **XR ➔ AR Session**.
   - Add **XR ➔ XR Origin (Mobile AR)**.
3. On the `XR Origin` GameObject:
   - Add Component: `AR Tracked Image Manager`.
   - Add Component: [Scripts/ARRouteNavigator.cs](file:///c:/Users/hemam/OneDrive/Desktop/rescue/ar_module/Scripts/ARRouteNavigator.cs).
   - Add Component: [Scripts/IndoorLocalizationManager.cs](file:///c:/Users/hemam/OneDrive/Desktop/rescue/ar_module/Scripts/IndoorLocalizationManager.cs).

### Step 3: Configure Backend Connection
1. In the Inspector for `ARRouteNavigator`:
   - Set **Backend Route Url**: `http://192.168.1.150:8000/api/v1/evacuation/route?origin=ROOM_1` (replace with your host PC's Wi-Fi IPv4).
   - Set **Route Poll Interval**: `3.0` seconds.

### Step 4: Build & Deploy to Android
1. Go to **File ➔ Build Settings...**
2. Switch platform to **Android**.
3. Go to **Player Settings ➔ XR Plug-in Management** and check **ARCore**.
4. Set Minimum API Level to **Android 7.0 (API Level 24)**.
5. Connect your Android phone via USB and click **Build and Run**.
