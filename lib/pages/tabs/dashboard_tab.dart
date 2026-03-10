import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/storage_reading.dart';
import '../../services/cold_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/risk_palette.dart';

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

        final readings = units.values.toList();
        final health = _averageFreshness(readings);
        final criticalCount = readings
            .where((reading) => reading.riskStatus.toLowerCase() == 'critical')
            .length;
        final warningCount = readings
            .where((reading) => reading.riskStatus.toLowerCase() == 'warning')
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _HeroPanel(
              health: health,
              totalUnits: units.length,
              warningCount: warningCount,
              criticalCount: criticalCount,
            ),
            const SizedBox(height: 16),
            Text(
              'Storage units',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            ...units.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UnitCard(
                  unitId: entry.key,
                  reading: entry.value,
                  onTap: () => onSelectUnit(entry.key),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _averageFreshness(List<StorageReading> readings) {
    final sum = readings.fold<double>(
      0,
      (running, item) => running + item.freshnessScore,
    );
    return readings.isEmpty ? 0 : sum / readings.length;
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.health,
    required this.totalUnits,
    required this.warningCount,
    required this.criticalCount,
  });

  final double health;
  final int totalUnits;
  final int warningCount;
  final int criticalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.ink, AppTheme.ocean, AppTheme.teal],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Realtime Fleet Snapshot',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${health.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Current storage health across all monitored units.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Units',
                  value: '$totalUnits',
                  tone: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Watch',
                  value: '$warningCount',
                  tone: const Color(0xFFFFD08A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Action',
                  value: '$criticalCount',
                  tone: const Color(0xFFFF9A8C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: tone,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
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
    final color = riskColor(reading.riskStatus);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayUnitName(unitId),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Updated ${DateFormat('dd MMM, HH:mm:ss').format(reading.timestamp)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.58),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: color),
                        const SizedBox(width: 8),
                        Text(
                          '${reading.riskStatus} • ${riskLabel(reading.riskStatus)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.thermostat,
                      label: 'Temperature',
                      value: '${reading.temperature.toStringAsFixed(1)} C',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: '${reading.humidity.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.air,
                      label: 'Gas level',
                      value: reading.gasLevel.toStringAsFixed(0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.eco_outlined,
                      label: 'Freshness',
                      value: '${reading.freshnessScore.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayUnitName(String unitId) {
    return unitId.replaceAll('_', ' ').toUpperCase();
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.ocean, size: 20),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
