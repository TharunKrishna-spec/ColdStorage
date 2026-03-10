#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// -------- WIFI / FIREBASE --------
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
const char* FIREBASE_DB_URL = "https://foodtracking-2f928-default-rtdb.firebaseio.com";
const char* FIREBASE_AUTH_TOKEN = "YOUR_FIREBASE_AUTH_TOKEN";
const char* STORAGE_UNIT = "storage_unit_01";  // Change per ESP32 device

// -------- PIN CONFIG --------
#define DHTPIN 4
#define DHTTYPE DHT22
#define MQ135_PIN 34

DHT dht(DHTPIN, DHTTYPE);

float gasHistory[3] = {0, 0, 0};
unsigned long lastUpdateMs = 0;
const unsigned long updateIntervalMs = 15000;
unsigned long lastWifiRetryMs = 0;
const unsigned long wifiRetryIntervalMs = 10000;

float calculateFreshness(float gasLevel, float temperature, float humidity) {
  float score = 100.0 - (gasLevel * 0.4) - (temperature * 0.3) - (humidity * 0.3);
  if (score < 0) score = 0;
  if (score > 100) score = 100;
  return score;
}

String classifyRisk(float freshness) {
  if (freshness > 70) return "Safe";
  if (freshness >= 40) return "Warning";
  return "Critical";
}

bool gasTrendUp() {
  return gasHistory[2] > gasHistory[1] && gasHistory[1] > gasHistory[0];
}

void reportStatus(const String& status, const String& detail = "") {
  Serial.print("[STATUS] ");
  Serial.print(status);
  if (detail.length() > 0) {
    Serial.print(" - ");
    Serial.print(detail);
  }
  Serial.println();
}

void connectWiFi() {
  reportStatus("WIFI_CONNECTING", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

bool ensureWiFiConnected() {
  if (WiFi.status() == WL_CONNECTED) {
    return true;
  }

  if (millis() - lastWifiRetryMs >= wifiRetryIntervalMs) {
    lastWifiRetryMs = millis();
    reportStatus("WIFI_DISCONNECTED", "Retrying connection");
    WiFi.disconnect();
    connectWiFi();
  }

  return false;
}

bool patchJson(const String& path, const String& payload) {
  if (!ensureWiFiConnected()) return false;
  HTTPClient http;
  String url = String(FIREBASE_DB_URL) + path + ".json?auth=" + FIREBASE_AUTH_TOKEN;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int code = http.PATCH(payload);
  http.end();
  reportStatus("FIREBASE_PATCH", String(code) + " " + path);
  return code > 0 && code < 300;
}

bool postJson(const String& path, const String& payload) {
  if (!ensureWiFiConnected()) return false;
  HTTPClient http;
  String url = String(FIREBASE_DB_URL) + path + ".json?auth=" + FIREBASE_AUTH_TOKEN;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int code = http.POST(payload);
  http.end();
  reportStatus("FIREBASE_POST", String(code) + " " + path);
  return code > 0 && code < 300;
}

void setup() {
  Serial.begin(115200);
  reportStatus("BOOT", "Cold storage monitor starting");

  dht.begin();

  connectWiFi();
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  reportStatus("WIFI_CONNECTED", WiFi.localIP().toString());
}

void loop() {
  if (millis() - lastUpdateMs < updateIntervalMs) return;
  lastUpdateMs = millis();

  if (!ensureWiFiConnected()) {
    reportStatus("WAITING", "WiFi not connected");
    return;
  }

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int rawGas = analogRead(MQ135_PIN);
  float gasLevel = (float)rawGas;

  if (isnan(temperature) || isnan(humidity)) {
    reportStatus("SENSOR_ERROR", "DHT read failed");
    return;
  }

  gasHistory[0] = gasHistory[1];
  gasHistory[1] = gasHistory[2];
  gasHistory[2] = gasLevel;

  float freshness = calculateFreshness(gasLevel, temperature, humidity);
  String risk = classifyRisk(freshness);
  bool trendUp = gasTrendUp();

  DynamicJsonDocument doc(512);
  unsigned long timestamp = (unsigned long)(millis() / 1000) + 1700000000;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["gas_level"] = gasLevel;
  doc["freshness_score"] = freshness;
  doc["risk_status"] = risk;
  doc["timestamp"] = timestamp;

  String payload;
  serializeJson(doc, payload);

  String basePath = "/cold_storage_system/" + String(STORAGE_UNIT);
  bool latestOk = patchJson(basePath + "/latest", payload);
  bool historyOk = postJson(basePath + "/history", payload);
  if (latestOk && historyOk) {
    reportStatus(
      "UPLOAD_OK",
      "T=" + String(temperature, 1) +
          " H=" + String(humidity, 1) +
          " G=" + String(gasLevel, 0) +
          " F=" + String(freshness, 1) +
          " " + risk
    );
  } else {
    reportStatus("UPLOAD_FAILED", basePath);
  }

  if (trendUp || risk == "Critical" || temperature > 4.0) {
    DynamicJsonDocument alertDoc(384);
    alertDoc["storage_unit"] = STORAGE_UNIT;
    if (trendUp) {
      alertDoc["message"] = "Gas levels rising rapidly. Possible spoilage starting.";
      alertDoc["severity"] = "critical";
    } else if (risk == "Critical") {
      alertDoc["message"] = "Freshness score is critical. Immediate inspection required.";
      alertDoc["severity"] = "critical";
    } else {
      alertDoc["message"] = "Temperature above optimal range. Reduce below 4C.";
      alertDoc["severity"] = "warning";
    }
    alertDoc["timestamp"] = timestamp;
    String alertPayload;
    serializeJson(alertDoc, alertPayload);
    bool alertOk = postJson("/alerts", alertPayload);
    reportStatus(alertOk ? "ALERT_POSTED" : "ALERT_FAILED", risk);
  }

  Serial.println(payload);
}
