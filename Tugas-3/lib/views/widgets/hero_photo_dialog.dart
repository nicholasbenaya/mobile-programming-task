import 'package:flutter/material.dart';

import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/hero_image.dart';
import '../screens/hero_detail_screen.dart';

class HeroPhotoDialog extends StatelessWidget {
  final HeroModel hero;

  const HeroPhotoDialog({super.key, required this.hero});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Box dengan Background Patriotik & Foto Utuh Tanpa Zoom
            Stack(
              alignment: Alignment.center,
              children: [
                // Background Box Gradien
                Container(
                  height: 290,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF8B0000),
                        Color(0xFF500005),
                        Color(0xFF1E293B),
                      ],
                    ),
                  ),
                ),

                // Elemen Box Pembingkai Foto (Foto tetap utuh, tidak ngezoom)
                Container(
                  width: 175,
                  height: 235,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.accentGold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        heroImage(
                          hero.photoPath,
                          fit: BoxFit.contain, // Foto 100% utuh tanpa zoom
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.white54,
                                ),
                              ),
                        ),
                        // Label Box Penutup Bawah
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            color: Colors.black.withValues(alpha: 0.75),
                            child: const Text(
                              'POTRET RESMI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Tutup di Sudut Kanan Atas
                Positioned(
                  top: 12,
                  right: 12,
                  child: _HoverableCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            // Deskripsi & Data Lengkap di Bawah Box Foto
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hero.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepNavy,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hero.knownAs,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warmAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hero.regionGroup,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warmAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 15,
                        color: AppTheme.primaryRed,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hero.fullOrigin,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 15,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Masa Hidup: ${hero.lifeTimeYears} (${hero.ageAtDeath} tahun)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hero.shortBio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _HoverableDetailButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .push(HeroDetailScreen.route(hero));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverableCloseButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _HoverableCloseButton({required this.onPressed});

  @override
  State<_HoverableCloseButton> createState() => _HoverableCloseButtonState();
}

class _HoverableCloseButtonState extends State<_HoverableCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.black87 : Colors.black45,
          shape: BoxShape.circle,
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
          padding: EdgeInsets.zero,
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class _HoverableDetailButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _HoverableDetailButton({required this.onPressed});

  @override
  State<_HoverableDetailButton> createState() => _HoverableDetailButtonState();
}

class _HoverableDetailButtonState extends State<_HoverableDetailButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRed.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovered
                ? AppTheme.primaryRed.withValues(alpha: 0.9)
                : AppTheme.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: _isHovered ? 3 : 0,
          ),
          onPressed: widget.onPressed,
          icon: const Icon(Icons.menu_book_rounded, size: 17),
          label: const Text(
            'Buka Halaman Detail Pahlawan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
