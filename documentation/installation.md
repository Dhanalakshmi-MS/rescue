# RescueLens XR – Installation & Setup Manual

This document provides step-by-step setup guides tailored for each of the three project team members.

---

## Member 1 – IoT Hardware Setup Guide

### 1. Required Hardware Checklist
- [x] ESP32 Development Board (30-pin or 38-pin version).
- [x] MQ-2 Gas/Smoke Sensor module.
- [x] DHT11 Temperature & Humidity Sensor module.
- [x] Optical Flame Sensor module (IR photodiode).
- [x] Active 5V Piezo Buzzer.
- [x] 3x 5mm LEDs: Red (Danger), Yellow (Warning), Green (Safe).
- [x] 3x 220Ω Resistors (for LEDs) + 1x 10kΩ Resistor (pull-up for DHT11).
- [x] Half-size or full-size Solderless Breadboard.
- [x] Male-to-Male and Male-to-Female Jumper Wires.
- [x] Micro-USB / USB-C data cable.

### 2. Software Installation
1. Download and install **Arduino IDE 2.x** from [arduino.cc](https://www.arduino.cc/en/software).
2. Open Arduino IDE and navigate to **File ➔ Preferences**.
3. Under **Additional boards manager URLs**, add:
   ```text
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Go to **Tools ➔ Board ➔ Boards Manager...**, search for `esp32` by Espressif Systems, and click **Install**.
5. Go to **Tools ➔ Manage Libraries...**, search for `DHT sensor library` by Adafruit, and click **Install All**.

### 3. Hardware Wiring
Follow the pinout defined in [esp32/README.md](file:///c:/Users/hemam/OneDrive/Desktop/rescue/esp32/README.md):
- `MQ-2 A0` ➔ `GPIO 34` | `VCC` ➔ `VIN (5V)` | `GND` ➔ `GND`
- `DHT11 DATA` ➔ `GPIO 4` | `VCC` ➔ `3.3V` | `GND` ➔ `GND`
- `FLAME D0` ➔ `GPIO 18` | `VCC` ➔ `3.3V` | `GND` ➔ `GND`
- `BUZZER (+)` ➔ `GPIO 25` | `(-)` ➔ `GND`
- `RED LED (+)` ➔ `[220Ω]` ➔ `GPIO 26` | `(-)` ➔ `GND`
- `YELLOW LED (+)` ➔ `[220Ω]` ➔ `GPIO 27` | `(-)` ➔ `GND`
- `GREEN LED (+)` ➔ `[220Ω]` ➔ `GPIO 14` | `(-)` ➔ `GND`

### 4. Flashing Firmware
1. Open [esp32/config.h](file:///c:/Users/hemam/OneDrive/Desktop/rescue/esp32/config.h) and set your Wi-Fi SSID and Password.
2. Set `BACKEND_SERVER_URL` to your team leader's local IP (e.g. `http://192.168.1.150:8000/api/v1/sensors/telemetry`).
3. Connect ESP32 via USB, select **ESP32 Dev Module** and the active **COM port**.
4. Click **Upload** (➔) and open the **Serial Monitor** at **115200 baud**.

---

## Member 2 – Flutter Mobile Application Setup Guide

### 1. Software Installation
1. Download the **Flutter SDK** (version 3.x) from [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile).
2. Extract the zip to `C:\src\flutter`.
3. Add `C:\src\flutter\bin` to your Windows System Environment Variable `PATH`:
   - Press `Win + R`, type `sysdm.cpl`, click **Environment Variables**.
   - Under User or System variables, select `Path`, click **Edit**, click **New**, and paste `C:\src\flutter\bin`.
4. Open a new PowerShell and verify installation:
   ```powershell
   flutter doctor
   ```
5. Install **Android Studio** and configure the Android SDK Command-line Tools and an Android Virtual Device (AVD) emulator.

### 2. Running the Application
1. Open PowerShell and navigate to the `frontend` directory:
   ```powershell
   cd c:\Users\hemam\OneDrive\Desktop\rescue\frontend
   ```
2. Install Dart packages:
   ```powershell
   flutter pub get
   ```
3. Run the application:
   - **On Android Emulator**:
     ```powershell
     flutter run
     ```
   - **In Google Chrome (Desktop Preview)**:
     ```powershell
     flutter run -d chrome
     ```
   - **On Physical Android Device**:
     Enable USB Debugging on your phone, connect via USB, and run `flutter run`.

---

## Member 3 – Backend & Cloud Integration Setup Guide

### 1. Python Environment Setup
1. Verify Python 3.13 is installed:
   ```powershell
   python --version
   ```
2. Navigate to the `backend` folder:
   ```powershell
   cd c:\Users\hemam\OneDrive\Desktop\rescue\backend
   ```
3. Create and activate a Python virtual environment:
   ```powershell
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   ```
4. Install all dependencies:
   ```powershell
   pip install -r requirements.txt
   ```
5. Verify tests:
   ```powershell
   python test_backend.py
   ```
6. Start the FastAPI development server:
   ```powershell
   python main.py
   ```
7. Access interactive API documentation at:
   - `http://localhost:8000/docs`

### 2. Firebase Realtime Database Configuration
1. Follow [firebase/README.md](file:///c:/Users/hemam/OneDrive/Desktop/rescue/firebase/README.md) to create a project on the [Firebase Console](https://console.firebase.google.com/).
2. Import [firebase/database_structure.json](file:///c:/Users/hemam/OneDrive/Desktop/rescue/firebase/database_structure.json).
3. Apply security rules from [firebase/database.rules.json](file:///c:/Users/hemam/OneDrive/Desktop/rescue/firebase/database.rules.json).
4. Save service account key as `firebase/serviceAccountKey.json`.

---

## 4. Connecting All 3 Systems Over Local Wi-Fi

```text
[Wi-Fi Router / Mobile Hotspot]
        |
        +---- ESP32 Board (IP: 192.168.1.105)
        |
        +---- Host Computer running FastAPI (IP: 192.168.1.150:8000)
        |
        +---- Mobile Phone running Flutter (IP: 192.168.1.120)
```

1. Find the Host Computer's IPv4 address:
   ```powershell
   ipconfig
   # Look for 'IPv4 Address' under Wireless LAN adapter Wi-Fi (e.g. 192.168.1.150)
   ```
2. In `esp32/config.h`, set:
   ```cpp
   #define BACKEND_SERVER_URL "http://192.168.1.150:8000/api/v1/sensors/telemetry"
   ```
3. In the Flutter App (Admin screen), set the backend URL to:
   ```text
   http://192.168.1.150:8000/api/v1
   ```
4. Verify by running Scenario 1 in the app; the ESP32 buzzer will sound and the 2D map will update simultaneously!
