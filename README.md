# IoT Cold Storage Monitoring System

Full implementation for cold storage monitoring with fish as the primary example:
- Flutter mobile app
- Firebase Authentication + Realtime Database + FCM
- Cloud Function for push alert fan-out
- ESP32 firmware with DHT22 + MQ135 + LCD + RGB LED + buzzer

## 1) Project Structure

- `lib/` Flutter app (auth, dashboard, history, alerts, recommendations)
- `firebase/rtdb.rules.json` Realtime Database rules
- `firebase/rtdb_seed.json` Seed data format
- `functions/` Firebase Cloud Function for FCM alerts
- `esp32/cold_storage_monitor.ino` Device firmware

## 2) App ID and Firebase

- Android app id is set to `foodttracker.in`.
- `android/app/google-services.json` is already copied from your file.
- Firebase options in `lib/firebase_options.dart` are populated from your config.

## 3) Flutter Run

```bash
flutter pub get
flutter run
```

## 4) Firebase Deploy

Install tools once:

```bash
npm install -g firebase-tools
firebase login
firebase use foodtracking-2f928
```

Deploy RTDB rules:

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

Seed sample RTDB data:

```bash
firebase database:set / firebase/rtdb_seed.json --confirm
```

## 5) Authentication Setup

Enable Email/Password provider in Firebase Console:
- Firebase Console -> Authentication -> Sign-in method -> Email/Password -> Enable

## 6) Device Setup (ESP32)

Open `esp32/cold_storage_monitor.ino` and set:
- `WIFI_SSID`
- `WIFI_PASSWORD`
- `FIREBASE_AUTH_TOKEN` (ID token or database secret flow)

Flash firmware and verify updates in:
- `cold_storage_system/storage_unit_01/latest`
- `cold_storage_system/storage_unit_01/history`
- `alerts`

## 7) Data Contract

Each reading payload:

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

Alert payload:

```json
{
  "storage_unit": "storage_unit_01",
  "message": "Gas levels rising rapidly. Possible spoilage starting.",
  "severity": "critical",
  "timestamp": 1762500000
}
```
