import 'package:flutter/material.dart';

Widget heroImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final imagePath = path.trim();
  if (imagePath.isEmpty) {
    return _imagePlaceholder(width: width, height: height);
  }

  final isNetwork =
      imagePath.startsWith('http://') || imagePath.startsWith('https://');
  return Image(
    image: isNetwork ? NetworkImage(imagePath) : AssetImage(imagePath),
    fit: fit,
    width: width,
    height: height,
    filterQuality: FilterQuality.medium,
    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded || frame != null) return child;
      return Stack(
        fit: StackFit.expand,
        children: [
          _imagePlaceholder(width: width, height: height),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    },
    errorBuilder:
        errorBuilder ??
        (_, __, ___) => _imagePlaceholder(width: width, height: height),
  );
}

Widget _imagePlaceholder({double? width, double? height}) {
  return Container(
    width: width,
    height: height,
    color: const Color(0xFFE8ECF1),
    alignment: Alignment.center,
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_outline_rounded, color: Color(0xFF7A8696), size: 32),
        SizedBox(height: 4),
        Text(
          'Foto belum tersedia',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7A8696),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
