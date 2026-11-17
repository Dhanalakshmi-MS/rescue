#ifndef RESCUE_LENS_CONFIG_H
#define RESCUE_LENS_CONFIG_H

// ============================================================================
// RESCUELENS XR - ESP32 FIRMWARE CONFIGURATION
// ============================================================================

// 1. Wi-Fi Credentials
// Replace with your local Wi-Fi router or mobile hotspot credentials
#define WIFI_SSID           "RescueLens_WiFi"
#define WIFI_PASSWORD       "SafetyFirst2026"

// 2. Backend Server Endpoint
// Replace with your computer's local Wi-Fi IPv4 address (e.g., 192.168.1.150)
// To find your IP on Windows: Open PowerShell and run 'ipconfig'
#define BACKEND_SERVER_URL  "http://192.168.1.150:8000/api/v1/sensors/telemetry"

// 3. Hardware Identity & Zone Assignment
#define DEVICE_ID           "ESP32_NODE_01"
#define ROOM_ID             "ROOM_1"

// 4. ESP32 Pin Mapping (Standard 30-Pin / 38-Pin Dev Board)
#define PIN_MQ2_ANALOG      34    // ADC1 Channel 6 (Input only, 3.3V safe)
#define PIN_DHT             4     // Digital I/O for DHT11 (Requires pull-up)
#define PIN_FLAME_DIGITAL   18    // Digital input from Flame photodiode (Active LOW)

#define PIN_BUZZER          25    // Active buzzer (+) Anode
#define PIN_LED_RED         26    // Red Emergency LED (220-ohm resistor)
#define PIN_LED_YELLOW      27    // Yellow Warning LED (220-ohm resistor)
#define PIN_LED_GREEN       14    // Green Normal/Safe LED (220-ohm resistor)

// 5. Sensor Thresholds for Edge Safety Evaluation
#define SMOKE_THRESHOLD_WARNING_PPM   250.0
#define SMOKE_THRESHOLD_CRITICAL_PPM  450.0

#define TEMP_THRESHOLD_WARNING_C      40.0
#define TEMP_THRESHOLD_CRITICAL_C     50.0

// 6. Timing Intervals (in Milliseconds)
#define TELEMETRY_INTERVAL_MS         2000    // Send reading every 2 seconds
#define SENSOR_READ_INTERVAL_MS       1000    // Sample sensors every 1 second
#define SERIAL_BAUD_RATE              115200  // Serial monitor speed

#endif // RESCUE_LENS_CONFIG_H
