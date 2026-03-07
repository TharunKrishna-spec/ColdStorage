import 'package:firebase_database/firebase_database.dart';

import '../models/alert_event.dart';
import '../models/storage_reading.dart';

class ColdStorageService {
  ColdStorageService._();
  static final ColdStorageService instance = ColdStorageService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  Stream<Map<String, StorageReading>> watchLatestReadingsByUnit() {
    return _root.child('cold_storage_system').onValue.map((event) {
      final map = <String, StorageReading>{};
      final snapshotValue = event.snapshot.value;
      if (snapshotValue is! Map) {
        return map;
      }

      snapshotValue.forEach((key, value) {
        if (value is Map && value['latest'] is Map) {
          map[key.toString()] = StorageReading.fromMap(value['latest'] as Map);
        }
      });
      return map;
    });
  }

  Stream<List<StorageReading>> watchHistory(String unitId) {
    return _root
        .child('cold_storage_system/$unitId/history')
        .orderByChild('timestamp')
        .limitToLast(60)
        .onValue
        .map((event) {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue is! Map) {
        return <StorageReading>[];
      }
      final readings = <StorageReading>[];
      snapshotValue.forEach((_, value) {
        if (value is Map) {
          readings.add(StorageReading.fromMap(value));
        }
      });
      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return readings;
    });
  }

  Stream<List<AlertEvent>> watchAlerts() {
    return _root
        .child('alerts')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .map((event) {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue is! Map) {
        return <AlertEvent>[];
      }
      final alerts = <AlertEvent>[];
      snapshotValue.forEach((id, value) {
        if (value is Map) {
          alerts.add(AlertEvent.fromMap(id.toString(), value));
        }
      });
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return alerts;
    });
  }

  Future<void> seedIfMissing() async {
    final reference = _root.child('cold_storage_system');
    final snapshot = await reference.get();
    if (snapshot.exists) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final baseUnit = <String, dynamic>{
      'latest': <String, dynamic>{
        'temperature': 3.2,
        'humidity': 72.5,
        'gas_level': 240,
        'freshness_score': 82,
        'risk_status': 'Safe',
        'timestamp': now,
      },
      'history': <String, dynamic>{
        'seed_1': <String, dynamic>{
          'temperature': 3.4,
          'humidity': 71.0,
          'gas_level': 230,
          'freshness_score': 85,
          'risk_status': 'Safe',
          'timestamp': now - 1200,
        },
        'seed_2': <String, dynamic>{
          'temperature': 3.3,
          'humidity': 71.7,
          'gas_level': 235,
          'freshness_score': 84,
          'risk_status': 'Safe',
          'timestamp': now - 600,
        },
        'seed_3': <String, dynamic>{
          'temperature': 3.2,
          'humidity': 72.5,
          'gas_level': 240,
          'freshness_score': 82,
          'risk_status': 'Safe',
          'timestamp': now,
        },
      },
    };

    await reference.set(<String, dynamic>{
      'storage_unit_01': baseUnit,
      'storage_unit_02': <String, dynamic>{
        ...baseUnit,
        'latest': <String, dynamic>{
          'temperature': 5.9,
          'humidity': 79.2,
          'gas_level': 320,
          'freshness_score': 63,
          'risk_status': 'Warning',
          'timestamp': now,
        },
      },
      'storage_unit_03': <String, dynamic>{
        ...baseUnit,
        'latest': <String, dynamic>{
          'temperature': 8.1,
          'humidity': 84.5,
          'gas_level': 470,
          'freshness_score': 34,
          'risk_status': 'Critical',
          'timestamp': now,
        },
      },
    });
  }
}
