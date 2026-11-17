/*
 * ============================================================================
 * RESCUELENS XR - ESP32 FIRMWARE
 * IoT-Based Smart Emergency Detection & Telemetry Transmitter
 * ============================================================================
 * 
 * Hardware Requirements:
 * - ESP32 Dev Board (30-pin or 38-pin)
 * - MQ-2 Gas/Smoke Sensor (A0 -> GPIO 34)
 * - DHT11 Temperature & Humidity Sensor (DATA -> GPIO 4)
 * - Optical Flame Photodiode Sensor (D0 -> GPIO 18)
 * - Active Piezo Buzzer (Anode -> GPIO 25)
 * - Red LED (GPIO 26), Yellow LED (GPIO 27), Green LED (GPIO 14)
 * 
 * Communication:
 * - Wi-Fi 802.11 b/g/n (2.4 GHz)
 * - HTTP POST JSON Telemetry -> Python FastAPI Backend -> Firebase Realtime DB
 * 
 * Educational Prototype Notice:
 * Safe low-voltage testing only. Not certified fire protection equipment.
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include "config.h"

// Initialize DHT11 sensor
#define DHTTYPE DHT11
DHT dht(PIN_DHT, DHTTYPE);

// Environmental Telemetry State Variables
float currentTemperature = 24.0;
float currentHumidity = 50.0;
float currentSmokePpm = 60.0;
bool isFlameDetected = false;

// System Status Enum
enum SystemStatus {
  STATUS_NORMAL,
  STATUS_WARNING,
  STATUS_CRITICAL
};

SystemStatus currentStatus = STATUS_NORMAL;

// Non-blocking Timing Timestamps
unsigned long lastSensorReadTime = 0;
unsigned long lastTelemetrySendTime = 0;
unsigned long lastBuzzerToggleTime = 0;
bool buzzerState = false;

// Serial Demonstration Override Flags
bool overrideActive = false;
bool overrideFlame = false;
float overrideSmoke = 0.0;
float overrideTemp = 0.0;

// Function Declarations
void setupPins();
void connectToWiFi();
void readSensors();
void evaluateSafetyStatus();
void updateActuators();
void sendTelemetryToBackend();
void handleSerialCommands();

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(SERIAL_BAUD_RATE);
  delay(1000);

  Serial.println("\n========================================================");
  Serial.println("         RESCUELENS XR - ESP32 NODE INITIALIZING        ");
  Serial.println("========================================================");

  setupPins();

  // Initialize DHT sensor
  dht.begin();
  Serial.println("[*] DHT11 Environmental Sensor Initialized.");

  // Connect to Wi-Fi network
  connectToWiFi();

  Serial.println("[*] RescueLens XR Edge Node Ready.");
  Serial.println("[*] TIP: Send '1' in Serial Monitor for Fire Test, '0' to Reset.");
  Serial.println("========================================================\n");
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  unsigned long currentMillis = millis();

  // Check for incoming serial demonstration commands
  handleSerialCommands();

  // 1. Periodic Sensor Reading (every 1 second)
  if (currentMillis - lastSensorReadTime >= SENSOR_READ_INTERVAL_MS) {
    lastSensorReadTime = currentMillis;
    readSensors();
    evaluateSafetyStatus();
  }

  // 2. Actuator Management (continuous update for flashing/buzzing)
  updateActuators();

  // 3. Periodic Telemetry Transmission to Backend (every 2 seconds)
  if (currentMillis - lastTelemetrySendTime >= TELEMETRY_INTERVAL_MS) {
    lastTelemetrySendTime = currentMillis;
    sendTelemetryToBackend();
  }
}

// ============================================================================
// HARDWARE PIN INITIALIZATION
// ============================================================================
void setupPins() {
  pinMode(PIN_LED_RED, OUTPUT);
  pinMode(PIN_LED_YELLOW, OUTPUT);
  pinMode(PIN_LED_GREEN, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);

  pinMode(PIN_FLAME_DIGITAL, INPUT);
  pinMode(PIN_MQ2_ANALOG, INPUT);

  // Self-test LED sequence on boot
  digitalWrite(PIN_LED_RED, HIGH);
  digitalWrite(PIN_LED_YELLOW, HIGH);
  digitalWrite(PIN_LED_GREEN, HIGH);
  delay(500);
  digitalWrite(PIN_LED_RED, LOW);
  digitalWrite(PIN_LED_YELLOW, LOW);
  digitalWrite(PIN_LED_GREEN, LOW);
}

// ============================================================================
// WI-FI CONNECTION
// ============================================================================
void connectToWiFi() {
  Serial.printf("[Wi-Fi] Connecting to SSID: %s\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    digitalWrite(PIN_LED_YELLOW, !digitalRead(PIN_LED_YELLOW)); // Blink yellow while connecting
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(PIN_LED_YELLOW, LOW);
    digitalWrite(PIN_LED_GREEN, HIGH);
    Serial.println("\n[Wi-Fi] Connected Successfully!");
    Serial.printf("[Wi-Fi] Assigned IP Address: %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("[Wi-Fi] Signal Strength (RSSI): %d dBm\n", WiFi.RSSI());
  } else {
    digitalWrite(PIN_LED_YELLOW, HIGH);
    Serial.println("\n[Wi-Fi] WARNING: Could not connect to Wi-Fi. Telemetry will retry automatically.");
  }
}

// ============================================================================
// SENSOR READING LOGIC
// ============================================================================
void readSensors() {
  if (overrideActive) {
    currentTemperature = overrideTemp;
    currentSmokePpm = overrideSmoke;
    isFlameDetected = overrideFlame;
    return;
  }

  // 1. Read DHT11
  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (!isnan(t)) {
    currentTemperature = t;
  }
  if (!isnan(h)) {
    currentHumidity = h;
  }

  // 2. Read MQ-2 Smoke Sensor (Analog ADC 0 - 4095 on ESP32)
  int rawAdc = analogRead(PIN_MQ2_ANALOG);
  // Calibration mapping: convert 12-bit ADC (0-4095) to approximate PPM curve
  // Clean air baseline ~ 50-80 PPM; Smoke spike ~ 300-800 PPM
  currentSmokePpm = (rawAdc / 4095.0) * 800.0;

  // 3. Read Optical Flame Sensor (Digital active LOW)
  // Low level (0) indicates infrared flame radiation detected
  int flameVal = digitalRead(PIN_FLAME_DIGITAL);
  isFlameDetected = (flameVal == LOW);
}

// ============================================================================
// SAFETY EVALUATION LOGIC
// ============================================================================
void evaluateSafetyStatus() {
  bool isCritical = false;
  bool isWarning = false;

  // Evaluation Rule 1: Instant Flame Detection
  if (isFlameDetected) {
    isCritical = true;
  }

  // Evaluation Rule 2: Smoke PPM Thresholds
  if (currentSmokePpm >= SMOKE_THRESHOLD_CRITICAL_PPM) {
    isCritical = true;
  } else if (currentSmokePpm >= SMOKE_THRESHOLD_WARNING_PPM) {
    isWarning = true;
  }

  // Evaluation Rule 3: Temperature Thresholds
  if (currentTemperature >= TEMP_THRESHOLD_CRITICAL_C) {
    isCritical = true;
  } else if (currentTemperature >= TEMP_THRESHOLD_WARNING_C) {
    isWarning = true;
  }

  if (isCritical) {
    currentStatus = STATUS_CRITICAL;
  } else if (isWarning) {
    currentStatus = STATUS_WARNING;
  } else {
    currentStatus = STATUS_NORMAL;
  }
}

// ============================================================================
// ACTUATOR OUTPUTS (BUZZER & STATUS LEDS)
// ============================================================================
void updateActuators() {
  unsigned long currentMillis = millis();

  switch (currentStatus) {
    case STATUS_NORMAL:
      digitalWrite(PIN_LED_GREEN, HIGH);
      digitalWrite(PIN_LED_YELLOW, LOW);
      digitalWrite(PIN_LED_RED, LOW);
      digitalWrite(PIN_BUZZER, LOW);
      break;

    case STATUS_WARNING:
      digitalWrite(PIN_LED_GREEN, LOW);
      digitalWrite(PIN_LED_RED, LOW);
      // Pulse yellow LED & intermittent buzzer chirp every 800ms
      if (currentMillis - lastBuzzerToggleTime >= 800) {
        lastBuzzerToggleTime = currentMillis;
        buzzerState = !buzzerState;
        digitalWrite(PIN_LED_YELLOW, buzzerState ? HIGH : LOW);
        digitalWrite(PIN_BUZZER, buzzerState ? HIGH : LOW);
      }
      break;

    case STATUS_CRITICAL:
      digitalWrite(PIN_LED_GREEN, LOW);
      digitalWrite(PIN_LED_YELLOW, LOW);
      // Rapid red flash & loud audio alarm every 200ms
      if (currentMillis - lastBuzzerToggleTime >= 200) {
        lastBuzzerToggleTime = currentMillis;
        buzzerState = !buzzerState;
        digitalWrite(PIN_LED_RED, buzzerState ? HIGH : LOW);
        digitalWrite(PIN_BUZZER, buzzerState ? HIGH : LOW);
      }
      break;
  }
}

// ============================================================================
// HTTP TELEMETRY TRANSMISSION TO BACKEND
// ============================================================================
void sendTelemetryToBackend() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[HTTP] Wi-Fi not connected. Attempting reconnection...");
    WiFi.reconnect();
    return;
  }

  HTTPClient http;
  http.begin(BACKEND_SERVER_URL);
  http.addHeader("Content-Type", "application/json");

  // Format JSON payload
  char jsonPayload[256];
  snprintf(jsonPayload, sizeof(jsonPayload),
    "{\"device_id\":\"%s\",\"room_id\":\"%s\",\"temperature\":%.1f,\"humidity\":%.1f,\"smoke_ppm\":%.1f,\"flame_detected\":%s}",
    DEVICE_ID,
    ROOM_ID,
    currentTemperature,
    currentHumidity,
    currentSmokePpm,
    isFlameDetected ? "true" : "false"
  );

  Serial.printf("[HTTP POST] Transmitting: %s\n", jsonPayload);

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.printf("[HTTP %d] Backend Response: %s\n", httpResponseCode, response.c_str());
  } else {
    Serial.printf("[HTTP ERROR] Failed to send telemetry. Code: %d (%s)\n",
      httpResponseCode, http.errorToString(httpResponseCode).c_str());
  }

  http.end();
}

// ============================================================================
// SERIAL COMMAND TEST INTERACTION (FOR CLASSROOM DEMONSTRATION)
// ============================================================================
void handleSerialCommands() {
  if (Serial.available() > 0) {
    char cmd = Serial.read();

    if (cmd == '1') {
      // Trigger simulated fire condition
      overrideActive = true;
      overrideFlame = true;
      overrideSmoke = 650.0;
      overrideTemp = 58.0;
      Serial.println("\n[DEMO OVERRIDE] >>> FIRE SCENARIO SIMULATED <<<");
      Serial.println("[DEMO OVERRIDE] Flame=TRUE, Smoke=650 PPM, Temp=58°C");
    } else if (cmd == '2') {
      // Trigger warning smoke condition
      overrideActive = true;
      overrideFlame = false;
      overrideSmoke = 320.0;
      overrideTemp = 42.0;
      Serial.println("\n[DEMO OVERRIDE] >>> ELEVATED SMOKE WARNING SIMULATED <<<");
    } else if (cmd == '0') {
      // Reset to physical sensor readings
      overrideActive = false;
      Serial.println("\n[DEMO OVERRIDE] >>> RESTORED PHYSICAL SENSORS <<<");
    }
  }
}
