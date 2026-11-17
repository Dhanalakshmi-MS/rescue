# RescueLens XR – Flutter Android Mobile Application

The **RescueLens XR Mobile Application** is built with Flutter and Dart to provide real-time life safety alerts, atmospheric monitoring, interactive 2D dynamic evacuation maps, and emergency drill management.

---

## 1. Application Architecture & Screens

| Screen | File Location | Features & Capabilities |
| :--- | :--- | :--- |
| **Screen 1: Login & Auth** | [lib/screens/auth/login_screen.dart](file:///c:/Users/hemam/OneDrive/Desktop/rescue/frontend/lib/screens/auth/login_screen.dart) | Dark navy styling, Role switching (Occupant vs Safety Officer), 1-tap demonstration auto-fill credentials. |
| **Screen 2: Home Dashboard** | [lib/screens/dashboard/home_dashboard_screen.dart](file:///c:/Users/hemam/OneDrive/Desktop/rescue/frontend/lib/screens/dashboard/home_dashboard_screen.dart) | Building status banner (Normal/Caution/Critical), active hazard quick card, smoke/temp/humidity/flame metrics, ESP32 connection badge. |
| **Screen 3: Sensor Monitor** | [lib/screens/monitor/sensor_monitor_screen.dart](file:///c:/Users/hemam/OneDrive/Desktop/rescue/frontend/lib/screens/monitor/sensor_monitor_screen.dart) | Live auto-updating `fl_chart` charts for Temperature (°C), Smoke PPM, and Relative Humidity (%), zone selector dropdown. |
| **Screen 4: Emergency Dispatch** | [lib/screens/alerts/emergency_alert_screen.dart](file:///c:/Users/hemam/OneDrive/Desktop/rescue/frontend/lib/screens/alerts/emergency_alert_screen.dart) | Pulsing life-safety hazard broadcast, sensor snapshot, suggested alternate exit routing, incident audit history timeline. |
| **Screen 5: 2D Floor Plan** | [lib/screens/map/building_map_screen.dart](file:///c:/Users/hemam/OneDrive/Desktop/rescue/frontend/lib/screens/map/building_map_screen.dart) | Custom-rendered 2D building map with dynamic Dijkstra paths (Green), fire/smoke blocked nodes (Red), warning zones (Yellow), turn-by-turn route directives. |
| **Screen 6: Safety Commander** | [lib/screens/admin/admin_dashboard_screen.dart](file:///c:/Users/hemam/OneDrive/Desktop/rescue/frontend/lib/screens/admin/admin_dashboard_screen.dart) | Emergency drill triggers (Scenarios 0–4), 1-click system drill reset, live backend IP configuration. |

---

## 2. Prerequisites for Member 2

1. **Install Flutter SDK**:
   - Download Flutter for Windows from [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile).
   - Unzip to `C:\src\flutter`.
   - Add `C:\src\flutter\bin` to your System Environment Variable `PATH`.
2. **Verify Setup**:
   Open a new PowerShell window and run:
   ```powershell
   flutter doctor
   ```
3. **Android Studio**:
   - Ensure the Android SDK, Android SDK Command-line Tools, and Android Virtual Device (AVD) Emulator are installed.

---

## 3. Running the Mobile Application

### Step 1: Install Dependencies
Open PowerShell in the `frontend` directory:
```powershell
cd c:\Users\hemam\OneDrive\Desktop\rescue\frontend
flutter pub get
```

### Step 2: Start the Backend Server First
In a separate terminal, launch the Python backend:
```powershell
cd c:\Users\hemam\OneDrive\Desktop\rescue\backend
.\venv\Scripts\Activate.ps1
python main.py
```

### Step 3: Launch Flutter
- **On Android Emulator**:
  ```powershell
  flutter run
  ```
- **In Chrome Browser (Instant Desktop Preview)**:
  ```powershell
  flutter run -d chrome
  ```
- **On Physical Android Phone**:
  1. Enable USB Debugging on your phone.
  2. Connect via USB cable.
  3. Ensure your phone and PC are on the same Wi-Fi network.
  4. In the app's Admin tab, update the backend IP to your PC's Wi-Fi IP (e.g. `http://192.168.1.150:8000/api/v1`).
  5. Run:
     ```powershell
     flutter run
     ```
