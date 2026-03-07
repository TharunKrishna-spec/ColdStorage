#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <LiquidCrystal_I2C.h>

// -------- WIFI / FIREBASE --------
const char* WIFI_SSID = "REPLACE_WIFI_SSID";
const char* WIFI_PASSWORD = "REPLACE_WIFI_PASSWORD";
const char* FIREBASE_DB_URL = "https://foodtracking-2f928-default-rtdb.firebaseio.com";
const char* FIREBASE_AUTH_TOKEN = "REPLACE_ID_TOKEN_OR_DB_SECRET";
const char* STORAGE_UNIT = "storage_unit_01";

// -------- PIN CONFIG --------
#define DHTPIN 4
#define DHTTYPE DHT22
#define MQ135_PIN 34
#define LED_R 25
#define LED_G 26
#define LED_B 27
#define BUZZER_PIN 14

DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27, 16, 2);

float gasHistory[3] = {0, 0, 0};
unsigned long lastUpdateMs = 0;
const unsigned long updateIntervalMs = 15000;

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

void setLedForRisk(const String& risk) {
  if (risk == "Safe") {
    analogWrite(LED_R, 0); analogWrite(LED_G, 255); analogWrite(LED_B, 0);
    noTone(BUZZER_PIN);
  } else if (risk == "Warning") {
    analogWrite(LED_R, 255); analogWrite(LED_G, 120); analogWrite(LED_B, 0);
    noTone(BUZZER_PIN);
  } else {
    analogWrite(LED_R, 255); analogWrite(LED_G, 0); analogWrite(LED_B, 0);
    tone(BUZZER_PIN, 2000);
  }
}

bool patchJson(const String& path, const String& payload) {
  if (WiFi.status() != WL_CONNECTED) return false;
  HTTPClient http;
  String url = String(FIREBASE_DB_URL) + path + ".json?auth=" + FIREBASE_AUTH_TOKEN;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int code = http.PATCH(payload);
  http.end();
  return code > 0 && code < 300;
}

bool postJson(const String& path, const String& payload) {
  if (WiFi.status() != WL_CONNECTED) return false;
  HTTPClient http;
  String url = String(FIREBASE_DB_URL) + path + ".json?auth=" + FIREBASE_AUTH_TOKEN;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int code = http.POST(payload);
  http.end();
  return code > 0 && code < 300;
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_R, OUTPUT);
  pinMode(LED_G, OUTPUT);
  pinMode(LED_B, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  dht.begin();
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Cold Storage");
  lcd.setCursor(0, 1);
  lcd.print("Booting...");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
}

void loop() {
  if (millis() - lastUpdateMs < updateIntervalMs) return;
  lastUpdateMs = millis();

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int rawGas = analogRead(MQ135_PIN);
  float gasLevel = (float)rawGas;

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("DHT read failed");
    return;
  }

  gasHistory[0] = gasHistory[1];
  gasHistory[1] = gasHistory[2];
  gasHistory[2] = gasLevel;

  float freshness = calculateFreshness(gasLevel, temperature, humidity);
  String risk = classifyRisk(freshness);
  bool trendUp = gasTrendUp();

  setLedForRisk(risk);

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
  patchJson(basePath + "/latest", payload);
  postJson(basePath + "/history", payload);

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
    postJson("/alerts", alertPayload);
  }

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Temp:");
  lcd.print(temperature, 1);
  lcd.print("C G:");
  lcd.print((int)gasLevel);
  lcd.setCursor(0, 1);
  lcd.print("Fresh:");
  lcd.print((int)freshness);
  lcd.print("% ");
  lcd.print(risk.substring(0, min(4, (int)risk.length())));

  Serial.println(payload);
}
