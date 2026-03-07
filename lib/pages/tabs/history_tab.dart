import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/storage_reading.dart';
import '../../services/cold_storage_service.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StorageReading>>(
      stream: ColdStorageService.instance.watchHistory(unitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final readings = snapshot.data ?? <StorageReading>[];
        if (readings.isEmpty) {
          return Center(child: Text('No history found for $unitId'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Historical Data: $unitId',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Temperature (°C)',
              color: Colors.blue,
              values: readings.map((e) => e.temperature).toList(),
            ),
            _ChartCard(
              title: 'Gas Level',
              color: Colors.deepOrange,
              values: readings.map((e) => e.gasLevel).toList(),
            ),
            _ChartCard(
              title: 'Freshness Score (%)',
              color: Colors.green,
              values: readings.map((e) => e.freshnessScore).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.color,
    required this.values,
  });

  final String title;
  final Color color;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final spots = values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
