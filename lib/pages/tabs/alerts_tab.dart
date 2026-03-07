import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/alert_event.dart';
import '../../services/cold_storage_service.dart';

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertEvent>>(
      stream: ColdStorageService.instance.watchAlerts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snapshot.data ?? <AlertEvent>[];
        if (alerts.isEmpty) {
          return const Center(child: Text('No alerts yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            final color = switch (alert.severity.toLowerCase()) {
              'critical' => Colors.red,
              'warning' => Colors.orange,
              _ => Colors.blueGrey,
            };
            return Card(
              child: ListTile(
                leading: Icon(Icons.warning, color: color),
                title: Text('${alert.storageUnit} - ${alert.severity.toUpperCase()}'),
                subtitle: Text(alert.message),
                trailing: Text(DateFormat('dd/MM HH:mm').format(alert.timestamp)),
              ),
            );
          },
        );
      },
    );
  }
}
