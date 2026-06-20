import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import '../providers/task_provider.dart';
import 'diary_editor_screen.dart';
import 'diary_list_screen.dart';
import 'home_dashboard_screen.dart';
import 'insights_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';

/// Main authenticated shell with bottom navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['MindLog', 'Diary', 'Tasks', 'Insights'];

  @override
  void initState() {
    super.initState();
    // Load data once the DB is unlocked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().load();
      context.read<TaskProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeDashboardScreen(),
      DiaryListScreen(),
      TasksScreen(),
      InsightsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Lock',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => context.read<AuthProvider>().lock(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New entry'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Diary'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Insights'),
        ],
      ),
    );
  }
}
