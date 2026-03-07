import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/storage_reading.dart';
import '../../services/cold_storage_service.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.onSelectUnit});

  final ValueChanged<String> onSelectUnit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, StorageReading>>(
      stream: ColdStorageService.instance.watchLatestReadingsByUnit(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final units = snapshot.data ?? <String, StorageReading>{};
        if (units.isEmpty) {
          return const Center(child: Text('No unit data found in RTDB.'));
        }
        final health = _averageFreshness(units.values.toList());
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Health',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${health.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...units.entries.map((entry) {
              return _UnitCard(
                unitId: entry.key,
                reading: entry.value,
                onTap: () => onSelectUnit(entry.key),
              );
            }),
          ],
        );
      },
    );
  }

  double _averageFreshness(List<StorageReading> readings) {
    if (readings.isEmpty) {
      return 0;
    }
    final sum = readings.map((e) => e.freshnessScore).reduce((a, b) => a + b);
    return sum / readings.length;
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unitId,
    required this.reading,
    required this.onTap,
  });

  final String unitId;
  final StorageReading reading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (reading.riskStatus.toLowerCase()) {
      'safe' => Colors.green,
      'warning' => Colors.orange,
      _ => Colors.red,
    };
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unitId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(reading.riskStatus),
                    backgroundColor: color.withValues(alpha: 0.16),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Temperature: ${reading.temperature.toStringAsFixed(1)}°C'),
              Text('Humidity: ${reading.humidity.toStringAsFixed(1)}%'),
              Text('Gas Level: ${reading.gasLevel.toStringAsFixed(0)}'),
              Text('Freshness: ${reading.freshnessScore.toStringAsFixed(1)}%'),
              const SizedBox(height: 4),
              Text(
                'Updated: ${DateFormat('dd MMM, HH:mm:ss').format(reading.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
