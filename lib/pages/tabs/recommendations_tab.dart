import 'package:flutter/material.dart';

import '../../models/storage_reading.dart';
import '../../services/cold_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/risk_palette.dart';
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

        final risk = riskColor(reading.riskStatus);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [risk.withValues(alpha: 0.92), AppTheme.ink],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unitId.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reading.riskStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendationFor(reading),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SignalCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${reading.temperature.toStringAsFixed(1)} C',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SignalCard(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '${reading.humidity.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SignalCard(
                    icon: Icons.air,
                    label: 'Gas level',
                    value: reading.gasLevel.toStringAsFixed(0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SignalCard(
                    icon: Icons.eco,
                    label: 'Freshness',
                    value: '${reading.freshnessScore.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended operator action',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _operatorAction(reading),
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _operatorAction(StorageReading reading) {
    if (reading.riskStatus.toLowerCase() == 'critical') {
      return 'Inspect inventory immediately, isolate affected batches, and verify chamber setpoint and airflow.';
    }
    if (reading.riskStatus.toLowerCase() == 'warning') {
      return 'Increase observation frequency and check refrigeration performance before the unit drifts into critical condition.';
    }
    return 'Conditions are stable. Continue routine observation and maintain current storage settings.';
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.ocean),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.62),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
