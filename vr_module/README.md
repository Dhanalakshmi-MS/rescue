# RescueLens XR – 3D Digital Twin & VR Visualization

The **VR Building Visualization Module** serves as an interactive **3D Digital Twin** for incident commanders, first responders, and emergency drill evaluators using **Unity 3D**.

---

## 1. System Features

1. **Volumetric 3D Floor Layout**: Renders Room 1, Room 2, Room 3, connecting corridors, and exits in 3D perspective.
2. **Real-Time Thermal & Smoke Tinting**: Compromised fire sectors dynamically transition to a glowing crimson red material.
3. **3D Luminous Evacuation Ribbon**: Dynamically draws a 3D laser-bright green ribbon connecting building zones along the optimal Dijkstra route.
4. **Dual Mode Operation**:
   - **Desktop Orbit Mode**: Evaluators can rotate, pan, and zoom the 3D model using mouse controls during a college presentation.
   - **Immersive VR Headset Mode**: Full 6-DOF inspection via Meta Quest 2 / Quest 3 or SteamVR headset.

---

## 2. Unity Setup & Execution Guide

### Step 1: Open or Create Project in Unity Hub
1. Create a new **3D (URP)** Unity project named `RescueLens_VR`.
2. Copy the script [vr_module/Scripts/VRBuildingTwin.cs](file:///c:/Users/hemam/OneDrive/Desktop/rescue/vr_module/Scripts/VRBuildingTwin.cs) into your Unity project's `Assets/Scripts/` folder.

### Step 2: Scene Configuration
1. Create an empty GameObject named `Building_Digital_Twin`.
2. Attach the `VRBuildingTwin.cs` script component to it.
3. Set the **Backend Status URL**:
   ```text
   http://192.168.1.150:8000/api/v1/building/status
   ```
4. Set the **Backend Route URL**:
   ```text
   http://192.168.1.150:8000/api/v1/evacuation/route?origin=ROOM_1
   ```
5. *(Optional)* If you have custom 3D room meshes, drag and drop them into the respective inspector slots. If left empty, the script automatically generates procedural 3D building blocks!

### Step 3: Run the Digital Twin
1. Ensure the Python FastAPI backend is running:
   ```powershell
   cd c:\Users\hemam\OneDrive\Desktop\rescue\backend
   .\venv\Scripts\python main.py
   ```
2. Press **Play** (▶) in the Unity Editor.
3. Trigger a fire scenario in the Flutter app or backend (e.g. Scenario 1).
4. Watch Room 1 turn fiery red in 3D, and the evacuation ribbon dynamically redirect occupants away from the hazard toward the safe exit!
