import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../routes/app_routes.dart';
import '../../services/prefs_service.dart';
import '../ecobuddy/eco_buddy_screen.dart';
import '../ecolog/eco_log_screen.dart';
import '../ecomap/eco_map_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// Root navigation shell hosting the Toolbar (AppBar + overflow menu),
/// the Navigation Drawer, and the Bottom Navigation bar. The selected
/// destination is shown from an [IndexedStack] so each tab keeps its state.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const String _tag = 'EcoLifeShell';
  final _prefs = PrefsService();

  int _index = 0;
  String? _nickname;

  static const _titles = ['Home', 'EcoMap', 'EcoLog', 'EcoBuddy', 'Settings'];

  static const _tabs = [
    HomeScreen(),
    EcoMapScreen(),
    EcoLogScreen(),
    EcoBuddyScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    developer.log('initState: MainShell created.', name: _tag);
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final nickname = await _prefs.getNickname();
    if (mounted) setState(() => _nickname = nickname);
  }

  void _select(int index) {
    developer.log('_select: tab $index (${_titles[index]})', name: _tag);
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case 'diary':
                  Navigator.pushNamed(context, AppRoutes.ecoDiary);
                case 'ranking':
                  Navigator.pushNamed(context, AppRoutes.ranking);
                case 'about':
                  Navigator.pushNamed(context, AppRoutes.about);
                case 'logout':
                  _logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'diary', child: Text('EcoDiary')),
              PopupMenuItem(value: 'ranking', child: Text('Ranking')),
              PopupMenuItem(value: 'about', child: Text('About EcoLife')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      onDrawerChanged: (isOpen) {
        if (isOpen) _loadNickname();
      },
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'EcoMap'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'EcoLog'),
          NavigationDestination(
              icon: Icon(Icons.local_florist_outlined),
              selectedIcon: Icon(Icons.local_florist),
              label: 'EcoBuddy'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: EcoColors.primaryDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Hello, ${_nickname ?? 'EcoExplorer'}!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  '${AppConstants.appName} ${AppConstants.releaseTag}',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          _drawerTab(0, Icons.home_outlined, 'Home'),
          _drawerTab(1, Icons.map_outlined, 'EcoMap'),
          _drawerTab(2, Icons.list_alt_outlined, 'EcoLog'),
          _drawerTab(3, Icons.local_florist_outlined, 'EcoBuddy'),
          _drawerTab(4, Icons.settings_outlined, 'Settings'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('EcoDiary'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.ecoDiary);
            },
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard_outlined),
            title: const Text('Ranking'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.ranking);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About EcoLife'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.about);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: EcoColors.climateRed),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    developer.log('_logout: signing out.', name: _tag);
    await FirebaseAuth.instance.signOut();
  }

  Widget _drawerTab(int index, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _index == index,
      selectedColor: EcoColors.primary,
      onTap: () {
        Navigator.pop(context);
        _select(index);
      },
    );
  }
}
