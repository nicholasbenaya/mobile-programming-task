import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import 'app_routes.dart';

/// Kerangka utama: dua tab (Beranda, Peta) dan tombol Catat di tengah.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        // Peta dibuat saat dibuka agar langsung memuat data terbaru.
        children: [const HomeScreen(), _index == 1 ? const MapScreen() : const SizedBox.shrink()],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Catatan baru',
        onPressed: () => AppRoutes.openCapture(context),
        child: const Icon(Icons.add_a_photo_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(child: _NavItem(icon: Icons.dashboard_rounded, label: 'Beranda', selected: _index == 0, onTap: () => setState(() => _index = 0))),
            const SizedBox(width: 72),
            Expanded(child: _NavItem(icon: Icons.map_rounded, label: 'Peta', selected: _index == 1, onTap: () => setState(() => _index = 1))),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
