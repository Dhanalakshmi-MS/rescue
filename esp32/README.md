# RescueLens XR – ESP32 Hardware Integration Guide

This guide contains complete circuit connections, pin assignments, library installations, safe testing protocols, and flashing instructions for **Member 1 (IoT Engineer)**.

---

## 1. Component & Pinout Assignment Table

| Component | Component Pin | ESP32 GPIO | Description / Notes | Power Source |
| :--- | :--- | :--- | :--- | :--- |
| **MQ-2 Smoke Sensor** | VCC | **5V (VIN)** | Heater coil requires 5V | ESP32 VIN / External 5V |
| | GND | **GND** | Common ground | ESP32 GND |
| | A0 (Analog) | **GPIO 34** | ADC1_CH6 (Input-only analog pin, 0-3.3V safe) | Analog reading |
| **DHT11 Sensor** | VCC | **3.3V** | Operating voltage | ESP32 3.3V pin |
| | GND | **GND** | Common ground | ESP32 GND |
| | DATA | **GPIO 4** | Digital bidirectional (Requires 10kΩ pull-up to 3.3V) | Digital I/O |
| **Flame Sensor (IR)**| VCC | **3.3V** | Operating voltage | ESP32 3.3V pin |
| | GND | **GND** | Common ground | ESP32 GND |
| | D0 (Digital) | **GPIO 18** | Digital threshold output (Active LOW on flame) | Digital Input |
| **Active Buzzer** | (+) Anode | **GPIO 25** | Audio emergency alarm | Controlled by GPIO |
| | (-) Cathode | **GND** | Common ground | ESP32 GND |
| **Red LED (Danger)** | (+) Anode | **GPIO 26** | Through 220Ω current-limiting resistor | Controlled by GPIO |
| | (-) Cathode | **GND** | Common ground | ESP32 GND |
| **Yellow LED (Warn)**| (+) Anode | **GPIO 27** | Through 220Ω current-limiting resistor | Controlled by GPIO |
| | (-) Cathode | **GND** | Common ground | ESP32 GND |
| **Green LED (Safe)** | (+) Anode | **GPIO 14** | Through 220Ω current-limiting resistor | Controlled by GPIO |
| | (-) Cathode | **GND** | Common ground | ESP32 GND |

---

## 2. Breadboard Wiring Schematic

```text
                  +-----------------------------------+
                  |           ESP32 DEV BOARD         |
                  |                                   |
    5V (VIN) -----+ VIN                           GND +----- Common GND Rail
    3.3V     -----+ 3V3                               |
                  |                                   |
    MQ-2 (A0) ----+ GPIO 34 (ADC1_6)          GPIO 25 +-----> (+) Buzzer
                  |                                   |
    DHT11(DATA) --+ GPIO 4                    GPIO 26 +-----> [220Ω] ---> (+) Red LED
                  |                                   |
    FLAME (D0) ---+ GPIO 18                   GPIO 27 +-----> [220Ω] ---> (+) Yellow LED
                  |                                   |
                  |                           GPIO 14 +-----> [220Ω] ---> (+) Green LED
                  +-----------------------------------+
```

> [!IMPORTANT]
> **Ground Rail Tip**: Connect all ground pins (DHT11 GND, MQ-2 GND, Flame GND, Buzzer (-), and LED cathodes) to the common negative (-) rail of your breadboard, and link that rail to an ESP32 `GND` pin.

---

## 3. Arduino IDE Setup Instructions

### Step 1: Install ESP32 Board Package
1. Open **Arduino IDE 2.x**.
2. Go to **File ➔ Preferences**.
3. In the **Additional boards manager URLs** field, paste:
   ```text
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Click **OK**.
5. Go to **Tools ➔ Board ➔ Boards Manager...**, search for `esp32` by Espressif Systems, and click **Install**.

### Step 2: Install Required Libraries
1. Open **Tools ➔ Manage Libraries...** (or press `Ctrl + Shift + I`).
2. Search and install:
   - `DHT sensor library` by **Adafruit** (Select "Install all" to include the required *Adafruit Unified Sensor* dependency).

---

## 4. Configuring & Flashing Firmware

1. Open the file [esp32/config.h](file:///c:/Users/hemam/OneDrive/Desktop/rescue/esp32/config.h).
2. Update your Wi-Fi credentials:
   ```cpp
   #define WIFI_SSID           "Your_WiFi_Name"
   #define WIFI_PASSWORD       "Your_WiFi_Password"
   ```
3. Update the backend URL to your computer's local IP:
   ```cpp
   #define BACKEND_SERVER_URL  "http://192.168.1.150:8000/api/v1/sensors/telemetry"
   ```
   *(To find your IPv4 on Windows, open PowerShell and run `ipconfig`).*
4. Connect the ESP32 board to your computer using a micro-USB / USB-C data cable.
5. In Arduino IDE, select:
   - **Board**: `ESP32 Dev Module`
   - **Port**: Select the active COM port (e.g., `COM3`, `COM4`, or `COM5`).
6. Click the **Upload** arrow button (➔).
7. If the IDE says `Connecting......._____`, press and hold the **BOOT** button on the ESP32 for 2 seconds until the upload starts.
8. Open the **Serial Monitor** at **115200 baud**.

---

## 5. Safe Low-Voltage Testing Protocol

> [!WARNING]
> **Safety First**: NEVER use open flames, matchsticks, or hazardous smoke in a classroom or college laboratory!

Use these approved, safe testing methods:

### A. Testing the Flame Sensor
- **Safe Method**: Point a household television / AC remote control directly at the dark photodiode lens and press any button. The remote emits harmless infrared (IR) light at ~940 nm, which instantly triggers the flame sensor photodiode.
- **Verification**: The onboard sensor DO LED illuminates, the ESP32 activates the Red LED and Buzzer, and sends `"flame_detected": true` to the backend.

### B. Testing the MQ-2 Smoke Sensor
- **Safe Method 1**: Moisten a cotton swab with rubbing alcohol (isopropyl alcohol) and hold it 2–3 cm away from the metal mesh cylinder. Alcohol vapor cleanly stimulates the internal tin dioxide ($SnO_2$) heating element.
- **Safe Method 2**: Use an unlit disposable butane lighter. Hold down the gas valve lever for 1 second near the sensor without striking the spark wheel.
- **Verification**: Smoke PPM increases above 300 PPM, triggering the warning/critical state.

### C. Testing the DHT11 Temperature Sensor
- **Safe Method**: Place your warm fingertip firmly over the blue plastic casing of the DHT11 or gently exhale warm breath onto it. The temperature will rise by 2–4°C within seconds.

### D. Zero-Hardware Interactive Serial Override
If hardware sensors are not yet wired or undergoing assembly, you can test edge firmware states directly via the Arduino Serial Monitor:
- Send `1` ➔ Simulates Fire & Heavy Smoke (Flame=True, Temp=58°C, Smoke=650 PPM).
- Send `2` ➔ Simulates Elevated Smoke Warning (Smoke=320 PPM).
- Send `0` ➔ Restores physical sensor readings.

---

## 6. Sensor Calibration Notes

- **MQ-2 Preheating (Burn-in)**: Brand new MQ-2 sensors require a 24 to 48-hour continuous power burn-in period to stabilize the internal heater resistance ($R_0$). In normal air, readings typically hover around 40–80 PPM.
- **DHT11 Sampling Limit**: The DHT11 sensor requires at least 1 second between consecutive read requests. The firmware uses a non-blocking 1-second sample loop (`millis()`) to prevent `nan` read errors.
