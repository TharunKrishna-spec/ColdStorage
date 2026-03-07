import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/cold_storage_service.dart';
import '../services/notification_service.dart';
import 'tabs/alerts_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/recommendations_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  String _selectedUnit = 'storage_unit_01';

  @override
  void initState() {
    super.initState();
    ColdStorageService.instance.seedIfMissing();
    NotificationService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardTab(onSelectUnit: _setSelectedUnit),
      HistoryTab(unitId: _selectedUnit),
      const AlertsTab(),
      RecommendationsTab(unitId: _selectedUnit),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cold Storage Monitoring'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'History'),
          NavigationDestination(icon: Icon(Icons.warning), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.tips_and_updates), label: 'Advice'),
        ],
      ),
    );
  }

  void _setSelectedUnit(String unitId) {
    setState(() {
      _selectedUnit = unitId;
    });
  }
}
