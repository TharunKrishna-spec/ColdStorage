import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/storage_reading.dart';
import '../../services/cold_storage_service.dart';
import '../../theme/app_theme.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend analysis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Historical profile for ${unitId.replaceAll('_', ' ').toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.66),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ChartCard(
              title: 'Temperature',
              unit: 'C',
              color: const Color(0xFF276FBF),
              values: readings.map((e) => e.temperature).toList(),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Gas level',
              unit: 'level',
              color: const Color(0xFFD15C2E),
              values: readings.map((e) => e.gasLevel).toList(),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Freshness score',
              unit: '%',
              color: AppTheme.safe,
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
    required this.unit,
    required this.color,
    required this.values,
  });

  final String title;
  final String unit;
  final Color color;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final minY = values.reduce(math.min);
    final maxY = values.reduce(math.max);
    final latest = values.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  'Now ${latest.toStringAsFixed(1)} $unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Range ${minY.toStringAsFixed(1)} - ${maxY.toStringAsFixed(1)} $unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.62),
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: values,
                  lineColor: color,
                  fillColor: color.withValues(alpha: 0.12),
                  gridColor: AppTheme.ink.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final valueRange = (maxValue - minValue).abs() < 0.001 ? 1.0 : maxValue - minValue;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final dx = values.length == 1 ? size.width / 2 : size.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / valueRange;
      final dy = size.height - (normalized * (size.height - 12)) - 6;
      points.add(Offset(dx, dy));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(controlX, previous.dy, controlX, current.dy, current.dx, current.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      points.last,
      5,
      Paint()..color = lineColor,
    );
    canvas.drawCircle(
      points.last,
      10,
      Paint()..color = lineColor.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor;
  }
}
