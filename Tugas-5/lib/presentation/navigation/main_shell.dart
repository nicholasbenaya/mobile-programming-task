import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import '../widgets/motion/press_scale.dart';
import 'app_routes.dart';

/// Kerangka utama: dua tab (Beranda, Peta) dan tombol Catat di tengah.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  double _direction = 1;

  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
  late final Animation<double> _curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _direction = i > _index ? 1 : -1;
      _index = i;
    });
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween(begin: Offset(0.05 * _direction, 0), end: Offset.zero).animate(_curve),
          child: IndexedStack(
            index: _index,
            // Peta dibuat saat dibuka agar langsung memuat data terbaru.
            children: [const HomeScreen(), _index == 1 ? const MapScreen() : const SizedBox.shrink()],
          ),
        ),
      ),
      floatingActionButton: PressScale(
        scale: 0.9,
        child: FloatingActionButton(
          tooltip: 'Catatan baru',
          onPressed: () => AppRoutes.openCapture(context),
          child: const Icon(Icons.add_a_photo_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(child: _NavItem(icon: Icons.dashboard_rounded, label: 'Beranda', selected: _index == 0, onTap: () => _select(0))),
            const SizedBox(width: 72),
            Expanded(child: _NavItem(icon: Icons.map_rounded, label: 'Peta', selected: _index == 1, onTap: () => _select(1))),
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: color),
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: color),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
