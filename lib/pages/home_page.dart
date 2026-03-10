import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/cold_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
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
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cold Storage Monitoring',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'Unit focus: $_selectedUnit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.65),
                  ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_done, size: 18, color: AppTheme.safe),
                SizedBox(width: 8),
                Text(
                  'Realtime',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F0E6), Color(0xFFEAF3F1)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: pages[_index],
        ),
      ),
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
