import 'package:flutter/material.dart';
import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/hero_image.dart';
import 'hero_detail_screen.dart';

class HeroListScreenOther extends StatelessWidget {
  final List<HeroModel> heroes;

  const HeroListScreenOther({super.key, required this.heroes});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 3 kolom mobile, 4-5 kolom layar lebar
        final crossAxisCount = constraints.maxWidth > 900
            ? 5
            : constraints.maxWidth > 600
                ? 4
                : 3;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: heroes.length,
          itemBuilder: (context, index) => _CatalogTile(hero: heroes[index]),
        );
      },
    );
  }
}

class _CatalogTile extends StatelessWidget {
  final HeroModel hero;

  const _CatalogTile({required this.hero});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gambar Pahlawan dengan heroImage + Session Cache
          heroImage(
            hero.photoPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(
                Icons.person,
                size: 36,
                color: AppTheme.textMuted,
              ),
            ),
          ),

          // Nama di bagian bawah foto dengan gradasi gelap
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Text(
                hero.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Area tap + efek ripple, diletakkan paling atas
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HeroDetailScreen(hero: hero),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}