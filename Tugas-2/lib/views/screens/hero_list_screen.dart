import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/search_filter_bar.dart';
import 'hero_list_screen_other.dart';

class HeroListScreen extends StatefulWidget {
  const HeroListScreen({super.key});

  @override
  State<HeroListScreen> createState() => _HeroListScreenState();
}

class _HeroListScreenState extends State<HeroListScreen> {
  bool _isCatalogView = false;

  bool _hasActiveFilter(PahlawanController controller) {
    return controller.searchQuery.isNotEmpty ||
        controller.selectedRegion != 'Semua' ||
        controller.selectedEra != 'Semua';
  }

  void _setView(bool isCatalog) {
    if (_isCatalogView == isCatalog) return;
    HapticFeedback.selectionClick();
    setState(() => _isCatalogView = isCatalog);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    final heroes = controller.filteredHeroes;
    final hasFilter = _hasActiveFilter(controller);
    // Falls back to white if AppBarTheme doesn't set an explicit foreground.
    final appBarFg = Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Daftar Pahlawan Nasional',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: hasFilter
                ? Padding(
                    key: const ValueKey('reset'),
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.resetFilters();
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: appBarFg.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 15, color: appBarFg),
                            const SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: TextStyle(
                                color: appBarFg,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('no-reset')),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatsBanner(total: controller.allHeroes.length),
          const SearchFilterBar(),
          _ResultBar(
            controller: controller,
            count: heroes.length,
            hasFilter: hasFilter,
            isCatalogView: _isCatalogView,
            onViewChanged: _setView,
          ),
          Expanded(
            child: heroes.isEmpty
                ? _EmptyState(
                    onReset: () {
                      HapticFeedback.selectionClick();
                      controller.resetFilters();
                    },
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _isCatalogView
                        ? HeroListScreenOther(
                            key: const ValueKey('catalog'),
                            heroes: heroes,
                          )
                        : ListView.builder(
                            key: const ValueKey('list'),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: heroes.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: HeroCard(hero: heroes[index]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A single deliberate visual moment for the screen: a gradient banner with
/// an animated total count and quiet decorative circles. Kept as the one
/// "bold" element so the rest of the screen can stay calm and legible.
class _StatsBanner extends StatelessWidget {
  const _StatsBanner({required this.total});
  final int total;

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryRed, _darken(AppTheme.primaryRed, 0.16)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -24,
                top: -34,
                child: _decorCircle(120, 0.10),
              ),
              Positioned(
                right: 54,
                bottom: -46,
                child: _decorCircle(84, 0.08),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mengenang jasa para pahlawan bangsa',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            _AnimatedCount(
                              value: total,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pahlawan Nasional',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 30,
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

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

/// Animates a number counting up whenever [value] changes, e.g. when the
/// filtered result count updates. Motion here answers a real change in
/// data rather than decorating the page.
class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => Text('$animatedValue', style: style),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.controller,
    required this.count,
    required this.hasFilter,
    required this.isCatalogView,
    required this.onViewChanged,
  });

  final PahlawanController controller;
  final int count;
  final bool hasFilter;
  final bool isCatalogView;
  final ValueChanged<bool> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    _AnimatedCount(
                      value: count,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'pahlawan ditemukan',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (hasFilter) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (controller.selectedRegion != 'Semua')
                        _FilterTag(
                          label: controller.selectedRegion,
                          icon: Icons.location_on_rounded,
                        ),
                      if (controller.selectedEra != 'Semua')
                        _FilterTag(
                          label: controller.selectedEra,
                          icon: Icons.schedule_rounded,
                        ),
                      if (controller.searchQuery.isNotEmpty)
                        _FilterTag(
                          label: '"${controller.searchQuery}"',
                          icon: Icons.search_rounded,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ViewToggle(isCatalogView: isCatalogView, onChanged: onViewChanged),
        ],
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: AppTheme.primaryRed),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.isCatalogView, required this.onChanged});
  final bool isCatalogView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.view_list_rounded, !isCatalogView, () => onChanged(false)),
          _button(Icons.grid_view_rounded, isCatalogView, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _button(IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppTheme.primaryRed.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pahlawan Tidak Ditemukan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba ubah kata kunci pencarian atau reset filter wilayah Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}