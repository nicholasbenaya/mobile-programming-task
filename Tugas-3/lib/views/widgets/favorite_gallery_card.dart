import 'package:flutter/material.dart';

import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/hero_image.dart';
import '../screens/hero_detail_screen.dart';
import 'hero_photo_dialog.dart';

/// Kartu Galeri Khusus untuk Koleksi Pahlawan Favorit.
/// Dirancang dengan estetika museum bernuansa Zamrud & Emas Nusantara,
/// dilengkapi foto potret besar, lencana bintang emas interaktif,
/// cuplikan mutiara kata, serta tombol pratinjau foto utuh.
class FavoriteGalleryCard extends StatelessWidget {
  final HeroModel hero;
  final VoidCallback? onRemove;
  final bool showQuote;

  const FavoriteGalleryCard({
    super.key,
    required this.hero,
    this.onRemove,
    this.showQuote = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(HeroDetailScreen.route(hero));
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Gambar Potret Pahlawan
                heroImage(
                  hero.photoPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      size: 52,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // 2. Gradien Hitam Sinematik untuk Keterbacaan Teks
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.94),
                        ],
                        stops: const [0.0, 0.30, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Lencana Wilayah (Kiri Atas)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 11,
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hero.regionGroup,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Tombol Aksi Kanan Atas: Bintang Favorit & Fullscreen
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Zoom Foto
                      Tooltip(
                        message: 'Perbesar Foto',
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => HeroPhotoDialog(hero: hero),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(5.5),
                              child: Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tombol Hapus Favorit dengan Bintang Emas Berkilau
                      Tooltip(
                        message: 'Hapus dari Favorit',
                        child: Material(
                          color: AppTheme.accentGold.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onRemove,
                            child: const Padding(
                              padding: EdgeInsets.all(5.5),
                              child: Icon(
                                Icons.star_rounded,
                                color: AppTheme.deepNavy,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Informasi Tokoh & Mutiara Kata (Bagian Bawah)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Tokoh
                      Text(
                        hero.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Asal Daerah & Masa Hidup
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11.5,
                            color: AppTheme.accentGold,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              hero.fullOrigin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hero.lifeTimeYears,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      // Cuplikan Kutipan Pahlawan (Jika Ada)
                      if (showQuote && hero.famousQuote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentGold.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                size: 12,
                                color: AppTheme.accentGold,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '"${hero.famousQuote}"',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 10,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
