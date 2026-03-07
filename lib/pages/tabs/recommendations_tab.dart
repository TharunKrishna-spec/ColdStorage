import 'package:flutter/material.dart';

import '../../models/storage_reading.dart';
import '../../services/cold_storage_service.dart';
import '../../utils/risk_utils.dart';

class RecommendationsTab extends StatelessWidget {
  const RecommendationsTab({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, StorageReading>>(
      stream: ColdStorageService.instance.watchLatestReadingsByUnit(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reading = snapshot.data?[unitId];
        if (reading == null) {
          return Center(child: Text('No data for $unitId'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Recommendations: $unitId',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.thermostat),
                title: const Text('Temperature'),
                subtitle: Text('${reading.temperature.toStringAsFixed(1)}°C'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.water_drop),
                title: const Text('Humidity'),
                subtitle: Text('${reading.humidity.toStringAsFixed(1)}%'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.air),
                title: const Text('Gas Level'),
                subtitle: Text(reading.gasLevel.toStringAsFixed(0)),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  recommendationFor(reading),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
