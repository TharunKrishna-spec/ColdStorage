# IoT Cold Storage Monitoring System

Cold storage monitoring system for fish and other perishable goods using:
- Flutter mobile app
- Firebase Authentication
- Firebase Realtime Database
- Firebase Cloud Messaging
- Firebase Cloud Functions
- ESP32 with DHT22 and MQ135

## Overview

The system monitors:
- temperature
- humidity
- gas level

The ESP32 calculates:
- freshness score
- risk status
- simple gas-rise trend alerts

The mobile app provides:
- login and signup
- live dashboard
- multi-unit monitoring
- history charts
- incident log
- recommendations

## Current Hardware Scope

Current firmware is sensor-only. It does not use:
- LCD
- RGB LED
- buzzer

The app and Firebase backend handle monitoring and alerts.

## Project Structure

- `lib/` Flutter app
- `firebase/rtdb.rules.json` RTDB rules
- `firebase/rtdb_seed.json` sample RTDB data
- `functions/` Firebase Cloud Function for push alerts
- `esp32/cold_storage_monitor.ino` ESP32 firmware
- `android/app/google-services.json` Android Firebase config

## Firebase Project

- Project ID: `foodtracking-2f928`
- Android app id: `foodttracker.in`
- RTDB URL: `https://foodtracking-2f928-default-rtdb.firebaseio.com`

## Android Build Requirements

The current app requires:
- `minSdk = 23`
- `ndkVersion = "27.0.12077973"`

These are already set in [android/app/build.gradle.kts](e:/projects/Cold%20storage/android/app/build.gradle.kts).

## Flutter App Setup

From the project root:

```bash
flutter pub get
flutter run
```

If Gradle or Flutter cache causes stale build issues:

```bash
flutter clean
flutter pub get
flutter run
```

## Firebase Console Setup

### 1. Enable Authentication

In Firebase Console:
- Authentication
- Sign-in method
- Enable `Email/Password`

If this is not enabled, login/signup will fail.

### 2. Realtime Database Rules

Use either:
- Firebase Console -> Realtime Database -> Rules -> paste rules
- Firebase CLI -> `firebase deploy --only database`

Rules file:
- [firebase/rtdb.rules.json](e:/projects/Cold%20storage/firebase/rtdb.rules.json)

### 3. Sample Data

Optional. Use this only if you want initial test data before the ESP32 starts writing.

You can:
- import [firebase/rtdb_seed.json](e:/projects/Cold%20storage/firebase/rtdb_seed.json) from the RTDB Data tab
- or use CLI:

```bash
firebase database:set / firebase/rtdb_seed.json --confirm
```

## Firebase CLI Deploy

Install and configure once:

```bash
npm install -g firebase-tools
firebase login
firebase use foodtracking-2f928
```

Deploy database rules:

```bash
firebase deploy --only database
```

Deploy Cloud Functions:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## ESP32 Setup

Open [esp32/cold_storage_monitor.ino](e:/projects/Cold%20storage/esp32/cold_storage_monitor.ino) and fill:

```cpp
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
const char* FIREBASE_DB_URL = "https://foodtracking-2f928-default-rtdb.firebaseio.com";
const char* FIREBASE_AUTH_TOKEN = "YOUR_FIREBASE_AUTH_TOKEN";
const char* STORAGE_UNIT = "storage_unit_01";
```

### ESP32 behavior

The firmware:
- connects to Wi-Fi
- retries Wi-Fi automatically if disconnected
- reads DHT22 and MQ135
- calculates freshness score
- writes latest reading to Firebase
- appends history entry to Firebase
- creates alert records when conditions are risky
- prints status logs to Serial Monitor

### Firebase nodes written by ESP32

The ESP32 writes to:
- `cold_storage_system/{storage_unit}/latest`
- `cold_storage_system/{storage_unit}/history`
- `alerts`

## Realtime Database Data Contract

### Reading payload

```json
{
  "temperature": 3.2,
  "humidity": 72.5,
  "gas_level": 240,
  "freshness_score": 82,
  "risk_status": "Safe",
  "timestamp": 1762500000
}
```

### Alert payload

```json
{
  "storage_unit": "storage_unit_01",
  "message": "Gas levels rising rapidly. Possible spoilage starting.",
  "severity": "critical",
  "timestamp": 1762500000
}
```

## Freshness and Risk Logic

Current formula:

```text
Freshness Score =
100 - (Gas Level * 0.4)
    - (Temperature * 0.3)
    - (Humidity * 0.3)
```

Risk classification:
- `> 70` -> Safe
- `40 to 70` -> Warning
- `< 40` -> Critical

Trend detection:

```text
gas(t) > gas(t-1) > gas(t-2)
```

## App Notes

- The login screen uses real Firebase Authentication.
- If login fails, check Email/Password provider in Firebase Console first.
- The dashboard reads from Realtime Database and expects authenticated access under current rules.
- Notification token upload only works when a user is signed in.

## Known Limitations

- `MQ135` is a general gas sensor, not a calibrated spoilage-gas sensor.
- ESP32 firmware currently uses placeholder-style timestamp generation, not true NTP time.
- Freshness logic is heuristic, not lab-calibrated.
- Push alerts depend on proper Firebase Functions deployment.

## Recommended Next Improvements

1. Add NTP-based real timestamps in ESP32 firmware.
2. Replace MQ135 with a better-calibrated gas sensing approach.
3. Improve freshness scoring with adaptive trend weighting.
4. Add device authentication flow instead of static token usage.
