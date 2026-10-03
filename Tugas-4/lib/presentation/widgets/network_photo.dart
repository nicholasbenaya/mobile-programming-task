import 'package:flutter/material.dart';

/// Foto jaringan dengan placeholder, fade-in setelah termuat, dan Hero opsional.
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.heroTag,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget image = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surfaceContainerHighest),
        if (url.isNotEmpty)
          Image.network(
            url,
            fit: fit,
            frameBuilder: (context, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    child: child,
                  ),
            errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_rounded, color: scheme.outline)),
          ),
      ],
    );
    if (width != null || height != null) {
      image = SizedBox(width: width, height: height, child: image);
    }
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return image;
  }
}
